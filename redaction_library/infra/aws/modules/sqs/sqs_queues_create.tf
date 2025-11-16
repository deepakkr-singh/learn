# ============================================================================
# CREATE SQS QUEUES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage SQS queues for your application.
# You have full control over queue configuration, retry policies, and DLQ setup.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - Standard or FIFO SQS queue
# - Dead Letter Queue (DLQ) for failed messages
# - Encryption (optional with KMS)
# - Long polling (recommended)
# - CloudWatch alarms for monitoring
#
# COMMON USE CASES:
# -----------------
# 1. Asynchronous task processing (file uploads, image processing)
# 2. Load leveling (buffer traffic spikes)
# 3. Event-driven architecture (order processing, notifications)
# 4. Decoupling microservices
# 5. Background job processing
#
# ============================================================================

# ----------------------------------------------------------------------------
# MAIN SQS QUEUE
# ----------------------------------------------------------------------------

resource "aws_sqs_queue" "main" {
  count = var.create_queue ? 1 : 0

  name                        = var.fifo_queue ? "${var.queue_name}.fifo" : var.queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  # Visibility timeout (how long message is invisible after being picked up)
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Message retention (how long messages stay in queue)
  message_retention_seconds = var.message_retention_seconds

  # Receive wait time (enable long polling to save costs)
  receive_wait_time_seconds = var.receive_wait_time_seconds

  # Delay (delay all messages by X seconds)
  delay_seconds = var.delay_seconds

  # Max message size
  max_message_size = var.max_message_size

  # Dead Letter Queue configuration
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  # Encryption
  kms_master_key_id                 = var.kms_key_id
  kms_data_key_reuse_period_seconds = var.kms_key_id != "" ? var.kms_data_key_reuse_period_seconds : null

  # FIFO throughput (only for FIFO queues)
  deduplication_scope   = var.fifo_queue ? var.deduplication_scope : null
  fifo_throughput_limit = var.fifo_queue ? var.fifo_throughput_limit : null

  tags = merge(
    var.common_tags,
    {
      Name        = var.queue_name
      Environment = var.environment
      Purpose     = var.queue_purpose
    }
  )
}

# ----------------------------------------------------------------------------
# DEAD LETTER QUEUE (DLQ)
# ----------------------------------------------------------------------------
# Captures messages that fail processing after max retries

resource "aws_sqs_queue" "dlq" {
  count = var.create_queue && var.create_dlq ? 1 : 0

  name       = var.fifo_queue ? "${var.queue_name}-dlq.fifo" : "${var.queue_name}-dlq"
  fifo_queue = var.fifo_queue

  # Keep failed messages longer for investigation
  message_retention_seconds = var.dlq_message_retention_seconds

  # DLQ doesn't need a DLQ itself!
  # (Messages here are already failed, inspect manually)

  # Same encryption as main queue
  kms_master_key_id                 = var.kms_key_id
  kms_data_key_reuse_period_seconds = var.kms_key_id != "" ? var.kms_data_key_reuse_period_seconds : null

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.queue_name}-dlq"
      Environment = var.environment
      Purpose     = "Dead Letter Queue for ${var.queue_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# QUEUE POLICY (Optional)
# ----------------------------------------------------------------------------
# Custom access policies for cross-account or service access

resource "aws_sqs_queue_policy" "main" {
  count = var.create_queue && var.queue_policy != "" ? 1 : 0

  queue_url = aws_sqs_queue.main[0].id
  policy    = var.queue_policy
}

# ----------------------------------------------------------------------------
# REDRIVE ALLOW POLICY (Optional)
# ----------------------------------------------------------------------------
# Allow messages to be moved back from DLQ to main queue

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.create_queue && var.create_dlq && var.enable_dlq_redrive ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main[0].arn]
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "queue_id" {
  description = "URL of the SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].id : null
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].arn : null
}

output "queue_name" {
  description = "Name of the SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].name : null
}

output "dlq_id" {
  description = "URL of the Dead Letter Queue"
  value       = var.create_queue && var.create_dlq ? aws_sqs_queue.dlq[0].id : null
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = var.create_queue && var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_name" {
  description = "Name of the Dead Letter Queue"
  value       = var.create_queue && var.create_dlq ? aws_sqs_queue.dlq[0].name : null
}

# Summary output
output "queue_summary" {
  description = "Summary of created SQS queue"
  value = var.create_queue ? {
    name                   = aws_sqs_queue.main[0].name
    url                    = aws_sqs_queue.main[0].id
    arn                    = aws_sqs_queue.main[0].arn
    fifo                   = var.fifo_queue
    encrypted              = var.kms_key_id != "" ? "KMS" : "No"
    visibility_timeout     = var.visibility_timeout_seconds
    message_retention_days = var.message_retention_seconds / 86400
    dlq_enabled            = var.create_dlq
    max_retries            = var.max_receive_count
  } : "not created"
}
