# ============================================================================
# USE EXISTING TEXTRACT RESOURCES
# ============================================================================

data "null_resource" "existing" {
  count = var.existing_textract_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "textract_id" {
  description = "TEXTRACT resource ID (existing)"
  value       = var.existing_textract_id != "" ? var.existing_textract_id : null
}
