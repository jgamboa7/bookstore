const AWS = require('aws-sdk');

// Initialize S3 and DynamoDB clients with exponential backoff for retries
const s3 = new AWS.S3({
  signatureVersion: 'v4',
  maxRetries: 3,
  retryDelayOptions: { base: 300 }
});

const dynamo = new AWS.DynamoDB.DocumentClient({
  maxRetries: 3,
  retryDelayOptions: { base: 300 }
});

// Constants
const URL_EXPIRATION_SECONDS = 300; // Signed URL valid for 5 minutes
const DEFAULT_CORS_ORIGIN = 'https://bookstore.jresume.cloud';
const RESPONSE_HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': process.env.CORS_ALLOWED_ORIGIN || DEFAULT_CORS_ORIGIN,
  'Access-Control-Allow-Credentials': true,
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key'
};

/**
 * Format standard API Gateway response
 * @param {number} statusCode - HTTP status code
 * @param {Object} body - Response body to be JSON stringified
 * @returns {Object} Formatted API Gateway response
 */
function formatResponse(statusCode, body) {
  return {
    statusCode,
    headers: RESPONSE_HEADERS,
    body: JSON.stringify(body),
  };
}

/**
 * Validate document ID parameter
 * @param {string} id - The document ID from the request
 * @returns {Object} - Object containing validation result and sanitized ID or error message
 */
function validateDocumentId(id) {
  if (!id || typeof id !== 'string') {
    return { isValid: false, error: "Query parameter 'id' is required" };
  }
  
  const sanitizedId = id.trim();
  
  if (sanitizedId === '') {
    return { isValid: false, error: "Query parameter 'id' cannot be empty" };
  }
  
  // Add additional validation as needed (e.g., format checks)
  
  return { isValid: true, sanitizedId };
}

/**
 * Retrieve document metadata from DynamoDB
 * @param {string} tableName - The DynamoDB table name
 * @param {string} book_Id - The document ID
 * @returns {Promise<Object>} - Promise resolving to the document metadata
 */
async function getDocumentMetadata(tableName, book_Id) {
  const params = {
    TableName: tableName,
    Key: {
      book_id: book_Id
    }
  };
  
  try {
    const data = await dynamo.get(params).promise();
    
    if (!data.Item) {
      throw new Error('Document not found');
    }
    
    return data.Item;
  } catch (error) {
    console.error("DynamoDB get error:", JSON.stringify(error));
    throw error;
  }
}

/**
 * Generate a signed URL for the document
 * @param {string} bucketName - The S3 bucket name
 * @param {string} objectKey - The S3 object key
 * @returns {Promise<string>} - Promise resolving to the signed URL
 */
async function generateSignedUrl(bucketName, objectKey) {
  const params = {
    Bucket: bucketName,
    Key: objectKey,
    Expires: URL_EXPIRATION_SECONDS
  };
  
  try {
    const url = await s3.getSignedUrlPromise('getObject', params);
    return url;
  } catch (error) {
    console.error("S3 signed URL error:", JSON.stringify(error));
    throw error;
  }
}

/**
 * Lambda handler for generating document download links
 * Supports CORS preflight requests
 */
exports.handler = async (event, context) => {
  // Add request ID for troubleshooting
  const requestId = context.awsRequestId;
  console.log(`Processing download request ${requestId}`, { event: JSON.stringify(event) });
  
  // Handle OPTIONS request for CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return formatResponse(200, {});
  }
  
  // Ensure environment variables are set
  const metadataTable = process.env.METADATA_TABLE;
  const documentBucket = process.env.UPLOAD_BUCKET;
  
  if (!metadataTable || !documentBucket) {
    console.error(`[${requestId}] Missing required env variables`);
    return formatResponse(500, { 
      error: "Server configuration error", 
      requestId 
    });
  }
  
  // Get and validate document ID
  const documentId = event.queryStringParameters?.id;
  const validation = validateDocumentId(documentId);
  
  if (!validation.isValid) {
    console.log(`[${requestId}] Invalid document ID: ${validation.error}`);
    return formatResponse(400, { 
      error: validation.error, 
      requestId 
    });
  }
  
  try {
    // Get document metadata from DynamoDB
    const metadata = await getDocumentMetadata(metadataTable, validation.sanitizedId);
    
    // Ensure the document has a valid file key
    if (!metadata.s3_path) {
      console.error(`[${requestId}] Document missing s3_path: ${validation.sanitizedId}`);
      return formatResponse(404, { 
        error: "Document file not found", 
        requestId 
      });
    }
    
    // Generate a signed URL for the document
    const downloadUrl = await generateSignedUrl(documentBucket, metadata.s3_path);
    
    // Add a download tracking record if needed (optional)
    // await trackDownload(downloadTrackingTable, metadata.id, event);
    
    // Return the signed URL to the client
    return formatResponse(200, {
      downloadUrl,
      documentId: metadata.id,
      documentTitle: metadata.title || 'Untitled Document',
      expiresIn: URL_EXPIRATION_SECONDS,
      requestId
    });
    
  } catch (error) {
    console.error(`[${requestId}] Error processing download request:`, error);
    
    if (error.message === 'Document not found') {
      return formatResponse(404, { 
        error: "Document not found", 
        requestId 
      });
    }
    
    return formatResponse(500, { 
      error: "Failed to generate download link", 
      message: error.message, 
      requestId 
    });
  }
  //test
}; 