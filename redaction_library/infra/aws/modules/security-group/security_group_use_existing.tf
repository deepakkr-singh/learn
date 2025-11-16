# ============================================================================
# USE EXISTING SECURITY GROUPS (CREATED BY NETWORK/SECURITY TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Network/Security Team has already created security groups.
# You just need to reference the existing security groups for your resources.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new security groups, use security_group_create.tf instead.
#
# WHAT YOU NEED FROM NETWORK/SECURITY TEAM:
# -----------------------------------------
# 1. Security Group IDs for each resource type you'll use:
#    - ALB Security Group ID (if using Load Balancer)
#    - Lambda Security Group ID (if using Lambda)
#    - RDS Security Group ID (if using databases)
#    - EC2 Security Group ID (if using EC2 instances)
#    - Bastion Security Group ID (if using bastion/jump server)
#
# 2. Confirm what traffic is allowed:
#    - Which ports are open?
#    - Which sources can connect (CIDR blocks or other SGs)?
#    - Are there any restrictions?
#
# HOW TO USE:
# -----------
# 1. Ask Network/Security Team for Security Group IDs
# 2. Fill in the IDs in variables.tf or terraform.tfvars
# 3. Reference these IDs in your Lambda/EC2/RDS resources
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING SECURITY GROUPS
# ----------------------------------------------------------------------------

# ALB Security Group (for Load Balancers)
data "aws_security_group" "alb" {
  count = var.existing_alb_sg_id != "" ? 1 : 0

  id = var.existing_alb_sg_id

  # Alternative: Find by name
  # filter {
  #   name   = "tag:Name"
  #   values = ["production-alb-sg"]
  # }
}

# Lambda Security Group
data "aws_security_group" "lambda" {
  count = var.existing_lambda_sg_id != "" ? 1 : 0

  id = var.existing_lambda_sg_id
}

# RDS Database Security Group
data "aws_security_group" "rds" {
  count = var.existing_rds_sg_id != "" ? 1 : 0

  id = var.existing_rds_sg_id
}

# EC2 Web Server Security Group
data "aws_security_group" "ec2_web" {
  count = var.existing_ec2_web_sg_id != "" ? 1 : 0

  id = var.existing_ec2_web_sg_id
}

# Bastion Host Security Group
data "aws_security_group" "bastion" {
  count = var.existing_bastion_sg_id != "" ? 1 : 0

  id = var.existing_bastion_sg_id
}

# ElastiCache Security Group
data "aws_security_group" "elasticache" {
  count = var.existing_elasticache_sg_id != "" ? 1 : 0

  id = var.existing_elasticache_sg_id
}

# ----------------------------------------------------------------------------
# OUTPUTS - SAME AS security_group_create.tf
# ----------------------------------------------------------------------------
# WHY: Your application code doesn't need to know if SG was created or existing
# Same output structure = no code changes needed!

output "alb_security_group_id" {
  description = "ID of ALB security group (existing)"
  value       = var.existing_alb_sg_id != "" ? data.aws_security_group.alb[0].id : null
}

output "lambda_security_group_id" {
  description = "ID of Lambda security group (existing)"
  value       = var.existing_lambda_sg_id != "" ? data.aws_security_group.lambda[0].id : null
}

output "rds_security_group_id" {
  description = "ID of RDS security group (existing)"
  value       = var.existing_rds_sg_id != "" ? data.aws_security_group.rds[0].id : null
}

output "ec2_web_security_group_id" {
  description = "ID of EC2 web server security group (existing)"
  value       = var.existing_ec2_web_sg_id != "" ? data.aws_security_group.ec2_web[0].id : null
}

output "bastion_security_group_id" {
  description = "ID of Bastion host security group (existing)"
  value       = var.existing_bastion_sg_id != "" ? data.aws_security_group.bastion[0].id : null
}

output "elasticache_security_group_id" {
  description = "ID of ElastiCache security group (existing)"
  value       = var.existing_elasticache_sg_id != "" ? data.aws_security_group.elasticache[0].id : null
}

output "security_group_summary" {
  description = "Summary of existing security groups"
  value = {
    alb_sg         = var.existing_alb_sg_id != "" ? data.aws_security_group.alb[0].id : "not provided"
    lambda_sg      = var.existing_lambda_sg_id != "" ? data.aws_security_group.lambda[0].id : "not provided"
    rds_sg         = var.existing_rds_sg_id != "" ? data.aws_security_group.rds[0].id : "not provided"
    ec2_web_sg     = var.existing_ec2_web_sg_id != "" ? data.aws_security_group.ec2_web[0].id : "not provided"
    bastion_sg     = var.existing_bastion_sg_id != "" ? data.aws_security_group.bastion[0].id : "not provided"
    elasticache_sg = var.existing_elasticache_sg_id != "" ? data.aws_security_group.elasticache[0].id : "not provided"
  }
}

