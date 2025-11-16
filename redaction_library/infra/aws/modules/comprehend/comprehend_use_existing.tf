# ============================================================================
# USE EXISTING COMPREHEND RESOURCES
# ============================================================================

data "null_resource" "existing" {
  count = var.existing_comprehend_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "comprehend_id" {
  description = "COMPREHEND resource ID (existing)"
  value       = var.existing_comprehend_id != "" ? var.existing_comprehend_id : null
}
