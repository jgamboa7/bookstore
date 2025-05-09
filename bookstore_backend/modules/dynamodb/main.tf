resource "aws_dynamodb_table" "bookstorage" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "book_id"

  attribute {
    name = "book_id"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}