# ----------------------------------------------------------------------------
# VALIDATION OUTPUTS
# ----------------------------------------------------------------------------
# WHAT: Extra information to verify security groups are configured correctly
# WHY: Help you confirm the SGs have the right rules

output "validation_info" {
  description = "Validation information for existing security groups"
  value = {
    alb_sg_details = var.existing_alb_sg_id != "" ? {
      id          = data.aws_security_group.alb[0].id
      name        = data.aws_security_group.alb[0].name
      description = data.aws_security_group.alb[0].description
      vpc_id      = data.aws_security_group.alb[0].vpc_id
    } : null

    lambda_sg_details = var.existing_lambda_sg_id != "" ? {
      id          = data.aws_security_group.lambda[0].id
      name        = data.aws_security_group.lambda[0].name
      description = data.aws_security_group.lambda[0].description
      vpc_id      = data.aws_security_group.lambda[0].vpc_id
    } : null

    rds_sg_details = var.existing_rds_sg_id != "" ? {
      id          = data.aws_security_group.rds[0].id
      name        = data.aws_security_group.rds[0].name
      description = data.aws_security_group.rds[0].description
      vpc_id      = data.aws_security_group.rds[0].vpc_id
    } : null

    ec2_web_sg_details = var.existing_ec2_web_sg_id != "" ? {
      id          = data.aws_security_group.ec2_web[0].id
      name        = data.aws_security_group.ec2_web[0].name
      description = data.aws_security_group.ec2_web[0].description
      vpc_id      = data.aws_security_group.ec2_web[0].vpc_id
    } : null

    bastion_sg_details = var.existing_bastion_sg_id != "" ? {
      id          = data.aws_security_group.bastion[0].id
      name        = data.aws_security_group.bastion[0].name
      description = data.aws_security_group.bastion[0].description
      vpc_id      = data.aws_security_group.bastion[0].vpc_id
    } : null

    elasticache_sg_details = var.existing_elasticache_sg_id != "" ? {
      id          = data.aws_security_group.elasticache[0].id
      name        = data.aws_security_group.elasticache[0].name
      description = data.aws_security_group.elasticache[0].description
      vpc_id      = data.aws_security_group.elasticache[0].vpc_id
    } : null
  }
}

# ----------------------------------------------------------------------------
# VARIABLES NEEDED (Add these to variables.tf)
# ----------------------------------------------------------------------------
# Copy these to your variables.tf file:
/*

# ========================================
# EXISTING SECURITY GROUP VARIABLES
# ========================================

variable "existing_alb_sg_id" {
  description = "ID of existing ALB security group (e.g., sg-0abc123def456789)"
  type        = string
  default     = ""
}

variable "existing_lambda_sg_id" {
  description = "ID of existing Lambda security group"
  type        = string
  default     = ""
}

variable "existing_rds_sg_id" {
  description = "ID of existing RDS security group"
  type        = string
  default     = ""
}

variable "existing_ec2_web_sg_id" {
  description = "ID of existing EC2 web server security group"
  type        = string
  default     = ""
}

variable "existing_bastion_sg_id" {
  description = "ID of existing Bastion host security group"
  type        = string
  default     = ""
}

variable "existing_elasticache_sg_id" {
  description = "ID of existing ElastiCache security group"
  type        = string
  default     = ""
}

*/

# ----------------------------------------------------------------------------
# EXAMPLE terraform.tfvars
# ----------------------------------------------------------------------------
# Create a file called terraform.tfvars with these values:
/*

# From Network/Security Team
existing_alb_sg_id         = "sg-0abc123def456789"  # ALB security group
existing_lambda_sg_id      = "sg-0def456abc123789"  # Lambda security group
existing_rds_sg_id         = "sg-0ghi789jkl456123"  # RDS security group
existing_ec2_web_sg_id     = "sg-0mno123pqr789456"  # EC2 web security group
existing_bastion_sg_id     = "sg-0stu456vwx123789"  # Bastion security group
existing_elasticache_sg_id = "sg-0yza789bcd456123"  # ElastiCache security group

*/
