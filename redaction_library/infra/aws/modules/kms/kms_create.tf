# ============================================================================
# CREATE NEW KMS KEYS
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage KMS encryption keys.
# You have full control over key policies, rotation, and permissions.
#
# WHEN NOT TO USE:
# ----------------
# If your Security Team has already created KMS keys, use kms_use_existing.tf
#
# WHAT THIS FILE CREATES:
# -----------------------
# Up to 7 different KMS keys (you choose which ones):
# 1. Secrets Manager key (for encrypting secrets)
# 2. S3 key (for encrypting files in S3 buckets)
# 3. DynamoDB key (for encrypting DynamoDB tables)
# 4. RDS key (for encrypting RDS databases)
# 5. Lambda key (for encrypting Lambda environment variables)
# 6. SNS key (for encrypting SNS topics)
# 7. SQS key (for encrypting SQS queues)
#
# WHY SEPARATE KEYS?
# ------------------
# Security isolation! If one key is compromised, others are safe.
# Example: If S3 key is compromised, your secrets are still safe.
#
# ============================================================================

# ----------------------------------------------------------------------------
# KMS KEY 1: SECRETS MANAGER
# ----------------------------------------------------------------------------
# WHAT: Encrypts all secrets in AWS Secrets Manager
# WHY: Protect API keys, database passwords, etc.
# WHO USES: Lambda functions that read secrets

resource "aws_kms_key" "secrets_manager" {
  count = var.create_secrets_manager_key ? 1 : 0

  description             = "KMS key for encrypting Secrets Manager secrets"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  # Key policy (who can use this key)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow account root full access (required)
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow Secrets Manager service to use key
      {
        Sid    = "Allow Secrets Manager"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-secrets-manager-key-${var.environment}"
      Purpose = "Secrets Manager Encryption"
    }
  )
}

# Alias for easy reference (use alias instead of key ID)
resource "aws_kms_alias" "secrets_manager" {
  count = var.create_secrets_manager_key ? 1 : 0

  name          = "alias/${var.project_name}-secrets-manager-${var.environment}"
  target_key_id = aws_kms_key.secrets_manager[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 2: S3 BUCKETS
# ----------------------------------------------------------------------------
# WHAT: Encrypts all files uploaded to S3
# WHY: Protect user uploads, documents, backups
# WHO USES: Applications uploading/downloading from S3

resource "aws_kms_key" "s3" {
  count = var.create_s3_key ? 1 : 0

  description             = "KMS key for encrypting S3 bucket objects"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow S3 service to use key
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-s3-key-${var.environment}"
      Purpose = "S3 Bucket Encryption"
    }
  )
}

