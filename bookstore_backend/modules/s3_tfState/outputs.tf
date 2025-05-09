output "bucket_name_state" {
  value = aws_s3_bucket.bookstore-terraform-state.bucket
}

output "bucket_id_state" {
  value = aws_s3_bucket.bookstore-terraform-state.id
}

output "bucket_arn_state" {
  value = aws_s3_bucket.bookstore-terraform-state.arn
}