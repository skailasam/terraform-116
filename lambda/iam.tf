
data "aws_iam_policy_document" "AWSLambdaPolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "AWSSQSPolicy" {
  statement {
    actions   = ["sqs:*"]
    resources = ["${aws_sqs_queue.queue.arn}", "${aws_sqs_queue.dlq.arn}"]
  }
}
data "aws_iam_policy_document" "AWSS3Policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}
resource "aws_iam_policy" "lambda_sqs" {
  name   = "AWSSQSPermsfor${var.app_name}-${var.env}"
  policy = data.aws_iam_policy_document.AWSSQSPolicy.json
}
resource "aws_iam_policy" "lambda_s3" {
  name   = "AWSS3Permsfor${var.app_name}-${var.env}"
  policy = data.aws_iam_policy_document.AWSS3Policy.json
}
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaPolicy.json
}
# IAM role to execute Lambda
resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# IAM role to access SQS
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs.arn
}
# IAM role to put object in S3 bucket
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}
