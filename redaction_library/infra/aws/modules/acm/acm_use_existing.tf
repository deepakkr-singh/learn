# ============================================================================
# USE EXISTING ACM RESOURCES
# ============================================================================

data "aws_acm_certificate" "existing" {
  count = var.existing_acm_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "certificate_id" {
  description = "ACM resource ID (existing)"
  value       = var.existing_acm_id != "" ? var.existing_acm_id : null
}
