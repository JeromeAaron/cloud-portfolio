output "website_bucket_name" {
  description = "S3 bucket where site files are uploaded"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidation in CI/CD"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain (e.g. d1234.cloudfront.net) — useful for testing before DNS cutover"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "route53_nameservers" {
  description = "IMPORTANT: Set these 4 nameservers on Namecheap to point your domain to Route 53"
  value       = aws_route53_zone.website.name_servers
}

output "github_actions_role_arn" {
  description = "IAM role ARN — add this as AWS_ROLE_ARN secret in GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
