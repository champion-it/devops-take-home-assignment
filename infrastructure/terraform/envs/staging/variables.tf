variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "key_pair_name" {
  type        = string
  description = "Existing Huawei Cloud SSH key pair name for worker nodes."
}
