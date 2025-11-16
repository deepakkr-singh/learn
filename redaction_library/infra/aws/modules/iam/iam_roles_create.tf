# ============================================================================
# CREATE NEW IAM ROLES FOR AWS SERVICES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create IAM roles for your application services.
# Common use case: Create Lambda execution roles, EC2 instance roles, etc.
#
# WHEN NOT TO USE:
# ----------------
# If Security Team pre-creates all IAM roles, use iam_roles_use_existing.tf
#
# WHAT THIS FILE CREATES:
# -----------------------
# Common IAM roles for typical applications:
# 1. Lambda execution role (DynamoDB + Secrets Manager + S3)
# 2. EC2 instance role (S3 + CloudWatch + SSM)
# 3. ECS task role (for Fargate containers)
# 4. Step Functions execution role
# 5. EventBridge role
#
# IMPORTANT SECURITY:
# -------------------
# - Follow least privilege (grant minimum needed permissions)
# - Never use "*" for Action or Resource in production
# - Create separate roles per service/function when possible
#
# ============================================================================

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# ============================================================================
# PATTERN 1: LAMBDA EXECUTION ROLE
# ============================================================================
# WHAT: Role for Lambda functions
# PERMISSIONS: CloudWatch Logs, DynamoDB, Secrets Manager, S3 (optional)
# WHO USES: Lambda functions

resource "aws_iam_role" "lambda_execution" {
  count = var.create_lambda_execution_role ? 1 : 0

  name        = "${var.project_name}-lambda-execution-${var.environment}"
  description = "Execution role for Lambda functions"

  # Trust policy: Who can assume this role?
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-lambda-execution-${var.environment}"
      Purpose = "Lambda Execution"
    }
  )
}

# CloudWatch Logs (AWS managed policy)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.create_lambda_execution_role ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access (custom policy)
resource "aws_iam_policy" "lambda_dynamodb" {
  count = var.create_lambda_execution_role && var.lambda_dynamodb_table_arns != [] ? 1 : 0

  name        = "${var.project_name}-lambda-dynamodb-${var.environment}"
  description = "Allow Lambda to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = var.lambda_dynamodb_table_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  count = var.create_lambda_execution_role && var.lambda_dynamodb_table_arns != [] ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = aws_iam_policy.lambda_dynamodb[0].arn
}

# Secrets Manager access (custom policy)
resource "aws_iam_policy" "lambda_secrets" {
  count = var.create_lambda_execution_role && var.lambda_secrets_arns != [] ? 1 : 0

  name        = "${var.project_name}-lambda-secrets-${var.environment}"
  description = "Allow Lambda to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.lambda_secrets_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  count = var.create_lambda_execution_role && var.lambda_secrets_arns != [] ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = aws_iam_policy.lambda_secrets[0].arn
}

# S3 access (custom policy)
resource "aws_iam_policy" "lambda_s3" {
  count = var.create_lambda_execution_role && var.lambda_s3_bucket_arns != [] ? 1 : 0

  name        = "${var.project_name}-lambda-s3-${var.environment}"
  description = "Allow Lambda to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = flatten([
          var.lambda_s3_bucket_arns,
          [for arn in var.lambda_s3_bucket_arns : "${arn}/*"]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  count = var.create_lambda_execution_role && var.lambda_s3_bucket_arns != [] ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = aws_iam_policy.lambda_s3[0].arn
}

# VPC access (AWS managed policy - only if Lambda in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count = var.create_lambda_execution_role && var.lambda_in_vpc ? 1 : 0

  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ============================================================================
# PATTERN 2: EC2 INSTANCE ROLE
# ============================================================================
# WHAT: Role for EC2 instances
# PERMISSIONS: S3, CloudWatch Logs, Systems Manager (SSM)
# WHO USES: EC2 instances

resource "aws_iam_role" "ec2_instance" {
  count = var.create_ec2_instance_role ? 1 : 0

  name        = "${var.project_name}-ec2-instance-${var.environment}"
  description = "Role for EC2 instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-ec2-instance-${var.environment}"
      Purpose = "EC2 Instance"
    }
  )
}

