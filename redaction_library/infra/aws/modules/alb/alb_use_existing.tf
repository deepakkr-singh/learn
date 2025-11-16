# ============================================================================
# USE EXISTING APPLICATION LOAD BALANCER (CREATED BY PLATFORM/NETWORK TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Platform/Network Team has already created an ALB.
# You just need to reference the existing ALB for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE a new ALB, use alb_create.tf instead.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. ALB Information:
#    - ALB name or ARN
#    - ALB DNS name
#    - Target group ARNs (if you're adding your targets)
#
# 2. Confirm permissions:
#    - Can I register my EC2/Fargate/Lambda to the target group?
#    - Do I have permissions to modify listener rules?
#    - What security groups does the ALB use?
#
# 3. ALB configuration details:
#    - Is it internet-facing or internal?
#    - What listeners are configured? (HTTP/HTTPS)
#    - What SSL certificate is attached?
#    - Are there existing routing rules I should be aware of?
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for ALB names/ARNs (use email template in README.md)
# 2. Fill in the ALB names in variables.tf or terraform.tfvars
# 3. Reference these ALBs and target groups for registering your targets
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING ALBs
# ----------------------------------------------------------------------------

# Main ALB
data "aws_lb" "main" {
  count = var.existing_alb_name != "" ? 1 : 0

  name = var.existing_alb_name
}

# Public ALB
data "aws_lb" "public" {
  count = var.existing_public_alb_name != "" ? 1 : 0

  name = var.existing_public_alb_name
}

# Internal ALB
data "aws_lb" "internal" {
  count = var.existing_internal_alb_name != "" ? 1 : 0

  name = var.existing_internal_alb_name
}

# API ALB
data "aws_lb" "api" {
  count = var.existing_api_alb_name != "" ? 1 : 0

  name = var.existing_api_alb_name
}

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING TARGET GROUPS
# ----------------------------------------------------------------------------

# Main target group
data "aws_lb_target_group" "main" {
  count = var.existing_target_group_name != "" ? 1 : 0

  name = var.existing_target_group_name
}

# Web target group
data "aws_lb_target_group" "web" {
  count = var.existing_web_target_group_name != "" ? 1 : 0

  name = var.existing_web_target_group_name
}

# API target group
data "aws_lb_target_group" "api" {
  count = var.existing_api_target_group_name != "" ? 1 : 0

  name = var.existing_api_target_group_name
}

# Admin target group
data "aws_lb_target_group" "admin" {
  count = var.existing_admin_target_group_name != "" ? 1 : 0

  name = var.existing_admin_target_group_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "main_alb_arn" {
  description = "ARN of the main ALB (existing)"
  value       = var.existing_alb_name != "" ? data.aws_lb.main[0].arn : null
}

output "main_alb_dns_name" {
  description = "DNS name of the main ALB (existing)"
  value       = var.existing_alb_name != "" ? data.aws_lb.main[0].dns_name : null
}

output "main_alb_zone_id" {
  description = "Zone ID of the main ALB (existing)"
  value       = var.existing_alb_name != "" ? data.aws_lb.main[0].zone_id : null
}

output "public_alb_arn" {
  description = "ARN of the public ALB (existing)"
  value       = var.existing_public_alb_name != "" ? data.aws_lb.public[0].arn : null
}

output "public_alb_dns_name" {
  description = "DNS name of the public ALB (existing)"
  value       = var.existing_public_alb_name != "" ? data.aws_lb.public[0].dns_name : null
}

output "internal_alb_arn" {
  description = "ARN of the internal ALB (existing)"
  value       = var.existing_internal_alb_name != "" ? data.aws_lb.internal[0].arn : null
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB (existing)"
  value       = var.existing_internal_alb_name != "" ? data.aws_lb.internal[0].dns_name : null
}

output "api_alb_arn" {
  description = "ARN of the API ALB (existing)"
  value       = var.existing_api_alb_name != "" ? data.aws_lb.api[0].arn : null
}

output "main_target_group_arn" {
  description = "ARN of the main target group (existing)"
  value       = var.existing_target_group_name != "" ? data.aws_lb_target_group.main[0].arn : null
}

output "web_target_group_arn" {
  description = "ARN of the web target group (existing)"
  value       = var.existing_web_target_group_name != "" ? data.aws_lb_target_group.web[0].arn : null
}

output "api_target_group_arn" {
  description = "ARN of the API target group (existing)"
  value       = var.existing_api_target_group_name != "" ? data.aws_lb_target_group.api[0].arn : null
}

output "admin_target_group_arn" {
  description = "ARN of the admin target group (existing)"
  value       = var.existing_admin_target_group_name != "" ? data.aws_lb_target_group.admin[0].arn : null
}

# Summary output
output "alb_summary" {
  description = "Summary of all existing ALBs"
  value = {
    main_alb = var.existing_alb_name != "" ? {
      name     = data.aws_lb.main[0].name
      arn      = data.aws_lb.main[0].arn
      dns_name = data.aws_lb.main[0].dns_name
      type     = data.aws_lb.main[0].internal ? "internal" : "internet-facing"
    } : "not provided"

    public_alb = var.existing_public_alb_name != "" ? {
      name     = data.aws_lb.public[0].name
      arn      = data.aws_lb.public[0].arn
      dns_name = data.aws_lb.public[0].dns_name
    } : "not provided"

    internal_alb = var.existing_internal_alb_name != "" ? {
      name     = data.aws_lb.internal[0].name
      arn      = data.aws_lb.internal[0].arn
      dns_name = data.aws_lb.internal[0].dns_name
    } : "not provided"

    api_alb = var.existing_api_alb_name != "" ? {
      name     = data.aws_lb.api[0].name
      arn      = data.aws_lb.api[0].arn
      dns_name = data.aws_lb.api[0].dns_name
    } : "not provided"
  }
}
