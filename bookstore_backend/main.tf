module "s3" {
  source = "./modules/s3_be_upload"
}

module "s3_tfState" {
  source = "./modules/s3_tfState"
}

module "vpc" {
  region  = var.aws_region
  source = "./modules/vpc"
}

module "cognito" {
  source          = "./modules/cognito"
  frontend_domain = "bookstore.jresume.cloud"
  cognito_domain  = var.cognito_domain
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  table_name   = var.tabledb_name
}

module "dynamodb_lock_table" {
  source       = "./modules/dynamodb_lock_table"
  project_name = var.project_name
}

module "lambda_upload" {
  source               = "./modules/lambda_upload"
  project_name         = var.project_name
  lambda_zip_path      = var.lambdaupload_zip_path
  s3_bucket_name       = module.s3.bucket_name
  s3_bucket_arn        = module.s3.bucket_arn
  dynamodb_table_name  = module.dynamodb.dynamodb_table_name
  dynamodb_table_arn   = module.dynamodb.dynamodb_table_arn
  cors_allowed_origin  = var.cors_allowed_origin
}

module "lambda_search" {
  source               = "./modules/lambda_search"
  project_name         = var.project_name
  lambdasearch_zip_path      = var.lambdasearch_zip_path
  dynamodb_table_name  = module.dynamodb.dynamodb_table_name
  dynamodb_table_arn   = module.dynamodb.dynamodb_table_arn
  cors_allowed_origin  = var.cors_allowed_origin
}

module "lambda_download" {
  source               = "./modules/lambda_download"
  project_name         = var.project_name
  dynamodb_table_name  = module.dynamodb.dynamodb_table_name
  dynamodb_table_arn   = module.dynamodb.dynamodb_table_arn
  s3_bucket_name       = module.s3.bucket_name
  s3_bucket_arn        = module.s3.bucket_arn
  lambdadownload_zip_path      = var.lambdadownload_zip_path
  cors_allowed_origin  = var.cors_allowed_origin
}

module "api_gateway" {
  source                = "./modules/api_gateway"
  region                = var.aws_region
  project_name          = var.project_name
  lambda_upload_invoke_arn     = module.lambda_upload.upload_lambda_arn
  lambda_search_invoke_arn     = module.lambda_search.search_lambda_arn
  lambda_download_invoke_arn   = module.lambda_download.download_lambda_arn
  lambda_upload_name           = module.lambda_upload.upload_lambda_name
  lambda_search_name           = module.lambda_search.search_lambda_name
  lambda_download_name         = module.lambda_download.download_lambda_name
  download_lambda_arn          = module.lambda_download.download_lambda_arn
  stage_name                   = "prod"
  cognito_user_pool_arn        = module.cognito.user_pool_arn
}

module "cloudwatch" {
  source                       = "./modules/cloudwatch"  
  lambda_upload_name           = module.lambda_upload.upload_lambda_name
  lambda_search_name           = module.lambda_search.search_lambda_name
  lambda_download_name         = module.lambda_download.download_lambda_name
  sns_arn                      = module.sns.sns_arn
}

module "sns" {
  source                       = "./modules/sns"
}
