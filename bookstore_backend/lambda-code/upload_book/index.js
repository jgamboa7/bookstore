const AWS = require('aws-sdk');
const busboy = require('busboy');
const { v4: uuidv4 } = require('uuid');

// Initialize AWS services
const s3 = new AWS.S3();
const dynamo = new AWS.DynamoDB.DocumentClient();

// Define constants
const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20MB in bytes
const ALLOWED_FILE_TYPES = ['pdf', 'epub', 'docx'];

/**
 * Get MIME type based on file extension
 * @param {string} extension - File extension
 * @returns {string} - MIME type
 */
function getMimeType(extension) {
  const mimeTypes = {
    'pdf': 'application/pdf',
    'epub': 'application/epub+zip',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  };
  
  return mimeTypes[extension] || 'application/octet-stream';
}

/**
 * Format API Gateway response
 * @param {number} statusCode - HTTP status code
 * @param {Object|string} body - Response body
 * @returns {Object} - Formatted response
 */
function formatResponse(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': 'https://bookstore.jresume.cloud',
      'Access-Control-Allow-Credentials': true
    },
    body: typeof body === 'string' ? body : JSON.stringify(body)
  };
}

/**
 * Lambda handler for file uploads
 * @param {Object} event - API Gateway event
 * @returns {Promise<Object>} - API Gateway response
 */
exports.handler = async (event) => {
  // Validate environment variables
  if (!process.env.UPLOAD_BUCKET || !process.env.METADATA_TABLE) {
    console.error('Missing required environment variables');
    return formatResponse(500, { error: 'Server configuration error' });
  }
  
  try {
    // Get content type from headers (case-insensitive)
    const contentType = Object.keys(event.headers)
      .find(h => h.toLowerCase() === 'content-type');
    
    if (!contentType || !event.headers[contentType].includes('multipart/form-data')) {
      return formatResponse(400, { error: 'Content-Type must be multipart/form-data' });
    }
    
    const bb = busboy({ headers: { 'content-type': event.headers[contentType] } });
    const bodyBuffer = Buffer.from(event.body, event.isBase64Encoded ? 'base64' : 'utf8');
    
    let fileBuffer, filename, keywords, title, author, excerpt;
    
    return new Promise((resolve, reject) => {
      bb.on('file', (fieldname, file, info) => {
        const chunks = [];
        filename = info.filename;
        
        file.on('data', (data) => chunks.push(data));
        file.on('end', () => {
          fileBuffer = Buffer.concat(chunks);
        });
      });
      
      bb.on('field', (fieldname, val) => {
        switch (fieldname) {
          case 'keywords':
            keywords = val.split(',').map(k => k.trim()).filter(k => k.length > 0);
            break;
          case 'title':
            title = val.trim();
            break;
          case 'author':
            author = val.trim();
            break;
          case 'excerpt':
            excerpt = val.trim();
            break;
        }
      });
      
      bb.on('error', (err) => {
        console.error('Busboy error:', err);
        return resolve(formatResponse(400, { error: `Failed to parse upload: ${err.message}` }));
      });
      
      bb.on('finish', async () => {
        try {
          // Validate required inputs
          if (!fileBuffer || !keywords || !title || !author) {
            return resolve(formatResponse(400, { error: 'Missing file or keywords' }));
          }
          
          // Validate file size
          if (fileBuffer.length > MAX_FILE_SIZE) {
            return resolve(formatResponse(400, { error: 'File exceeds maximum size of 20MB' }));
          }
          
          // Validate file type
          const ext = filename.split('.').pop().toLowerCase();
          if (!ALLOWED_FILE_TYPES.includes(ext)) {
            return resolve(formatResponse(400, { 
              error: `Unsupported file type. Allowed types: ${ALLOWED_FILE_TYPES.join(', ')}` 
            }));
          }
          
          // Generate unique filename
          const uniqueFilename = `${uuidv4()}_${filename}`;
          
          // Get content type
          const contentType = getMimeType(ext);
          
          const bucket = process.env.UPLOAD_BUCKET;
          const table = process.env.METADATA_TABLE;
          
          // Upload to S3 
          await s3.putObject({
            Bucket: bucket,
            Key: uniqueFilename,
            Body: fileBuffer,
            ContentType: contentType,
          }).promise();
          
          // Store metadata in DynamoDB
          await dynamo.put({
            TableName: table,
            Item: {
              book_id: uniqueFilename,
              keywords,
              s3_path: uniqueFilename,
              upload_timestamp: Date.now(),
              size_bytes: fileBuffer.length,
              title,
              author,
              excerpt
            }
          }).promise();
          
          return resolve(formatResponse(200, { 
            message: 'Upload successful', 
            fileId: uniqueFilename 
          }));
        } catch (error) {
          console.error('Error during upload processing:', error);
          return resolve(formatResponse(500, { error: 'Failed to process upload' }));
        }
      });
      
      bb.end(bodyBuffer);
    });
  } catch (error) {
    console.error('Unexpected error:', error);
    return formatResponse(500, { error: 'Internal server error' });
  }
};