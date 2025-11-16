# ============================================================================
# CREATE SNS TOPICS
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage SNS topics for pub/sub messaging.
# You have full control over topic configuration, subscriptions, and delivery policies.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - SNS topic for publish/subscribe messaging
# - Subscriptions (Lambda, SQS, Email, SMS, HTTP, etc.)
# - Message filtering policies
# - Delivery retry policies
# - Encryption (optional with KMS)
#
# COMMON USE CASES:
# -----------------
# 1. Event notifications (order placed, user signup)
# 2. System alerts (errors, warnings, critical events)
# 3. Fan-out pattern (one message to many subscribers)
# 4. Webhook delivery (HTTP/HTTPS endpoints)
# 5. Mobile push notifications
#
# ============================================================================

# ----------------------------------------------------------------------------
# SNS TOPIC
# ----------------------------------------------------------------------------

resource "aws_sns_topic" "main" {
  count = var.create_topic ? 1 : 0

  name         = var.fifo_topic ? "${var.topic_name}.fifo" : var.topic_name
  display_name = var.display_name
  fifo_topic   = var.fifo_topic

  # Content-based deduplication (FIFO only)
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  # Encryption
  kms_master_key_id = var.kms_key_id

  # Delivery policy (retry configuration)
  delivery_policy = var.delivery_policy != "" ? var.delivery_policy : null

  # HTTP delivery settings
  http_success_feedback_role_arn    = var.enable_delivery_status_logging ? var.http_success_feedback_role_arn : null
  http_success_feedback_sample_rate = var.enable_delivery_status_logging ? var.http_success_feedback_sample_rate : null
  http_failure_feedback_role_arn    = var.enable_delivery_status_logging ? var.http_failure_feedback_role_arn : null

  # Lambda delivery settings
  lambda_success_feedback_role_arn    = var.enable_delivery_status_logging ? var.lambda_success_feedback_role_arn : null
  lambda_success_feedback_sample_rate = var.enable_delivery_status_logging ? var.lambda_success_feedback_sample_rate : null
  lambda_failure_feedback_role_arn    = var.enable_delivery_status_logging ? var.lambda_failure_feedback_role_arn : null

  # SQS delivery settings
  sqs_success_feedback_role_arn    = var.enable_delivery_status_logging ? var.sqs_success_feedback_role_arn : null
  sqs_success_feedback_sample_rate = var.enable_delivery_status_logging ? var.sqs_success_feedback_sample_rate : null
  sqs_failure_feedback_role_arn    = var.enable_delivery_status_logging ? var.sqs_failure_feedback_role_arn : null

  # Signature version (for HTTP/HTTPS endpoints)
  signature_version = var.signature_version

  # Tracing (X-Ray)
  tracing_config = var.enable_tracing ? "Active" : "PassThrough"

  tags = merge(
    var.common_tags,
    {
      Name        = var.topic_name
      Environment = var.environment
      Purpose     = var.topic_purpose
    }
  )
}

# ----------------------------------------------------------------------------
# TOPIC POLICY (Optional)
# ----------------------------------------------------------------------------
# Custom access policies for cross-account or service access

resource "aws_sns_topic_policy" "main" {
  count = var.create_topic && var.topic_policy != "" ? 1 : 0

  arn    = aws_sns_topic.main[0].arn
  policy = var.topic_policy
}

# ----------------------------------------------------------------------------
# DATA PROTECTION POLICY (Optional)
# ----------------------------------------------------------------------------
# Scan for PII/sensitive data in messages

resource "aws_sns_topic_data_protection_policy" "main" {
  count = var.create_topic && var.data_protection_policy != "" ? 1 : 0

  arn    = aws_sns_topic.main[0].arn
  policy = var.data_protection_policy
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "topic_id" {
  description = "ARN of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.main[0].id : null
}

output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.main[0].arn : null
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.main[0].name : null
}

output "topic_owner" {
  description = "AWS account ID of the topic owner"
  value       = var.create_topic ? aws_sns_topic.main[0].owner : null
}

# Summary output
output "topic_summary" {
  description = "Summary of created SNS topic"
  value = var.create_topic ? {
    name      = aws_sns_topic.main[0].name
    arn       = aws_sns_topic.main[0].arn
    fifo      = var.fifo_topic
    encrypted = var.kms_key_id != "" ? "KMS" : "No"
    purpose   = var.topic_purpose
  } : "not created"
}
