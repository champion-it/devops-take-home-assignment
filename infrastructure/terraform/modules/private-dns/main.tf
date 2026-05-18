terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

# Private DNS zone — resolves only from within associated VPC(s).
# Admin tools (argocd, grafana, vault, prometheus) live behind names in this
# zone so they are NOT discoverable from the public Internet.
resource "huaweicloud_dns_zone" "internal" {
  name        = var.zone_name
  zone_type   = "private"
  description = var.description
  ttl         = var.ttl

  router {
    router_id     = var.vpc_id
    router_region = var.region
  }

  tags = var.tags
}

# One A record per entry in var.records.
# Key = short hostname ("argocd"), value = IP (usually the ELB's IP).
resource "huaweicloud_dns_recordset" "a" {
  for_each = var.records

  zone_id     = huaweicloud_dns_zone.internal.id
  name        = "${each.key}.${var.zone_name}"
  type        = "A"
  ttl         = var.ttl
  records     = [each.value]
  description = "Managed by Terraform"
}
