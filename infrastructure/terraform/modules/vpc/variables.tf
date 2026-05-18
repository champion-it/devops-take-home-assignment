variable "vpc_name" {
  type        = string
  description = "Name of the VPC."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC."
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "List of subnets to create in the VPC. `key` is the Terraform map key (must be unique); defaults to `name` if omitted. `name` is the Huawei subnet name (can repeat across subnets)."
  type = list(object({
    key               = optional(string)
    name              = string
    cidr              = string
    gateway_ip        = string
    availability_zone = string
  }))
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to create a NAT gateway for outbound traffic."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
