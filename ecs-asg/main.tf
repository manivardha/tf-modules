module "ecs-asg" {
    source              = "../base-asg"
    instance_type      = "t2.micro"
    security_groups     = var.security_groups  
    application         = var.application       
    core_min            = var.core_min          
    network_access      = var.network_access     
    layer               = var.layer              
    environment         = var.environment
    service             = var.service         
    subnet_list         = var.subnet_list       
    noncore_min         = var.noncore_min        
    vpc_id              = var.vpc_id           
    parameters          = var.parameters             
    sub_environment     = var.sub_environment    
    max_size            = var.max_size           
    traffic_source_attachments = {
      ex-alb = {
        traffic_source_identifier = module.target-group.target_group_arn
        traffic_source_type       = "elbv2" // default
      }
    }
    scaling_policies = var.scaling_policies
}

# Capacity providers for the cluster to enable autoscaling.
resource "aws_ecs_capacity_provider" "capacity_provider" {
  count = local.capacity_provider_count

  name = (
    local.capacity_provider_count == 1
    ? "capacity-${var.cluster_name}"
    : "capacity-${var.cluster_name}-${count.index}"
  )

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[count.index].arn
    managed_termination_protection = var.autoscaling_termination_protection ? "ENABLED" : "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = var.capacity_provider_max_scale_step
      minimum_scaling_step_size = var.capacity_provider_min_scale_step
      status                    = "ENABLED"
      target_capacity           = var.capacity_provider_target
    }
  }
}

# When enabled, create this resource only once to capture capacity providers and associate this resource with the ECS
# cluster.
resource "aws_ecs_cluster_capacity_providers" "this" {
  count = (
    var.create_resources && local.capacity_provider_count > 0
    ? 1
    : 0
  )

  cluster_name = aws_ecs_cluster.ecs[0].name

  capacity_providers = aws_ecs_capacity_provider.capacity_provider[*].name

  dynamic "default_capacity_provider_strategy" {
    for_each = aws_ecs_capacity_provider.capacity_provider
    iterator = capacity_provider

    content {
      capacity_provider = capacity_provider.value.name
      weight            = 1
    }
  }
}

# Base64 encode user data input, compute the list of default tags to apply to the cluster, as well as the number of capacity providers and auto-scaling
# groups based on the configuration (either no capacity provider, one capacity provider, or one capacity provider with
# one auto-scaling group per subnet/availability group https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers.html)
locals {

  # Launch templates do not support non-base64 user data input - for backwards compatability keep the existing vars, but 
  # encode the non-base64 input if the base64 input is not provided. If both var inputs are null, set user_data input to null
  user_data = (
    var.cluster_instance_user_data_base64 == null
    ? (
      var.cluster_instance_user_data == null
      ? null
      : base64encode(var.cluster_instance_user_data)
    )
    : var.cluster_instance_user_data_base64
  )

  capacity_provider_count = (
    var.create_resources && var.capacity_provider_enabled
    ? (
      var.multi_az_capacity_provider
      ? length(var.subnet_list)
      : 1
    )
    : 0
  )
  auto_scaling_group_count = (
    var.create_resources
    ? (
      var.capacity_provider_enabled && var.multi_az_capacity_provider
      ? length(var.subnet_list)
      : 1
    )
    : 0
  )

  default_tags = concat([
    {
      key                 = "Name"
      value               = var.cluster_name
      propagate_at_launch = true
    },
    ],

    # When using capacity providers, ECS automatically adds the AmazonECSManaged tag to the ASG. Without this tag,
    # capacity providers don't work correctly. Therefore, we add this tag here to make sure it doesn't accidentally get
    # removed on follow-up calls to 'apply'.
    local.capacity_provider_count > 0
    ? [
      {
        key                 = "AmazonECSManaged"
        value               = ""
        propagate_at_launch = true
      }
    ]
    : []
  )
}
