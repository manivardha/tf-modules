module "target-group" {
  source = "../target-group"

  application = var.application
  environment = var.environment
  service     = var.service

  load_balancer_arn = var.load_balancer_arn
  port              = var.inbound_port
  protocol          = var.protocol
  vpc_id            = var.vpc_id

  stickiness = var.stickiness

  health_check_path = var.health_check_path
  certificate_arn   = var.certificate_arn
}


module "mas-policy" {
  source = "../mass-policy"
  environment = var.environment
}

# Other alarms
module "elb_healthy_hosts_alarm" {
  source = "../cw-metric-alarm"

  application = var.application
  environment = var.environment
  service     = var.service

  comparison_operator = "LessThanThreshold"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  threshold           = 1
  alarm_description   = "Count of healthy hosts in the ELB."
  alarm_actions       = ["arn:aws:sns:us-east-1:${module.mas-policy.aws_acctid}:${var.application}-${var.environment}-SEV1-Alarms"]
  treat_missing_data  = "breaching"
  dimensions = {
    TargetGroup  = module.target-group.target_group_arn_suffix
    LoadBalancer = var.load_balancer_arn_suffix
  }
}


module "non-ecs-asg" {
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
    scaling_policies = {
    cpu-tracking = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = var.health_check_grace_period
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = var.cpu_target_value
      }
    },
    mem-tracking = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = var.health_check_grace_period
      target_tracking_configuration = {
        customized_metric_specification = {
          metrics = [{
            id = "mem"
            metric_stat = {
              metric = {
                namespace   = "${var.application}/${var.environment}/${var.service}"
                metric_name = "mem_used_percent"
                dimensions = [{
                  name  = "AutoScalingGroupName"
                  value = "${var.application}.${var.environment}.${var.service}"
                }]
              }
              stat = "Average"
            }
          }]
        }
        target_value = var.mem_target_value
      }
    }
  }
    }

# MAS Core Hours Autoscaling
# "The supported cron expression format consists of five fields separated by white spaces: [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]"
# It also doesn't seem to like `?`, so I've replaced this with `*`
# The start_time will cause the event on the very first start, so we set it on creation, then ignore it.
# https://stackoverflow.com/a/71474280
resource "aws_autoscaling_schedule" "stop" {
  scheduled_action_name  = "${var.application}.${var.environment}.${var.service}.Stop"
  desired_capacity       = var.noncore_min
  min_size               = var.noncore_min
  max_size               = var.max_size
  start_time             = coalesce(var.stop_schedule_start_time, timeadd(timestamp(), "30m"))
  recurrence             = coalesce(var.stop_schedule_recurrence, "${module.mas-policy.core_hour["minutes"]} ${module.mas-policy.core_hour["stop_hours"]} * ${module.mas-policy.core_hour["month"]} ${module.mas-policy.core_hour["day_of_week"]}")
  autoscaling_group_name = module.asg.autoscaling_group_name
  time_zone              = var.schedule_time_zone
  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "aws_autoscaling_schedule" "start" {
  scheduled_action_name  = "${var.application}.${var.environment}.${var.service}.Start"
  desired_capacity       = var.core_min
  min_size               = var.core_min
  max_size               = var.max_size
  start_time             = coalesce(var.start_schedule_start_time, timeadd(timestamp(), "30m"))
  recurrence             = coalesce(var.start_schedule_recurrence, "${module.mas-policy.core_hour["minutes"]} ${module.mas-policy.core_hour["start_hours"]} * ${module.mas-policy.core_hour["month"]} ${module.mas-policy.core_hour["day_of_week"]}")
  autoscaling_group_name = module.asg.autoscaling_group_name
  time_zone              = var.schedule_time_zone
  lifecycle {
    ignore_changes = [start_time]
  }
}