# ============================================================================
# KEY VAULT SECRETS
# ============================================================================
# Stores Terraform outputs as Key Vault secrets.
#
# Purpose: Automatically store sensitive credentials in Key Vault (not .env files).
# Security: Secrets encrypted at rest, accessed via RBAC, rotatable.
#
# What gets created:
#   1. azure-client-id (Service Principal client ID)
#   2. azure-client-secret (Service Principal password)
#   3. azure-tenant-id (Azure AD tenant ID)
#   4. azure-text-analytics-endpoint (Text Analytics API endpoint)
#
# Best Practice: Application reads secrets from Key Vault at runtime.
# ============================================================================

# ----------------------------------------------------------------------------
# WAIT FOR RBAC PROPAGATION
# ----------------------------------------------------------------------------
# Azure RBAC assignments can take up to 5 minutes to propagate.
# This resource waits before creating secrets to avoid permission errors.

resource "time_sleep" "wait_for_rbac_propagation" {
  # Wait 30 seconds for RBAC to propagate
  create_duration = "30s"

  # Only wait after RBAC assignments are created
  depends_on = [
    azurerm_role_assignment.current_user_to_key_vault_admin,
    azurerm_role_assignment.sp_to_key_vault_secrets_user
  ]
}

# ----------------------------------------------------------------------------
# SECRET: AZURE_CLIENT_ID
# ----------------------------------------------------------------------------
# Service Principal Application (Client) ID.
# This is NOT secret (like a username), but stored in Key Vault for convenience.

resource "azurerm_key_vault_secret" "azure_client_id" {
  # Secret name in Key Vault
  # Use hyphens (not underscores) as per Azure naming conventions
  name = "azure-client-id"

  # Secret value: Application ID from Service Principal
  value = azuread_application.redaction_app.client_id

  # Key Vault where secret is stored
  key_vault_id = azurerm_key_vault.redaction_kv.id

  # Content type (optional metadata)
  content_type = "text/plain"

  # Expiration date (optional)
  # Uncomment to set expiration
  # expiration_date = timeadd(timestamp(), "8760h")  # 1 year

  # Tags for organization
  tags = merge(
    local.common_tags,
    {
      SecretType  = "Credential"
      Purpose     = "Service Principal Client ID"
      Sensitivity = "Low"  # Client ID is not secret
    }
  )

  # Dependencies
  depends_on = [
    time_sleep.wait_for_rbac_propagation
  ]
}

# ----------------------------------------------------------------------------
# SECRET: AZURE_CLIENT_SECRET
# ----------------------------------------------------------------------------
# Service Principal password (client secret).
# THIS IS HIGHLY SENSITIVE - never expose in logs or outputs.

resource "azurerm_key_vault_secret" "azure_client_secret" {
  # Secret name in Key Vault
  name = "azure-client-secret"

  # Secret value: Client secret from Service Principal
  value = azuread_service_principal_password.redaction_secret.value

  # Key Vault where secret is stored
  key_vault_id = azurerm_key_vault.redaction_kv.id

  # Content type
  content_type = "text/plain"

  # Expiration date: Match Service Principal secret expiration
  expiration_date = local.secret_end_date

  # Tags
  tags = merge(
    local.common_tags,
    {
      SecretType  = "Credential"
      Purpose     = "Service Principal Client Secret"
      Sensitivity = "High"  # This is SECRET!
      ExpiresOn   = formatdate("YYYY-MM-DD", local.secret_end_date)
    }
  )

  # Dependencies
  depends_on = [
    time_sleep.wait_for_rbac_propagation
  ]

  # Lifecycle: Prevent accidental deletion
  lifecycle {
    # Uncomment for production
    # prevent_destroy = true

    # Ignore changes to expiration date (managed externally)
    # ignore_changes = [expiration_date]
  }
}

# ----------------------------------------------------------------------------
# SECRET: AZURE_TENANT_ID
# ----------------------------------------------------------------------------
# Azure AD Tenant (Directory) ID.
# Not secret, but stored for convenience.

resource "azurerm_key_vault_secret" "azure_tenant_id" {
  # Secret name
  name = "azure-tenant-id"

  # Secret value: Tenant ID from current Azure context
  value = data.azurerm_client_config.current.tenant_id

  # Key Vault
  key_vault_id = azurerm_key_vault.redaction_kv.id

  # Content type
  content_type = "text/plain"

  # Tags
  tags = merge(
    local.common_tags,
    {
      SecretType  = "Credential"
      Purpose     = "Azure AD Tenant ID"
      Sensitivity = "Low"  # Tenant ID is not secret
    }
  )

  # Dependencies
  depends_on = [
    time_sleep.wait_for_rbac_propagation
  ]
}

