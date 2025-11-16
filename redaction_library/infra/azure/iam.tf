# ============================================================================
# IAM ROLE ASSIGNMENTS
# ============================================================================
# Assigns Azure RBAC roles to grant Service Principal access to Text Analytics.
#
# Purpose: Grant least-privilege access for Service Principal to call Text Analytics API.
# Security: Uses Azure RBAC (not API keys) for fine-grained access control.
#
# What gets created:
#   1. Role assignment: Service Principal → Text Analytics
#   2. (Optional) Role assignment: Current user → Text Analytics (for testing)
#
# Best Practice: Use "Cognitive Services User" (read-only) not "Contributor".
# ============================================================================

# ----------------------------------------------------------------------------
# SERVICE PRINCIPAL ROLE ASSIGNMENT
# ----------------------------------------------------------------------------
# Grants Service Principal permission to call Text Analytics API.
# This is the primary authentication method for the application.

resource "azurerm_role_assignment" "sp_to_text_analytics" {
  # Scope: What resource this role applies to
  # Limit to specific Text Analytics resource (not entire resource group)
  scope = azurerm_cognitive_account.text_analytics.id

  # Role: What permissions are granted
  # "Cognitive Services User" = Read-only access (recommended)
  #   - Can call recognize_pii_entities() API
  #   - Cannot modify or delete resource
  #   - Cannot regenerate API keys
  #
  # Alternative roles:
  # "Cognitive Services Contributor" = Read-write access (not recommended)
  #   - Can modify resource settings
  #   - Can regenerate API keys
  #   - Too broad for application use
  #
  # "Cognitive Services OpenAI User" = For OpenAI services only
  role_definition_name = var.cognitive_services_role

  # Principal: WHO gets this role
  # Service Principal object ID (not client ID!)
  principal_id = azuread_service_principal.redaction_sp.object_id

  # Principal type: Clarify what kind of identity
  # Helps Azure optimize permission checks
  principal_type = "ServicePrincipal"

  # Skip service principal check during creation
  # Avoids race condition if SP not fully propagated in Azure AD
  skip_service_principal_aad_check = true

  # Dependency: Ensure resources exist before assignment
  depends_on = [
    azuread_service_principal.redaction_sp,
    azurerm_cognitive_account.text_analytics
  ]

  # Description (optional, for documentation)
  # description = "Allows ${local.service_principal_name} to call Text Analytics PII detection API"
}

# ----------------------------------------------------------------------------
# CURRENT USER ROLE ASSIGNMENT (OPTIONAL)
# ----------------------------------------------------------------------------
# Grants current user (who runs Terraform) access to Text Analytics.
# Useful for testing and troubleshooting in development.
#
# Comment out or set count = 0 for production deployments.

resource "azurerm_role_assignment" "current_user_to_text_analytics" {
  # Only create in dev environment (comment out for production)
  count = var.environment == "dev" ? 1 : 0

  # Scope: Text Analytics resource
  scope = azurerm_cognitive_account.text_analytics.id

  # Role: Give current user Contributor access for testing
  # Allows regenerating keys, testing in Portal, etc.
  role_definition_name = "Cognitive Services Contributor"

  # Principal: Current user running Terraform
  principal_id = data.azuread_client_config.current.object_id

  # Principal type: User (person) vs ServicePrincipal (application)
  principal_type = "User"

  # Dependency: Ensure Text Analytics exists
  depends_on = [
    azurerm_cognitive_account.text_analytics
  ]
}

# ----------------------------------------------------------------------------
# ROLE ASSIGNMENT VERIFICATION
# ----------------------------------------------------------------------------
# Output role assignment details for verification

resource "null_resource" "role_assignment_info" {
  # Trigger on role assignment changes
  triggers = {
    role_assignment_id = azurerm_role_assignment.sp_to_text_analytics.id
  }

  # Print role assignment information
  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "✅ IAM ROLE ASSIGNMENT CREATED:"
      echo "   Service Principal: ${local.service_principal_name}"
      echo "   Role: ${var.cognitive_services_role}"
      echo "   Resource: ${azurerm_cognitive_account.text_analytics.name}"
      echo "   Scope: Text Analytics API access only"
      echo ""
      echo "   Service Principal can now:"
      echo "   ✓ Call recognize_pii_entities() API"
      echo "   ✓ Detect PII in text"
      echo "   ✗ Cannot modify resource settings"
      echo "   ✗ Cannot delete resource"
      echo ""
    EOT
  }
}

# ----------------------------------------------------------------------------
# ADDITIONAL ROLE ASSIGNMENTS (OPTIONAL)
# ----------------------------------------------------------------------------
# Add more role assignments as needed

# Example: Grant Service Principal access to Key Vault
# Uncomment if using Azure Key Vault for secrets

# resource "azurerm_role_assignment" "sp_to_key_vault" {
#   scope                = var.key_vault_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = azuread_service_principal.redaction_sp.object_id
#   principal_type       = "ServicePrincipal"
# }

# Example: Grant Service Principal access to Storage Account
# Uncomment if storing redacted data in Azure Blob Storage

# resource "azurerm_role_assignment" "sp_to_storage" {
#   scope                = var.storage_account_id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azuread_service_principal.redaction_sp.object_id
#   principal_type       = "ServicePrincipal"
# }

# ----------------------------------------------------------------------------
# RBAC BEST PRACTICES
# ----------------------------------------------------------------------------
# 1. Least Privilege: Use "User" role (read-only) not "Contributor"
# 2. Scope Limitation: Assign to specific resource, not resource group
# 3. Time-Bound: Consider using Azure PIM for temporary elevated access
# 4. Audit: Enable diagnostic logs to track who accessed what
# 5. Review: Regularly review and remove unused role assignments
#
# Security Note:
# - Service Principal should ONLY have access to Text Analytics
# - Do NOT grant "Owner" or "Contributor" at subscription level
# - Use separate Service Principals for different applications
# ============================================================================
