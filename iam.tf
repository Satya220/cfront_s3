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

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
                "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::escavalar-bucket/*"
    ]
  }
}