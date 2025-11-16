# ============================================================================
# USE EXISTING S3 BUCKETS (CREATED BY INFRASTRUCTURE TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Infrastructure/Platform Team has already created S3 buckets.
# You just need to reference the existing buckets for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new S3 buckets, use s3_buckets_create.tf instead.
#
# WHAT YOU NEED FROM INFRASTRUCTURE TEAM:
# ---------------------------------------
# 1. S3 Bucket Names:
#    - Upload bucket name
#    - Backup bucket name
#    - Log bucket name
#    - Static assets bucket name
#    - Any other buckets your app needs
#
# 2. Confirm permissions:
#    - Does my Lambda/EC2 role have s3:GetObject permission?
#    - Does my role have s3:PutObject permission?
#    - Is the bucket in the same AWS region?
#    - Is the bucket encrypted? If yes, do I have KMS key access?
#
# 3. Bucket configuration details:
#    - Is versioning enabled?
#    - What's the encryption type (SSE-S3 or SSE-KMS)?
#    - Are there any bucket policies I need to know about?
#    - What's the CORS configuration (if needed)?
#
# HOW TO USE:
# -----------
# 1. Ask Infrastructure Team for bucket names (use email template in README.md)
# 2. Fill in the bucket names in variables.tf or terraform.tfvars
# 3. Reference these buckets in your Lambda/application code
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING S3 BUCKETS
# ----------------------------------------------------------------------------

# Main application upload bucket
data "aws_s3_bucket" "uploads" {
  count = var.existing_uploads_bucket_name != "" ? 1 : 0

  bucket = var.existing_uploads_bucket_name
}

# Backup bucket
data "aws_s3_bucket" "backups" {
  count = var.existing_backups_bucket_name != "" ? 1 : 0

  bucket = var.existing_backups_bucket_name
}

# Static assets bucket (HTML, CSS, JS, images)
data "aws_s3_bucket" "static_assets" {
  count = var.existing_static_assets_bucket_name != "" ? 1 : 0

  bucket = var.existing_static_assets_bucket_name
}

# Logs bucket
data "aws_s3_bucket" "logs" {
  count = var.existing_logs_bucket_name != "" ? 1 : 0

  bucket = var.existing_logs_bucket_name
}

