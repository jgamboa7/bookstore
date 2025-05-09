output "bucket_name" {
  value = aws_s3_bucket.bookstorage.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.bookstorage.arn
}