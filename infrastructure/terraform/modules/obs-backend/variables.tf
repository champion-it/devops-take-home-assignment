variable "bucket_name" {
  type        = string
  description = "Globally-unique OBS bucket name used to store Terraform state."
}

variable "tags" {
  type    = map(string)
  default = {}
}
