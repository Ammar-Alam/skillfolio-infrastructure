# Configuration --------------------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "my_domain" {
  description = "My domain name"
  type = string
  
}

variable "my_certificate" {
  description = "ARN of my domain certificate"
  type = string
  sensitive = true
  
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Configure www version of site's bucket and Cloudfront distribution ------------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "www_site" {
  bucket = "www.myskillfoliotest01"

  tags = {
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "www_site" {
  bucket = aws_s3_bucket.www_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.www_site.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  index_document {
    suffix = "index.html"
  }
}


resource "aws_cloudfront_distribution" "www_site" {
  origin {
    domain_name = aws_s3_bucket.www_site.bucket_domain_name
    origin_id   = aws_s3_bucket.www_site.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront Distribution for www_site S3 bucket"
  default_root_object = "index.html"
  aliases = [ "www.${var.my_domain}" ]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.www_site.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
}

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.my_certificate
    ssl_support_method             = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"

  }

}



# Configure non www version of site's bucket for redirection and Cloudfront distribution ------------------------------------------------------------------------------------------------------------------------


resource "aws_s3_bucket" "redirect_site" {
  bucket = "redirectmyskillfoliotest01"

  tags = {
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "redirect_site" {
  bucket = aws_s3_bucket.redirect_site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "redirect_site" {
  bucket = aws_s3_bucket.redirect_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "redirect_site" {
  bucket = aws_s3_bucket.redirect_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.redirect_site.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "redirect_site" {
  bucket = aws_s3_bucket.redirect_site.id
  redirect_all_requests_to {
    host_name = "www.${var.my_domain}"
    protocol = "https"
  }
}

resource "aws_cloudfront_distribution" "redirect_site" {
  origin {
    domain_name = aws_s3_bucket.redirect_site.bucket_domain_name
    origin_id   = aws_s3_bucket.redirect_site.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront Distribution for redirect_site S3 bucket"
  #default_root_object = "index.html"
  aliases = [ var.my_domain ]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.redirect_site.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
}

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.my_certificate
    ssl_support_method             = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"

  }

}

# Configure DNS ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_route53_zone" "primary" {
  name = var.my_domain
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.my_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_site.domain_name
    zone_id                = aws_cloudfront_distribution.www_site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.my_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.redirect_site.domain_name
    zone_id                = aws_cloudfront_distribution.redirect_site.hosted_zone_id
    evaluate_target_health = false
  }
}

# Outputs ---------------------------------------------------------------------------------------------------------------------------------------------

output "nameservers" {
  value = aws_route53_zone.primary.name_servers
}