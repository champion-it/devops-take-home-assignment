terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

resource "huaweicloud_vpc" "this" {
  name = var.vpc_name
  cidr = var.vpc_cidr
  tags = var.tags
}

resource "huaweicloud_vpc_subnet" "this" {
  # Use the caller-provided `key` (unique per subnet) as the for_each map key,
  # falling back to `name` for backward compatibility. Huawei allows duplicate
  # subnet names within a VPC, so callers can name all subnets the same and
  # disambiguate with `key` (e.g. all three subnets called "sg-dev-cce-node").
  for_each = { for s in var.subnets : coalesce(s.key, s.name) => s }

  name              = each.value.name
  cidr              = each.value.cidr
  gateway_ip        = each.value.gateway_ip
  vpc_id            = huaweicloud_vpc.this.id
  availability_zone = each.value.availability_zone
  dhcp_enable       = true
  tags              = var.tags
}

# Optional NAT gateway for private subnet outbound traffic
resource "huaweicloud_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  name        = "${var.vpc_name}-nat"
  spec        = "1"
  vpc_id      = huaweicloud_vpc.this.id
  subnet_id   = values(huaweicloud_vpc_subnet.this)[0].id
  description = "NAT gateway for ${var.vpc_name}"
}
