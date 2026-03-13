variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. Must be unique across all AWS accounts."
  type        = string
  # No default — pass via: export TF_VAR_state_bucket_name="jerome-aaron-portfolio-tfstate-$(aws sts get-caller-identity --query Account --output text)"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "jerome-aaron-portfolio-tflock"
}
