# ============================================
# PROXMOX BACKUP S3 INFRASTRUCTURE
# ============================================
# Terraform configuration for S3-compatible storage (AWS, MinIO, Wasabi, etc.)

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================
# S3 BUCKET
# ============================================
resource "aws_s3_bucket" "proxmox_backups" {
  bucket = var.bucket_name

  tags = {
    Name        = "Proxmox Backups"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Kopia Backups"
    Project     = "ProxmoxBackup"
  }
}

# ============================================
# BUCKET VERSIONING
# ============================================
resource "aws_s3_bucket_versioning" "proxmox_backups" {
  bucket = aws_s3_bucket.proxmox_backups.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# ============================================
# LIFECYCLE RULES
# ============================================
resource "aws_s3_bucket_lifecycle_configuration" "proxmox_backups" {
  bucket = aws_s3_bucket.proxmox_backups.id

  # Delete incomplete multipart uploads after 7 days
  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Transition old versions to cheaper storage (if versioning enabled)
  dynamic "rule" {
    for_each = var.enable_versioning ? [1] : []

    content {
      id     = "transition-old-versions"
      status = "Enabled"

      noncurrent_version_transition {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }

      noncurrent_version_expiration {
        noncurrent_days = 90
      }
    }
  }
}

# ============================================
# SERVER-SIDE ENCRYPTION
# ============================================
resource "aws_s3_bucket_server_side_encryption_configuration" "proxmox_backups" {
  bucket = aws_s3_bucket.proxmox_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================
# BLOCK PUBLIC ACCESS
# ============================================
resource "aws_s3_bucket_public_access_block" "proxmox_backups" {
  bucket = aws_s3_bucket.proxmox_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================
# BUCKET POLICY (Optional - for IP restriction)
# ============================================
resource "aws_s3_bucket_policy" "proxmox_backups" {
  count  = var.restrict_to_ips != null ? 1 : 0
  bucket = aws_s3_bucket.proxmox_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RestrictToSpecificIPs"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.proxmox_backups.arn}",
          "${aws_s3_bucket.proxmox_backups.arn}/*"
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = var.restrict_to_ips
          }
        }
      }
    ]
  })
}
