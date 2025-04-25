terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_s3_bucket" "tf-example" {
  bucket = "demsy-tf-test-bucket"

  tags = {
    Name        = "demsy"
    Environment = "sandbox"
  }
}
