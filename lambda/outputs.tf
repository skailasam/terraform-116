output "api_url" {
  description = "API Gateway URL"
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/"
}
output "sqs_queue" {
  description = "SQS queue"
  value       = aws_sqs_queue.queue.id
}
output "s3_bucket" {
  description = "S3 bucket"
  value       = aws_s3_bucket.bucket.id
}
