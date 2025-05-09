output "download_lambda_arn" {
  value = aws_lambda_function.download_books.arn
}

output "download_lambda_name" {
  value = aws_lambda_function.download_books.function_name
}