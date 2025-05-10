resource "aws_iam_role" "lambdaupload_exec_role" {
  name = "${var.project_name}-upload-lambda-role"
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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-upload-lambda-policy"
  role = aws_iam_role.lambdaupload_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Action = [
          "dynamodb:PutItem"
        ],
        Effect   = "Allow",
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_lambda_function" "upload_books" {
  function_name = "${var.project_name}-upload"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambdaupload_exec_role.arn
  #filename      = var.lambda_zip_path
  timeout       = 30

  environment {
    variables = {
      UPLOAD_BUCKET    = var.s3_bucket_name
      METADATA_TABLE   = var.dynamodb_table_name
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
    }
  }

  #source_code_hash = filebase64sha256(var.lambda_zip_path)

}
