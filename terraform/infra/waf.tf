# -----------------------------------------------------------------------------
# WAF (Web Application Firewall)
# Sits in front of CloudFront and filters malicious requests before they reach
# your site. Uses AWS-managed rule groups — regularly updated by AWS.
# scope = "CLOUDFRONT" means this must be deployed in us-east-1.
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "website" {
  name  = "portfolio-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {} # Allow requests by default; rules below BLOCK specific bad traffic
  }

  # Rule 1: AWS IP Reputation List
  # Blocks IPs that AWS has identified as malicious (botnets, scanners, etc.)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {} # Use the rule group's default actions
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Common Rule Set
  # Blocks common web exploits: SQLi, XSS, path traversal, etc.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Known Bad Inputs
  # Blocks requests containing patterns known to be malicious (log4j, etc.)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "portfolio-web-acl"
    sampled_requests_enabled   = true
  }
}
