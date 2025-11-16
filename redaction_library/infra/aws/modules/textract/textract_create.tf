# ============================================================================
# CREATE TEXTRACT RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "null_resource" "this" {
  count = var.create_textract ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-textract"
      Environment = var.environment
    }
  )
}

# Outputs
output "textract_id" {
  description = "TEXTRACT resource ID"
  value       = var.create_textract ? null_resource.this[0].id : null
}

output "textract_arn" {
  description = "TEXTRACT resource ARN"
  value       = var.create_textract ? null_resource.this[0].arn : null
}
