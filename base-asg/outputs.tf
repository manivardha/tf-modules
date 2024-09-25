output "ec2_access_policy_arn" {
  description = "The ARN of the EC2 access IAM policy"
  value       = module.iam-policy.policy_arn
}

output "asg_security_group_id" {
  description = "The ID of the security group created for the ASG"
  value       = module.asg_security_group.security_group_id
}