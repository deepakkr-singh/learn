# ============================================================================
# CREATE STEP FUNCTIONS STATE MACHINE
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage Step Functions workflows
# (state machines) to orchestrate AWS services.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - Step Functions State Machine
# - IAM Role for State Machine
# - CloudWatch Log Group (for execution logs)
# - CloudWatch Alarms (optional, for monitoring)
#
# COMMON USE CASES:
# -----------------
# 1. Order processing workflows
# 2. Data pipelines (ETL)
# 3. Approval workflows
# 4. Multi-step API orchestration
# 5. Batch processing jobs
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP (EXECUTION LOGS)
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/vendedlogs/states/${var.state_machine_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "/aws/vendedlogs/states/${var.state_machine_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# IAM ROLE FOR STATE MACHINE
# ----------------------------------------------------------------------------

resource "aws_iam_role" "state_machine" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-${var.state_machine_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.state_machine_name}-role"
    }
  )
}

# CloudWatch Logs permissions
resource "aws_iam_role_policy" "logs" {
  count = var.create_iam_role && var.enable_logging ? 1 : 0

  name = "cloudwatch-logs"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda invocation permissions
resource "aws_iam_role_policy" "lambda" {
  count = var.create_iam_role && length(var.lambda_functions) > 0 ? 1 : 0

  name = "lambda-invoke"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.lambda_functions
      }
    ]
  })
}

# SNS publish permissions
resource "aws_iam_role_policy" "sns" {
  count = var.create_iam_role && length(var.sns_topics) > 0 ? 1 : 0

  name = "sns-publish"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topics
      }
    ]
  })
}

# SQS send message permissions
resource "aws_iam_role_policy" "sqs" {
  count = var.create_iam_role && length(var.sqs_queues) > 0 ? 1 : 0

  name = "sqs-send"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queues
      }
    ]
  })
}

# DynamoDB permissions
resource "aws_iam_role_policy" "dynamodb" {
  count = var.create_iam_role && length(var.dynamodb_tables) > 0 ? 1 : 0

  name = "dynamodb-access"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_tables
      }
    ]
  })
}

# ECS run task permissions
resource "aws_iam_role_policy" "ecs" {
  count = var.create_iam_role && length(var.ecs_task_definitions) > 0 ? 1 : 0

  name = "ecs-run-task"
  role = aws_iam_role.state_machine[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]
        Resource = var.ecs_task_definitions
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
      }
    ]
  })
}

# Custom IAM policy
resource "aws_iam_role_policy" "custom" {
  count = var.create_iam_role && var.custom_iam_policy != "" ? 1 : 0

  name   = "custom-policy"
  role   = aws_iam_role.state_machine[0].id
  policy = var.custom_iam_policy
}

# ----------------------------------------------------------------------------
# STATE MACHINE
# ----------------------------------------------------------------------------

resource "aws_sfn_state_machine" "main" {
  name     = "${var.project_name}-${var.environment}-${var.state_machine_name}"
  role_arn = var.create_iam_role ? aws_iam_role.state_machine[0].arn : var.existing_role_arn
  type     = var.state_machine_type

  definition = var.state_machine_definition

  dynamic "logging_configuration" {
    for_each = var.enable_logging ? [1] : []
    content {
      log_destination        = "${aws_cloudwatch_log_group.main[0].arn}:*"
      include_execution_data = var.log_include_execution_data
      level                  = var.log_level
    }
  }

  dynamic "tracing_configuration" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.state_machine_name}"
      Environment = var.environment
    }
  )
}

# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS (MONITORING)
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "execution_failed" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.state_machine_name}-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Step Functions execution fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.main.arn
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.state_machine_name}-failed"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "execution_throttled" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.state_machine_name}-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Step Functions execution is throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.main.arn
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.state_machine_name}-throttled"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "execution_timeout" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.state_machine_name}-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Step Functions execution times out"
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.main.arn
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.state_machine_name}-timeout"
    }
  )
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "state_machine_arn" {
  description = "ARN of the state machine"
  value       = aws_sfn_state_machine.main.arn
}

output "state_machine_name" {
  description = "Name of the state machine"
  value       = aws_sfn_state_machine.main.name
}

output "state_machine_id" {
  description = "ID of the state machine"
  value       = aws_sfn_state_machine.main.id
}

output "state_machine_role_arn" {
  description = "ARN of the state machine IAM role"
  value       = var.create_iam_role ? aws_iam_role.state_machine[0].arn : var.existing_role_arn
}

output "log_group_name" {
  description = "Name of CloudWatch log group"
  value       = var.enable_logging ? aws_cloudwatch_log_group.main[0].name : null
}

output "state_machine_summary" {
  description = "Summary of state machine configuration"
  value = {
    name              = aws_sfn_state_machine.main.name
    arn               = aws_sfn_state_machine.main.arn
    type              = var.state_machine_type
    logging_enabled   = var.enable_logging
    xray_enabled      = var.enable_xray_tracing
    alarms_enabled    = var.create_alarms
  }
}
