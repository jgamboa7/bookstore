output "user_pool_id" {
  value = aws_cognito_user_pool.bookstore_users.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.bookstore_users.arn
}

output "cognito_domain" {
  value = aws_cognito_user_pool_domain.cognito_domain.domain
}