variable "application" { type = string }
variable "environment" { type = string }
variable "sub_environment" { type = string }
variable "service" { type = string }
variable "layer" { type = string }

variable "default_block_device_mapping" {
  description = "Default block device mapping"
  type = object({
    device_name = string
    no_device   = string
    ebs = object({
      delete_on_termination = bool
      encrypted             = bool
      volume_size           = number
      volume_type           = string
    })
  })
  default = {
    device_name = "/dev/sda1"
    no_device   = 1
    ebs = {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 31
      volume_type           = "gp3"
    }
  }
}

variable "additional_block_device_mappings" {
  description = "List of additional block devices"
  type = list(object({
    device_name = string            # Required
    no_device   = optional(string)  # Optional
    ebs = optional(object({         # Optional
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      volume_size           = optional(number)
      volume_type           = optional(string)
    }))
  }))
  default = []
}



variable "health_check_path" {
  description = "The path used for health checks."
  type        = string
  default     = "/"
}


variable "core_min" {
  type        = number
  description = "The base number of servers to run during core hours."
}

variable "function" {
  type        = string
  default = "asg"  
}

variable "noncore_min" {
  type        = number
  description = "The minimum number of servers to run during non-core hours."
}

variable "max_size" {
  type        = number
  description = "The maximum number of servers to run during core hours."
}


variable "ec2_access_policy_documents" {
  description = "List of additional policy documents to attach to the EC2 access IAM policy"
  type        = string
  default     = ""
}


variable "traffic_source_attachments" {
  description = "Map of traffic source attachments"
  type = map(object({
    traffic_source_identifier = string
    traffic_source_type       = string
  }))
  default = {}
}

variable "scaling_policies" {
  
}
variable "additional_iam_role_policies" {
  description = "Map of additional IAM role policies to attach to the instance profile"
  type        = map(string)
  default     = {}
}


variable "subnet_list" {
  type        = list(string)
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside."
}

variable "instance_type" {
  type = string
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

variable "parameters" {
  description = "A map of the software installers used by DocGen, which are in Artifactory."
  type = map(object({
    value       = string
    description = string
  }))
}

# variable "artifact_login_arn" {
#   description = "The ARN for the artifact repository login credentials."
#   type        = string
# }

variable "vpc_id" {
  type = string
}

variable "health_check_grace_period" {
  type        = number
  description = "(Optional) Time (in seconds) after instance comes into service before checking health."
  default     = 2400
}

variable "gold_image_name" {
  type        = string
  description = "(Optional) The name of the MAS-approved gold image to use."
  default     = "rhel"
}