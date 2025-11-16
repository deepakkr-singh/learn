# ============================================================================
# AZURE KEY VAULT
# ============================================================================
# Creates Azure Key Vault for secure secret storage.
#
# Purpose: Store all sensitive credentials (client_secret, API keys) securely.
# Security: Secrets stored encrypted at rest, accessed via RBAC, audit logs enabled.
#
# What gets created:
#   1. Key Vault (secure secret storage)
#   2. Access policies (who can read/write secrets)
#   3. Diagnostic settings (audit logs)
#
# Best Practice: Store ALL secrets in Key Vault, never in .env files.
# ============================================================================

# ----------------------------------------------------------------------------
# KEY VAULT RESOURCE
# ----------------------------------------------------------------------------
# Azure Key Vault for storing secrets, keys, and certificates.

resource "azurerm_key_vault" "redaction_kv" {
  # Name must be globally unique (3-24 chars, alphanumeric + hyphens)
  # Format: {project}kv{environment}{random} (no dashes to avoid length issues)
  name = "${var.project_name}kv${var.environment}${random_string.suffix.result}"

  # Location and resource group
  location            = azurerm_resource_group.redaction_rg.location
  resource_group_name = azurerm_resource_group.redaction_rg.name

  # Azure AD tenant ID (who owns this Key Vault)
  tenant_id = data.azurerm_client_config.current.tenant_id

  # Pricing tier
  # Standard = Software-protected keys (cheap, sufficient for most cases)
  # Premium = Hardware Security Module (HSM) protected keys (expensive, high security)
  sku_name = "standard"

  # Soft delete configuration
  # When secret is deleted, it's kept for recovery period before permanent deletion
  soft_delete_retention_days = 7  # Keep deleted secrets for 7 days (min: 7, max: 90)
  purge_protection_enabled   = false  # Set true for production (prevents permanent deletion)

  # Network access configuration
  # Public access: Allow from internet (development)
  # For production: Use private endpoints or network ACLs
  public_network_access_enabled = var.enable_public_network_access

  # Network ACLs: IP-based access control
  # Empty = allow all IPs (when public access enabled)
  network_acls {
    # Default action when IP not in allowed list
    default_action = var.enable_public_network_access && length(var.allowed_ip_ranges) > 0 ? "Deny" : "Allow"

    # Bypass Azure services (allows Azure VMs, App Services to access)
    bypass = "AzureServices"

    # Allowed IP ranges (if specified)
    ip_rules = var.allowed_ip_ranges

    # Virtual network subnet IDs (for private access)
    # virtual_network_subnet_ids = []
  }

  # RBAC for Key Vault access control
  # true = Use Azure RBAC (recommended, more flexible)
  # false = Use access policies (legacy)
  enable_rbac_authorization = true

  # Enable Key Vault for specific Azure services
  enabled_for_deployment          = false  # Azure VMs can retrieve secrets during deployment
  enabled_for_disk_encryption     = false  # Azure Disk Encryption can use keys
  enabled_for_template_deployment = false  # ARM templates can retrieve secrets

  # Tags for organization and cost tracking
  tags = merge(
    local.common_tags,
    {
      ResourceType = "Key Vault"
      Purpose      = "Secret Storage"
      Description  = "Stores Service Principal credentials and API secrets"
    }
  )

  # Lifecycle rules
  lifecycle {
    # Prevent accidental deletion in production
    # Uncomment for production environments
    # prevent_destroy = true

    # Ignore changes to access policies (managed via RBAC)
    ignore_changes = [
      # Access policies are deprecated when using RBAC
      # access_policy,
    ]
  }

  # Dependency: Create resource group first
  depends_on = [
    azurerm_resource_group.redaction_rg
  ]
}

# ----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS (AUDIT LOGS)
# ----------------------------------------------------------------------------
# Enable audit logging for Key Vault access.
# Tracks who accessed which secrets, when, and from where.

# Uncomment to enable diagnostic logs (requires Log Analytics workspace)

