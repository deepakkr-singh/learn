# ============================================================================
# USE EXISTING REKOGNITION RESOURCES
# ============================================================================

data "null_resource" "existing" {
  count = var.existing_rekognition_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "rekognition_id" {
  description = "REKOGNITION resource ID (existing)"
  value       = var.existing_rekognition_id != "" ? var.existing_rekognition_id : null
}
