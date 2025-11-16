# ============================================================================
# CREATE NEW SECRETS IN AWS SECRETS MANAGER
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage secrets for your application.
# You control what secrets exist and their values.
#
# WHEN NOT TO USE:
# ----------------
# If Security Team manages all secrets, use secrets_use_existing.tf
#
# WHAT THIS FILE CREATES:
# -----------------------
# Common secrets for a typical application:
# 1. Database credentials (username + password + host)
# 2. API keys (Stripe, SendGrid, Twilio, etc.)
# 3. JWT signing key
# 4. OAuth credentials
# 5. Custom application secrets
#
# IMPORTANT: Secret VALUES
# -------------------------
# Do NOT hardcode secret values in this file!
# Values come from variables (terraform.tfvars which is in .gitignore)
#
# ============================================================================

# ----------------------------------------------------------------------------
# PATTERN 1: DATABASE CREDENTIALS (JSON FORMAT)
# ----------------------------------------------------------------------------
# WHAT: Store all database connection details together
# WHY: Username, password, host always used together
# FORMAT: JSON (multiple values)

resource "aws_secretsmanager_secret" "database_credentials" {
  count = var.create_database_credentials ? 1 : 0

  name        = "${var.project_name}/${var.environment}/database/credentials"
  description = "Database connection credentials (username, password, host, port)"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-database-credentials-${var.environment}"
      Purpose = "Database Credentials"
      Format  = "JSON"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  count = var.create_database_credentials ? 1 : 0

  secret_id = aws_secretsmanager_secret.database_credentials[0].id

  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
    host     = var.database_host
    port     = var.database_port
    database = var.database_name
    engine   = var.database_engine  # postgresql, mysql, etc.
  })
}

# ----------------------------------------------------------------------------
# PATTERN 2: DATABASE PASSWORD ONLY (STRING FORMAT)
# ----------------------------------------------------------------------------
# WHAT: Store just the database password
# WHY: If other connection details are not secret (in env vars)
# FORMAT: String (single value)

resource "aws_secretsmanager_secret" "database_password" {
  count = var.create_database_password ? 1 : 0

  name        = "${var.project_name}/${var.environment}/database/password"
  description = "Database password"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-database-password-${var.environment}"
      Purpose = "Database Password"
      Format  = "String"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database_password" {
  count = var.create_database_password ? 1 : 0

  secret_id     = aws_secretsmanager_secret.database_password[0].id
  secret_string = var.database_password
}

# ----------------------------------------------------------------------------
# PATTERN 3: STRIPE API KEY
# ----------------------------------------------------------------------------
# WHAT: Stripe API secret key for payments
# WHY: Process credit card payments
# FORMAT: String

resource "aws_secretsmanager_secret" "stripe_api_key" {
  count = var.create_stripe_api_key ? 1 : 0

  name        = "${var.project_name}/${var.environment}/stripe/api-key"
  description = "Stripe API secret key"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-stripe-api-key-${var.environment}"
      Purpose = "Stripe Payments"
      Format  = "String"
    }
  )
}

resource "aws_secretsmanager_secret_version" "stripe_api_key" {
  count = var.create_stripe_api_key ? 1 : 0

  secret_id     = aws_secretsmanager_secret.stripe_api_key[0].id
  secret_string = var.stripe_api_key
}

# ----------------------------------------------------------------------------
# PATTERN 4: SENDGRID API KEY
# ----------------------------------------------------------------------------
# WHAT: SendGrid API key for sending emails
# WHY: Transactional emails (password reset, notifications)
# FORMAT: String

resource "aws_secretsmanager_secret" "sendgrid_api_key" {
  count = var.create_sendgrid_api_key ? 1 : 0

  name        = "${var.project_name}/${var.environment}/sendgrid/api-key"
  description = "SendGrid API key for sending emails"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-sendgrid-api-key-${var.environment}"
      Purpose = "Email Sending"
      Format  = "String"
    }
  )
}

resource "aws_secretsmanager_secret_version" "sendgrid_api_key" {
  count = var.create_sendgrid_api_key ? 1 : 0

  secret_id     = aws_secretsmanager_secret.sendgrid_api_key[0].id
  secret_string = var.sendgrid_api_key
}

# ----------------------------------------------------------------------------
# PATTERN 5: TWILIO CREDENTIALS (JSON FORMAT)
# ----------------------------------------------------------------------------
# WHAT: Twilio credentials for SMS
# WHY: Send SMS notifications, 2FA codes
# FORMAT: JSON (Account SID + Auth Token)

resource "aws_secretsmanager_secret" "twilio_credentials" {
  count = var.create_twilio_credentials ? 1 : 0

  name        = "${var.project_name}/${var.environment}/twilio/credentials"
  description = "Twilio Account SID and Auth Token"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-twilio-credentials-${var.environment}"
      Purpose = "SMS Sending"
      Format  = "JSON"
    }
  )
}

