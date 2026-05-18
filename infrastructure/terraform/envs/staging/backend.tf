# Huawei Cloud OBS is S3-compatible — we use the standard Terraform "s3"
# backend pointed at the OBS endpoint. The bucket itself is provisioned
# by infra/terraform/bootstrap.
terraform {
  backend "s3" {
    bucket                      = "devops-takehome-tfstate"
    key                         = "staging/terraform.tfstate"
    region                      = "ap-southeast-2"
    endpoints                   = { s3 = "https://obs.ap-southeast-2.myhuaweicloud.com" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = false
  }
}
