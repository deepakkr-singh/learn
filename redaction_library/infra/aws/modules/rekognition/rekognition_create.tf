# ============================================================================
# CREATE REKOGNITION RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "null_resource" "this" {
  count = var.create_rekognition ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-rekognition"
      Environment = var.environment
    }
  )
}

# Outputs
output "rekognition_id" {
  description = "REKOGNITION resource ID"
  value       = var.create_rekognition ? null_resource.this[0].id : null
}

output "rekognition_arn" {
  description = "REKOGNITION resource ARN"
  value       = var.create_rekognition ? null_resource.this[0].arn : null
}
