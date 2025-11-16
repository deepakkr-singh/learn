# ============================================================================
# USE EXISTING IAM ROLES (CREATED BY SECURITY TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when Security Team has already created IAM roles.
# You just need to reference existing roles for your services.
#
# WHAT YOU NEED FROM SECURITY TEAM:
# ---------------------------------
# IAM Role ARNs for:
# - Lambda execution role
# - EC2 instance role (and instance profile name)
# - ECS task role
#
# HOW TO USE:
# -----------
# 1. Ask Security Team for role ARNs
# 2. Fill in values in terraform.tfvars
# 3. Reference these roles in your Lambda/EC2/ECS resources
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING ROLES
# ----------------------------------------------------------------------------

# Lambda Execution Role
data "aws_iam_role" "lambda_execution" {
  count = var.existing_lambda_execution_role_name != "" ? 1 : 0

  name = var.existing_lambda_execution_role_name
}

# EC2 Instance Role
data "aws_iam_role" "ec2_instance" {
  count = var.existing_ec2_instance_role_name != "" ? 1 : 0

  name = var.existing_ec2_instance_role_name
}

# EC2 Instance Profile
data "aws_iam_instance_profile" "ec2" {
  count = var.existing_ec2_instance_profile_name != "" ? 1 : 0

  name = var.existing_ec2_instance_profile_name
}

# ECS Task Role
data "aws_iam_role" "ecs_task" {
  count = var.existing_ecs_task_role_name != "" ? 1 : 0

  name = var.existing_ecs_task_role_name
}

# ----------------------------------------------------------------------------
# OUTPUTS - SAME AS iam_roles_create.tf
# ----------------------------------------------------------------------------

output "lambda_execution_role_arn" {
  description = "ARN of Lambda execution role (existing)"
  value       = var.existing_lambda_execution_role_name != "" ? data.aws_iam_role.lambda_execution[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Name of Lambda execution role (existing)"
  value       = var.existing_lambda_execution_role_name != "" ? data.aws_iam_role.lambda_execution[0].name : null
}

output "ec2_instance_role_arn" {
  description = "ARN of EC2 instance role (existing)"
  value       = var.existing_ec2_instance_role_name != "" ? data.aws_iam_role.ec2_instance[0].arn : null
}

output "ec2_instance_role_name" {
  description = "Name of EC2 instance role (existing)"
  value       = var.existing_ec2_instance_role_name != "" ? data.aws_iam_role.ec2_instance[0].name : null
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile (existing)"
  value       = var.existing_ec2_instance_profile_name != "" ? data.aws_iam_instance_profile.ec2[0].name : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of EC2 instance profile (existing)"
  value       = var.existing_ec2_instance_profile_name != "" ? data.aws_iam_instance_profile.ec2[0].arn : null
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role (existing)"
  value       = var.existing_ecs_task_role_name != "" ? data.aws_iam_role.ecs_task[0].arn : null
}

output "ecs_task_role_name" {
  description = "Name of ECS task role (existing)"
  value       = var.existing_ecs_task_role_name != "" ? data.aws_iam_role.ecs_task[0].name : null
}

# Summary output
output "roles_summary" {
  description = "Summary of all existing IAM roles"
  value = {
    lambda_execution = var.existing_lambda_execution_role_name != "" ? {
      arn  = data.aws_iam_role.lambda_execution[0].arn
      name = data.aws_iam_role.lambda_execution[0].name
    } : "not provided"

    ec2_instance = var.existing_ec2_instance_role_name != "" ? {
      role_arn         = data.aws_iam_role.ec2_instance[0].arn
      role_name        = data.aws_iam_role.ec2_instance[0].name
      instance_profile = var.existing_ec2_instance_profile_name
    } : "not provided"

    ecs_task = var.existing_ecs_task_role_name != "" ? {
      arn  = data.aws_iam_role.ecs_task[0].arn
      name = data.aws_iam_role.ecs_task[0].name
    } : "not provided"
  }
}
