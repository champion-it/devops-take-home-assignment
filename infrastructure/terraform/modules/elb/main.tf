terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

# Public EIP attached to the load balancer (so Ingress traffic can reach it from the Internet).
resource "huaweicloud_vpc_eip" "this" {
  count = var.create_public_eip ? 1 : 0

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "${var.elb_name}-eip-bw"
    size        = var.eip_bandwidth_mbps
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# Dedicated ELB (recommended over shared for production workloads).
# EIP is attached directly via `ipv4_eip_id` — Huawei provider 1.91 rejects
# `huaweicloud_networking_eip_associate` for ELB ports.
resource "huaweicloud_elb_loadbalancer" "this" {
  name              = var.elb_name
  cross_vpc_backend = false
  vpc_id            = var.vpc_id
  ipv4_subnet_id    = var.ipv4_subnet_id
  availability_zone = var.availability_zones
  l4_flavor_id      = var.l4_flavor_id
  l7_flavor_id      = var.l7_flavor_id
  ipv4_eip_id       = var.create_public_eip ? huaweicloud_vpc_eip.this[0].id : null

  # consoleProtection prevents accidental deletion from the web console; set
  # to "nonProtection" to allow `terraform destroy` to work in dev / demo.
  protection_status = "nonProtection"
  protection_reason = "Managed by Terraform"

  tags = var.tags

  # Huawei auto-assigns flavors at create-time when we leave these null.
  # Don't try to push them back to null on subsequent applies (rejected).
  # ipv4_eip_id can't be updated once the ELB exists — set only at create-time
  # or bind via Console post-hoc.
  lifecycle {
    ignore_changes = [l4_flavor_id, l7_flavor_id, ipv4_eip_id]
  }
}

# ---- Backend pool + members for ingress-nginx NodePort --------------------
# One pool that all listeners share. Members = every worker node, port = NodePort.
resource "huaweicloud_elb_pool" "ingress" {
  name            = "${var.elb_name}-pool"
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
  loadbalancer_id = huaweicloud_elb_loadbalancer.this.id

  # ingress-nginx terminates each request — we don't need session stickiness at
  # the LB layer. (HTTP pools on Huawei ELB only support HTTP_COOKIE
  # persistence, not SOURCE_IP. Easiest to disable.)
}

# Health check pings ingress-nginx's /healthz on the HTTP NodePort.
resource "huaweicloud_elb_monitor" "ingress" {
  pool_id     = huaweicloud_elb_pool.ingress.id
  protocol    = "HTTP"
  interval    = 10
  timeout     = 5
  max_retries = 3
  url_path    = "/healthz"
  port        = var.ingress_nodeport_http
}

# Register every worker node as a pool member.
resource "huaweicloud_elb_member" "ingress" {
  for_each = var.worker_node_ips

  pool_id       = huaweicloud_elb_pool.ingress.id
  address       = each.value
  protocol_port = var.ingress_nodeport_http
  subnet_id     = var.ipv4_subnet_id
}

# HTTP listener (port 80) — forwards to ingress-nginx HTTP NodePort.
resource "huaweicloud_elb_listener" "http" {
  name            = "${var.elb_name}-http"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.this.id
  default_pool_id = huaweicloud_elb_pool.ingress.id

  forward_eip          = true
  forward_port         = true
  forward_request_port = true
  forward_host         = true
}

# HTTPS listener (port 443) — TLS terminates at ELB using SCM cert.
# If you prefer cert-manager + TLS at ingress-nginx, leave enable_https_listener=false
# and rely on TCP passthrough via a separate L4 listener (not implemented here).
resource "huaweicloud_elb_listener" "https" {
  count = var.enable_https_listener ? 1 : 0

  name               = "${var.elb_name}-https"
  protocol           = "HTTPS"
  protocol_port      = 443
  loadbalancer_id    = huaweicloud_elb_loadbalancer.this.id
  default_pool_id    = huaweicloud_elb_pool.ingress.id
  server_certificate = var.scm_certificate_id
  tls_ciphers_policy = "tls-1-2-strict"

  forward_eip          = true
  forward_port         = true
  forward_request_port = true
  forward_host         = true
}
