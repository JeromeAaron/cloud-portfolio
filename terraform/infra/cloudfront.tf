# -----------------------------------------------------------------------------
# CloudFront Distribution
# The CDN that sits between users and your S3 bucket.
# It caches your site at edge locations globally and handles HTTPS.
# -----------------------------------------------------------------------------

# CloudFront Function — rewrites directory URLs to index.html
# CloudFront's default_root_object only fixes the root "/".
# Without this, a request for "/blog" would look for a file literally named "blog"
# in S3 and get a 403. This function rewrites it to "/blog/index.html" first.
resource "aws_cloudfront_function" "url_rewrite" {
  name    = "portfolio-url-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // If URI ends with '/', append index.html
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      }
      // If URI has no file extension, it's a directory route — append /index.html
      else if (!uri.split('/').pop().includes('.')) {
        request.uri += '/index.html';
      }

      return request;
    }
  EOT
}

# -----------------------------------------------------------------------------
# Security Response Headers Policy
# CloudFront injects these headers into every response before it reaches the browser.
# This defends against common web attacks regardless of what the site itself does.
# -----------------------------------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "portfolio-security-headers"

  # Remove headers that reveal backend implementation details
  remove_headers_config {
    items {
      header = "x-amz-server-side-encryption"
    }
    items {
      header = "x-amz-request-id"
    }
    items {
      header = "x-amz-id-2"
    }
  }

  server_timing_headers_config {
    enabled       = false
    sampling_rate = 0
  }

  security_headers_config {
    # Prevent browsers from MIME-sniffing responses away from the declared content-type
    content_type_options {
      override = true
    }

    # Prevent site from being embedded in an iframe (clickjacking defence)
    frame_options {
      frame_option = "DENY"
      override     = true
    }

    # Force HTTPS for 1 year, including subdomains
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    # Control how much referrer info is sent with outbound requests
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    # Content Security Policy — defines exactly what sources are allowed to load.
    # 'self'                    = files from this domain only
    # fonts.googleapis.com      = Google Fonts CSS
    # fonts.gstatic.com         = Google Fonts files
    # frame-ancestors 'none'    = no iframing (stricter than X-Frame-Options)
    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self'; style-src 'self' fonts.googleapis.com; font-src fonts.gstatic.com; img-src 'self' data:; frame-ancestors 'none';"
      override                = true
    }
  }
}

# Origin Access Control — the secure handshake between CloudFront and S3.
# This replaces the older OAI (Origin Access Identity) approach.
# It signs every request from CloudFront to S3 so S3 can verify the source.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "portfolio-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, var.www_domain_name]
  price_class         = "PriceClass_100" # US, Canada, Europe — cheapest tier
  web_acl_id          = aws_wafv2_web_acl.website.arn

  # Where CloudFront fetches content from — our private S3 bucket
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # Default cache behavior — applies to all requests
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = "redirect-to-https" # HTTP → HTTPS automatically
    compress               = true                 # gzip/brotli for faster loads

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Attach the URL rewrite function to run on every viewer request
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }

    # Attach the security headers policy to every response
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    min_ttl     = 0
    default_ttl = 3600  # Cache for 1 hour by default
    max_ttl     = 86400 # Max cache: 24 hours
  }

  # Custom error pages — when S3 returns a 403 or 404, serve our custom page
  # S3 returns 403 (not 404) for missing objects when public access is blocked
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  # Use the ACM certificate we created — waits for validation to complete
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only" # Modern TLS — supported by all current browsers
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # No geo-blocking — site is public worldwide
    }
  }
}
