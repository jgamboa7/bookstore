output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "user_pool_id" {
  value = module.cognito.user_pool_id
}  

output "user_pool_client_id" {
  value = module.cognito.user_pool_client_id
}

output "user_pool_arn" {
  value = module.cognito.user_pool_arn
}

output "cognito_domain" {
  value = module.cognito.cognito_domain
}

output "dynamodb_table_name" {
  value = module.dynamodb.dynamodb_table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.dynamodb_table_arn
}

output "dynamodb_table_name_state" {
  value = module.dynamodb_lock_table.dynamodb_table_name_state
}

output "dynamodb_table_arn_state" {
  value = module.dynamodb_lock_table.dynamodb_table_arn_state
}

output "upload_lambda_arn" {
  value = module.lambda_upload.upload_lambda_arn
}

output "upload_lambda_name" {
  value = module.lambda_upload.upload_lambda_name
}

output "search_lambda_arn" {
  value = module.lambda_search.search_lambda_arn
}

output "search_lambda_name" {
  value = module.lambda_search.search_lambda_name
}

output "download_lambda_arn" {
  value = module.lambda_download.download_lambda_arn
}

output "download_lambda_name" {
  value = module.lambda_download.download_lambda_name
}

output "upload_api_url" {
  value = module.api_gateway.upload_api_url
}

output "search_api_url" {
  value = module.api_gateway.search_api_url
}

output "download_api_url" {
  value = module.api_gateway.download_api_url
}

output "execution_arn" {
  value = module.api_gateway.execution_arn
}

output "bucket_arn_state" {
  value = module.s3_tfState.bucket_arn_state
}

output "sns_arn" {
  value = module.sns.sns_arn
}