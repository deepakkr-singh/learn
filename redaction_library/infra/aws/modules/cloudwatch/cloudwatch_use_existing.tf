# ============================================================================
# USE EXISTING CLOUDWATCH LOG GROUP
# ============================================================================

data "aws_cloudwatch_log_group" "existing" {
  count = var.existing_log_group_name != "" ? 1 : 0

  name = var.existing_log_group_name
}

# Outputs
output "log_group_name" {
  description = "CloudWatch log group name (existing)"
  value       = var.existing_log_group_name != "" ? data.aws_cloudwatch_log_group.existing[0].name : null
}

output "log_group_arn" {
  description = "CloudWatch log group ARN (existing)"
  value       = var.existing_log_group_name != "" ? data.aws_cloudwatch_log_group.existing[0].arn : null
}
