resource "aws_s3_bucket" "test_web" {
  bucket = "escavalar-bucket"

  tags = {
    Name = "Test_bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.test_web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# resource "aws_s3_bucket_acl" "test_web_acl" {
#   bucket = aws_s3_bucket.test_web.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_public_access_block" "test_web_block" {
#   bucket = aws_s3_bucket.test_web.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.test_web.id
  policy = <<EOF

  {
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::escavalar-bucket/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
            }
        }
    }
}
EOF
  }
    
  
resource "aws_s3_bucket" "log_storage" {
  bucket = "bscavalar-bucket"

  tags = {
    Name = "Log_bucket"
  }
}

resource "aws_s3_bucket_policy" "log" {
  bucket = aws_s3_bucket.log_storage.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadWrite",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": [
            "s3:GetObject",
            "s3:PutObject"
        ],
        "Resource": "arn:aws:s3:::bscavalar-bucket/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
            }
        }
    }
}
EOF
}
  


resource "aws_s3_bucket_ownership_controls" "log_bucket_owner" {
  bucket = aws_s3_bucket.log_storage.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# resource "aws_s3_bucket_acl" "log_acl" {
#   depends_on = [aws_s3_bucket_ownership_controls.log_bucket_owner]

#   bucket = aws_s3_bucket.log_storage.id
#   acl    = "private"
# }

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.test_web.bucket
  key    = "index.html"
  source = "${path.module}/index.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.module}/index.html")
}

resource "aws_s3_object" "css" {
  bucket = aws_s3_bucket.test_web.bucket
  key    = "style.css"
  source = "${path.module}/css/style.css"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.module}/css/style.css")
}

resource "aws_s3_object" "error_Object" {
  bucket = aws_s3_bucket.test_web.bucket
  key    = "404.html"
  source = "${path.module}/404.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.module}/404.html")
}

# resource "aws_s3_bucket_website_configuration" "example" {
#   bucket = aws_s3_bucket.test_web.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "404.html"
#   }

#   routing_rule {
#     condition {
#       key_prefix_equals = "/"
#     }
#     redirect {
#       replace_key_prefix_with = "documents/"
#     }
#   }
# }

resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "OAC_cfront"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.test_web.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
    origin_id                = aws_s3_bucket.test_web.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "This distributiom is for testing purposes"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "bscavalar-bucket.s3.amazonaws.com"
    prefix          = "myprefix"
  }

   aliases = [var.zone_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.test_web.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.test_web.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.test_web.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    # cloudfront_default_certificate = true
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
  }
}