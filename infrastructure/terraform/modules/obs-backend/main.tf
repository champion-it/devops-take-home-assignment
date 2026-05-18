terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
  }
}

# OBS bucket used as a Terraform remote backend (S3-compatible API).
# Versioning + encryption are required for safe state storage.
# NOTE: Provider 1.91+ flattened `versioning`/`server_side_encryption` blocks
# into top-level arguments. Older docs still show block syntax — ignore those.
resource "huaweicloud_obs_bucket" "state" {
  bucket        = var.bucket_name
  acl           = "private"
  storage_class = "STANDARD"
  force_destroy = false

  # Keep every state revision; non-current versions purged after 90d below.
  versioning = true

  # SSE-KMS would need a KMS key ID; AES256 is fine for state.
  encryption    = true
  sse_algorithm = "AES256"

  lifecycle_rule {
    name    = "expire-old-versions"
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }

  tags = var.tags
}
