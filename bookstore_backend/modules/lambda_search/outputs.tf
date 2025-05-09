output "search_lambda_arn" {
  value = aws_lambda_function.search_bookss.arn
}

output "search_lambda_name" {
  value = aws_lambda_function.search_bookss.function_name
}