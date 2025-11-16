# ============================================================================
# USE EXISTING SECRETS (CREATED BY SECURITY TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when Security Team has already created secrets.
# You just need to reference existing secrets for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new secrets, use secrets_create.tf instead.
#
# WHAT YOU NEED FROM SECURITY TEAM:
# ---------------------------------
# Secret ARNs or names for:
# - Database credentials
# - API keys (Stripe, SendGrid, Twilio, etc.)
# - JWT signing key
# - OAuth credentials
# - Any other application secrets
#
# HOW TO USE:
# -----------
# 1. Ask Security Team for secret names or ARNs
# 2. Fill in the values in terraform.tfvars
# 3. Reference these secrets in your Lambda/EC2/Fargate resources
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING SECRETS
# ----------------------------------------------------------------------------

# Database Credentials
data "aws_secretsmanager_secret" "database_credentials" {
  count = var.existing_database_credentials_name != "" ? 1 : 0

  name = var.existing_database_credentials_name
}

# Database Password
data "aws_secretsmanager_secret" "database_password" {
  count = var.existing_database_password_name != "" ? 1 : 0

  name = var.existing_database_password_name
}

# Stripe API Key
data "aws_secretsmanager_secret" "stripe_api_key" {
  count = var.existing_stripe_api_key_name != "" ? 1 : 0

  name = var.existing_stripe_api_key_name
}

# SendGrid API Key
data "aws_secretsmanager_secret" "sendgrid_api_key" {
  count = var.existing_sendgrid_api_key_name != "" ? 1 : 0

  name = var.existing_sendgrid_api_key_name
}

# Twilio Credentials
data "aws_secretsmanager_secret" "twilio_credentials" {
  count = var.existing_twilio_credentials_name != "" ? 1 : 0

  name = var.existing_twilio_credentials_name
}

# JWT Signing Key
data "aws_secretsmanager_secret" "jwt_signing_key" {
  count = var.existing_jwt_signing_key_name != "" ? 1 : 0

  name = var.existing_jwt_signing_key_name
}

# OAuth Credentials
data "aws_secretsmanager_secret" "oauth_credentials" {
  count = var.existing_oauth_credentials_name != "" ? 1 : 0

  name = var.existing_oauth_credentials_name
}

# Custom Secret
data "aws_secretsmanager_secret" "custom_secret" {
  count = var.existing_custom_secret_name != "" ? 1 : 0

  name = var.existing_custom_secret_name
}

# ----------------------------------------------------------------------------
# OUTPUTS - SAME AS secrets_create.tf
# ----------------------------------------------------------------------------

output "database_credentials_arn" {
  description = "ARN of database credentials secret (existing)"
  value       = var.existing_database_credentials_name != "" ? data.aws_secretsmanager_secret.database_credentials[0].arn : null
}

output "database_credentials_name" {
  description = "Name of database credentials secret (existing)"
  value       = var.existing_database_credentials_name != "" ? data.aws_secretsmanager_secret.database_credentials[0].name : null
}

output "database_password_arn" {
  description = "ARN of database password secret (existing)"
  value       = var.existing_database_password_name != "" ? data.aws_secretsmanager_secret.database_password[0].arn : null
}

output "database_password_name" {
  description = "Name of database password secret (existing)"
  value       = var.existing_database_password_name != "" ? data.aws_secretsmanager_secret.database_password[0].name : null
}

output "stripe_api_key_arn" {
  description = "ARN of Stripe API key secret (existing)"
  value       = var.existing_stripe_api_key_name != "" ? data.aws_secretsmanager_secret.stripe_api_key[0].arn : null
}

output "stripe_api_key_name" {
  description = "Name of Stripe API key secret (existing)"
  value       = var.existing_stripe_api_key_name != "" ? data.aws_secretsmanager_secret.stripe_api_key[0].name : null
}

output "sendgrid_api_key_arn" {
  description = "ARN of SendGrid API key secret (existing)"
  value       = var.existing_sendgrid_api_key_name != "" ? data.aws_secretsmanager_secret.sendgrid_api_key[0].arn : null
}

output "sendgrid_api_key_name" {
  description = "Name of SendGrid API key secret (existing)"
  value       = var.existing_sendgrid_api_key_name != "" ? data.aws_secretsmanager_secret.sendgrid_api_key[0].name : null
}

