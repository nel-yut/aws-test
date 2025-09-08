terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }

  backend "s3" {
    bucket  = "nel-terraform"
    key     = "aws-test/infra-lambda/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

provider "aws" {
  region = var.aws_region
}
