variable "region" {
  type        = string
  description = "Huawei Cloud region (e.g. ap-southeast-2)."
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally-unique OBS bucket name for Terraform state."
}
