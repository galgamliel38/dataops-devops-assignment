terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3 with native locking (no DynamoDB needed – use_lockfile=true)
  # Uncomment after creating the state bucket:
  #   aws s3 mb s3://dataops-devops-tfstate-933832340588 --region eu-west-1
  backend "s3" {
    bucket       = "dataops-devops-tfstate-933832340588"
    key          = "dataops-devops-assignment/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true   # Native S3 locking – no DynamoDB needed
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
