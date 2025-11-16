# ============================================================================
# USE EXISTING SNS TOPICS (CREATED BY PLATFORM/APP TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Platform/App Team has already created SNS topics.
# You just need to reference the existing topics for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new SNS topics, use sns_topics_create.tf instead.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Topic Names or ARNs:
#    - Event notification topic name/ARN
#    - Alert topic name/ARN
#    - System events topic name/ARN
#
# 2. Confirm permissions:
#    - Does my Lambda/application role have sns:Publish permission?
#    - Does my role have sns:Subscribe permission?
#    - Is the topic encrypted? If yes, do I have KMS key access?
#
# 3. Topic configuration details:
#    - Is it a FIFO topic?
#    - What message format is expected?
#    - Are there any message filtering policies?
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for topic names/ARNs (use email template in README.md)
# 2. Fill in the topic names in variables.tf or terraform.tfvars
# 3. Reference these topics in your Lambda/application code for publishing
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING SNS TOPICS
# ----------------------------------------------------------------------------

# Main event topic
data "aws_sns_topic" "events" {
  count = var.existing_events_topic_name != "" ? 1 : 0

  name = var.existing_events_topic_name
}

# Alert topic
data "aws_sns_topic" "alerts" {
  count = var.existing_alerts_topic_name != "" ? 1 : 0

  name = var.existing_alerts_topic_name
}

# System notifications topic
data "aws_sns_topic" "system" {
  count = var.existing_system_topic_name != "" ? 1 : 0

  name = var.existing_system_topic_name
}

# Custom topic
data "aws_sns_topic" "custom" {
  count = var.existing_custom_topic_name != "" ? 1 : 0

  name = var.existing_custom_topic_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "events_topic_arn" {
  description = "ARN of the events topic (existing)"
  value       = var.existing_events_topic_name != "" ? data.aws_sns_topic.events[0].arn : null
}

output "events_topic_name" {
  description = "Name of the events topic (existing)"
  value       = var.existing_events_topic_name != "" ? data.aws_sns_topic.events[0].name : null
}

output "alerts_topic_arn" {
  description = "ARN of the alerts topic (existing)"
  value       = var.existing_alerts_topic_name != "" ? data.aws_sns_topic.alerts[0].arn : null
}

output "alerts_topic_name" {
  description = "Name of the alerts topic (existing)"
  value       = var.existing_alerts_topic_name != "" ? data.aws_sns_topic.alerts[0].name : null
}

output "system_topic_arn" {
  description = "ARN of the system topic (existing)"
  value       = var.existing_system_topic_name != "" ? data.aws_sns_topic.system[0].arn : null
}

output "system_topic_name" {
  description = "Name of the system topic (existing)"
  value       = var.existing_system_topic_name != "" ? data.aws_sns_topic.system[0].name : null
}

output "custom_topic_arn" {
  description = "ARN of the custom topic (existing)"
  value       = var.existing_custom_topic_name != "" ? data.aws_sns_topic.custom[0].arn : null
}

output "custom_topic_name" {
  description = "Name of the custom topic (existing)"
  value       = var.existing_custom_topic_name != "" ? data.aws_sns_topic.custom[0].name : null
}

# Summary output
output "sns_topics_summary" {
  description = "Summary of all existing SNS topics"
  value = {
    events_topic = var.existing_events_topic_name != "" ? {
      name = data.aws_sns_topic.events[0].name
      arn  = data.aws_sns_topic.events[0].arn
    } : "not provided"

    alerts_topic = var.existing_alerts_topic_name != "" ? {
      name = data.aws_sns_topic.alerts[0].name
      arn  = data.aws_sns_topic.alerts[0].arn
    } : "not provided"

    system_topic = var.existing_system_topic_name != "" ? {
      name = data.aws_sns_topic.system[0].name
      arn  = data.aws_sns_topic.system[0].arn
    } : "not provided"

    custom_topic = var.existing_custom_topic_name != "" ? {
      name = data.aws_sns_topic.custom[0].name
      arn  = data.aws_sns_topic.custom[0].arn
    } : "not provided"
  }
}
