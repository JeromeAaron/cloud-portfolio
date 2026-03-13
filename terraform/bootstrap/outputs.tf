output "state_bucket_name" {
  description = "S3 bucket name — use this in the infra backend config"
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_bucket_arn" {
  description = "ARN of the state bucket — used when writing IAM policies"
  value       = aws_s3_bucket.tfstate.arn
}

output "lock_table_name" {
  description = "DynamoDB table name — use this in the infra backend config"
  value       = aws_dynamodb_table.tflock.name
}

output "lock_table_arn" {
  description = "ARN of the lock table — used when writing IAM policies"
  value       = aws_dynamodb_table.tflock.arn
}
