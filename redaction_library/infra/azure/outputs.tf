# ============================================================================
# TERRAFORM OUTPUTS
# ============================================================================
# Exports values needed for application configuration (.env file).
#
# Purpose: Provide credentials and endpoints for the Redaction Library.
# Security: Mark sensitive outputs to prevent exposure in logs.
#
# Usage:
#   terraform output AZURE_CLIENT_ID
#   terraform output -raw AZURE_CLIENT_SECRET  # -raw removes quotes
#
# Auto-populate .env:
#   See README.md for script to generate .env from outputs
# ============================================================================

# ----------------------------------------------------------------------------
# AZURE AD CREDENTIALS
# ----------------------------------------------------------------------------
# Service Principal credentials for application authentication.
# These values go into your .env file.

output "AZURE_CLIENT_ID" {
  description = "Azure AD Application (Client) ID. Used for authentication."
  value       = azuread_application.redaction_app.client_id

  # Not sensitive: Client ID is public identifier (like username)
  sensitive = false
}

output "AZURE_TENANT_ID" {
  description = "Azure AD Tenant (Directory) ID. Identifies your Azure AD instance."
  value       = data.azurerm_client_config.current.tenant_id

  # Not sensitive: Tenant ID is public identifier
  sensitive = false
}

output "AZURE_CLIENT_SECRET" {
  description = "Azure AD Client Secret (Password). KEEP THIS SECRET! Store in .env file."
  value       = azuread_service_principal_password.redaction_secret.value

  # SENSITIVE: This is the password! Never expose in logs.
  sensitive = true
}

# ----------------------------------------------------------------------------
# AZURE TEXT ANALYTICS
# ----------------------------------------------------------------------------
# Text Analytics endpoint and configuration.

output "AZURE_TEXT_ANALYTICS_ENDPOINT" {
  description = "Azure Text Analytics endpoint URL. Used for API calls."
  value       = azurerm_cognitive_account.text_analytics.endpoint

  # Not sensitive: Endpoint is public URL
  sensitive = false

  # Example: https://redaction-ta-dev-abc123.cognitiveservices.azure.com/
}

output "AZURE_TEXT_ANALYTICS_NAME" {
  description = "Azure Text Analytics resource name. For reference only."
  value       = azurerm_cognitive_account.text_analytics.name

  # Not sensitive: Resource name is public
  sensitive = false
}

output "AZURE_TEXT_ANALYTICS_LOCATION" {
  description = "Azure region where Text Analytics is deployed."
  value       = azurerm_cognitive_account.text_analytics.location

  # Not sensitive: Location is public
  sensitive = false
}

# ----------------------------------------------------------------------------
# RESOURCE INFORMATION
# ----------------------------------------------------------------------------
# Additional details for reference and debugging.

output "resource_group_name" {
  description = "Name of the Azure Resource Group containing all resources."
  value       = azurerm_resource_group.redaction_rg.name
}

output "subscription_id" {
  description = "Azure Subscription ID where resources are deployed."
  value       = data.azurerm_client_config.current.subscription_id
}

output "service_principal_object_id" {
  description = "Service Principal Object ID (for IAM assignments)."
  value       = azuread_service_principal.redaction_sp.object_id

  # Not sensitive: Object ID is public identifier
  sensitive = false
}

output "text_analytics_sku" {
  description = "Text Analytics pricing tier (F0 = Free, S = Standard)."
  value       = azurerm_cognitive_account.text_analytics.sku_name
}

# ----------------------------------------------------------------------------
# SECRET MANAGEMENT
# ----------------------------------------------------------------------------
# Information about client secret expiration.

output "client_secret_expiration_date" {
  description = "Date when client secret expires (YYYY-MM-DD). Set reminder to rotate before this date."
  value       = formatdate("YYYY-MM-DD", local.secret_end_date)

  # Not sensitive: Expiration date is metadata
  sensitive = false
}

