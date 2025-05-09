provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile # if running locally
}

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "bookstore-tf-state"   # Change to your actual S3 bucket name
    key            = "envs/prod/terraform.tfstate" # Change for dev/prod later
    region         = "eu-central-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
