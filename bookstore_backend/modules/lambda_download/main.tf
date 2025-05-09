resource "aws_iam_role" "lambda_download_exec_role" {
  name = "${var.project_name}-download-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

# Lambda basic execution role policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_download_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for S3 and DynamoDB access
resource "aws_iam_policy" "lambda_download_policy" {
  name = "${var.project_name}-download-lambda-policy"
  description = "Allows lambda function to access S3 documents and DynamoDB metadata"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_download_policy_attachment" {
  role       = aws_iam_role.lambda_download_exec_role.name
  policy_arn = aws_iam_policy.lambda_download_policy.arn
}

resource "aws_lambda_function" "download_books" {
  function_name = "${var.project_name}-donwload"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_download_exec_role.arn
  filename      = var.lambdadownload_zip_path
  timeout       = 30

  environment {
    variables = {
      UPLOAD_BUCKET    = var.s3_bucket_name
      METADATA_TABLE   = var.dynamodb_table_name
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
    }
  }

  source_code_hash = filebase64sha256(var.lambdadownload_zip_path)

}