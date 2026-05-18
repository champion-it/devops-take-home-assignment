terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

resource "huaweicloud_swr_organization" "this" {
  name = var.organization
}

resource "huaweicloud_swr_repository" "repos" {
  for_each = toset(var.repositories)

  organization = huaweicloud_swr_organization.this.name
  name         = each.value
  description  = "Container image repository for ${each.value}"
  category     = "linux"
  is_public    = false
}

# Retention policy resource was removed in Huawei provider 1.91+.
# Configure retention in the SWR Console instead, or via the REST API.
# Variable `retention_keep_count` is now informational only.
