terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote backend will be enabled after AWS account activation.
  # backend "s3" {
  #   bucket       = "CHANGE_ME_TERRAFORM_STATE_BUCKET"
  #   key          = "dataops-devops-assignment/terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}