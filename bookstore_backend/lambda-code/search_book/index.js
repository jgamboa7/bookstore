const AWS = require('aws-sdk');

// Initialize DynamoDB client with exponential backoff for retries
const dynamo = new AWS.DynamoDB.DocumentClient({
  maxRetries: 3,
  retryDelayOptions: { base: 300 }
});

// Constants
const MAX_RESULTS = 100; // Limit results to prevent large response payloads
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
 * Validate and sanitize the search query parameter
 * @param {string} query - The raw search query from the request
 * @returns {Object} - Object containing validation result and sanitized query or error message
 */
function validateSearchQuery(query) {
  if (!query || typeof query !== 'string') {
    return { isValid: false, error: "Query parameter 'query' is required" };
  }
  
  const sanitizedQuery = query.trim().toLowerCase();
  
  if (sanitizedQuery === '') {
    return { isValid: false, error: "Query parameter 'query' cannot be empty" };
  }
  
  if (sanitizedQuery.length < 2) {
    return { isValid: false, error: "Query parameter 'query' must be at least 2 characters long" };
  }
  
  // Additional validation rules could be added here
  
  return { isValid: true, sanitizedQuery };
}

/**
 * Perform the DynamoDB scan operation with pagination support
 * @param {string} tableName - The DynamoDB table name
 * @param {string} keyword - The sanitized search keyword
 * @returns {Promise<Array>} - Promise resolving to an array of matching items
 */
async function searchDynamoDB(tableName, keyword) {
  const params = {
    TableName: tableName,
    FilterExpression: "contains(keywords, :kw)",
    ExpressionAttributeValues: {
      ":kw": keyword,
    },
    Limit: MAX_RESULTS
  };
  
  try {
    const data = await dynamo.scan(params).promise();
    return data.Items || [];
  } catch (error) {
    console.error("DynamoDB scan error:", JSON.stringify(error));
    throw error;
  }
}

/**
 * Lambda handler for searching books by keyword
 * Supports CORS preflight requests
 */
exports.handler = async (event, context) => {

console.log("FULL EVENT:", JSON.stringify(event, null, 2));
console.log("QUERY PARAMS:", JSON.stringify(event.queryStringParameters));
console.log("TABLE NAME:", process.env.METADATA_TABLE);

  // Add request ID for troubleshooting
  const requestId = context.awsRequestId;
  console.log(`Processing request ${requestId}`, { event: JSON.stringify(event) });
  
  // Handle OPTIONS request for CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return formatResponse(200, {});
  }
  
  // Ensure environment variables are set
  const tableName = process.env.METADATA_TABLE;
  if (!tableName) {
    console.error(`[${requestId}] Missing METADATA_TABLE env variable`);
    return formatResponse(500, { 
      error: "Server configuration error", 
      requestId 
    });
  }
  
  // Get and validate query param
  const searchQuery = event.queryStringParameters?.query;
  const validation = validateSearchQuery(searchQuery);
  
  if (!validation.isValid) {
    console.log(`[${requestId}] Invalid search query: "${searchQuery}"`);
    return formatResponse(400, { 
      error: validation.error,
      requestId
    });
  }
  
  try {
    // Set timeout to ensure we don't hit Lambda execution limits
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error('Search operation timed out'));
      }, context.getRemainingTimeInMillis() - 500); // Leave 500ms buffer
    });
    
    // Race between the actual operation and timeout
    const results = await Promise.race([
      searchDynamoDB(tableName, validation.sanitizedQuery),
      timeoutPromise
    ]);
    
    console.log(`[${requestId}] Search complete, found ${results.length} results`);
    
    return formatResponse(200, {
      results,
      count: results.length,
      query: validation.sanitizedQuery,
      requestId
    });
  } catch (error) {
    // Handle different error types
    if (error.code === 'ProvisionedThroughputExceededException') {
      console.error(`[${requestId}] DynamoDB throughput exceeded:`, error);
      return formatResponse(429, { 
        error: "Too many requests, please try again later",
        requestId 
      });
    } else if (error.message === 'Search operation timed out') {
      console.error(`[${requestId}] Search timed out`);
      return formatResponse(408, { 
        error: "Search operation timed out",
        requestId 
      });
    } else {
      console.error(`[${requestId}] Unexpected error:`, error);
      return formatResponse(500, { 
        error: "Search failed",
        requestId 
      });
    }
  }
};