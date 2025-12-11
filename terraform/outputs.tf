# ============================================
# TERRAFORM OUTPUTS
# ============================================

output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.proxmox_backups.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.proxmox_backups.arn
}

output "bucket_endpoint" {
  description = "S3 endpoint URL"
  value       = var.s3_endpoint
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = var.s3_region
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.enable_versioning
}

output "kopia_repository_paths" {
  description = "Kopia repository paths for each node"
  value = {
    node1 = "s3://${aws_s3_bucket.proxmox_backups.bucket}/node1-repo"
    node2 = "s3://${aws_s3_bucket.proxmox_backups.bucket}/node2-repo"
    node3 = "s3://${aws_s3_bucket.proxmox_backups.bucket}/node3-repo"
  }
}
