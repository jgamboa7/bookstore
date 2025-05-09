output "upload_lambda_arn" {
  value = aws_lambda_function.upload_books.arn
}

output "upload_lambda_name" {
  value = aws_lambda_function.upload_books.function_name
}
