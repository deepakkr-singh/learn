# ============================================================================
# CREATE API GATEWAY (REST API or HTTP API)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage API Gateway to expose
# Lambda functions or HTTP endpoints as REST/WebSocket APIs.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - API Gateway (REST or HTTP)
# - API Gateway Resources (URL paths)
# - API Gateway Methods (HTTP verbs)
# - Lambda Integration
# - API Gateway Deployment & Stage
# - Custom Domain (optional)
# - Usage Plan & API Keys (optional)
# - CloudWatch Logs (optional)
#
# COMMON USE CASES:
# -----------------
# 1. Serverless REST APIs (Lambda backend)
# 2. WebSocket APIs (real-time communication)
# 3. API versioning (v1, v2)
# 4. API key management for partners
# 5. Request/response transformation
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ----------------------------------------------------------------------------
# REST API
# ----------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "main" {
  count = var.api_type == "REST" ? 1 : 0

  name        = "${var.project_name}-${var.environment}-${var.api_name}"
  description = var.api_description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.api_name}"
      Environment = var.environment
    }
  )
}

# ----------------------------------------------------------------------------
# HTTP API (Simpler, Cheaper)
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "main" {
  count = var.api_type == "HTTP" ? 1 : 0

  name          = "${var.project_name}-${var.environment}-${var.api_name}"
  protocol_type = "HTTP"
  description   = var.api_description

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = var.cors_allow_methods
    allow_headers = var.cors_allow_headers
    max_age       = var.cors_max_age
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.api_name}"
      Environment = var.environment
    }
  )
}

# ----------------------------------------------------------------------------
# REST API - RESOURCES (URL Paths)
# ----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "main" {
  for_each = var.api_type == "REST" ? var.api_resources : {}

  rest_api_id = aws_api_gateway_rest_api.main[0].id
  parent_id   = aws_api_gateway_rest_api.main[0].root_resource_id
  path_part   = each.value.path_part
}

# ----------------------------------------------------------------------------
# REST API - METHODS (HTTP Verbs)
# ----------------------------------------------------------------------------

resource "aws_api_gateway_method" "main" {
  for_each = var.api_type == "REST" ? var.api_methods : {}

  rest_api_id   = aws_api_gateway_rest_api.main[0].id
  resource_id   = aws_api_gateway_resource.main[each.value.resource_key].id
  http_method   = each.value.http_method
  authorization = each.value.authorization

  authorizer_id = each.value.authorization == "CUSTOM" ? aws_api_gateway_authorizer.main[0].id : null

  request_parameters = each.value.request_parameters
}

# ----------------------------------------------------------------------------
# REST API - LAMBDA INTEGRATION
# ----------------------------------------------------------------------------

resource "aws_api_gateway_integration" "lambda" {
  for_each = var.api_type == "REST" ? var.api_methods : {}

  rest_api_id = aws_api_gateway_rest_api.main[0].id
  resource_id = aws_api_gateway_resource.main[each.value.resource_key].id
  http_method = aws_api_gateway_method.main[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_arn != "" ? "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${each.value.lambda_arn}/invocations" : null
}

# ----------------------------------------------------------------------------
# HTTP API - LAMBDA INTEGRATION
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = var.api_type == "HTTP" ? var.http_api_routes : {}

  api_id = aws_apigatewayv2_api.main[0].id

  integration_uri    = each.value.lambda_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "main" {
  for_each = var.api_type == "HTTP" ? var.http_api_routes : {}

  api_id = aws_apigatewayv2_api.main[0].id

  route_key = "${each.value.http_method} ${each.value.route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"

  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorization_type == "JWT" ? aws_apigatewayv2_authorizer.main[0].id : null
}

# ----------------------------------------------------------------------------
# LAMBDA PERMISSION (Allow API Gateway to invoke Lambda)
# ----------------------------------------------------------------------------

resource "aws_lambda_permission" "api_gateway" {
  for_each = var.api_type == "REST" ? var.api_methods : var.http_api_routes

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = var.api_type == "REST" ? "${aws_api_gateway_rest_api.main[0].execution_arn}/*/*" : "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

# ----------------------------------------------------------------------------
# REST API - AUTHORIZER (Lambda Authorizer)
# ----------------------------------------------------------------------------

resource "aws_api_gateway_authorizer" "main" {
  count = var.api_type == "REST" && var.create_authorizer ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.main[0].id
  authorizer_uri         = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.authorizer_lambda_arn}/invocations"
  authorizer_credentials = var.authorizer_role_arn
  identity_source        = var.authorizer_identity_source
  type                   = var.authorizer_type
}

# ----------------------------------------------------------------------------
# HTTP API - AUTHORIZER (JWT Authorizer)
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_authorizer" "main" {
  count = var.api_type == "HTTP" && var.create_authorizer ? 1 : 0

  api_id           = aws_apigatewayv2_api.main[0].id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-${var.environment}-authorizer"

  jwt_configuration {
    audience = var.jwt_audience
    issuer   = var.jwt_issuer
  }
}

