resource "aws_dynamodb_table" "terraform-lock-table" {
  name           = "terraform-lock-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = var.project_name
    Environment = "prod"
  }
}
