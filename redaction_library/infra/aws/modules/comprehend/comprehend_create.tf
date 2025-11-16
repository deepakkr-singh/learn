# ============================================================================
# CREATE COMPREHEND RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "null_resource" "this" {
  count = var.create_comprehend ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-comprehend"
      Environment = var.environment
    }
  )
}

# Outputs
output "comprehend_id" {
  description = "COMPREHEND resource ID"
  value       = var.create_comprehend ? null_resource.this[0].id : null
}

output "comprehend_arn" {
  description = "COMPREHEND resource ARN"
  value       = var.create_comprehend ? null_resource.this[0].arn : null
}