# ----------------------------------------------------------------------------
# REST API - DEPLOYMENT
# ----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "main" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main[0].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.main,
      aws_api_gateway_method.main,
      aws_api_gateway_integration.lambda,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------
# REST API - STAGE
# ----------------------------------------------------------------------------

resource "aws_api_gateway_stage" "main" {
  count = var.api_type == "REST" ? 1 : 0

  deployment_id = aws_api_gateway_deployment.main[0].id
  rest_api_id   = aws_api_gateway_rest_api.main[0].id
  stage_name    = var.stage_name

  cache_cluster_enabled = var.enable_caching
  cache_cluster_size    = var.enable_caching ? var.cache_size : null

  xray_tracing_enabled = var.enable_xray_tracing

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.stage_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# HTTP API - STAGE
# ----------------------------------------------------------------------------

resource "aws_apigatewayv2_stage" "main" {
  count = var.api_type == "HTTP" ? 1 : 0

  api_id = aws_apigatewayv2_api.main[0].id
  name   = var.stage_name

  auto_deploy = true

  access_log_settings {
    destination_arn = var.enable_logging ? aws_cloudwatch_log_group.main[0].arn : null
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.stage_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP (API Gateway Logs)
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/apigateway/${var.project_name}-${var.environment}-${var.api_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "/aws/apigateway/${var.project_name}-${var.environment}-${var.api_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# USAGE PLAN (Rate Limiting)
# ----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan" "main" {
  count = var.api_type == "REST" && var.create_usage_plan ? 1 : 0

  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Usage plan for ${var.api_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main[0].id
    stage  = aws_api_gateway_stage.main[0].stage_name
  }

  quota_settings {
    limit  = var.usage_plan_quota_limit
    period = var.usage_plan_quota_period
  }

  throttle_settings {
    burst_limit = var.usage_plan_burst_limit
    rate_limit  = var.usage_plan_rate_limit
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-usage-plan"
    }
  )
}

# ----------------------------------------------------------------------------
# API KEY
# ----------------------------------------------------------------------------

resource "aws_api_gateway_api_key" "main" {
  for_each = var.api_type == "REST" && var.create_usage_plan ? var.api_keys : {}

  name        = each.key
  description = each.value.description
  enabled     = true

  tags = merge(
    var.common_tags,
    {
      Name = each.key
    }
  )
}

resource "aws_api_gateway_usage_plan_key" "main" {
  for_each = var.api_type == "REST" && var.create_usage_plan ? var.api_keys : {}

  key_id        = aws_api_gateway_api_key.main[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "api_id" {
  description = "ID of the API Gateway"
  value       = var.api_type == "REST" ? aws_api_gateway_rest_api.main[0].id : aws_apigatewayv2_api.main[0].id
}

output "api_endpoint" {
  description = "Invoke URL of the API"
  value = var.api_type == "REST" ? aws_api_gateway_stage.main[0].invoke_url : aws_apigatewayv2_stage.main[0].invoke_url
}

output "api_execution_arn" {
  description = "Execution ARN of the API"
  value       = var.api_type == "REST" ? aws_api_gateway_rest_api.main[0].execution_arn : aws_apigatewayv2_api.main[0].execution_arn
}

output "api_keys" {
  description = "API keys created"
  value       = var.api_type == "REST" && var.create_usage_plan ? { for k, v in aws_api_gateway_api_key.main : k => v.value } : {}
  sensitive   = true
}

output "api_summary" {
  description = "Summary of API Gateway configuration"
  value = {
    name         = var.api_name
    type         = var.api_type
    endpoint     = var.api_type == "REST" ? aws_api_gateway_stage.main[0].invoke_url : aws_apigatewayv2_stage.main[0].invoke_url
    stage        = var.stage_name
    caching      = var.enable_caching
    logging      = var.enable_logging
    usage_plan   = var.create_usage_plan
  }
}
