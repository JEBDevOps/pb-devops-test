
output "api_url" {
  description = "The invoke URL for the API Gateway stage"
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}
