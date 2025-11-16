# ============================================================================
# USE EXISTING SQS QUEUES (CREATED BY PLATFORM/APP TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Platform/App Team has already created SQS queues.
# You just need to reference the existing queues for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new SQS queues, use sqs_queues_create.tf instead.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Queue Names or URLs:
#    - Main processing queue name
#    - Dead Letter Queue name (if exists)
#    - FIFO queue name (if using FIFO)
#
# 2. Confirm permissions:
#    - Does my Lambda/EC2 role have sqs:SendMessage permission?
#    - Does my role have sqs:ReceiveMessage permission?
#    - Does my role have sqs:DeleteMessage permission?
#    - Is the queue encrypted? If yes, do I have KMS key access?
#
# 3. Queue configuration details:
#    - Visibility timeout setting
#    - Message retention period
#    - Is it a FIFO queue?
#    - Max receive count (for DLQ)
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for queue names (use email template in README.md)
# 2. Fill in the queue names in variables.tf or terraform.tfvars
# 3. Reference these queues in your Lambda/application code
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING SQS QUEUES
# ----------------------------------------------------------------------------

# Main processing queue
data "aws_sqs_queue" "main" {
  count = var.existing_queue_name != "" ? 1 : 0

  name = var.existing_queue_name
}

# Dead Letter Queue
data "aws_sqs_queue" "dlq" {
  count = var.existing_dlq_name != "" ? 1 : 0

  name = var.existing_dlq_name
}

# FIFO Queue
data "aws_sqs_queue" "fifo" {
  count = var.existing_fifo_queue_name != "" ? 1 : 0

  name = var.existing_fifo_queue_name
}

# Custom queue (for additional queues)
data "aws_sqs_queue" "custom" {
  count = var.existing_custom_queue_name != "" ? 1 : 0

  name = var.existing_custom_queue_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "main_queue_id" {
  description = "URL of the main queue (existing)"
  value       = var.existing_queue_name != "" ? data.aws_sqs_queue.main[0].id : null
}

output "main_queue_arn" {
  description = "ARN of the main queue (existing)"
  value       = var.existing_queue_name != "" ? data.aws_sqs_queue.main[0].arn : null
}

output "main_queue_url" {
  description = "URL of the main queue (existing)"
  value       = var.existing_queue_name != "" ? data.aws_sqs_queue.main[0].url : null
}

output "dlq_id" {
  description = "URL of the DLQ (existing)"
  value       = var.existing_dlq_name != "" ? data.aws_sqs_queue.dlq[0].id : null
}

output "dlq_arn" {
  description = "ARN of the DLQ (existing)"
  value       = var.existing_dlq_name != "" ? data.aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL of the DLQ (existing)"
  value       = var.existing_dlq_name != "" ? data.aws_sqs_queue.dlq[0].url : null
}

output "fifo_queue_id" {
  description = "URL of the FIFO queue (existing)"
  value       = var.existing_fifo_queue_name != "" ? data.aws_sqs_queue.fifo[0].id : null
}

output "fifo_queue_arn" {
  description = "ARN of the FIFO queue (existing)"
  value       = var.existing_fifo_queue_name != "" ? data.aws_sqs_queue.fifo[0].arn : null
}

output "fifo_queue_url" {
  description = "URL of the FIFO queue (existing)"
  value       = var.existing_fifo_queue_name != "" ? data.aws_sqs_queue.fifo[0].url : null
}

output "custom_queue_id" {
  description = "URL of the custom queue (existing)"
  value       = var.existing_custom_queue_name != "" ? data.aws_sqs_queue.custom[0].id : null
}

output "custom_queue_arn" {
  description = "ARN of the custom queue (existing)"
  value       = var.existing_custom_queue_name != "" ? data.aws_sqs_queue.custom[0].arn : null
}

output "custom_queue_url" {
  description = "URL of the custom queue (existing)"
  value       = var.existing_custom_queue_name != "" ? data.aws_sqs_queue.custom[0].url : null
}

# Summary output
output "sqs_queues_summary" {
  description = "Summary of all existing SQS queues"
  value = {
    main_queue = var.existing_queue_name != "" ? {
      name = data.aws_sqs_queue.main[0].name
      url  = data.aws_sqs_queue.main[0].url
      arn  = data.aws_sqs_queue.main[0].arn
    } : "not provided"

    dlq = var.existing_dlq_name != "" ? {
      name = data.aws_sqs_queue.dlq[0].name
      url  = data.aws_sqs_queue.dlq[0].url
      arn  = data.aws_sqs_queue.dlq[0].arn
    } : "not provided"

    fifo_queue = var.existing_fifo_queue_name != "" ? {
      name = data.aws_sqs_queue.fifo[0].name
      url  = data.aws_sqs_queue.fifo[0].url
      arn  = data.aws_sqs_queue.fifo[0].arn
    } : "not provided"

    custom_queue = var.existing_custom_queue_name != "" ? {
      name = data.aws_sqs_queue.custom[0].name
      url  = data.aws_sqs_queue.custom[0].url
      arn  = data.aws_sqs_queue.custom[0].arn
    } : "not provided"
  }
}
