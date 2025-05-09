output "bucket_name" {
  value = aws_s3_bucket.bookstorage.bucket
}

output "bucket_id" {
  value = aws_s3_bucket.bookstorage.id
}

output "bucket_arn" {
  value = aws_s3_bucket.bookstorage.arn
}