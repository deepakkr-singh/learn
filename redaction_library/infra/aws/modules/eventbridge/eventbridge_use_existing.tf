# ============================================================================
# USE EXISTING EVENTBRIDGE RESOURCES
# ============================================================================

data "aws_cloudwatch_event_bus" "existing" {
  count = var.existing_eventbridge_id != "" ? 1 : 0
  # Add appropriate data source attributes here
}

# Outputs
output "event_rule_id" {
  description = "EVENTBRIDGE resource ID (existing)"
  value       = var.existing_eventbridge_id != "" ? var.existing_eventbridge_id : null
}
