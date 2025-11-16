# ============================================================================
# USE EXISTING COGNITO USER POOL
# ============================================================================

data "aws_cognito_user_pools" "existing" {
  count = var.existing_user_pool_name != "" ? 1 : 0
  name  = var.existing_user_pool_name
}

# Outputs
output "user_pool_id" {
  description = "Cognito User Pool ID (existing)"
  value       = var.existing_user_pool_name != "" ? data.aws_cognito_user_pools.existing[0].ids[0] : null
}

output "user_pool_arns" {
  description = "Cognito User Pool ARNs (existing)"
  value       = var.existing_user_pool_name != "" ? data.aws_cognito_user_pools.existing[0].arns : null
}
