# ============================================================================
# CREATE CLOUDFRONT RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "aws_cloudfront_distribution" "this" {
  count = var.create_cloudfront ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-cloudfront"
      Environment = var.environment
    }
  )
}

# Outputs
output "distribution_id" {
  description = "CLOUDFRONT resource ID"
  value       = var.create_cloudfront ? aws_cloudfront_distribution.this[0].id : null
}

output "distribution_arn" {
  description = "CLOUDFRONT resource ARN"
  value       = var.create_cloudfront ? aws_cloudfront_distribution.this[0].arn : null
}
