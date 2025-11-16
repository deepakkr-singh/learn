# ============================================================================
# USE EXISTING ECS CLUSTER (CREATED BY PLATFORM TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Platform Team has already created an ECS cluster.
# You just need to deploy your services to the existing cluster.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE a new ECS cluster, use fargate_service_create.tf instead.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Cluster Information:
#    - ECS Cluster name or ARN
#    - Cluster region
#    - Cluster capacity providers (FARGATE, FARGATE_SPOT)
#
# 2. Confirm permissions:
#    - Can I deploy services to this cluster?
#    - Can I create task definitions?
#    - Do I have permissions for ECS Exec (debugging)?
#
# 3. Networking:
#    - Which subnets should my tasks run in?
#    - Which security groups should I use?
#    - Should tasks have public IPs?
#
# 4. Load Balancing (if applicable):
#    - Which ALB/target group should I use?
#    - What health check path should my app implement?
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for cluster name (use email template in variables file)
# 2. Fill in the cluster name in variables.tf or terraform.tfvars
# 3. Deploy your task definitions and services to this cluster
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING ECS CLUSTERS
# ----------------------------------------------------------------------------

# Main cluster
data "aws_ecs_cluster" "main" {
  count = var.existing_cluster_name != "" ? 1 : 0

  cluster_name = var.existing_cluster_name
}

# Production cluster
data "aws_ecs_cluster" "prod" {
  count = var.existing_prod_cluster_name != "" ? 1 : 0

  cluster_name = var.existing_prod_cluster_name
}

# Staging cluster
data "aws_ecs_cluster" "staging" {
  count = var.existing_staging_cluster_name != "" ? 1 : 0

  cluster_name = var.existing_staging_cluster_name
}

# Dev cluster
data "aws_ecs_cluster" "dev" {
  count = var.existing_dev_cluster_name != "" ? 1 : 0

  cluster_name = var.existing_dev_cluster_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "main_cluster_id" {
  description = "ID of the main ECS cluster (existing)"
  value       = var.existing_cluster_name != "" ? data.aws_ecs_cluster.main[0].id : null
}

output "main_cluster_arn" {
  description = "ARN of the main ECS cluster (existing)"
  value       = var.existing_cluster_name != "" ? data.aws_ecs_cluster.main[0].arn : null
}

output "prod_cluster_id" {
  description = "ID of the production ECS cluster (existing)"
  value       = var.existing_prod_cluster_name != "" ? data.aws_ecs_cluster.prod[0].id : null
}

output "prod_cluster_arn" {
  description = "ARN of the production ECS cluster (existing)"
  value       = var.existing_prod_cluster_name != "" ? data.aws_ecs_cluster.prod[0].arn : null
}

output "staging_cluster_id" {
  description = "ID of the staging ECS cluster (existing)"
  value       = var.existing_staging_cluster_name != "" ? data.aws_ecs_cluster.staging[0].id : null
}

output "dev_cluster_id" {
  description = "ID of the dev ECS cluster (existing)"
  value       = var.existing_dev_cluster_name != "" ? data.aws_ecs_cluster.dev[0].id : null
}

# Summary output
output "ecs_clusters_summary" {
  description = "Summary of all existing ECS clusters"
  value = {
    main_cluster = var.existing_cluster_name != "" ? {
      name = data.aws_ecs_cluster.main[0].cluster_name
      arn  = data.aws_ecs_cluster.main[0].arn
    } : "not provided"

    prod_cluster = var.existing_prod_cluster_name != "" ? {
      name = data.aws_ecs_cluster.prod[0].cluster_name
      arn  = data.aws_ecs_cluster.prod[0].arn
    } : "not provided"

    staging_cluster = var.existing_staging_cluster_name != "" ? {
      name = data.aws_ecs_cluster.staging[0].cluster_name
      arn  = data.aws_ecs_cluster.staging[0].arn
    } : "not provided"

    dev_cluster = var.existing_dev_cluster_name != "" ? {
      name = data.aws_ecs_cluster.dev[0].cluster_name
      arn  = data.aws_ecs_cluster.dev[0].arn
    } : "not provided"
  }
}
