# ============================================================================
# CREATE LAMBDA FUNCTIONS
# ============================================================================
#
# COMMON LAMBDA PATTERNS:
# 1. API handler (with API Gateway)
# 2. S3 event processor
# 3. Scheduled job (EventBridge/CloudWatch Events)
# 4. SQS queue processor
#
# ============================================================================

# Basic Lambda function
resource "aws_lambda_function" "main" {
  filename      = var.lambda_zip_file
  function_name = "${var.project_name}-${var.function_name}-${var.environment}"
  role          = var.lambda_execution_role_arn
  handler       = var.handler
  runtime       = var.runtime

  source_code_hash = filebase64sha256(var.lambda_zip_file)

  timeout     = var.timeout
  memory_size = var.memory_size

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration (if Lambda needs to access VPC resources)
  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != [] ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.function_name}-${var.environment}"
      Environment = var.environment
    }
  )
}

# CloudWatch Log Group (for Lambda logs)
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "function_arn" {
  description = "ARN of Lambda function"
  value       = aws_lambda_function.main.arn
}

output "function_name" {
  description = "Name of Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "invoke_arn" {
  description = "Invoke ARN (for API Gateway integration)"
  value       = aws_lambda_function.main.invoke_arn
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda.name
}
