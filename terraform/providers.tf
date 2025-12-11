# ============================================
# TERRAFORM PROVIDERS
# ============================================

provider "aws" {
  region     = var.s3_region
  access_key = var.s3_access_key
  secret_key = var.s3_secret_key

  # Custom endpoint for S3-compatible storage
  endpoints {
    s3 = var.s3_endpoint
  }

  # Skip AWS-specific validations
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  default_tags {
    tags = merge(
      {
        ManagedBy = "Terraform"
        Project   = "ProxmoxBackup"
      },
      var.tags
    )
  }
}
