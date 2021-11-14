variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}
variable "owner" {
  description = "Owner"
  type        = string
  default     = "techops"
}
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "lambda"
}
variable "app_runtime" {
  description = "Application runtime"
  type        = string
  default     = "python3.8"
}
variable "app_src" {
  description = "Application source code folder"
  type        = string
  default     = "../src"
}
