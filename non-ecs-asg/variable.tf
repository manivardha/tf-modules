variable "application" { type = string }
variable "environment" { type = string }
variable "service" { type = string }
variable "sub_environment" { type = string }
variable "layer" { type = string }

variable "parameters" {
    type = string
    default = "value"
}

variable "protocol" {
  description = "The protocol used by the target group (e.g., HTTP, HTTPS)."
  type        = string
  default     = "HTTPS"
}

variable "stickiness" {
  description = "Configuration for stickiness."
  type = object({
    type            = string
    enabled         = bool
    cookie_duration = number
  })
  default = {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 900
  }
}

variable "stop_schedule_start_time" {
  description = "Start time for the stop schedule action"
  type        = string
  default     = null
}

variable "stop_schedule_recurrence" {
  description = "Recurrence for the stop schedule action"
  type        = string
  default     = null
}

variable "start_schedule_start_time" {
  description = "Start time for the start schedule action"
  type        = string
  default     = null
}

variable "start_schedule_recurrence" {
  description = "Recurrence for the start schedule action"
  type        = string
  default     = null
}

variable "schedule_time_zone" {
  description = "Time zone for the start and stop schedules"
  type        = string
  default     = "America/New_York"
}

variable "vpc_id" {
  type = string
}

variable "load_balancer_arn" {
  type        = string
  description = "The ARN of the load balancer that will service this autoscaling group."
}

variable "load_balancer_arn_suffix" {
  type        = string
  description = "The ARN suffix (for CloudWatch metrics) of the load balancer that will service this autoscaling group."
}

variable "inbound_port" {
  type        = number
  description = "The port the load balancer will listen on."
}

variable "certificate_arn" {
  type        = string
  description = "The TLS certificate used by the load balancer listener."
}

variable "noncore_min" {
  type        = number
  description = "The minimum number of servers to run during non-core hours."
}

variable "max_size" {
  type        = number
  description = "The maximum number of servers to run during core hours."
}

variable "health_check_path" {
  description = "The path used for health checks."
  type        = string
  default     = "/"
}


variable "subnet_list" {
  type        = list(string)
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside."
}

variable "parameters" {
  description = "A map of the software installers used by DocGen, which are in Artifactory."
  type = map(object({
    value       = string
    description = string
  }))
}

variable "security_groups" {
  type        = list(string)
  description = "A list of security groups to add to the autoscaling group."
}


variable "network_access" {
  type = map(
    map(
      object({
        security_group_id = string
        port              = number
      })
    )
  )
  description = "Creates reciprocal inbound/outbound traffic between this autoscaling group and the provided security group on the provided port as either `inbound` or `outbound`."
}

variable "core_min" {
  type        = number
  description = "The base number of servers to run during core hours."
}

variable "health_check_grace_period" {
  type        = number
  description = "(Optional) Time (in seconds) after instance comes into service before checking health."
  default     = 2400
}

variable "cpu_target_value" {
  description = "The target value for CPU utilization in the scaling policy."
  type        = number
  default     = 80  # You can set the default to whatever you prefer
}

variable "mem_target_value" {
  description = "The target value for memory utilization in the scaling policy."
  type        = number
  default     = 80  # You can set the default to whatever you prefer
}