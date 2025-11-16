# ============================================================================
# CREATE ACM RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "aws_acm_certificate" "this" {
  count = var.create_acm ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-acm"
      Environment = var.environment
    }
  )
}

# Outputs
output "certificate_id" {
  description = "ACM resource ID"
  value       = var.create_acm ? aws_acm_certificate.this[0].id : null
}

output "certificate_arn" {
  description = "ACM resource ARN"
  value       = var.create_acm ? aws_acm_certificate.this[0].arn : null
}
