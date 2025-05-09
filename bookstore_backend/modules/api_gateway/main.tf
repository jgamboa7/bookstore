//api definition
resource "aws_api_gateway_rest_api" "bookstore_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for file upload, file search and download"
  binary_media_types = ["multipart/form-data"]
}

// upload path, search path and download
resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  parent_id   = aws_api_gateway_rest_api.bookstore_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "search" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  parent_id   = aws_api_gateway_rest_api.bookstore_api.root_resource_id
  path_part   = "search"
}

resource "aws_api_gateway_resource" "download" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  parent_id   = aws_api_gateway_rest_api.bookstore_api.root_resource_id
  path_part   = "download"
}

// post method for upload
resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

// GET method for search and download
resource "aws_api_gateway_method" "search_get" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "download_get" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.download.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS" 
  authorizer_id = aws_api_gateway_authorizer.cognito.id
   
  # Request parameters - make "id" required
  request_parameters = {
    "method.request.querystring.id" = true
  }
}

// OPTIONS method for upload, search and download
resource "aws_api_gateway_method" "upload_options" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "search_options" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "download_options" {
  rest_api_id   = aws_api_gateway_rest_api.bookstore_api.id
  resource_id   = aws_api_gateway_resource.download.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

//authorizer for upload, search and download
resource "aws_api_gateway_authorizer" "cognito" {
  name                    = "CognitoAuthorizer"
  rest_api_id             = aws_api_gateway_rest_api.bookstore_api.id
  identity_source         = "method.request.header.Authorization"
  type                    = "COGNITO_USER_POOLS"
  provider_arns           = [var.cognito_user_pool_arn]
}

// Lambda integration for upload, search and download
resource "aws_api_gateway_integration" "lambda_upload_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookstore_api.id
  resource_id             = aws_api_gateway_resource.upload.id
  http_method             = aws_api_gateway_method.upload_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_upload_invoke_arn}/invocations"

  depends_on = [aws_api_gateway_method.upload_post]

}

resource "aws_api_gateway_integration" "lambda_search_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookstore_api.id
  resource_id             = aws_api_gateway_resource.search.id
  http_method             = aws_api_gateway_method.search_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_search_invoke_arn}/invocations"
  
  depends_on = [aws_api_gateway_method.search_get]

}

resource "aws_api_gateway_integration" "lambda_download_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = aws_api_gateway_method.download_get.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_download_invoke_arn}/invocations"

  depends_on = [aws_api_gateway_method.download_get]

}

// OPTIONS integration for upload, search and download
resource "aws_api_gateway_integration" "upload_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options.http_method
  type        = "MOCK"  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "search_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.search_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "download_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = aws_api_gateway_method.download_options.http_method
  
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

//Post method response for upload
resource "aws_api_gateway_method_response" "upload_post_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  depends_on = [aws_api_gateway_method.upload_post]

}

//GET method response for usearch and download
resource "aws_api_gateway_method_response" "search_get_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  depends_on = [aws_api_gateway_method.search_get]
  
}

resource "aws_api_gateway_method_response" "download_get_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  depends_on = [aws_api_gateway_method.download_get]

}

//OPTIONS Method response for options Upload, search and download
resource "aws_api_gateway_method_response" "upload_options_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "search_options_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "download_options_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

//POST integration response for upload, search and download
resource "aws_api_gateway_integration_response" "upload_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://bookstore.jresume.cloud'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
  }

  depends_on = [
    aws_api_gateway_method.upload_post,
    aws_api_gateway_integration.lambda_upload_integration,
    aws_api_gateway_method_response.upload_post_response
  ]

}

resource "aws_api_gateway_integration_response" "search_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://bookstore.jresume.cloud'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'"
  }

  depends_on = [
    aws_api_gateway_method.search_get,
    aws_api_gateway_integration.lambda_search_integration,
    aws_api_gateway_method_response.search_get_response
  ]

}

resource "aws_api_gateway_integration_response" "download_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://bookstore.jresume.cloud'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'"
  }

  depends_on = [
    aws_api_gateway_method.download_get,
    aws_api_gateway_integration.lambda_download_integration,
    aws_api_gateway_method_response.download_get_response
  ]

}

// integration response for options Upload, search and download
resource "aws_api_gateway_integration_response" "upload_options_integration_response" {
  depends_on = [aws_api_gateway_integration.upload_options_integration]

  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://bookstore.jresume.cloud'"
  }
}

resource "aws_api_gateway_integration_response" "search_options_integration_response" {
  depends_on = [aws_api_gateway_integration.search_options_integration]

  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.search_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://bookstore.jresume.cloud'"
  }
}

resource "aws_api_gateway_integration_response" "download_options_integration_response" {
  depends_on = [aws_api_gateway_integration.download_options_integration]

  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = aws_api_gateway_method.download_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://bookstore.jresume.cloud'"
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_upload_integration,
    aws_api_gateway_integration.lambda_search_integration,
    aws_api_gateway_integration.lambda_download_integration,
    aws_api_gateway_integration.upload_options_integration,
    aws_api_gateway_integration.search_options_integration,
    aws_api_gateway_integration.download_options_integration,
    aws_api_gateway_integration_response.upload_options_integration_response,
    aws_api_gateway_integration_response.search_options_integration_response,
    aws_api_gateway_integration_response.download_options_integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  stage_name  = var.stage_name

}

//Gateway response for 4xx and 5xx erros
resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'https://bookstore.jresume.cloud'",
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
  }

  status_code = "400"
}

resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id = aws_api_gateway_rest_api.bookstore_api.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'https://bookstore.jresume.cloud'",
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
  }

  status_code = "500"
}

// lambda permission to allow apiGW for upload and search
resource "aws_lambda_permission" "allow_api_gateway_upload" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_upload_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookstore_api.execution_arn}/*/POST/upload"
}

resource "aws_lambda_permission" "allow_api_gateway_search" {
  statement_id  = "AllowSearchFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_search_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookstore_api.execution_arn}/*/GET/search"
}

resource "aws_lambda_permission" "allow_api_gateway_download" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_download_name
  principal     = "apigateway.amazonaws.com"
  
  # Allow invocation from any stage/method on this API Gateway resource
  source_arn = "${aws_api_gateway_rest_api.bookstore_api.execution_arn}/*/GET/download"
}

