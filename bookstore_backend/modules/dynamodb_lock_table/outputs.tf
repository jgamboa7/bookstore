output "dynamodb_table_name_state" {
  value = aws_dynamodb_table.terraform-lock-table.name
}

output "dynamodb_table_arn_state" {
  value = aws_dynamodb_table.terraform-lock-table.arn
}