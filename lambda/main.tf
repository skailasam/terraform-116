locals {
  app_build = "${path.module}/build"
  s3_bucket = "${var.app_name}-${var.env}-${random_id.id.dec}"
  s3_key    = "${var.app_name}-${random_string.str.result}"
}
resource "random_id" "id" {
  byte_length = 4
}
resource "random_string" "str" {
  length    = 7
  min_lower = 7
  special   = false
}
# Lambda source files
data "archive_file" "lambda_src" {
  count       = length(fileset(var.app_src, "${var.app_name}*.py"))
  type        = "zip"
  source_file = "${var.app_src}/${var.app_name}${count.index + 1}.py"
  output_path = "${local.app_build}/${var.app_name}${count.index + 1}.zip"
}
# Lambda functions
resource "aws_lambda_function" "lambda" {
  count            = length(data.archive_file.lambda_src)
  function_name    = "${var.app_name}${count.index + 1}"
  handler          = "${var.app_name}${count.index + 1}.lambda_handler"
  runtime          = var.app_runtime
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_src[count.index].output_path
  source_code_hash = data.archive_file.lambda_src[count.index].output_base64sha256
  publish          = true
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }
  environment {
    variables = {
      sqs_url   = "${aws_sqs_queue.queue.id}"
      s3_bucket = "${aws_s3_bucket.bucket.id}"
      s3_key    = "${local.s3_key}"
    }
  }
}
resource "aws_cloudwatch_log_group" "log_group" {
  count             = length(aws_lambda_function.lambda)
  name              = "/aws/lambda/${aws_lambda_function.lambda[count.index].function_name}"
  retention_in_days = 7
}
# API Gateway to trigger Lambda 1 function
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.app_name}-${var.env}-api"
  protocol_type = "HTTP"
  route_key     = "POST /"
  target        = aws_lambda_function.lambda[0].arn
}
resource "aws_lambda_permission" "allow_api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[0].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
# SQS queue to trigger Lambda 2 function
resource "aws_sqs_queue" "queue" {
  name                      = "${var.app_name}-${var.env}-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 4
  })
}
resource "aws_sqs_queue" "dlq" {
  name = "${var.app_name}-${var.env}-dlq"
}
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.lambda[1].arn
}
# S3 bucket to trigger Lambda 3 function
resource "aws_s3_bucket" "bucket" {
  bucket = local.s3_bucket
  acl    = "private"
}
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[2].arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda[2].arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}
