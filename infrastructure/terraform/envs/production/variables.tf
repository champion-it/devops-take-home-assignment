variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "key_pair_name" {
  type        = string
  description = "Existing Huawei Cloud SSH key pair name for worker nodes. Set this OR root_password."
  default     = null
}

variable "root_password" {
  type        = string
  description = "Root password for worker nodes (alternative to key_pair_name). 8-26 chars incl. A-Z, a-z, 0-9, special."
  default     = null
  sensitive   = true
}

variable "git_repo" {
  type        = string
  description = "Git repo URL Argo CD syncs from (e.g. https://github.com/OWNER/REPO.git)."
  default     = "https://github.com/champion-it/devops-demo-assignment.git"
}

variable "git_revision" {
  type    = string
  default = "main"
}
