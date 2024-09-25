# module "gold_image" {
#   source = "git::https://bitbucket.cgif-hcp.com/scm/masiac/iac-policies.git//gold-image"

#   gold_image_name = var.gold_image_name
# }


module "asg_security_group" {
  source = "../security-group"

  environment     = var.environment
  sub_environment = var.sub_environment
  service         = var.service
  function        = var.function
  vpc_id          = var.vpc_id
}

# This policy/role is used both by the ASG and by an environment-specific EC2 spun up specifically for the install/update pipeline (masapps/docgen)
module "iam-policy" {
  source = "../iam-policy"

  application = var.application
  environment = var.environment
  service     = var.service
  policy_name = "EC2Access"
  policy_doc  = var.ec2_access_policy_documents
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = ">= 8.0.0"

  # Autoscaling group
  name            = "${var.application}.${var.environment}.${var.service}"
  use_name_prefix = false

  min_size            = var.core_min
  max_size            = var.max_size
  desired_capacity    = var.core_min
  health_check_type   = "ELB"
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  vpc_zone_identifier = var.subnet_list

  # Networking
  #target_group_arns         = [module.target-group.target_group_arn]

  traffic_source_attachments = var.traffic_source_attachments
  security_groups           = concat(var.security_groups, [module.asg_security_group.security_group_id])
  health_check_grace_period = var.health_check_grace_period

  # Launch template
  launch_template_name            = "${var.application}.${var.environment}.${var.service}"
  launch_template_use_name_prefix = false

  image_id          = "ami-066784287e358dad1"
  instance_type     = var.instance_type
  ebs_optimized     = true
  enable_monitoring = true
  user_data         = filebase64("${path.module}/user_data.sh")

  # Extra tags for a specific resource
  tag_specifications = [
    {
      resource_type = "volume"
      tags          = { Name = "${var.application}.${var.environment}.${var.service}.AutoScale" }
    }
  ]

  # IAM role & instance profile
  create_iam_instance_profile   = true
  iam_role_use_name_prefix      = false
  iam_role_name                 = "${var.application}.${var.environment}.${var.service}"
  iam_role_path                 = "/delegatedadmin/developer/"
  iam_role_permissions_boundary = "arn:aws:iam::829212170394:policy/cms-cloud-admin/developer-boundary-policy"

  # iam_role_policies = {
  #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #   CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  #   EC2Policy                    = module.iam-policy.policy_arn
  # }

  iam_role_policies = merge({
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EC2Policy                    = module.iam-policy.policy_arn
  }, var.additional_iam_role_policies)


  # This wil be updated by the pipeline each time a new sdb is created
  block_device_mappings = concat(
    [var.default_block_device_mapping],  
    var.additional_block_device_mappings
  )

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # The provider.tf tags don't seem to be fully propogating and these are _necessary_ for the user_data
  tags = {
    application = var.application
    service     = var.service
    environment = var.environment
  }

  # Autoscaling
  scaling_policies = var.scaling_policies
}

