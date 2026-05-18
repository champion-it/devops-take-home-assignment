terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

# CCE Turbo cluster — uses ENI networking (Cloud Native 2.0) so Pods get
# IPs directly from VPC subnets, no overlay encapsulation. Lower latency
# and per-Pod security groups become possible.
resource "huaweicloud_cce_cluster" "this" {
  name                   = var.cluster_name
  cluster_version        = var.cluster_version
  cluster_type           = "VirtualMachine"
  flavor_id              = var.cluster_flavor
  vpc_id                 = var.vpc_id
  subnet_id              = var.subnet_id
  container_network_type = "eni"             # ← Turbo (was "overlay_l2")
  eni_subnet_id          = var.eni_subnet_id # subnet for Pod ENI addresses
  service_network_cidr   = var.service_cidr
  authentication_mode    = "rbac"

  tags = var.tags
}

# Node pools live in the env layer now (inline `huaweicloud_cce_node_pool`
# blocks with for_each), so they can be created one-per-AZ for true HA.
# Module exports cluster outputs only — see outputs.tf.
