# ============================================================================
# CREATE ROUTE53 RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "aws_route53_zone" "this" {
  count = var.create_route53 ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-route53"
      Environment = var.environment
    }
  )
}

# Outputs
output "zone_id" {
  description = "ROUTE53 resource ID"
  value       = var.create_route53 ? aws_route53_zone.this[0].id : null
}

output "zone_arn" {
  description = "ROUTE53 resource ARN"
  value       = var.create_route53 ? aws_route53_zone.this[0].arn : null
}
