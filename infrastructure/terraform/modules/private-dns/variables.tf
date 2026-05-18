variable "zone_name" {
  type        = string
  description = "Private DNS zone name (must end with a dot, e.g. 'example.internal.')."
  validation {
    condition     = endswith(var.zone_name, ".")
    error_message = "zone_name must end with a trailing dot, e.g. 'example.internal.'"
  }
}

variable "description" {
  type    = string
  default = "Internal DNS for admin tools (Argo CD, Grafana, Vault, Prometheus)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate the zone with (only this VPC can resolve names)."
}

variable "region" {
  type        = string
  description = "Huawei Cloud region (e.g. ap-southeast-2)."
}

variable "ttl" {
  type    = number
  default = 300
}

variable "records" {
  type        = map(string)
  description = "Map of subdomain → IPv4 address. Each entry becomes an A record under the zone."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
