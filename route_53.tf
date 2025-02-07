# resource "aws_iam_role" "bucket_role" {
#   name = "bucket_role"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "s3.amazonaws.com"
#         }
#       },
#     ]
#   })

#   tags = {
#     tag-key = "website-dev"
#   }
# }

# resource "aws_iam_policy" "s3_policy" {
#   name        = "test_policy"
#   description = "Policy for public access"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "PublicReadGetObject",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": [
#                 "s3:Get*",
#                 "s3:List*",
#                 "s3:Describe*",
#                 "s3-object-lambda:Get*",
#                 "s3-object-lambda:List*"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::escavalar-bucket/*"
#             ]
#         }
#     ]
#   })
# }

# data "aws_iam_policy_document" "example" {
#   statement {
#     sid = "AllowCloudFrontServicePrincipalReadOnly"

#     actions = [
#       "s3:GetObject",
#     ]

#     principals {
#       type = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }

#     resources = [
#       "arn:aws:s3:::escavalar-bucket/*",
#     ]

#     condition{
#       test = "ArnEquals"
#       variable = "aws:SourceArn"
#       values = [
#         aws_cloudfront_distribution.s3_distribution.arn
#       ]

#     }
#   }
# }

# resource "aws_iam_policy" "example" {
#   name   = "website_policy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.example.json
# }

# data "aws_iam_policy_document" "log_policy" {
#   statement {
#     sid = "AllowCloudFrontServicePrincipalReadOnly"

#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#     ]

#     principals {
#       type = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }

#     resources = [
#       "arn:aws:s3:::bscavalar-bucket/*",
#     ]

#     condition{
#       test = "ArnEquals"
#       variable = "aws:SourceArn"
#       values = [
#        aws_cloudfront_distribution.s3_distribution.arn
#       ]

#     }
#   }
# }

# resource "aws_iam_policy" "log_pol" {
#   name   = "log_policy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.log_policy.json
# }

resource "aws_route53_zone" "primary" {
  name = var.zone_name
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "A_rec" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = aws_route53_zone.primary.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.zone_name
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}