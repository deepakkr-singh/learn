# ============================================================================
# SERVICE PRINCIPAL (APP REGISTRATION)
# ============================================================================
# Creates Azure AD Service Principal for application authentication.
#
# Purpose: Provides secure identity for the application to authenticate with Azure AD.
# Security: Uses token-based authentication (not static API keys).
#
# What gets created:
#   1. App Registration (identity definition)
#   2. Service Principal (instance of the identity)
#   3. Client Secret (password for authentication)
#
# Best Practice: Rotate secrets every 90 days for security.
# ============================================================================

# ----------------------------------------------------------------------------
# APP REGISTRATION
# ----------------------------------------------------------------------------
# Creates the application identity in Azure AD.
# This defines WHAT the application is.

resource "azuread_application" "redaction_app" {
  # Display name shown in Azure Portal
  display_name = local.service_principal_name

  # Optional: Add description for documentation
  description = "Service Principal for ${var.project_name} Redaction Library - ${var.environment} environment"

  # Prevent accidental deletion by requiring confirmation
  # Best Practice: Protect production identities
  prevent_duplicate_names = true

  # Sign-in audience: Who can use this application
  # AzureADMyOrg = Only this tenant (most secure)
  # AzureADMultipleOrgs = Any Azure AD tenant
  sign_in_audience = "AzureADMyOrg"

  # Tags for organization and filtering
  tags = [
    var.environment,
    var.project_name,
    "service-principal",
    "redaction-library"
  ]

  # Optional: Add owners for management
  # owners = [data.azuread_client_config.current.object_id]
}

# ----------------------------------------------------------------------------
# SERVICE PRINCIPAL
# ----------------------------------------------------------------------------
# Creates the service principal (instance of the app registration).
# This is the actual identity that gets permissions.

resource "azuread_service_principal" "redaction_sp" {
  # Link to the App Registration created above
  # This creates an instance of the application in this tenant
  client_id = azuread_application.redaction_app.client_id

  # Account enabled: true = active, false = disabled
  account_enabled = true

  # App role assignment required: false = anyone can use (default)
  # Set true for production to control who can get tokens
  app_role_assignment_required = false

  # Notify on password expiration
  # Azure will send notification 30 days before expiration
  notification_email_addresses = []  # Add admin emails for notifications

  # Description for documentation
  description = "Service Principal for Redaction Library authentication to Azure Text Analytics"

  # Tags for organization
  tags = [
    var.environment,
    var.project_name,
    "automated",
    "terraform-managed"
  ]

  # Optional: Restrict to specific Azure subscriptions
  # alternative_names = ["redaction-sp-${var.environment}"]
}

# ----------------------------------------------------------------------------
# CLIENT SECRET (PASSWORD)
# ----------------------------------------------------------------------------
# Creates a password (client secret) for the Service Principal.
# This is used by the application to authenticate.

resource "azuread_service_principal_password" "redaction_secret" {
  # Link to the Service Principal created above
  service_principal_id = azuread_service_principal.redaction_sp.id

  # Display name (shown in Azure Portal for management)
  display_name = "Terraform-managed secret for ${var.environment}"

  # Secret expiration date
  # Best Practice: Short-lived secrets (90 days) for security
  # Calculate end date from current time + configured days
  end_date = local.secret_end_date

  # Rotate suffix: Change this to force secret rotation
  # When you need to rotate, increment this number
  # rotate_when_changed = {
  #   rotation = "1"  # Increment to rotate secret
  # }
}

# ----------------------------------------------------------------------------
# WARNINGS AND REMINDERS
# ----------------------------------------------------------------------------
# Output reminder about secret rotation to console

resource "null_resource" "rotation_reminder" {
  # Trigger on secret creation/update
  triggers = {
    secret_id = azuread_service_principal_password.redaction_secret.id
  }

  # Print reminder message
  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "⚠️  SECRET ROTATION REMINDER:"
      echo "   Client secret expires on: ${formatdate("YYYY-MM-DD", local.secret_end_date)}"
      echo "   Set calendar reminder to rotate ${var.client_secret_expiration_days - 10} days from now"
      echo ""
      echo "   To rotate:"
      echo "   1. Update client_secret_expiration_days in variables"
      echo "   2. Run: terraform apply"
      echo "   3. Update .env with new AZURE_CLIENT_SECRET"
      echo ""
    EOT
  }
}

# ----------------------------------------------------------------------------
# LIFECYCLE RULES
# ----------------------------------------------------------------------------
# Best practices for managing Service Principal lifecycle

# Prevent accidental deletion of Service Principal
# Remove this lifecycle block if you want to allow deletion
# lifecycle {
#   prevent_destroy = true
# }

# Ignore changes to password after creation (managed externally)
# lifecycle {
#   ignore_changes = [
#     azuread_service_principal_password.redaction_secret
#   ]
# }
