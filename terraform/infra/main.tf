terraform {
  required_version = ">= 1.0"

  # Remote backend — uses the S3 bucket and DynamoDB table we created in bootstrap.
  # This means Terraform's state is stored in AWS, not on your laptop.
  backend "s3" {
    bucket         = "jerome-aaron-portfolio-tfstate-345259854106"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jerome-aaron-portfolio-tflock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# All resources go in us-east-1.
# This is required for ACM certificates used with CloudFront — CloudFront only
# accepts certificates from us-east-1, regardless of where your users are.
provider "aws" {
  region = var.aws_region
}
