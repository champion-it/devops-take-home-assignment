variable "organization" {
  type        = string
  description = "SWR organization name (namespace under the registry domain)."
}

variable "repositories" {
  type        = list(string)
  description = "Repositories to create within the organization."
  default     = ["devops-backend", "devops-frontend"]
}

variable "retention_keep_count" {
  type        = number
  description = "Keep only the latest N images per repo. 0 disables retention."
  default     = 20
}
