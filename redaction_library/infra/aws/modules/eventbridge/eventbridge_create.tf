# ============================================================================
# CREATE EVENTBRIDGE RESOURCES
# ============================================================================

# Note: This is a simplified example. Customize based on your needs.

resource "aws_cloudwatch_event_rule" "this" {
  count = var.create_eventbridge ? 1 : 0

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-eventbridge"
      Environment = var.environment
    }
  )
}

# Outputs
output "event_rule_id" {
  description = "EVENTBRIDGE resource ID"
  value       = var.create_eventbridge ? aws_cloudwatch_event_rule.this[0].id : null
}

output "event_rule_arn" {
  description = "EVENTBRIDGE resource ARN"
  value       = var.create_eventbridge ? aws_cloudwatch_event_rule.this[0].arn : null
}
