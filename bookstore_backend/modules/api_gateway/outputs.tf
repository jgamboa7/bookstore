output "upload_api_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/upload"
}

output "search_api_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/search"
}

output "download_api_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/download"
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.bookstore_api.execution_arn
}