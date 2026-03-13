# -----------------------------------------------------------------------------
# TLS Certificate (HTTPS)
# ACM (AWS Certificate Manager) issues free certificates and auto-renews them.
# We request one certificate that covers both the apex domain and www subdomain.
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "website" {
  domain_name               = var.domain_name
  subject_alternative_names = [var.www_domain_name]  # covers www too
  validation_method         = "DNS"                   # proves ownership via DNS record

  lifecycle {
    # Create the new cert before destroying the old one during renewals.
    # Without this, CloudFront would briefly have no valid certificate.
    create_before_destroy = true
  }
}

# ACM uses DNS validation: it gives you a CNAME record to add to your zone.
# Adding that record proves you control the domain.
# This creates those validation records in Route 53 automatically.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.website.zone_id
}

# Wait for ACM to validate the certificate before we proceed.
# Terraform will poll until validation completes (usually 1-5 minutes).
resource "aws_acm_certificate_validation" "website" {
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
