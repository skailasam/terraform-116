terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "${var.env}"
      Owner       = "${var.owner}"
      Project     = "${var.app_name}"
    }
  }
}
