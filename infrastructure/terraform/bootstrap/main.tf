# Bootstrap stack — creates the OBS bucket that all other Terraform stacks use
# as their remote backend. Run this ONCE per project with local state, then
# migrate the bucket's state into itself (or simply keep its state local).
#
#   cd infra/terraform/bootstrap
#   terraform init
#   terraform apply
#
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

module "tfstate_bucket" {
  source      = "../modules/obs-backend"
  bucket_name = var.state_bucket_name
  tags = {
    project = "devops-takehome"
    purpose = "terraform-state"
  }
}

output "state_bucket_name" {
  value = module.tfstate_bucket.bucket_name
}

output "backend_config_example" {
  value = <<-EOT
    Add this to your stack's backend.tf:

      terraform {
        backend "s3" {
          bucket                      = "${module.tfstate_bucket.bucket_name}"
          key                         = "<env>/terraform.tfstate"
          region                      = "${var.region}"
          endpoints                   = { s3 = "https://obs.${var.region}.myhuaweicloud.com" }
          skip_region_validation      = true
          skip_credentials_validation = true
          skip_metadata_api_check     = true
          skip_requesting_account_id  = true
          skip_s3_checksum            = true
          use_path_style              = false
        }
      }

    Export your Huawei Cloud access keys before running 'terraform init':
      $env:AWS_ACCESS_KEY_ID     = "<HUAWEI_AK>"
      $env:AWS_SECRET_ACCESS_KEY = "<HUAWEI_SK>"
  EOT
}
