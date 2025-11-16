# ============================================================================
# TEXT ANALYTICS RESOURCES
# ============================================================================
# Creates Azure Cognitive Services Text Analytics for PII detection.
#
# Purpose: AI-powered PII detection service for names, emails, addresses, etc.
# Pricing: F0 (Free) = 5,000 texts/month, S (Standard) = $2 per 1,000 texts
#
# What gets created:
#   1. Resource Group (container for resources)
#   2. Random suffix (for globally unique names)
#   3. Text Analytics account (Cognitive Services)
#
# Best Practice: Use F0 for dev, S for production.
# ============================================================================

# ----------------------------------------------------------------------------
# RESOURCE GROUP
# ----------------------------------------------------------------------------
# Container for all Azure resources.
# Logical grouping for management, billing, and access control.

resource "azurerm_resource_group" "redaction_rg" {
  # Name must be unique within subscription
  name = local.resource_group_name

  # Azure region where resources will be created
  # Choose region closest to users for lowest latency
  location = var.location

  # Tags for cost tracking and organization
  tags = merge(
    local.common_tags,
    {
      ResourceType = "Resource Group"
      Description  = "Container for Redaction Library Azure resources"
    }
  )

  # Lifecycle: Prevent accidental deletion of production resources
  # Uncomment for production environments
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# ----------------------------------------------------------------------------
# RANDOM SUFFIX
# ----------------------------------------------------------------------------
# Generates random suffix for globally unique resource names.
# Text Analytics names must be unique across ALL of Azure.

resource "random_string" "suffix" {
  # Length of random string
  length = 8

  # Character set: lowercase alphanumeric only
  special = false  # No special characters (-, _, etc.)
  upper   = false  # Lowercase only
  numeric = true   # Include numbers

  # Ensure randomness changes if environment changes
  keepers = {
    environment  = var.environment
    project_name = var.project_name
  }
}

# ----------------------------------------------------------------------------
# TEXT ANALYTICS ACCOUNT
# ----------------------------------------------------------------------------
# Azure Cognitive Services Text Analytics resource.
# Provides PII detection, entity recognition, sentiment analysis.

resource "azurerm_cognitive_account" "text_analytics" {
  # Globally unique name across all of Azure
  # Format: {project}-ta-{env}-{random}
  # Example: redaction-ta-dev-a1b2c3d4
  name = local.text_analytics_name

  # Location and resource group
  location            = azurerm_resource_group.redaction_rg.location
  resource_group_name = azurerm_resource_group.redaction_rg.name

  # Service type: TextAnalytics for PII detection
  # Other options: ComputerVision, Face, SpeechServices, etc.
  kind = "TextAnalytics"

  # Pricing tier (SKU)
  # F0 = Free tier (5,000 texts/month, 20 requests/minute)
  # S  = Standard tier ($2 per 1,000 texts, 1,000 requests/second)
  sku_name = var.text_analytics_sku

  # Network access configuration
  # true  = Allow public internet access (development)
  # false = Private endpoints only (production)
  public_network_access_enabled = var.enable_public_network_access

  # API properties and configuration
  custom_subdomain_name = local.text_analytics_name  # Custom subdomain for endpoint

  # Managed Identity configuration (optional)
  # Useful if Text Analytics needs to access other Azure resources
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Network ACLs: IP-based access control
  # Empty list = allow all IPs (when public access enabled)
  dynamic "network_acls" {
    for_each = var.enable_public_network_access && length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      ip_rules       = var.allowed_ip_ranges
    }
  }

  # Local authentication: Enable API key authentication (backup)
  # Best Practice: Use Azure AD (Service Principal) as primary auth
  # Keep this enabled as fallback for emergency access
  local_auth_enabled = true

  # Outbound network access (for models and updates)
  # true = Allow (required for service to function)
  outbound_network_access_restricted = false

  # Tags for organization and cost tracking
  tags = merge(
    local.common_tags,
    {
      ResourceType = "Cognitive Services"
      Service      = "Text Analytics"
      SKU          = var.text_analytics_sku
      Purpose      = "PII Detection"
    }
  )

  # Lifecycle rules
  # Prevent accidental deletion in production
  lifecycle {
    # Uncomment for production
    # prevent_destroy = true

    # Ignore changes to these fields (managed externally)
    ignore_changes = [
      # Ignore local_auth changes (can be toggled in portal)
      # local_auth_enabled,
    ]

    # Create new resource before destroying old one (zero downtime)
    create_before_destroy = false
  }
}

# ----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS (OPTIONAL)
# ----------------------------------------------------------------------------
# Enable logging and monitoring for Text Analytics.
# Useful for debugging, auditing, and cost tracking.

# Uncomment to enable diagnostic logs
# Requires: Log Analytics workspace

# resource "azurerm_monitor_diagnostic_setting" "text_analytics_logs" {
#   count = var.enable_diagnostic_logs ? 1 : 0
#
#   name                       = "${local.text_analytics_name}-diagnostics"
#   target_resource_id         = azurerm_cognitive_account.text_analytics.id
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#
#   # Enable request/response logs
#   enabled_log {
#     category = "RequestResponse"
#   }
#
#   # Enable audit logs
#   enabled_log {
#     category = "Audit"
#   }
#
#   # Enable metrics
#   metric {
#     category = "AllMetrics"
#   }
# }

# ----------------------------------------------------------------------------
# OUTPUTS (FOR DEBUGGING)
# ----------------------------------------------------------------------------
# Output resource information to console during apply

output "text_analytics_debug_info" {
  value = {
    name              = azurerm_cognitive_account.text_analytics.name
    location          = azurerm_cognitive_account.text_analytics.location
    sku               = azurerm_cognitive_account.text_analytics.sku_name
    endpoint          = azurerm_cognitive_account.text_analytics.endpoint
    resource_group    = azurerm_resource_group.redaction_rg.name
    public_access     = var.enable_public_network_access
    managed_identity  = var.enable_managed_identity
  }
  description = "Text Analytics resource details for debugging"
}
