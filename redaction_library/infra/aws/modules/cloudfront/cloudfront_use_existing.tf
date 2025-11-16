# ============================================================================
# USE EXISTING CLOUDFRONT RESOURCES
# ============================================================================

data "aws_cloudfront_distribution" "existing" {
  count = var.existing_cloudfront_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "distribution_id" {
  description = "CLOUDFRONT resource ID (existing)"
  value       = var.existing_cloudfront_id != "" ? var.existing_cloudfront_id : null
}
