# ============================================================
# Bootstrap — run ONCE before the main Terraform config
# Creates the S3 bucket used for remote state storage
# Usage:
#   cd bootstrap/
#   terraform init
#   terraform apply
#   → copy the bucket name into providers.tf backend block
# ============================================================

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Bootstrap uses local state intentionally — it only manages one bucket
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name — used in bucket name"
  type        = string
  default     = "dataops-devops"
}

locals {
  # Bucket name must be globally unique; we append account ID to guarantee that
  state_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name

  # Prevent accidental deletion of state
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.state_bucket_name
    ManagedBy = "Terraform"
    Purpose   = "Terraform remote state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  description = "Copy this value into providers.tf backend block → bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "next_step" {
  value = "Update providers.tf: set bucket = \"${local.state_bucket_name}\""
}
