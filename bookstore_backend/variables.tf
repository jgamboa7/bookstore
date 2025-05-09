variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_profile" {
  default = "default"
}

variable "project_name" {
  default = "bookstorage"
}

variable "tabledb_name" {
  default = "book-metadata"
}

variable "lambdaupload_zip_path" {
  default = "./lambda-code/upload_book.zip"
}

variable "lambdasearch_zip_path" {
  default = "./lambda-code/search_book.zip"
}

variable "lambdadownload_zip_path" {
  default = "./lambda-code/download_book.zip"
}

variable "cors_allowed_origin" {
  default = "https://bookstore.jresume.cloud"
}

variable "cognito_domain" {
  default = "bookstoreapp"
}

