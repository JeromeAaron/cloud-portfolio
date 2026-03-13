terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# S3 bucket — stores the Terraform state file for the main infra
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion of the bucket that holds all your state
  lifecycle {
    prevent_destroy = true
  }
}

# Keep every version of the state file so you can roll back if something breaks
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest — it contains resource IDs and ARNs
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State files must never be public — this blocks all public access paths
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# DynamoDB table — provides state locking
# Prevents two terraform applies from running simultaneously and corrupting state
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "tflock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no capacity planning needed; pay per operation
  hash_key     = "LockID"          # Terraform requires this exact key name

  attribute {
    name = "LockID"
    type = "S" # S = String
  }
}
