resource "aws_iam_role" "lambdasearch_exec_role" {
  name = "${var.project_name}-search-lambda-role"
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
  role       = aws_iam_role.lambdasearch_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_read_access" {
  name = "${var.project_name}-searchDB-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_search_dynamo" {
  role       = aws_iam_role.lambdasearch_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_read_access.arn
}

resource "aws_iam_policy" "kms_decrypt_access" {
  name = "${var.project_name}-kms-decrypt-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = "arn:aws:kms:eu-central-1:826589250962:key/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kms_decrypt" {
  role       = aws_iam_role.lambdasearch_exec_role.name
  policy_arn = aws_iam_policy.kms_decrypt_access.arn
}

resource "aws_lambda_function" "search_bookss" {
  function_name = "${var.project_name}-search"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = var.lambdasearch_zip_path
  role          = aws_iam_role.lambdasearch_exec_role.arn
  timeout       = 10
  kms_key_arn = null

  environment {
    variables = {
      METADATA_TABLE = var.dynamodb_table_name
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
    }
  }

  source_code_hash = filebase64sha256(var.lambdasearch_zip_path)
}
