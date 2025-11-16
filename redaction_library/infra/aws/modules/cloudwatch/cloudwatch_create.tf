# ============================================================================
# CREATE CLOUDWATCH LOG GROUPS AND ALARMS
# ============================================================================

# Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = var.log_group_name != "" ? var.log_group_name : "/aws/${var.project_name}/${var.environment}"
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.common_tags,
    {
      Name        = var.log_group_name != "" ? var.log_group_name : "/aws/${var.project_name}/${var.environment}"
      Environment = var.environment
    }
  )
}

# Metric Alarm
resource "aws_cloudwatch_metric_alarm" "this" {
  count = var.create_alarm ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.alarm_name}"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = var.alarm_description
  alarm_actions       = var.alarm_actions

  dimensions = var.dimensions

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.alarm_name}"
      Environment = var.environment
    }
  )
}

# Outputs
output "log_group_name" {
  description = "CloudWatch log group name"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

output "alarm_arn" {
  description = "CloudWatch alarm ARN"
  value       = var.create_alarm ? aws_cloudwatch_metric_alarm.this[0].arn : null
}
