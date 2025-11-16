# ============================================================================
# USE EXISTING ROUTE53 RESOURCES
# ============================================================================

data "aws_route53_zone" "existing" {
  count = var.existing_route53_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "zone_id" {
  description = "ROUTE53 resource ID (existing)"
  value       = var.existing_route53_id != "" ? var.existing_route53_id : null
}
