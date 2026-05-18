variable "elb_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ipv4_subnet_id" {
  type        = string
  description = "IPv4 subnet (network) ID where the ELB attaches."
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs the ELB spans (must match cluster AZs)."
}

variable "l4_flavor_id" {
  type    = string
  default = null
}

variable "l7_flavor_id" {
  type    = string
  default = null
}

variable "create_public_eip" {
  type    = bool
  default = true
}

variable "eip_bandwidth_mbps" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ---- Ingress-nginx wiring -------------------------------------------------
variable "worker_node_ips" {
  type        = map(string)
  description = "Map of node name → private IP. ELB members = these IPs at NodePort."
  default     = {}
}

variable "ingress_nodeport_http" {
  type    = number
  default = 30080
}

variable "ingress_nodeport_https" {
  type    = number
  default = 30443
}

variable "enable_https_listener" {
  type        = bool
  description = "Create the :443 listener. Disable if you terminate TLS at ingress-nginx instead."
  default     = false
}

variable "scm_certificate_id" {
  type        = string
  description = "Huawei SCM certificate ID for the HTTPS listener (only used if enable_https_listener=true)."
  default     = ""
}
