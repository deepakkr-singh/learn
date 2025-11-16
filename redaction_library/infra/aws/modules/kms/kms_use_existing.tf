# ============================================================================
# USE EXISTING KMS KEYS (CREATED BY SECURITY TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Security Team has already created KMS keys.
# You just need to reference the existing keys for your resources.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new KMS keys, use kms_create.tf instead.
#
# WHAT YOU NEED FROM SECURITY TEAM:
# ---------------------------------
# 1. KMS Key ARNs or Aliases for each service you'll use:
#    - Secrets Manager KMS key ARN
#    - S3 KMS key ARN
#    - DynamoDB KMS key ARN
#    - RDS KMS key ARN (if using RDS)
#    - Lambda KMS key ARN (if using Lambda env vars)
#    - SNS KMS key ARN (if using SNS)
#    - SQS KMS key ARN (if using SQS)
#
# 2. Confirm permissions:
#    - Does my Lambda execution role have kms:Decrypt and kms:Encrypt permissions?
#    - Does my S3 bucket have permission to use the key?
#
# HOW TO USE:
# -----------
# 1. Ask Security Team for KMS key ARNs (use email template in README.md)
# 2. Fill in the ARNs in variables.tf or terraform.tfvars
# 3. Reference these keys in your Secrets Manager/S3/DynamoDB resources
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING KMS KEYS
# ----------------------------------------------------------------------------

# Secrets Manager KMS Key
data "aws_kms_key" "secrets_manager" {
  count = var.existing_secrets_manager_key_arn != "" ? 1 : 0

  key_id = var.existing_secrets_manager_key_arn

  # Alternative: Find by alias instead of ARN
  # key_id = "alias/my-secrets-manager-key"
}

# S3 KMS Key
data "aws_kms_key" "s3" {
  count = var.existing_s3_key_arn != "" ? 1 : 0

  key_id = var.existing_s3_key_arn
}

# DynamoDB KMS Key
data "aws_kms_key" "dynamodb" {
  count = var.existing_dynamodb_key_arn != "" ? 1 : 0

  key_id = var.existing_dynamodb_key_arn
}

# RDS KMS Key
data "aws_kms_key" "rds" {
  count = var.existing_rds_key_arn != "" ? 1 : 0

  key_id = var.existing_rds_key_arn
}

# Lambda KMS Key
data "aws_kms_key" "lambda" {
  count = var.existing_lambda_key_arn != "" ? 1 : 0

  key_id = var.existing_lambda_key_arn
}

# SNS KMS Key
data "aws_kms_key" "sns" {
  count = var.existing_sns_key_arn != "" ? 1 : 0

  key_id = var.existing_sns_key_arn
}

# SQS KMS Key
data "aws_kms_key" "sqs" {
  count = var.existing_sqs_key_arn != "" ? 1 : 0

  key_id = var.existing_sqs_key_arn
}

# ----------------------------------------------------------------------------
# OUTPUTS - SAME AS kms_create.tf
# ----------------------------------------------------------------------------
# WHY: Your application code doesn't need to know if key was created or existing
# Same output structure = no code changes needed!

output "secrets_manager_key_id" {
  description = "ID of KMS key for Secrets Manager (existing)"
  value       = var.existing_secrets_manager_key_arn != "" ? data.aws_kms_key.secrets_manager[0].key_id : null
}

output "secrets_manager_key_arn" {
  description = "ARN of KMS key for Secrets Manager (existing)"
  value       = var.existing_secrets_manager_key_arn != "" ? data.aws_kms_key.secrets_manager[0].arn : null
}

output "secrets_manager_key_alias" {
  description = "Alias of KMS key for Secrets Manager (existing)"
  value       = var.existing_secrets_manager_key_arn != "" ? data.aws_kms_key.secrets_manager[0].id : null
}

output "s3_key_id" {
  description = "ID of KMS key for S3 (existing)"
  value       = var.existing_s3_key_arn != "" ? data.aws_kms_key.s3[0].key_id : null
}

output "s3_key_arn" {
  description = "ARN of KMS key for S3 (existing)"
  value       = var.existing_s3_key_arn != "" ? data.aws_kms_key.s3[0].arn : null
}

output "s3_key_alias" {
  description = "Alias of KMS key for S3 (existing)"
  value       = var.existing_s3_key_arn != "" ? data.aws_kms_key.s3[0].id : null
}

output "dynamodb_key_id" {
  description = "ID of KMS key for DynamoDB (existing)"
  value       = var.existing_dynamodb_key_arn != "" ? data.aws_kms_key.dynamodb[0].key_id : null
}

output "dynamodb_key_arn" {
  description = "ARN of KMS key for DynamoDB (existing)"
  value       = var.existing_dynamodb_key_arn != "" ? data.aws_kms_key.dynamodb[0].arn : null
}

output "dynamodb_key_alias" {
  description = "Alias of KMS key for DynamoDB (existing)"
  value       = var.existing_dynamodb_key_arn != "" ? data.aws_kms_key.dynamodb[0].id : null
}

