# -----------------------------------------------------------------------------
# Route 53 — DNS
# Creates a hosted zone for jeromeaaron.com.
# After applying, you'll get 4 nameservers — update these on Namecheap.
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "website" {
  name = var.domain_name
}

# A record for the apex domain (jeromeaaron.com) → CloudFront
# This uses an "alias" record, which is Route 53's way of pointing an apex domain
# at an AWS resource. Normal CNAMEs can't be used on apex domains (RFC restriction).
resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.website.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA record for IPv6 — same target, CloudFront supports it out of the box
resource "aws_route53_record" "apex_ipv6" {
  zone_id = aws_route53_zone.website.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# www subdomain → same CloudFront distribution
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.website.zone_id
  name    = var.www_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