# Instance profile (EC2 requires this)
resource "aws_iam_instance_profile" "ec2" {
  count = var.create_ec2_instance_role ? 1 : 0

  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_instance[0].name
}

# CloudWatch Logs access
resource "aws_iam_policy" "ec2_cloudwatch" {
  count = var.create_ec2_instance_role ? 1 : 0

  name        = "${var.project_name}-ec2-cloudwatch-${var.environment}"
  description = "Allow EC2 to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  count = var.create_ec2_instance_role ? 1 : 0

  role       = aws_iam_role.ec2_instance[0].name
  policy_arn = aws_iam_policy.ec2_cloudwatch[0].arn
}

# S3 access
resource "aws_iam_policy" "ec2_s3" {
  count = var.create_ec2_instance_role && var.ec2_s3_bucket_arns != [] ? 1 : 0

  name        = "${var.project_name}-ec2-s3-${var.environment}"
  description = "Allow EC2 to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = flatten([
          var.ec2_s3_bucket_arns,
          [for arn in var.ec2_s3_bucket_arns : "${arn}/*"]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  count = var.create_ec2_instance_role && var.ec2_s3_bucket_arns != [] ? 1 : 0

  role       = aws_iam_role.ec2_instance[0].name
  policy_arn = aws_iam_policy.ec2_s3[0].arn
}

# Systems Manager (SSM) access - for remote management
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = var.create_ec2_instance_role && var.ec2_enable_ssm ? 1 : 0

  role       = aws_iam_role.ec2_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================================================
# PATTERN 3: ECS TASK ROLE (for Fargate)
# ============================================================================
# WHAT: Role for ECS/Fargate tasks
# PERMISSIONS: Similar to Lambda (DynamoDB, Secrets, S3)
# WHO USES: Fargate containers

resource "aws_iam_role" "ecs_task" {
  count = var.create_ecs_task_role ? 1 : 0

  name        = "${var.project_name}-ecs-task-${var.environment}"
  description = "Execution role for ECS tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-ecs-task-${var.environment}"
      Purpose = "ECS Task"
    }
  )
}

# ECS task execution role (pulls images, writes logs)
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count = var.create_ecs_task_role ? 1 : 0

  role       = aws_iam_role.ecs_task[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "lambda_execution_role_arn" {
  description = "ARN of Lambda execution role"
  value       = var.create_lambda_execution_role ? aws_iam_role.lambda_execution[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Name of Lambda execution role"
  value       = var.create_lambda_execution_role ? aws_iam_role.lambda_execution[0].name : null
}

output "ec2_instance_role_arn" {
  description = "ARN of EC2 instance role"
  value       = var.create_ec2_instance_role ? aws_iam_role.ec2_instance[0].arn : null
}

output "ec2_instance_role_name" {
  description = "Name of EC2 instance role"
  value       = var.create_ec2_instance_role ? aws_iam_role.ec2_instance[0].name : null
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile (use this in aws_instance)"
  value       = var.create_ec2_instance_role ? aws_iam_instance_profile.ec2[0].name : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of EC2 instance profile"
  value       = var.create_ec2_instance_role ? aws_iam_instance_profile.ec2[0].arn : null
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = var.create_ecs_task_role ? aws_iam_role.ecs_task[0].arn : null
}

output "ecs_task_role_name" {
  description = "Name of ECS task role"
  value       = var.create_ecs_task_role ? aws_iam_role.ecs_task[0].name : null
}

# Summary output
output "roles_summary" {
  description = "Summary of all created IAM roles"
  value = {
    lambda_execution = var.create_lambda_execution_role ? {
      arn  = aws_iam_role.lambda_execution[0].arn
      name = aws_iam_role.lambda_execution[0].name
    } : "not created"

    ec2_instance = var.create_ec2_instance_role ? {
      role_arn         = aws_iam_role.ec2_instance[0].arn
      role_name        = aws_iam_role.ec2_instance[0].name
      instance_profile = aws_iam_instance_profile.ec2[0].name
    } : "not created"

    ecs_task = var.create_ecs_task_role ? {
      arn  = aws_iam_role.ecs_task[0].arn
      name = aws_iam_role.ecs_task[0].name
    } : "not created"
  }
}