output "client_secret_expiration_warning" {
  description = "Warning message about secret rotation."
  value       = "⚠️  Client secret expires on ${formatdate("YYYY-MM-DD", local.secret_end_date)}. Set calendar reminder to rotate ${var.client_secret_expiration_days - 10} days from now!"

  # Not sensitive: Warning message
  sensitive = false
}

# ----------------------------------------------------------------------------
# .ENV FILE TEMPLATE
# ----------------------------------------------------------------------------
# Complete .env file content for easy copy-paste.

output "dotenv_file_content" {
  description = "Complete .env file content. Copy this to your .env file."
  value       = <<-EOT
    # =================================================================
    # Azure Service Principal Credentials
    # =================================================================
    # Generated by Terraform on ${formatdate("YYYY-MM-DD", timestamp())}
    # Client secret expires: ${formatdate("YYYY-MM-DD", local.secret_end_date)}

    AZURE_CLIENT_ID=${azuread_application.redaction_app.client_id}
    AZURE_CLIENT_SECRET=${azuread_service_principal_password.redaction_secret.value}
    AZURE_TENANT_ID=${data.azurerm_client_config.current.tenant_id}

    # =================================================================
    # Azure Text Analytics Configuration
    # =================================================================
    # Endpoint for PII detection API

    AZURE_TEXT_ANALYTICS_ENDPOINT=${azurerm_cognitive_account.text_analytics.endpoint}

    # =================================================================
    # Additional Information (for reference)
    # =================================================================
    # Resource Group: ${azurerm_resource_group.redaction_rg.name}
    # Location: ${azurerm_cognitive_account.text_analytics.location}
    # SKU: ${azurerm_cognitive_account.text_analytics.sku_name}
    # Environment: ${var.environment}
  EOT

  # SENSITIVE: Contains client secret
  sensitive = true
}

# ----------------------------------------------------------------------------
# USAGE INSTRUCTIONS
# ----------------------------------------------------------------------------
# Helpful commands for working with outputs.

output "usage_instructions" {
  description = "Instructions for using Terraform outputs."
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    TERRAFORM OUTPUTS - USAGE GUIDE                       ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    📋 View all outputs:
       terraform output

    📋 View specific output:
       terraform output AZURE_CLIENT_ID
       terraform output -raw AZURE_CLIENT_SECRET  # Without quotes

    📋 Create .env file automatically:
       terraform output -raw dotenv_file_content > ../../.env

    📋 Or copy values manually:
       AZURE_CLIENT_ID=$(terraform output -raw AZURE_CLIENT_ID)
       AZURE_CLIENT_SECRET=$(terraform output -raw AZURE_CLIENT_SECRET)
       AZURE_TENANT_ID=$(terraform output -raw AZURE_TENANT_ID)
       AZURE_TEXT_ANALYTICS_ENDPOINT=$(terraform output -raw AZURE_TEXT_ANALYTICS_ENDPOINT)

    ⚠️  SECURITY REMINDER:
       • Never commit .env to git (add to .gitignore)
       • Never share AZURE_CLIENT_SECRET publicly
       • Rotate secret every ${var.client_secret_expiration_days} days
       • Client secret expires: ${formatdate("YYYY-MM-DD", local.secret_end_date)}

    🧪 Test connection:
       cd ../..
       python -c "from azure.identity import ClientSecretCredential; \
                   import os; \
                   from dotenv import load_dotenv; \
                   load_dotenv(); \
                   c = ClientSecretCredential(os.getenv('AZURE_TENANT_ID'), \
                                              os.getenv('AZURE_CLIENT_ID'), \
                                              os.getenv('AZURE_CLIENT_SECRET')); \
                   print('✅ Authentication successful!')"

    🚀 Run examples:
       PYTHONPATH=. python examples/examples.py

  EOT
}

# ----------------------------------------------------------------------------
# KEY VAULT INFORMATION
# ----------------------------------------------------------------------------
# Key Vault details for reading secrets securely.

output "AZURE_KEY_VAULT_URL" {
  description = "Key Vault URL. Use this to read secrets from Key Vault instead of .env file."
  value       = azurerm_key_vault.redaction_kv.vault_uri

  # Not sensitive: Key Vault URL is public
  sensitive = false

  # Example: https://redaction-kv-dev-abc123.vault.azure.net/
}

