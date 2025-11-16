# ============================================================================
# CREATE S3 BUCKETS
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage S3 buckets for your application.
# You have full control over bucket configuration, lifecycle rules, and encryption.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - S3 bucket with configurable name
# - Public access blocking (security)
# - Versioning (optional, for file history)
# - Encryption (SSE-S3 free or SSE-KMS)
# - Lifecycle rules (auto-move to cheaper storage)
# - CORS configuration (for web uploads)
# - Access logging (for compliance)
# - Bucket policies (for fine-grained access)
# - Intelligent Tiering (automatic cost optimization)
#
# COMMON USE CASES:
# -----------------
# 1. User uploads (photos, documents)
# 2. Static website hosting
# 3. Application backups
# 4. Log storage
# 5. Data lake / analytics
#
# ============================================================================

# ----------------------------------------------------------------------------
# MAIN S3 BUCKET
# ----------------------------------------------------------------------------

resource "aws_s3_bucket" "main" {
  count = var.create_s3_bucket ? 1 : 0

  bucket        = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-${var.environment}-${var.bucket_purpose}"
  force_destroy = var.force_destroy

  tags = merge(
    var.common_tags,
    {
      Name        = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-${var.environment}-${var.bucket_purpose}"
      Environment = var.environment
      Purpose     = var.bucket_purpose
    }
  )
}

# ----------------------------------------------------------------------------
# PUBLIC ACCESS BLOCK (SECURITY)
# ----------------------------------------------------------------------------
# Block all public access by default (recommended for 99% of use cases)

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# ----------------------------------------------------------------------------
# VERSIONING
# ----------------------------------------------------------------------------
# Keep history of file changes (protects against accidental deletes)

resource "aws_s3_bucket_versioning" "main" {
  count = var.create_s3_bucket && var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# ----------------------------------------------------------------------------
# ENCRYPTION
# ----------------------------------------------------------------------------
# Encrypt all files at rest (SSE-S3 free, SSE-KMS for compliance)

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.kms_key_id != "" ? true : false
  }
}

# ----------------------------------------------------------------------------
# LIFECYCLE RULES (COST OPTIMIZATION)
# ----------------------------------------------------------------------------
# Automatically move old files to cheaper storage classes

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.create_s3_bucket && var.enable_lifecycle_rules ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  # Transition to cheaper storage
  rule {
    id     = "transition-to-cheaper-storage"
    status = var.lifecycle_rules_enabled ? "Enabled" : "Disabled"

    # Standard → IA → Glacier → Deep Archive
    dynamic "transition" {
      for_each = var.transition_to_ia_days > 0 ? [1] : []
      content {
        days          = var.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.transition_to_glacier_days > 0 ? [1] : []
      content {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }

    dynamic "transition" {
      for_each = var.transition_to_deep_archive_days > 0 ? [1] : []
      content {
        days          = var.transition_to_deep_archive_days
        storage_class = "DEEP_ARCHIVE"
      }
    }
  }

  # Expire old versions
  dynamic "rule" {
    for_each = var.enable_versioning && var.noncurrent_version_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-old-versions"
      status = "Enabled"

      noncurrent_version_expiration {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }

  # Clean up incomplete uploads
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
}

# ----------------------------------------------------------------------------
# CORS CONFIGURATION (for web applications)
# ----------------------------------------------------------------------------
# Allow direct browser uploads to S3

resource "aws_s3_bucket_cors_configuration" "main" {
  count = var.create_s3_bucket && var.enable_cors ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

# ----------------------------------------------------------------------------
# LOGGING
# ----------------------------------------------------------------------------
# Track who accesses files (for compliance/security)

resource "aws_s3_bucket_logging" "main" {
  count = var.create_s3_bucket && var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  target_bucket = var.logging_bucket_name
  target_prefix = var.logging_prefix != "" ? var.logging_prefix : "s3-access-logs/${var.project_name}/${var.environment}/"
}

# ----------------------------------------------------------------------------
# BUCKET POLICY
# ----------------------------------------------------------------------------
# Custom bucket policies (CloudFront access, cross-account, etc.)

resource "aws_s3_bucket_policy" "main" {
  count = var.create_s3_bucket && var.bucket_policy != "" ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  policy = var.bucket_policy
}

# ----------------------------------------------------------------------------
# INTELLIGENT TIERING
# ----------------------------------------------------------------------------
# AWS auto-optimizes storage costs based on access patterns

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  count = var.create_s3_bucket && var.enable_intelligent_tiering ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  name   = "EntireBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "bucket_id" {
  description = "Name of the S3 bucket"
  value       = var.create_s3_bucket ? aws_s3_bucket.main[0].id : null
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = var.create_s3_bucket ? aws_s3_bucket.main[0].arn : null
}

output "bucket_domain_name" {
  description = "Bucket domain name (for CloudFront origin)"
  value       = var.create_s3_bucket ? aws_s3_bucket.main[0].bucket_domain_name : null
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name"
  value       = var.create_s3_bucket ? aws_s3_bucket.main[0].bucket_regional_domain_name : null
}

# Summary output
output "bucket_summary" {
  description = "Summary of created S3 bucket"
  value = var.create_s3_bucket ? {
    name                  = aws_s3_bucket.main[0].id
    arn                   = aws_s3_bucket.main[0].arn
    versioning_enabled    = var.enable_versioning
    encryption            = var.kms_key_id != "" ? "SSE-KMS" : "SSE-S3"
    public_access_blocked = var.block_public_access
    lifecycle_enabled     = var.enable_lifecycle_rules
  } : "not created"
}
