# ============================================================================
# USE EXISTING ECR REPOSITORY (CREATED BY INFRASTRUCTURE TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Infrastructure/Platform Team has already created an
# ECR repository. You just need to reference the existing repository for pushing
# your Docker images.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE a new ECR repository, use ecr_create.tf instead.
#
# WHAT YOU NEED FROM INFRASTRUCTURE TEAM:
# ---------------------------------------
# 1. ECR Repository Name:
#    - Example: "my-company-dev-api-service"
#    - Full repository URL (optional)
#    - AWS Account ID where repository exists
#
# 2. Confirm permissions:
#    - Does my IAM role/user have ecr:GetAuthorizationToken?
#    - Does my role have ecr:BatchGetImage permission?
#    - Does my role have ecr:GetDownloadUrlForLayer?
#    - Does my role have ecr:BatchCheckLayerAvailability?
#    - For pushing: ecr:PutImage, ecr:InitiateLayerUpload, ecr:CompleteLayerUpload
#
# 3. Repository configuration details:
#    - Is image scanning enabled?
#    - What's the lifecycle policy?
#    - Are image tags mutable or immutable?
#    - What's the encryption type (AES256 or KMS)?
#
# HOW TO USE:
# -----------
# 1. Ask Infrastructure Team for repository name
# 2. Fill in the repository name in variables.tf or terraform.tfvars:
#    existing_ecr_repository_name = "my-company-dev-api-service"
# 3. Use the repository URL in your CI/CD pipeline:
#    docker tag myimage:latest <repository_url>:latest
#    docker push <repository_url>:latest
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCE - FETCH EXISTING ECR REPOSITORY
# ----------------------------------------------------------------------------

data "aws_ecr_repository" "main" {
  count = var.existing_ecr_repository_name != "" ? 1 : 0

  name = var.existing_ecr_repository_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "existing_repository_arn" {
  description = "ARN of the existing ECR repository"
  value       = var.existing_ecr_repository_name != "" ? data.aws_ecr_repository.main[0].arn : null
}

output "existing_repository_name" {
  description = "Name of the existing ECR repository"
  value       = var.existing_ecr_repository_name != "" ? data.aws_ecr_repository.main[0].name : null
}

output "existing_repository_url" {
  description = "URL of the existing ECR repository"
  value       = var.existing_ecr_repository_name != "" ? data.aws_ecr_repository.main[0].repository_url : null
}

output "existing_registry_id" {
  description = "Registry ID where the repository exists"
  value       = var.existing_ecr_repository_name != "" ? data.aws_ecr_repository.main[0].registry_id : null
}

output "existing_ecr_summary" {
  description = "Summary of existing ECR repository"
  value = var.existing_ecr_repository_name != "" ? {
    name         = data.aws_ecr_repository.main[0].name
    url          = data.aws_ecr_repository.main[0].repository_url
    arn          = data.aws_ecr_repository.main[0].arn
    registry_id  = data.aws_ecr_repository.main[0].registry_id
  } : "not provided"
}

# ----------------------------------------------------------------------------
# VALIDATION OUTPUTS
# ----------------------------------------------------------------------------

output "validation_info" {
  description = "Validation information for existing ECR repository"
  value = var.existing_ecr_repository_name != "" ? {
    repository_name     = data.aws_ecr_repository.main[0].name
    repository_url      = data.aws_ecr_repository.main[0].repository_url
    registry_id         = data.aws_ecr_repository.main[0].registry_id
    image_tag_mutability = data.aws_ecr_repository.main[0].image_tag_mutability
    encryption_type     = data.aws_ecr_repository.main[0].encryption_configuration[0].encryption_type
    scan_on_push        = data.aws_ecr_repository.main[0].image_scanning_configuration[0].scan_on_push
  } : null
}