output "AZURE_KEY_VAULT_NAME" {
  description = "Key Vault name. For reference only."
  value       = azurerm_key_vault.redaction_kv.name

  # Not sensitive: Name is public
  sensitive = false
}

# ----------------------------------------------------------------------------
# KEY VAULT USAGE INSTRUCTIONS
# ----------------------------------------------------------------------------
# How to read secrets from Key Vault in your application.

output "key_vault_usage_instructions" {
  description = "Instructions for reading secrets from Key Vault."
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    KEY VAULT - SECURE SECRET STORAGE                     ║
    ╚══════════════════════════════════════════════════════════════════════════╝

    🔐 Secrets stored in Key Vault:
       • azure-client-id
       • azure-client-secret
       • azure-tenant-id
       • azure-text-analytics-endpoint
       • azure-client-secret-expiration-date

    📋 Key Vault URL:
       ${azurerm_key_vault.redaction_kv.vault_uri}

    🐍 Python Example (using Key Vault):

    from azure.identity import DefaultAzureCredential
    from azure.keyvault.secrets import SecretClient

    # Authenticate (uses Azure CLI or Managed Identity)
    credential = DefaultAzureCredential()

    # Connect to Key Vault
    vault_url = "${azurerm_key_vault.redaction_kv.vault_uri}"
    kv_client = SecretClient(vault_url=vault_url, credential=credential)

    # Read secrets
    client_id = kv_client.get_secret("azure-client-id").value
    client_secret = kv_client.get_secret("azure-client-secret").value
    tenant_id = kv_client.get_secret("azure-tenant-id").value
    endpoint = kv_client.get_secret("azure-text-analytics-endpoint").value

    # Use with Redaction Library
    from azure.identity import ClientSecretCredential
    from redaction_library import RedactionService, AzureProvider

    provider = AzureProvider(
        client_id=client_id,
        client_secret=client_secret,
        tenant_id=tenant_id
    )

    service = RedactionService(
        provider=provider,
        use_cloud_detection=True,
        azure_text_analytics_endpoint=endpoint
    )

    ✅ BENEFITS OF KEY VAULT:
       • No .env file needed (secrets in secure vault)
       • Automatic secret rotation
       • Audit logs (who accessed what, when)
       • RBAC access control
       • Encrypted at rest

    🔧 Development (Azure CLI):
       az login
       python examples/examples.py  # Reads from Key Vault automatically!

    🚀 Production (Managed Identity):
       # Deploy to Azure App Service / AKS / VM
       # Enable Managed Identity
       # No credentials needed! Azure handles authentication.

  EOT
}

# ----------------------------------------------------------------------------
# OUTPUTS FOR CI/CD
# ----------------------------------------------------------------------------
# Machine-readable outputs for automation scripts.

output "outputs_json" {
  description = "All outputs in JSON format for CI/CD pipelines."
  value = jsonencode({
    azure_client_id                   = azuread_application.redaction_app.client_id
    azure_tenant_id                   = data.azurerm_client_config.current.tenant_id
    azure_text_analytics_endpoint     = azurerm_cognitive_account.text_analytics.endpoint
    azure_key_vault_url               = azurerm_key_vault.redaction_kv.vault_uri
    azure_key_vault_name              = azurerm_key_vault.redaction_kv.name
    resource_group_name               = azurerm_resource_group.redaction_rg.name
    text_analytics_name               = azurerm_cognitive_account.text_analytics.name
    text_analytics_location           = azurerm_cognitive_account.text_analytics.location
    text_analytics_sku                = azurerm_cognitive_account.text_analytics.sku_name
    service_principal_object_id       = azuread_service_principal.redaction_sp.object_id
    client_secret_expiration_date     = formatdate("YYYY-MM-DD", local.secret_end_date)
    environment                       = var.environment
  })

  # Contains non-sensitive metadata only
  # Client secret excluded from JSON output
  sensitive = false
}
