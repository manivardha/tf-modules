# # This policy/role is used both by the ASG and by an environment-specific EC2 spun up specifically for the install/update pipeline (masapps/docgen)
# module "iam-policy" {
#   source = "../iam-policy"

#   application = var.application
#   environment = var.environment
#   service     = var.service
#   policy_name = "EC2Access"
#   policy_doc  = data.aws_iam_policy_document.policy_document.json
# }

# data "aws_iam_policy_document" "policy_document" {
#   version = "2012-10-17"

#   # Get S3 objects for install/config
#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:ListBucket",
#       "s3:GetObjectTagging"
#     ]
#     resources = [
#       "arn:aws:s3:::mas${lower(var.environment)}config",
#       "arn:aws:s3:::mas${lower(var.environment)}config/*",
#       "arn:aws:s3:::massharedconfig",
#       "arn:aws:s3:::massharedconfig/*",
#       "arn:aws:s3:::massharedstorage",
#       "arn:aws:s3:::massharedstorage/*"
#     ]
#   }
#   statement {
#     effect    = "Allow"
#     actions   = ["s3:ListAllMyBuckets"]
#     resources = ["*"]
#   }

#   Get Secrets for install/config
#   statement {
#     effect = "Allow"
#     actions = [
#       "secretsmanager:GetSecretValue"
#     ]
#     resources = [
#       module.secret.arn,
#       var.artifact_login_arn
#     ]
#   }

#    statement {
#     effect = "Allow"
#     actions = [
#       "secretsmanager:GetSecretValue"
#     ]
#     resources = "*"
#   }

#   # Get Parameters for install/config
#   statement {
#     effect = "Allow"
#     actions = [
#       "ssm:GetParametersByPath"
#     ]
#     # Loop through all parameters and replace everything after the last slash with a star
#     resources = distinct([
#       for key, value in var.parameters : replace(module.parameters[key].resource_name, "/(\\w+)$/", "*")
#     ])
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "ssm:GetParametersByPath"
#     ]
#     # Loop through all parameters and replace everything after the last slash with a star
#     resources = "*"
#   }
#   statement {
#     effect = "Allow"
#     actions = [
#       "ssm:GetParameters"
#     ]
#     # Loop through all parameters and replace everything after the last slash with a star
#     resources = "*"
#   }

#   # Get tags for CM logging
#   # This only allows wildcard for the resource
#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeLaunchTemplates",
#       "ec2:DescribeInstances",
#       "ec2:DescribeTags"
#     ]
#     resources = ["*"]
#   }
# }