output "rds_key_id" {
  description = "ID of KMS key for RDS (existing)"
  value       = var.existing_rds_key_arn != "" ? data.aws_kms_key.rds[0].key_id : null
}

output "rds_key_arn" {
  description = "ARN of KMS key for RDS (existing)"
  value       = var.existing_rds_key_arn != "" ? data.aws_kms_key.rds[0].arn : null
}

output "rds_key_alias" {
  description = "Alias of KMS key for RDS (existing)"
  value       = var.existing_rds_key_arn != "" ? data.aws_kms_key.rds[0].id : null
}

output "lambda_key_id" {
  description = "ID of KMS key for Lambda (existing)"
  value       = var.existing_lambda_key_arn != "" ? data.aws_kms_key.lambda[0].key_id : null
}

output "lambda_key_arn" {
  description = "ARN of KMS key for Lambda (existing)"
  value       = var.existing_lambda_key_arn != "" ? data.aws_kms_key.lambda[0].arn : null
}

output "lambda_key_alias" {
  description = "Alias of KMS key for Lambda (existing)"
  value       = var.existing_lambda_key_arn != "" ? data.aws_kms_key.lambda[0].id : null
}

output "sns_key_id" {
  description = "ID of KMS key for SNS (existing)"
  value       = var.existing_sns_key_arn != "" ? data.aws_kms_key.sns[0].key_id : null
}

output "sns_key_arn" {
  description = "ARN of KMS key for SNS (existing)"
  value       = var.existing_sns_key_arn != "" ? data.aws_kms_key.sns[0].arn : null
}

output "sns_key_alias" {
  description = "Alias of KMS key for SNS (existing)"
  value       = var.existing_sns_key_arn != "" ? data.aws_kms_key.sns[0].id : null
}

output "sqs_key_id" {
  description = "ID of KMS key for SQS (existing)"
  value       = var.existing_sqs_key_arn != "" ? data.aws_kms_key.sqs[0].key_id : null
}

output "sqs_key_arn" {
  description = "ARN of KMS key for SQS (existing)"
  value       = var.existing_sqs_key_arn != "" ? data.aws_kms_key.sqs[0].arn : null
}

output "sqs_key_alias" {
  description = "Alias of KMS key for SQS (existing)"
  value       = var.existing_sqs_key_arn != "" ? data.aws_kms_key.sqs[0].id : null
}

# Summary output
output "kms_keys_summary" {
  description = "Summary of all existing KMS keys"
  value = {
    secrets_manager = var.existing_secrets_manager_key_arn != "" ? {
      key_id = data.aws_kms_key.secrets_manager[0].key_id
      arn    = data.aws_kms_key.secrets_manager[0].arn
    } : "not provided"

    s3 = var.existing_s3_key_arn != "" ? {
      key_id = data.aws_kms_key.s3[0].key_id
      arn    = data.aws_kms_key.s3[0].arn
    } : "not provided"

    dynamodb = var.existing_dynamodb_key_arn != "" ? {
      key_id = data.aws_kms_key.dynamodb[0].key_id
      arn    = data.aws_kms_key.dynamodb[0].arn
    } : "not provided"

    rds = var.existing_rds_key_arn != "" ? {
      key_id = data.aws_kms_key.rds[0].key_id
      arn    = data.aws_kms_key.rds[0].arn
    } : "not provided"

    lambda = var.existing_lambda_key_arn != "" ? {
      key_id = data.aws_kms_key.lambda[0].key_id
      arn    = data.aws_kms_key.lambda[0].arn
    } : "not provided"

    sns = var.existing_sns_key_arn != "" ? {
      key_id = data.aws_kms_key.sns[0].key_id
      arn    = data.aws_kms_key.sns[0].arn
    } : "not provided"

    sqs = var.existing_sqs_key_arn != "" ? {
      key_id = data.aws_kms_key.sqs[0].key_id
      arn    = data.aws_kms_key.sqs[0].arn
    } : "not provided"
  }
}

# ----------------------------------------------------------------------------
# VALIDATION OUTPUTS
# ----------------------------------------------------------------------------
# WHAT: Extra information to verify KMS keys are configured correctly
# WHY: Help you confirm the keys have the right settings

