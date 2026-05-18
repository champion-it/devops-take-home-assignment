terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

provider "huaweicloud" {
  region = var.region
}

locals {
  env  = "staging"
  name = "devops-takehome-${local.env}"
  tags = {
    project = "devops-takehome"
    env     = local.env
    owner   = "devops-team"
  }
}

module "vpc" {
  source   = "../../modules/vpc"
  vpc_name = "${local.name}-vpc"
  vpc_cidr = "10.10.0.0/16"

  subnets = [
    {
      name              = "private-a"
      cidr              = "10.10.1.0/24"
      gateway_ip        = "10.10.1.1"
      availability_zone = var.availability_zones[0]
    },
    {
      name              = "private-b"
      cidr              = "10.10.2.0/24"
      gateway_ip        = "10.10.2.1"
      availability_zone = var.availability_zones[1]
    },
  ]

  enable_nat_gateway = true
  tags               = local.tags
}

module "swr" {
  source       = "../../modules/swr"
  organization = "devops-takehome"
  repositories = ["devops-backend", "devops-frontend"]
}

module "cce" {
  source            = "../../modules/cce"
  cluster_name      = "${local.name}-cce"
  cluster_version   = "v1.29"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.subnet_ipv4_ids["private-a"]
  node_count        = 2
  min_node_count    = 2
  max_node_count    = 4
  node_flavor       = "s6.xlarge.2"
  availability_zone = var.availability_zones[0]
  key_pair_name     = var.key_pair_name
  tags              = local.tags
}

module "elb" {
  source             = "../../modules/elb"
  elb_name           = "${local.name}-elb"
  vpc_id             = module.vpc.vpc_id
  ipv4_subnet_id     = module.vpc.subnet_ipv4_ids["private-a"]
  availability_zones = var.availability_zones
  create_public_eip  = true
  eip_bandwidth_mbps = 5
  tags               = local.tags
}
