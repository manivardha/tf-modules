variable "application" { type = string }
variable "environment" { type = string }
variable "service" { type = string }
variable "sub_environment" { type = string }
variable "layer" { type = string }

variable "vpc_id" {
  type = string
}


variable "noncore_min" {
  type        = number
  description = "The minimum number of servers to run during non-core hours."
}

variable "max_size" {
  type        = number
  description = "The maximum number of servers to run during core hours."
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

variable "scaling_policies" {
  
}

# General ECS Cluster properties
variable "cluster_name" {
  description = "The name of the ECS cluster (e.g. ecs-prod). This is used to namespace all the resources created by these templates."
  type        = string
}

variable "autoscaling_termination_protection" {
  description = "Protect EC2 instances running ECS tasks from being terminated due to scale in (spot instances do not support lifecycle modifications)"
  type        = bool
  default     = false
}

variable "capacity_provider_max_scale_step" {
  description = "Maximum step adjustment size to the ASG's desired instance count"
  type        = number
  default     = 10
}

variable "capacity_provider_min_scale_step" {
  description = "Minimum step adjustment size to the ASG's desired instance count"
  type        = number
  default     = 1
}

variable "capacity_provider_target" {
  description = "Target cluster utilization for the capacity provider; a number from 1 to 100."
  type        = number
  default     = 75
}

variable "create_resources" {
  description = "If you set this variable to false, this module will not create any resources. This is used as a workaround because Terraform does not allow you to use the 'count' parameter on modules. By using this parameter, you can optionally create or not create the resources within this module."
  type        = bool
  default     = true
}

variable "cluster_instance_user_data_base64" {
  description = "The base64-encoded User Data script to run on the server when it is booting. This can be used to pass binary User Data, such as a gzipped cloud-init script. If you wish to pass in plain text (e.g., typical Bash script) for User Data, use var.cluster_instance_user_data instead."
  type        = string
  default     = null
}

variable "cluster_instance_user_data" {
  description = "The User Data script to run on each of the ECS Cluster's EC2 Instances on their first boot."
  type        = string
  default     = null
}

variable "capacity_provider_enabled" {
  description = "Enable a capacity provider to autoscale the EC2 ASG created for this ECS cluster"
  type        = bool
  default     = false
}

variable "multi_az_capacity_provider" {
  description = "Enable a multi-az capacity provider to autoscale the EC2 ASGs created for this ECS cluster, only if capacity_provider_enabled = true"
  type        = bool
  default     = false
}