output "twilio_credentials_arn" {
  description = "ARN of Twilio credentials secret (existing)"
  value       = var.existing_twilio_credentials_name != "" ? data.aws_secretsmanager_secret.twilio_credentials[0].arn : null
}

output "twilio_credentials_name" {
  description = "Name of Twilio credentials secret (existing)"
  value       = var.existing_twilio_credentials_name != "" ? data.aws_secretsmanager_secret.twilio_credentials[0].name : null
}

output "jwt_signing_key_arn" {
  description = "ARN of JWT signing key secret (existing)"
  value       = var.existing_jwt_signing_key_name != "" ? data.aws_secretsmanager_secret.jwt_signing_key[0].arn : null
}

output "jwt_signing_key_name" {
  description = "Name of JWT signing key secret (existing)"
  value       = var.existing_jwt_signing_key_name != "" ? data.aws_secretsmanager_secret.jwt_signing_key[0].name : null
}

output "oauth_credentials_arn" {
  description = "ARN of OAuth credentials secret (existing)"
  value       = var.existing_oauth_credentials_name != "" ? data.aws_secretsmanager_secret.oauth_credentials[0].arn : null
}

output "oauth_credentials_name" {
  description = "Name of OAuth credentials secret (existing)"
  value       = var.existing_oauth_credentials_name != "" ? data.aws_secretsmanager_secret.oauth_credentials[0].name : null
}

output "custom_secret_arn" {
  description = "ARN of custom secret (existing)"
  value       = var.existing_custom_secret_name != "" ? data.aws_secretsmanager_secret.custom_secret[0].arn : null
}

output "custom_secret_name" {
  description = "Name of custom secret (existing)"
  value       = var.existing_custom_secret_name != "" ? data.aws_secretsmanager_secret.custom_secret[0].name : null
}

# Summary output
output "secrets_summary" {
  description = "Summary of all existing secrets"
  value = {
    database_credentials = var.existing_database_credentials_name != "" ? {
      name = data.aws_secretsmanager_secret.database_credentials[0].name
      arn  = data.aws_secretsmanager_secret.database_credentials[0].arn
    } : "not provided"

    database_password = var.existing_database_password_name != "" ? {
      name = data.aws_secretsmanager_secret.database_password[0].name
      arn  = data.aws_secretsmanager_secret.database_password[0].arn
    } : "not provided"

    stripe_api_key = var.existing_stripe_api_key_name != "" ? {
      name = data.aws_secretsmanager_secret.stripe_api_key[0].name
      arn  = data.aws_secretsmanager_secret.stripe_api_key[0].arn
    } : "not provided"

    sendgrid_api_key = var.existing_sendgrid_api_key_name != "" ? {
      name = data.aws_secretsmanager_secret.sendgrid_api_key[0].name
      arn  = data.aws_secretsmanager_secret.sendgrid_api_key[0].arn
    } : "not provided"

    twilio_credentials = var.existing_twilio_credentials_name != "" ? {
      name = data.aws_secretsmanager_secret.twilio_credentials[0].name
      arn  = data.aws_secretsmanager_secret.twilio_credentials[0].arn
    } : "not provided"

    jwt_signing_key = var.existing_jwt_signing_key_name != "" ? {
      name = data.aws_secretsmanager_secret.jwt_signing_key[0].name
      arn  = data.aws_secretsmanager_secret.jwt_signing_key[0].arn
    } : "not provided"

    oauth_credentials = var.existing_oauth_credentials_name != "" ? {
      name = data.aws_secretsmanager_secret.oauth_credentials[0].name
      arn  = data.aws_secretsmanager_secret.oauth_credentials[0].arn
    } : "not provided"

    custom_secret = var.existing_custom_secret_name != "" ? {
      name = data.aws_secretsmanager_secret.custom_secret[0].name
      arn  = data.aws_secretsmanager_secret.custom_secret[0].arn
    } : "not provided"
  }
}

# ----------------------------------------------------------------------------
# HOW TO FIND SECRET NAMES
# ----------------------------------------------------------------------------
# If Security Team only gave you descriptions, find names using AWS CLI:
/*

# List all secrets
aws secretsmanager list-secrets

# Find specific secret by name pattern
aws secretsmanager list-secrets | grep "database"

# Get secret details
aws secretsmanager describe-secret --secret-id "production/database/password"

*/
