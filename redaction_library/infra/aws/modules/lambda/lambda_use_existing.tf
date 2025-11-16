# ============================================================================
# USE EXISTING LAMBDA FUNCTIONS
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when you need to reference existing Lambda functions or layers
# created outside of this module. Common scenarios:
#
# 1. Shared Lambda Layers (created by Platform Team)
# 2. Utility functions shared across teams
# 3. Invoking another team's Lambda function
# 4. Referencing Lambda for event source mapping
#
# NOTE: This is LESS COMMON than other modules because Lambda functions
# usually contain team-specific application code, not shared infrastructure.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Function Information:
#    - Lambda function name or ARN
#    - Function runtime (Python, Node.js, etc.)
#    - Permissions: Can I invoke this function?
#
# 2. Lambda Layers (if using shared layers):
#    - Layer name
#    - Layer version ARN
#    - Compatible runtimes
#
# 3. Integration Details:
#    - Expected input format
#    - Expected output format
#    - Error handling behavior
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for function name/ARN or layer name
# 2. Use data sources below to fetch existing resources
# 3. Reference outputs in your configurations
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING LAMBDA FUNCTIONS
# ----------------------------------------------------------------------------

# Fetch Lambda function by name
data "aws_lambda_function" "by_name" {
  count = var.existing_function_name != "" ? 1 : 0

  function_name = var.existing_function_name
}

# Fetch Lambda function by ARN (qualified or unqualified)
data "aws_lambda_function" "by_arn" {
  count = var.existing_function_arn != "" ? 1 : 0

  function_name = var.existing_function_arn
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING IAM ROLE
# ----------------------------------------------------------------------------

data "aws_iam_role" "existing" {
  count = var.existing_iam_role_name != "" ? 1 : 0

  name = var.existing_iam_role_name
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING LAMBDA LAYERS
# ----------------------------------------------------------------------------

data "aws_lambda_layer_version" "existing" {
  count = var.existing_layer_name != "" ? 1 : 0

  layer_name = var.existing_layer_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "existing_function_arn" {
  description = "ARN of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].arn : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].arn : null
  )
}

output "existing_function_name" {
  description = "Name of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].function_name : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].function_name : null
  )
}

output "existing_function_qualified_arn" {
  description = "Qualified ARN of existing Lambda function (with version)"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].qualified_arn : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].qualified_arn : null
  )
}

output "existing_function_version" {
  description = "Latest version of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].version : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].version : null
  )
}

output "existing_function_invoke_arn" {
  description = "Invoke ARN of existing Lambda function (for API Gateway)"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].invoke_arn : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].invoke_arn : null
  )
}

output "existing_function_role_arn" {
  description = "IAM role ARN of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].role : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].role : null
  )
}

output "existing_function_runtime" {
  description = "Runtime of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].runtime : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].runtime : null
  )
}

output "existing_function_handler" {
  description = "Handler of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].handler : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].handler : null
  )
}

output "existing_function_memory_size" {
  description = "Memory size of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].memory_size : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].memory_size : null
  )
}

output "existing_function_timeout" {
  description = "Timeout of existing Lambda function"
  value = var.existing_function_name != "" ? data.aws_lambda_function.by_name[0].timeout : (
    var.existing_function_arn != "" ? data.aws_lambda_function.by_arn[0].timeout : null
  )
}

output "existing_iam_role_arn" {
  description = "ARN of existing IAM role"
  value       = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : null
}

output "existing_layer_arn" {
  description = "ARN of existing Lambda layer"
  value       = var.existing_layer_name != "" ? data.aws_lambda_layer_version.existing[0].arn : null
}

output "existing_layer_version" {
  description = "Version of existing Lambda layer"
  value       = var.existing_layer_name != "" ? data.aws_lambda_layer_version.existing[0].version : null
}

output "existing_resources_summary" {
  description = "Summary of existing Lambda resources"
  value = {
    function = var.existing_function_name != "" ? {
      name         = data.aws_lambda_function.by_name[0].function_name
      arn          = data.aws_lambda_function.by_name[0].arn
      runtime      = data.aws_lambda_function.by_name[0].runtime
      handler      = data.aws_lambda_function.by_name[0].handler
      memory_size  = data.aws_lambda_function.by_name[0].memory_size
      timeout      = data.aws_lambda_function.by_name[0].timeout
      role_arn     = data.aws_lambda_function.by_name[0].role
    } : (
      var.existing_function_arn != "" ? {
        name         = data.aws_lambda_function.by_arn[0].function_name
        arn          = data.aws_lambda_function.by_arn[0].arn
        runtime      = data.aws_lambda_function.by_arn[0].runtime
        handler      = data.aws_lambda_function.by_arn[0].handler
        memory_size  = data.aws_lambda_function.by_arn[0].memory_size
        timeout      = data.aws_lambda_function.by_arn[0].timeout
        role_arn     = data.aws_lambda_function.by_arn[0].role
      } : "not provided"
    )

    iam_role = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : "not provided"

    layer = var.existing_layer_name != "" ? {
      arn     = data.aws_lambda_layer_version.existing[0].arn
      version = data.aws_lambda_layer_version.existing[0].version
    } : "not provided"
  }
}
