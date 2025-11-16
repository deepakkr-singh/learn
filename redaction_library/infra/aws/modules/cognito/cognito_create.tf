# ============================================================================
# CREATE COGNITO USER POOL
# ============================================================================

resource "aws_cognito_user_pool" "this" {
  count = var.create_user_pool ? 1 : 0

  name = "${var.project_name}-${var.environment}-users"

  # Password policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = var.password_require_lowercase
    require_uppercase                = var.password_require_uppercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration

  # Auto-verified attributes
  auto_verified_attributes = var.auto_verified_attributes

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-users"
      Environment = var.environment
    }
  )
}

# User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  count = var.create_user_pool ? 1 : 0

  name         = "${var.project_name}-${var.environment}-client"
  user_pool_id = aws_cognito_user_pool.this[0].id

  generate_secret                      = var.generate_client_secret
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = var.allowed_oauth_flows
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  supported_identity_providers         = var.supported_identity_providers
}

# Outputs
output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.create_user_pool ? aws_cognito_user_pool.this[0].id : null
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = var.create_user_pool ? aws_cognito_user_pool.this[0].arn : null
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = var.create_user_pool ? aws_cognito_user_pool.this[0].endpoint : null
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = var.create_user_pool ? aws_cognito_user_pool_client.this[0].id : null
}
