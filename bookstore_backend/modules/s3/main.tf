resource "aws_s3_bucket" "bookstorage" {
  bucket = "bookstorage-be-${random_id.suffix.hex}"
  force_destroy = true

  versioning {
    enabled = true
  }

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

output "bucket_id" {
  value = aws_s3_bucket.bookstorage.id
}
