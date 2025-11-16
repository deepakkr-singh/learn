# ============================================================================
# CREATE ECR (Elastic Container Registry) REPOSITORY
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage ECR repositories to store
# Docker images for Fargate, ECS, or Lambda.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - ECR Repository
# - Lifecycle Policy (auto-delete old images)
# - Repository Policy (access control)
# - Image Scanning Configuration
#
# COMMON USE CASES:
# -----------------
# 1. Store Docker images for Fargate/ECS
# 2. Store container images for Lambda
# 3. Private Docker registry
# 4. CI/CD pipeline image storage
#
# ============================================================================

# ----------------------------------------------------------------------------
# ECR REPOSITORY
# ----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.environment}-${var.repository_name}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.repository_name}"
      Environment = var.environment
    }
  )
}

# ----------------------------------------------------------------------------
# LIFECYCLE POLICY (Auto-delete old images)
# ----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "main" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = concat(
      var.lifecycle_keep_last_n_images > 0 ? [{
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_keep_last_n_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_keep_last_n_images
        }
        action = {
          type = "expire"
        }
      }] : [],
      var.lifecycle_expire_untagged_days > 0 ? [{
        rulePriority = 2
        description  = "Delete untagged images after ${var.lifecycle_expire_untagged_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_expire_untagged_days
        }
        action = {
          type = "expire"
        }
      }] : []
    )
  })
}

# ----------------------------------------------------------------------------
# REPOSITORY POLICY (Access Control)
# ----------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "main" {
  count = var.repository_policy != "" ? 1 : 0

  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.main.registry_id
}

output "ecr_summary" {
  description = "Summary of ECR repository"
  value = {
    name                = aws_ecr_repository.main.name
    url                 = aws_ecr_repository.main.repository_url
    scan_on_push        = var.scan_on_push
    lifecycle_enabled   = var.enable_lifecycle_policy
    immutable_tags      = var.image_tag_mutability == "IMMUTABLE"
  }
}