resource "aws_secretsmanager_secret_version" "twilio_credentials" {
  count = var.create_twilio_credentials ? 1 : 0

  secret_id = aws_secretsmanager_secret.twilio_credentials[0].id

  secret_string = jsonencode({
    account_sid = var.twilio_account_sid
    auth_token  = var.twilio_auth_token
  })
}

# ----------------------------------------------------------------------------
# PATTERN 6: JWT SIGNING KEY
# ----------------------------------------------------------------------------
# WHAT: Secret key for signing JWT tokens
# WHY: Authenticate API requests, user sessions
# FORMAT: String

resource "aws_secretsmanager_secret" "jwt_signing_key" {
  count = var.create_jwt_signing_key ? 1 : 0

  name        = "${var.project_name}/${var.environment}/jwt/signing-key"
  description = "Secret key for signing JWT tokens"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-jwt-signing-key-${var.environment}"
      Purpose = "JWT Token Signing"
      Format  = "String"
    }
  )
}

# Generate random JWT signing key if not provided
resource "random_password" "jwt_key" {
  count = var.create_jwt_signing_key && var.jwt_signing_key == "" ? 1 : 0

  length  = 64
  special = true
}

resource "aws_secretsmanager_secret_version" "jwt_signing_key" {
  count = var.create_jwt_signing_key ? 1 : 0

  secret_id = aws_secretsmanager_secret.jwt_signing_key[0].id

  # Use provided key or generated random key
  secret_string = var.jwt_signing_key != "" ? var.jwt_signing_key : random_password.jwt_key[0].result
}

# ----------------------------------------------------------------------------
# PATTERN 7: OAUTH CREDENTIALS (JSON FORMAT)
# ----------------------------------------------------------------------------
# WHAT: OAuth app credentials (Google, GitHub, etc.)
# WHY: Social login, OAuth integrations
# FORMAT: JSON (Client ID + Client Secret)

resource "aws_secretsmanager_secret" "oauth_credentials" {
  count = var.create_oauth_credentials ? 1 : 0

  name        = "${var.project_name}/${var.environment}/oauth/${var.oauth_provider}/credentials"
  description = "${var.oauth_provider} OAuth credentials"
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name     = "${var.project_name}-${var.oauth_provider}-oauth-${var.environment}"
      Purpose  = "OAuth Integration"
      Provider = var.oauth_provider
      Format   = "JSON"
    }
  )
}

resource "aws_secretsmanager_secret_version" "oauth_credentials" {
  count = var.create_oauth_credentials ? 1 : 0

  secret_id = aws_secretsmanager_secret.oauth_credentials[0].id

  secret_string = jsonencode({
    client_id     = var.oauth_client_id
    client_secret = var.oauth_client_secret
  })
}

# ----------------------------------------------------------------------------
# PATTERN 8: CUSTOM APPLICATION SECRET
# ----------------------------------------------------------------------------
# WHAT: Any custom secret your app needs
# WHY: Flexibility for app-specific secrets
# FORMAT: String or JSON (based on var.custom_secret_is_json)

resource "aws_secretsmanager_secret" "custom_secret" {
  count = var.create_custom_secret ? 1 : 0

  name        = "${var.project_name}/${var.environment}/${var.custom_secret_name}"
  description = var.custom_secret_description
  kms_key_id  = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-${var.custom_secret_name}-${var.environment}"
      Purpose = var.custom_secret_description
      Format  = var.custom_secret_is_json ? "JSON" : "String"
    }
  )
}

