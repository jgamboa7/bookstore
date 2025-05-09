resource "aws_s3_bucket" "bookstore-terraform-state" {
  bucket = "bookstore-tf-state"

    tags = {
        Name        = "bookstore-tf-state"
    }
}

resource "aws_s3_bucket_versioning" "bookstore_versioning" {
  bucket = aws_s3_bucket.bookstore-terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}