output "validation_info" {
  description = "Validation information for existing KMS keys"
  value = {
    secrets_manager_details = var.existing_secrets_manager_key_arn != "" ? {
      key_id               = data.aws_kms_key.secrets_manager[0].key_id
      arn                  = data.aws_kms_key.secrets_manager[0].arn
      enabled              = data.aws_kms_key.secrets_manager[0].enabled
      key_state            = data.aws_kms_key.secrets_manager[0].key_state
      key_usage            = data.aws_kms_key.secrets_manager[0].key_usage
      multi_region         = data.aws_kms_key.secrets_manager[0].multi_region
    } : null

    s3_details = var.existing_s3_key_arn != "" ? {
      key_id               = data.aws_kms_key.s3[0].key_id
      arn                  = data.aws_kms_key.s3[0].arn
      enabled              = data.aws_kms_key.s3[0].enabled
      key_state            = data.aws_kms_key.s3[0].key_state
      key_usage            = data.aws_kms_key.s3[0].key_usage
      multi_region         = data.aws_kms_key.s3[0].multi_region
    } : null

    dynamodb_details = var.existing_dynamodb_key_arn != "" ? {
      key_id               = data.aws_kms_key.dynamodb[0].key_id
      arn                  = data.aws_kms_key.dynamodb[0].arn
      enabled              = data.aws_kms_key.dynamodb[0].enabled
      key_state            = data.aws_kms_key.dynamodb[0].key_state
      key_usage            = data.aws_kms_key.dynamodb[0].key_usage
      multi_region         = data.aws_kms_key.dynamodb[0].multi_region
    } : null

    rds_details = var.existing_rds_key_arn != "" ? {
      key_id               = data.aws_kms_key.rds[0].key_id
      arn                  = data.aws_kms_key.rds[0].arn
      enabled              = data.aws_kms_key.rds[0].enabled
      key_state            = data.aws_kms_key.rds[0].key_state
      key_usage            = data.aws_kms_key.rds[0].key_usage
      multi_region         = data.aws_kms_key.rds[0].multi_region
    } : null

    lambda_details = var.existing_lambda_key_arn != "" ? {
      key_id               = data.aws_kms_key.lambda[0].key_id
      arn                  = data.aws_kms_key.lambda[0].arn
      enabled              = data.aws_kms_key.lambda[0].enabled
      key_state            = data.aws_kms_key.lambda[0].key_state
      key_usage            = data.aws_kms_key.lambda[0].key_usage
      multi_region         = data.aws_kms_key.lambda[0].multi_region
    } : null

    sns_details = var.existing_sns_key_arn != "" ? {
      key_id               = data.aws_kms_key.sns[0].key_id
      arn                  = data.aws_kms_key.sns[0].arn
      enabled              = data.aws_kms_key.sns[0].enabled
      key_state            = data.aws_kms_key.sns[0].key_state
      key_usage            = data.aws_kms_key.sns[0].key_usage
      multi_region         = data.aws_kms_key.sns[0].multi_region
    } : null

    sqs_details = var.existing_sqs_key_arn != "" ? {
      key_id               = data.aws_kms_key.sqs[0].key_id
      arn                  = data.aws_kms_key.sqs[0].arn
      enabled              = data.aws_kms_key.sqs[0].enabled
      key_state            = data.aws_kms_key.sqs[0].key_state
      key_usage            = data.aws_kms_key.sqs[0].key_usage
      multi_region         = data.aws_kms_key.sqs[0].multi_region
    } : null
  }
}

# ----------------------------------------------------------------------------
# VARIABLES NEEDED (Add these to variables.tf)
# ----------------------------------------------------------------------------
# Copy these to your variables.tf file:
/*

# ========================================
# EXISTING KMS KEY VARIABLES
# ========================================

variable "existing_secrets_manager_key_arn" {
  description = "ARN of existing KMS key for Secrets Manager"
  type        = string
  default     = ""
}

variable "existing_s3_key_arn" {
  description = "ARN of existing KMS key for S3"
  type        = string
  default     = ""
}

variable "existing_dynamodb_key_arn" {
  description = "ARN of existing KMS key for DynamoDB"
  type        = string
  default     = ""
}

variable "existing_rds_key_arn" {
  description = "ARN of existing KMS key for RDS"
  type        = string
  default     = ""
}

variable "existing_lambda_key_arn" {
  description = "ARN of existing KMS key for Lambda"
  type        = string
  default     = ""
}

variable "existing_sns_key_arn" {
  description = "ARN of existing KMS key for SNS"
  type        = string
  default     = ""
}

variable "existing_sqs_key_arn" {
  description = "ARN of existing KMS key for SQS"
  type        = string
  default     = ""
}

*/

# ----------------------------------------------------------------------------
# EXAMPLE terraform.tfvars
# ----------------------------------------------------------------------------
# Create a file called terraform.tfvars with these values:
/*

# From Security Team
existing_secrets_manager_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc-123-def-456"
existing_s3_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/def-456-ghi-789"
existing_dynamodb_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/ghi-789-jkl-012"

# Optional (only if using these services)
existing_rds_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/jkl-012-mno-345"
existing_lambda_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/mno-345-pqr-678"
existing_sns_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/pqr-678-stu-901"
existing_sqs_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/stu-901-vwx-234"

*/

# ----------------------------------------------------------------------------
# HOW TO FIND KMS KEY ARN
# ----------------------------------------------------------------------------
# If Security Team only gave you the alias, find ARN using AWS CLI:
/*

# Find key by alias
aws kms describe-key --key-id alias/my-secrets-manager-key

# Output shows ARN:
{
  "KeyMetadata": {
    "KeyId": "abc-123-def-456",
    "Arn": "arn:aws:kms:us-east-1:123456789012:key/abc-123-def-456"
  }
}

# List all KMS keys
aws kms list-keys

# Get key details
aws kms describe-key --key-id <key-id>

*/