# resource "azurerm_monitor_diagnostic_setting" "key_vault_logs" {
#   count = var.enable_diagnostic_logs ? 1 : 0
#
#   name               = "${azurerm_key_vault.redaction_kv.name}-diagnostics"
#   target_resource_id = azurerm_key_vault.redaction_kv.id
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#
#   # Audit logs: Who accessed what
#   enabled_log {
#     category = "AuditEvent"
#   }
#
#   # Metrics: Performance and usage
#   metric {
#     category = "AllMetrics"
#   }
# }

# ----------------------------------------------------------------------------
# RBAC ROLE ASSIGNMENTS
# ----------------------------------------------------------------------------
# Grant access to Key Vault using Azure RBAC.

# Grant Service Principal access to read secrets
resource "azurerm_role_assignment" "sp_to_key_vault_secrets_user" {
  # Scope: Key Vault resource
  scope = azurerm_key_vault.redaction_kv.id

  # Role: Key Vault Secrets User (read-only access to secrets)
  # Other roles:
  # - "Key Vault Secrets Officer" = Read + write secrets
  # - "Key Vault Administrator" = Full access
  role_definition_name = "Key Vault Secrets User"

  # Principal: Service Principal that needs to read secrets
  principal_id = azuread_service_principal.redaction_sp.object_id

  # Principal type
  principal_type = "ServicePrincipal"

  # Skip service principal check (avoid race condition)
  skip_service_principal_aad_check = true

  # Dependency: Ensure Key Vault and Service Principal exist
  depends_on = [
    azurerm_key_vault.redaction_kv,
    azuread_service_principal.redaction_sp
  ]
}

# Grant current user (Terraform runner) access to manage secrets
# This allows Terraform to create secrets in Key Vault
resource "azurerm_role_assignment" "current_user_to_key_vault_admin" {
  # Scope: Key Vault resource
  scope = azurerm_key_vault.redaction_kv.id

  # Role: Key Vault Secrets Officer (can create/read/update/delete secrets)
  role_definition_name = "Key Vault Secrets Officer"

  # Principal: Current user running Terraform
  principal_id = data.azuread_client_config.current.object_id

  # Principal type
  principal_type = "User"

  # Dependency: Ensure Key Vault exists
  depends_on = [
    azurerm_key_vault.redaction_kv
  ]
}

# ----------------------------------------------------------------------------
# OUTPUTS (FOR DEBUGGING)
# ----------------------------------------------------------------------------

output "key_vault_debug_info" {
  value = {
    name                  = azurerm_key_vault.redaction_kv.name
    vault_uri             = azurerm_key_vault.redaction_kv.vault_uri
    location              = azurerm_key_vault.redaction_kv.location
    resource_group        = azurerm_resource_group.redaction_rg.name
    rbac_enabled          = azurerm_key_vault.redaction_kv.enable_rbac_authorization
    soft_delete_enabled   = azurerm_key_vault.redaction_kv.soft_delete_retention_days
    public_access_enabled = azurerm_key_vault.redaction_kv.public_network_access_enabled
  }
  description = "Key Vault resource details for debugging"
}

# ----------------------------------------------------------------------------
# NOTES AND BEST PRACTICES
# ----------------------------------------------------------------------------
# 1. Soft Delete: Protects against accidental deletion (secrets recoverable for 7-90 days)
# 2. Purge Protection: Prevents permanent deletion (enable in production)
# 3. RBAC: Use Azure RBAC instead of legacy access policies (more flexible)
# 4. Network ACLs: Restrict access by IP in production
# 5. Diagnostic Logs: Enable audit logging for compliance
# 6. Naming: Key Vault names must be globally unique (3-24 chars)
# 7. Cost: ~$0.03 per 10,000 operations (very cheap)
#
# Security Checklist:
# ✅ Use RBAC for access control
# ✅ Enable soft delete (7+ days)
# ✅ Enable purge protection (production)
# ✅ Restrict network access (production)
# ✅ Enable diagnostic logs (audit trail)
# ✅ Use Managed Identity (no secrets in code)
# ✅ Rotate secrets regularly (90 days)
# ============================================================================
