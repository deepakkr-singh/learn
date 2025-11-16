# ============================================================================
# USE EXISTING API GATEWAY
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when you need to reference existing API Gateway created by
# another team or for integration purposes.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. API Information:
#    - API Gateway ID
#    - API Gateway name
#    - API type (REST or HTTP)
#    - Stage name
#
# 2. Permissions:
#    - Can I invoke this API?
#    - Can I view API configuration?
#    - Do I need API key?
#
# 3. Integration Details:
#    - API endpoint URL
#    - Available routes/resources
#    - Authentication method
#    - Rate limits
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for API Gateway ID/name
# 2. Use data sources below to fetch existing API
# 3. Reference outputs in your configurations
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING REST API
# ----------------------------------------------------------------------------

data "aws_api_gateway_rest_api" "main" {
  count = var.existing_rest_api_name != "" ? 1 : 0

  name = var.existing_rest_api_name
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING HTTP API
# ----------------------------------------------------------------------------

data "aws_apigatewayv2_api" "main" {
  count = var.existing_http_api_id != "" ? 1 : 0

  api_id = var.existing_http_api_id
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING API KEY
# ----------------------------------------------------------------------------

data "aws_api_gateway_api_key" "main" {
  count = var.existing_api_key_id != "" ? 1 : 0

  id = var.existing_api_key_id
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "existing_rest_api_id" {
  description = "ID of existing REST API"
  value       = var.existing_rest_api_name != "" ? data.aws_api_gateway_rest_api.main[0].id : null
}

output "existing_rest_api_root_resource_id" {
  description = "Root resource ID of existing REST API"
  value       = var.existing_rest_api_name != "" ? data.aws_api_gateway_rest_api.main[0].root_resource_id : null
}

output "existing_rest_api_execution_arn" {
  description = "Execution ARN of existing REST API"
  value       = var.existing_rest_api_name != "" ? data.aws_api_gateway_rest_api.main[0].execution_arn : null
}

output "existing_http_api_id" {
  description = "ID of existing HTTP API"
  value       = var.existing_http_api_id != "" ? data.aws_apigatewayv2_api.main[0].id : null
}

output "existing_http_api_endpoint" {
  description = "Endpoint of existing HTTP API"
  value       = var.existing_http_api_id != "" ? data.aws_apigatewayv2_api.main[0].api_endpoint : null
}

output "existing_http_api_execution_arn" {
  description = "Execution ARN of existing HTTP API"
  value       = var.existing_http_api_id != "" ? data.aws_apigatewayv2_api.main[0].execution_arn : null
}

output "existing_api_key_value" {
  description = "Value of existing API key"
  value       = var.existing_api_key_id != "" ? data.aws_api_gateway_api_key.main[0].value : null
  sensitive   = true
}

output "existing_resources_summary" {
  description = "Summary of existing API Gateway resources"
  value = {
    rest_api = var.existing_rest_api_name != "" ? {
      id              = data.aws_api_gateway_rest_api.main[0].id
      name            = data.aws_api_gateway_rest_api.main[0].name
      root_resource_id = data.aws_api_gateway_rest_api.main[0].root_resource_id
      execution_arn   = data.aws_api_gateway_rest_api.main[0].execution_arn
    } : "not provided"

    http_api = var.existing_http_api_id != "" ? {
      id            = data.aws_apigatewayv2_api.main[0].id
      name          = data.aws_apigatewayv2_api.main[0].name
      endpoint      = data.aws_apigatewayv2_api.main[0].api_endpoint
      execution_arn = data.aws_apigatewayv2_api.main[0].execution_arn
    } : "not provided"

    api_key = var.existing_api_key_id != "" ? "API key found" : "not provided"
  }
}
