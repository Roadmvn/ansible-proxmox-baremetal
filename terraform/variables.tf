# ============================================
# TERRAFORM VARIABLES
# ============================================

variable "s3_endpoint" {
  description = "S3 endpoint URL (AWS, MinIO, Wasabi, etc.)"
  type        = string
  default     = "https://s3.your-provider.com"
}

variable "s3_region" {
  description = "S3 region"
  type        = string
  default     = "your-region"
}

variable "s3_access_key" {
  description = "S3 access key"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "S3 secret key"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Name of the S3 bucket for backups"
  type        = string
  default     = "your-bucket-name"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
}

variable "restrict_to_ips" {
  description = "List of IPs allowed to access the bucket (optional)"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