resource "aws_kms_alias" "s3" {
  count = var.create_s3_key ? 1 : 0

  name          = "alias/${var.project_name}-s3-${var.environment}"
  target_key_id = aws_kms_key.s3[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 3: DYNAMODB TABLES
# ----------------------------------------------------------------------------
# WHAT: Encrypts DynamoDB tables at rest
# WHY: Protect user data, application data in database
# WHO USES: Applications reading/writing to DynamoDB

resource "aws_kms_key" "dynamodb" {
  count = var.create_dynamodb_key ? 1 : 0

  description             = "KMS key for encrypting DynamoDB tables"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow DynamoDB service to use key
      {
        Sid    = "Allow DynamoDB Service"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-dynamodb-key-${var.environment}"
      Purpose = "DynamoDB Table Encryption"
    }
  )
}

resource "aws_kms_alias" "dynamodb" {
  count = var.create_dynamodb_key ? 1 : 0

  name          = "alias/${var.project_name}-dynamodb-${var.environment}"
  target_key_id = aws_kms_key.dynamodb[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 4: RDS DATABASES
# ----------------------------------------------------------------------------
# WHAT: Encrypts RDS database instances (PostgreSQL, MySQL, etc.)
# WHY: Protect relational database data
# WHO USES: RDS service

resource "aws_kms_key" "rds" {
  count = var.create_rds_key ? 1 : 0

  description             = "KMS key for encrypting RDS databases"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow RDS service to use key
      {
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-rds-key-${var.environment}"
      Purpose = "RDS Database Encryption"
    }
  )
}

resource "aws_kms_alias" "rds" {
  count = var.create_rds_key ? 1 : 0

  name          = "alias/${var.project_name}-rds-${var.environment}"
  target_key_id = aws_kms_key.rds[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 5: LAMBDA ENVIRONMENT VARIABLES
# ----------------------------------------------------------------------------
# WHAT: Encrypts Lambda environment variables
# WHY: Protect config values, API endpoints
# WHO USES: Lambda service

resource "aws_kms_key" "lambda" {
  count = var.create_lambda_key ? 1 : 0

  description             = "KMS key for encrypting Lambda environment variables"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow Lambda service to use key
      {
        Sid    = "Allow Lambda Service"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-lambda-key-${var.environment}"
      Purpose = "Lambda Environment Variables Encryption"
    }
  )
}

resource "aws_kms_alias" "lambda" {
  count = var.create_lambda_key ? 1 : 0

  name          = "alias/${var.project_name}-lambda-${var.environment}"
  target_key_id = aws_kms_key.lambda[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 6: SNS TOPICS
# ----------------------------------------------------------------------------
# WHAT: Encrypts messages in SNS topics
# WHY: Protect notification content
# WHO USES: SNS service

resource "aws_kms_key" "sns" {
  count = var.create_sns_key ? 1 : 0

  description             = "KMS key for encrypting SNS topics"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow SNS service to use key
      {
        Sid    = "Allow SNS Service"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-sns-key-${var.environment}"
      Purpose = "SNS Topic Encryption"
    }
  )
}

resource "aws_kms_alias" "sns" {
  count = var.create_sns_key ? 1 : 0

  name          = "alias/${var.project_name}-sns-${var.environment}"
  target_key_id = aws_kms_key.sns[0].key_id
}

# ----------------------------------------------------------------------------
# KMS KEY 7: SQS QUEUES
# ----------------------------------------------------------------------------
# WHAT: Encrypts messages in SQS queues
# WHY: Protect queue message content
# WHO USES: SQS service

resource "aws_kms_key" "sqs" {
  count = var.create_sqs_key ? 1 : 0

  description             = "KMS key for encrypting SQS queues"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow SQS service to use key
      {
        Sid    = "Allow SQS Service"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-sqs-key-${var.environment}"
      Purpose = "SQS Queue Encryption"
    }
  )
}

resource "aws_kms_alias" "sqs" {
  count = var.create_sqs_key ? 1 : 0

  name          = "alias/${var.project_name}-sqs-${var.environment}"
  target_key_id = aws_kms_key.sqs[0].key_id
}

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
# WHY: Your other modules (Secrets Manager, S3, DynamoDB) need these key IDs/ARNs

output "secrets_manager_key_id" {
  description = "ID of KMS key for Secrets Manager"
  value       = var.create_secrets_manager_key ? aws_kms_key.secrets_manager[0].key_id : null
}

output "secrets_manager_key_arn" {
  description = "ARN of KMS key for Secrets Manager"
  value       = var.create_secrets_manager_key ? aws_kms_key.secrets_manager[0].arn : null
}

output "secrets_manager_key_alias" {
  description = "Alias of KMS key for Secrets Manager"
  value       = var.create_secrets_manager_key ? aws_kms_alias.secrets_manager[0].name : null
}

output "s3_key_id" {
  description = "ID of KMS key for S3"
  value       = var.create_s3_key ? aws_kms_key.s3[0].key_id : null
}

output "s3_key_arn" {
  description = "ARN of KMS key for S3"
  value       = var.create_s3_key ? aws_kms_key.s3[0].arn : null
}

output "s3_key_alias" {
  description = "Alias of KMS key for S3"
  value       = var.create_s3_key ? aws_kms_alias.s3[0].name : null
}

output "dynamodb_key_id" {
  description = "ID of KMS key for DynamoDB"
  value       = var.create_dynamodb_key ? aws_kms_key.dynamodb[0].key_id : null
}

output "dynamodb_key_arn" {
  description = "ARN of KMS key for DynamoDB"
  value       = var.create_dynamodb_key ? aws_kms_key.dynamodb[0].arn : null
}

output "dynamodb_key_alias" {
  description = "Alias of KMS key for DynamoDB"
  value       = var.create_dynamodb_key ? aws_kms_alias.dynamodb[0].name : null
}

output "rds_key_id" {
  description = "ID of KMS key for RDS"
  value       = var.create_rds_key ? aws_kms_key.rds[0].key_id : null
}

output "rds_key_arn" {
  description = "ARN of KMS key for RDS"
  value       = var.create_rds_key ? aws_kms_key.rds[0].arn : null
}

output "rds_key_alias" {
  description = "Alias of KMS key for RDS"
  value       = var.create_rds_key ? aws_kms_alias.rds[0].name : null
}

output "lambda_key_id" {
  description = "ID of KMS key for Lambda"
  value       = var.create_lambda_key ? aws_kms_key.lambda[0].key_id : null
}

output "lambda_key_arn" {
  description = "ARN of KMS key for Lambda"
  value       = var.create_lambda_key ? aws_kms_key.lambda[0].arn : null
}

output "lambda_key_alias" {
  description = "Alias of KMS key for Lambda"
  value       = var.create_lambda_key ? aws_kms_alias.lambda[0].name : null
}

output "sns_key_id" {
  description = "ID of KMS key for SNS"
  value       = var.create_sns_key ? aws_kms_key.sns[0].key_id : null
}

output "sns_key_arn" {
  description = "ARN of KMS key for SNS"
  value       = var.create_sns_key ? aws_kms_key.sns[0].arn : null
}

output "sns_key_alias" {
  description = "Alias of KMS key for SNS"
  value       = var.create_sns_key ? aws_kms_alias.sns[0].name : null
}

output "sqs_key_id" {
  description = "ID of KMS key for SQS"
  value       = var.create_sqs_key ? aws_kms_key.sqs[0].key_id : null
}

output "sqs_key_arn" {
  description = "ARN of KMS key for SQS"
  value       = var.create_sqs_key ? aws_kms_key.sqs[0].arn : null
}

output "sqs_key_alias" {
  description = "Alias of KMS key for SQS"
  value       = var.create_sqs_key ? aws_kms_alias.sqs[0].name : null
}

# Summary output
output "kms_keys_summary" {
  description = "Summary of all created KMS keys"
  value = {
    secrets_manager = var.create_secrets_manager_key ? {
      key_id = aws_kms_key.secrets_manager[0].key_id
      arn    = aws_kms_key.secrets_manager[0].arn
      alias  = aws_kms_alias.secrets_manager[0].name
    } : "not created"

    s3 = var.create_s3_key ? {
      key_id = aws_kms_key.s3[0].key_id
      arn    = aws_kms_key.s3[0].arn
      alias  = aws_kms_alias.s3[0].name
    } : "not created"

    dynamodb = var.create_dynamodb_key ? {
      key_id = aws_kms_key.dynamodb[0].key_id
      arn    = aws_kms_key.dynamodb[0].arn
      alias  = aws_kms_alias.dynamodb[0].name
    } : "not created"

    rds = var.create_rds_key ? {
      key_id = aws_kms_key.rds[0].key_id
      arn    = aws_kms_key.rds[0].arn
      alias  = aws_kms_alias.rds[0].name
    } : "not created"

    lambda = var.create_lambda_key ? {
      key_id = aws_kms_key.lambda[0].key_id
      arn    = aws_kms_key.lambda[0].arn
      alias  = aws_kms_alias.lambda[0].name
    } : "not created"

    sns = var.create_sns_key ? {
      key_id = aws_kms_key.sns[0].key_id
      arn    = aws_kms_key.sns[0].arn
      alias  = aws_kms_alias.sns[0].name
    } : "not created"

    sqs = var.create_sqs_key ? {
      key_id = aws_kms_key.sqs[0].key_id
      arn    = aws_kms_key.sqs[0].arn
      alias  = aws_kms_alias.sqs[0].name
    } : "not created"
  }
}

# Monthly cost estimate
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for KMS keys (does not include API request costs)"
  value = format(
    "$%d/month for %d KMS keys ($1 per key)",
    (var.create_secrets_manager_key ? 1 : 0) +
    (var.create_s3_key ? 1 : 0) +
    (var.create_dynamodb_key ? 1 : 0) +
    (var.create_rds_key ? 1 : 0) +
    (var.create_lambda_key ? 1 : 0) +
    (var.create_sns_key ? 1 : 0) +
    (var.create_sqs_key ? 1 : 0),
    (var.create_secrets_manager_key ? 1 : 0) +
    (var.create_s3_key ? 1 : 0) +
    (var.create_dynamodb_key ? 1 : 0) +
    (var.create_rds_key ? 1 : 0) +
    (var.create_lambda_key ? 1 : 0) +
    (var.create_sns_key ? 1 : 0) +
    (var.create_sqs_key ? 1 : 0)
  )
}