# Custom/additional bucket
data "aws_s3_bucket" "custom" {
  count = var.existing_custom_bucket_name != "" ? 1 : 0

  bucket = var.existing_custom_bucket_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "uploads_bucket_id" {
  description = "Name of the uploads bucket (existing)"
  value       = var.existing_uploads_bucket_name != "" ? data.aws_s3_bucket.uploads[0].id : null
}

output "uploads_bucket_arn" {
  description = "ARN of the uploads bucket (existing)"
  value       = var.existing_uploads_bucket_name != "" ? data.aws_s3_bucket.uploads[0].arn : null
}

output "uploads_bucket_domain_name" {
  description = "Domain name of the uploads bucket (existing)"
  value       = var.existing_uploads_bucket_name != "" ? data.aws_s3_bucket.uploads[0].bucket_domain_name : null
}

output "uploads_bucket_regional_domain_name" {
  description = "Regional domain name of the uploads bucket (existing)"
  value       = var.existing_uploads_bucket_name != "" ? data.aws_s3_bucket.uploads[0].bucket_regional_domain_name : null
}

output "backups_bucket_id" {
  description = "Name of the backups bucket (existing)"
  value       = var.existing_backups_bucket_name != "" ? data.aws_s3_bucket.backups[0].id : null
}

output "backups_bucket_arn" {
  description = "ARN of the backups bucket (existing)"
  value       = var.existing_backups_bucket_name != "" ? data.aws_s3_bucket.backups[0].arn : null
}

output "static_assets_bucket_id" {
  description = "Name of the static assets bucket (existing)"
  value       = var.existing_static_assets_bucket_name != "" ? data.aws_s3_bucket.static_assets[0].id : null
}

output "static_assets_bucket_arn" {
  description = "ARN of the static assets bucket (existing)"
  value       = var.existing_static_assets_bucket_name != "" ? data.aws_s3_bucket.static_assets[0].arn : null
}

output "logs_bucket_id" {
  description = "Name of the logs bucket (existing)"
  value       = var.existing_logs_bucket_name != "" ? data.aws_s3_bucket.logs[0].id : null
}

output "logs_bucket_arn" {
  description = "ARN of the logs bucket (existing)"
  value       = var.existing_logs_bucket_name != "" ? data.aws_s3_bucket.logs[0].arn : null
}

output "custom_bucket_id" {
  description = "Name of the custom bucket (existing)"
  value       = var.existing_custom_bucket_name != "" ? data.aws_s3_bucket.custom[0].id : null
}

output "custom_bucket_arn" {
  description = "ARN of the custom bucket (existing)"
  value       = var.existing_custom_bucket_name != "" ? data.aws_s3_bucket.custom[0].arn : null
}

# Summary output
output "s3_buckets_summary" {
  description = "Summary of all existing S3 buckets"
  value = {
    uploads = var.existing_uploads_bucket_name != "" ? {
      name   = data.aws_s3_bucket.uploads[0].id
      arn    = data.aws_s3_bucket.uploads[0].arn
      region = data.aws_s3_bucket.uploads[0].region
    } : "not provided"

    backups = var.existing_backups_bucket_name != "" ? {
      name   = data.aws_s3_bucket.backups[0].id
      arn    = data.aws_s3_bucket.backups[0].arn
      region = data.aws_s3_bucket.backups[0].region
    } : "not provided"

    static_assets = var.existing_static_assets_bucket_name != "" ? {
      name   = data.aws_s3_bucket.static_assets[0].id
      arn    = data.aws_s3_bucket.static_assets[0].arn
      region = data.aws_s3_bucket.static_assets[0].region
    } : "not provided"

    logs = var.existing_logs_bucket_name != "" ? {
      name   = data.aws_s3_bucket.logs[0].id
      arn    = data.aws_s3_bucket.logs[0].arn
      region = data.aws_s3_bucket.logs[0].region
    } : "not provided"

    custom = var.existing_custom_bucket_name != "" ? {
      name   = data.aws_s3_bucket.custom[0].id
      arn    = data.aws_s3_bucket.custom[0].arn
      region = data.aws_s3_bucket.custom[0].region
    } : "not provided"
  }
}

# ----------------------------------------------------------------------------
# VALIDATION OUTPUTS
# ----------------------------------------------------------------------------
# Extra information to verify buckets are configured correctly

output "validation_info" {
  description = "Validation information for existing S3 buckets"
  value = {
    uploads_details = var.existing_uploads_bucket_name != "" ? {
      name          = data.aws_s3_bucket.uploads[0].id
      arn           = data.aws_s3_bucket.uploads[0].arn
      region        = data.aws_s3_bucket.uploads[0].region
      hosted_zone_id = data.aws_s3_bucket.uploads[0].hosted_zone_id
    } : null

    backups_details = var.existing_backups_bucket_name != "" ? {
      name          = data.aws_s3_bucket.backups[0].id
      arn           = data.aws_s3_bucket.backups[0].arn
      region        = data.aws_s3_bucket.backups[0].region
      hosted_zone_id = data.aws_s3_bucket.backups[0].hosted_zone_id
    } : null

    static_assets_details = var.existing_static_assets_bucket_name != "" ? {
      name          = data.aws_s3_bucket.static_assets[0].id
      arn           = data.aws_s3_bucket.static_assets[0].arn
      region        = data.aws_s3_bucket.static_assets[0].region
      hosted_zone_id = data.aws_s3_bucket.static_assets[0].hosted_zone_id
    } : null

    logs_details = var.existing_logs_bucket_name != "" ? {
      name          = data.aws_s3_bucket.logs[0].id
      arn           = data.aws_s3_bucket.logs[0].arn
      region        = data.aws_s3_bucket.logs[0].region
      hosted_zone_id = data.aws_s3_bucket.logs[0].hosted_zone_id
    } : null

    custom_details = var.existing_custom_bucket_name != "" ? {
      name          = data.aws_s3_bucket.custom[0].id
      arn           = data.aws_s3_bucket.custom[0].arn
      region        = data.aws_s3_bucket.custom[0].region
      hosted_zone_id = data.aws_s3_bucket.custom[0].hosted_zone_id
    } : null
  }
}
