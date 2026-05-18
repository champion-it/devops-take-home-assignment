variable "cluster_name" {
  type        = string
  description = "CCE cluster name."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version, e.g. v1.33."
  default     = "v1.33"
}

variable "cluster_flavor" {
  type        = string
  description = "Control plane flavor (HA = cce.s2.* family)."
  default     = "cce.s2.small"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy the cluster in."
}

variable "subnet_id" {
  type        = string
  description = "VPC subnet ID for the cluster (huaweicloud_vpc_subnet.id)."
}

variable "eni_subnet_id" {
  type        = string
  description = "IPv4 subnet (network) ID where Pod ENIs live in Turbo mode. Required when container_network_type='eni'."
}

variable "service_cidr" {
  type        = string
  description = "ClusterIP service CIDR."
  default     = "10.247.0.0/16"
}

variable "tags" {
  type    = map(string)
  default = {}
}
