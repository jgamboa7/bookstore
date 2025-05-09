resource "aws_s3_bucket" "bookstorage" {
  bucket = "bookstorage-be-${random_id.suffix.hex}"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "Book Storage"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bookstorage.id
  versioning_configuration {
    status = "Enabled"
  }
}


