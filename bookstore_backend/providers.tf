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
