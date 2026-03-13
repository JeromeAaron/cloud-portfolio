# -----------------------------------------------------------------------------
# Website S3 bucket
# Stores the built HTML/CSS/JS files from Astro.
# NOTE: This bucket is PRIVATE. Users never access it directly — only CloudFront
# can read from it, via the Origin Access Control defined in cloudfront.tf.
# This is more secure than the old "static website hosting" approach.
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "website" {
  bucket = "jerome-aaron-portfolio-website-${var.aws_account_id}"
}

# Block all public access — nobody reads this bucket directly
resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt files at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy: only CloudFront (via OAC) can read objects.
# The condition checks the CloudFront distribution ARN so no other distribution
# can serve your content even if someone knows your bucket name.
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # This depends on the CloudFront distribution existing first
  depends_on = [aws_cloudfront_distribution.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}
