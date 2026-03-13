variable "aws_region" {
  description = "AWS region. Must be us-east-1 for CloudFront ACM certificate support."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Root domain name for the portfolio site"
  type        = string
  default     = "jeromeaaron.com"
}

variable "www_domain_name" {
  description = "www subdomain — both apex and www will serve the site"
  type        = string
  default     = "www.jeromeaaron.com"
}

variable "github_repo" {
  description = "GitHub repository in org/repo format — used to scope the OIDC trust policy"
  type        = string
  default     = "JeromeAaron/cloud-portfolio"
}

variable "aws_account_id" {
  description = "AWS account ID — used for globally unique resource naming. Pass via TF_VAR_aws_account_id environment variable, do not hardcode here."
  type        = string
  # No default — must be supplied at runtime.
  # Set with: export TF_VAR_aws_account_id=$(aws sts get-caller-identity --query Account --output text)
}
