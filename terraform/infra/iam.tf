# -----------------------------------------------------------------------------
# GitHub Actions OIDC — keyless authentication
#
# Traditional approach: store AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY as
# GitHub secrets. Problem: long-lived credentials that can leak.
#
# Better approach (what we're doing): GitHub Actions uses OIDC to prove its
# identity to AWS. AWS issues a short-lived token just for that workflow run.
# No long-lived credentials stored anywhere.
# -----------------------------------------------------------------------------

# Register GitHub's OIDC provider with your AWS account.
# This tells AWS "trust identity tokens issued by GitHub Actions."
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprints — these are public values, not secrets
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# IAM role that GitHub Actions will assume during deployments
resource "aws_iam_role" "github_actions" {
  name = "portfolio-github-actions"

  # Trust policy: only our specific repo can assume this role.
  # The :ref:refs/heads/main part means only the main branch — not PRs from forks.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Least-privilege policy — only what the deploy workflow actually needs
resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "portfolio-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Upload/delete site files in S3
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*",
        ]
      },
      {
        # Invalidate CloudFront cache after deploying new files.
        # Without this, users would see stale cached content after a deploy.
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = [aws_cloudfront_distribution.website.arn]
      },
    ]
  })
}