resource "aws_secretsmanager_secret_version" "custom_secret" {
  count = var.create_custom_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.custom_secret[0].id

  # If JSON, encode it; otherwise use as-is
  secret_string = var.custom_secret_is_json ? jsonencode(var.custom_secret_value) : var.custom_secret_value
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
# WHY: Your Lambda/EC2/Fargate needs these ARNs to read secrets

output "database_credentials_arn" {
  description = "ARN of database credentials secret"
  value       = var.create_database_credentials ? aws_secretsmanager_secret.database_credentials[0].arn : null
}

output "database_credentials_name" {
  description = "Name of database credentials secret"
  value       = var.create_database_credentials ? aws_secretsmanager_secret.database_credentials[0].name : null
}

output "database_password_arn" {
  description = "ARN of database password secret"
  value       = var.create_database_password ? aws_secretsmanager_secret.database_password[0].arn : null
}

output "database_password_name" {
  description = "Name of database password secret"
  value       = var.create_database_password ? aws_secretsmanager_secret.database_password[0].name : null
}

output "stripe_api_key_arn" {
  description = "ARN of Stripe API key secret"
  value       = var.create_stripe_api_key ? aws_secretsmanager_secret.stripe_api_key[0].arn : null
}

output "stripe_api_key_name" {
  description = "Name of Stripe API key secret"
  value       = var.create_stripe_api_key ? aws_secretsmanager_secret.stripe_api_key[0].name : null
}

output "sendgrid_api_key_arn" {
  description = "ARN of SendGrid API key secret"
  value       = var.create_sendgrid_api_key ? aws_secretsmanager_secret.sendgrid_api_key[0].arn : null
}

output "sendgrid_api_key_name" {
  description = "Name of SendGrid API key secret"
  value       = var.create_sendgrid_api_key ? aws_secretsmanager_secret.sendgrid_api_key[0].name : null
}

output "twilio_credentials_arn" {
  description = "ARN of Twilio credentials secret"
  value       = var.create_twilio_credentials ? aws_secretsmanager_secret.twilio_credentials[0].arn : null
}

output "twilio_credentials_name" {
  description = "Name of Twilio credentials secret"
  value       = var.create_twilio_credentials ? aws_secretsmanager_secret.twilio_credentials[0].name : null
}

output "jwt_signing_key_arn" {
  description = "ARN of JWT signing key secret"
  value       = var.create_jwt_signing_key ? aws_secretsmanager_secret.jwt_signing_key[0].arn : null
}

output "jwt_signing_key_name" {
  description = "Name of JWT signing key secret"
  value       = var.create_jwt_signing_key ? aws_secretsmanager_secret.jwt_signing_key[0].name : null
}

output "oauth_credentials_arn" {
  description = "ARN of OAuth credentials secret"
  value       = var.create_oauth_credentials ? aws_secretsmanager_secret.oauth_credentials[0].arn : null
}

output "oauth_credentials_name" {
  description = "Name of OAuth credentials secret"
  value       = var.create_oauth_credentials ? aws_secretsmanager_secret.oauth_credentials[0].name : null
}

output "custom_secret_arn" {
  description = "ARN of custom secret"
  value       = var.create_custom_secret ? aws_secretsmanager_secret.custom_secret[0].arn : null
}

output "custom_secret_name" {
  description = "Name of custom secret"
  value       = var.create_custom_secret ? aws_secretsmanager_secret.custom_secret[0].name : null
}

# Summary output
output "secrets_summary" {
  description = "Summary of all created secrets"
  value = {
    database_credentials = var.create_database_credentials ? {
      name = aws_secretsmanager_secret.database_credentials[0].name
      arn  = aws_secretsmanager_secret.database_credentials[0].arn
    } : "not created"

    database_password = var.create_database_password ? {
      name = aws_secretsmanager_secret.database_password[0].name
      arn  = aws_secretsmanager_secret.database_password[0].arn
    } : "not created"

    stripe_api_key = var.create_stripe_api_key ? {
      name = aws_secretsmanager_secret.stripe_api_key[0].name
      arn  = aws_secretsmanager_secret.stripe_api_key[0].arn
    } : "not created"

    sendgrid_api_key = var.create_sendgrid_api_key ? {
      name = aws_secretsmanager_secret.sendgrid_api_key[0].name
      arn  = aws_secretsmanager_secret.sendgrid_api_key[0].arn
    } : "not created"

    twilio_credentials = var.create_twilio_credentials ? {
      name = aws_secretsmanager_secret.twilio_credentials[0].name
      arn  = aws_secretsmanager_secret.twilio_credentials[0].arn
    } : "not created"

    jwt_signing_key = var.create_jwt_signing_key ? {
      name = aws_secretsmanager_secret.jwt_signing_key[0].name
      arn  = aws_secretsmanager_secret.jwt_signing_key[0].arn
    } : "not created"

    oauth_credentials = var.create_oauth_credentials ? {
      name = aws_secretsmanager_secret.oauth_credentials[0].name
      arn  = aws_secretsmanager_secret.oauth_credentials[0].arn
    } : "not created"

    custom_secret = var.create_custom_secret ? {
      name = aws_secretsmanager_secret.custom_secret[0].name
      arn  = aws_secretsmanager_secret.custom_secret[0].arn
    } : "not created"
  }
}

# Monthly cost estimate
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for Secrets Manager (storage only, excludes API calls)"
  value = format(
    "$%.2f/month for %d secrets ($0.40 per secret)",
    (
      (var.create_database_credentials ? 1 : 0) +
      (var.create_database_password ? 1 : 0) +
      (var.create_stripe_api_key ? 1 : 0) +
      (var.create_sendgrid_api_key ? 1 : 0) +
      (var.create_twilio_credentials ? 1 : 0) +
      (var.create_jwt_signing_key ? 1 : 0) +
      (var.create_oauth_credentials ? 1 : 0) +
      (var.create_custom_secret ? 1 : 0)
    ) * 0.40,
    (var.create_database_credentials ? 1 : 0) +
    (var.create_database_password ? 1 : 0) +
    (var.create_stripe_api_key ? 1 : 0) +
    (var.create_sendgrid_api_key ? 1 : 0) +
    (var.create_twilio_credentials ? 1 : 0) +
    (var.create_jwt_signing_key ? 1 : 0) +
    (var.create_oauth_credentials ? 1 : 0) +
    (var.create_custom_secret ? 1 : 0)
  )
}