# ----------------------------------------------------------------------------
# SECRET: AZURE_TEXT_ANALYTICS_ENDPOINT
# ----------------------------------------------------------------------------
# Azure Text Analytics API endpoint URL.
# Not secret, but stored for centralized configuration.

resource "azurerm_key_vault_secret" "azure_text_analytics_endpoint" {
  # Secret name
  name = "azure-text-analytics-endpoint"

  # Secret value: Text Analytics endpoint URL
  value = azurerm_cognitive_account.text_analytics.endpoint

  # Key Vault
  key_vault_id = azurerm_key_vault.redaction_kv.id

  # Content type
  content_type = "text/plain"

  # Tags
  tags = merge(
    local.common_tags,
    {
      SecretType  = "Configuration"
      Purpose     = "Text Analytics API Endpoint"
      Sensitivity = "Low"  # Endpoint URL is not secret
    }
  )

  # Dependencies
  depends_on = [
    time_sleep.wait_for_rbac_propagation
  ]
}

# ----------------------------------------------------------------------------
# SECRET: SECRET_EXPIRATION_DATE (METADATA)
# ----------------------------------------------------------------------------
# Store when the client secret expires (for monitoring/alerts).
# This is metadata to help track secret rotation.

resource "azurerm_key_vault_secret" "secret_expiration_date" {
  # Secret name
  name = "azure-client-secret-expiration-date"

  # Secret value: Expiration date in ISO format
  value = formatdate("YYYY-MM-DD", local.secret_end_date)

  # Key Vault
  key_vault_id = azurerm_key_vault.redaction_kv.id

  # Content type
  content_type = "text/plain"

  # Tags
  tags = merge(
    local.common_tags,
    {
      SecretType  = "Metadata"
      Purpose     = "Track client secret expiration"
      Sensitivity = "Low"
    }
  )

  # Dependencies
  depends_on = [
    time_sleep.wait_for_rbac_propagation
  ]
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
# Output Key Vault secret names (NOT values!) for reference.

output "key_vault_secrets" {
  value = {
    client_id_secret_name                = azurerm_key_vault_secret.azure_client_id.name
    client_secret_secret_name            = azurerm_key_vault_secret.azure_client_secret.name
    tenant_id_secret_name                = azurerm_key_vault_secret.azure_tenant_id.name
    text_analytics_endpoint_secret_name  = azurerm_key_vault_secret.azure_text_analytics_endpoint.name
    expiration_date_secret_name          = azurerm_key_vault_secret.secret_expiration_date.name
  }
  description = "Key Vault secret names (use these to retrieve secrets in your application)"
}

# ----------------------------------------------------------------------------
# EXAMPLE: HOW TO READ SECRETS IN PYTHON
# ----------------------------------------------------------------------------
# Your application reads secrets from Key Vault instead of .env file:
#
# from azure.identity import DefaultAzureCredential
# from azure.keyvault.secrets import SecretClient
#
# # Authenticate using Managed Identity (production) or Azure CLI (development)
# credential = DefaultAzureCredential()
#
# # Connect to Key Vault
# vault_url = "https://redaction-kv-dev-abc123.vault.azure.net/"
# client = SecretClient(vault_url=vault_url, credential=credential)
#
# # Read secrets
# client_id = client.get_secret("azure-client-id").value
# client_secret = client.get_secret("azure-client-secret").value
# tenant_id = client.get_secret("azure-tenant-id").value
# endpoint = client.get_secret("azure-text-analytics-endpoint").value
#
# # Use credentials
# from azure.identity import ClientSecretCredential
# credential = ClientSecretCredential(tenant_id, client_id, client_secret)
#
# # Now use Text Analytics with these credentials
# from azure.ai.textanalytics import TextAnalyticsClient
# ta_client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
# ============================================================================

# ----------------------------------------------------------------------------
# ROTATION STRATEGY
# ----------------------------------------------------------------------------
# When client secret expires:
# 1. Terraform creates new client secret
# 2. Terraform updates Key Vault secret "azure-client-secret"
# 3. Application reads new secret from Key Vault (no code changes!)
# 4. Old secret expires and is deleted
#
# This is why Key Vault is better than .env files!
# ============================================================================

# ----------------------------------------------------------------------------
# SECURITY NOTES
# ----------------------------------------------------------------------------
# 1. Never output secret values in Terraform (use sensitive = true)
# 2. Grant least privilege: Service Principal only needs "Secrets User" role
# 3. Enable soft delete: Deleted secrets recoverable for 7-90 days
# 4. Monitor access: Enable diagnostic logs to track who accessed secrets
# 5. Rotate secrets: Set expiration dates and rotate every 90 days
# 6. Use Managed Identity: In production, use Managed Identity (no credentials needed)
# ============================================================================
