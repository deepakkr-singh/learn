# ============================================================================
# TERRAFORM CONFIGURATION
# ============================================================================
# This file configures Terraform providers and backend for Azure infrastructure.
#
# Purpose: Define required providers and their versions for reproducible builds.
# Best Practice: Pin provider versions to prevent breaking changes.
# ============================================================================

terraform {
  # Require Terraform version 1.0 or higher
  # Best Practice: Pin to major version to prevent breaking changes
  required_version = ">= 1.0"

  # Define required providers with version constraints
  required_providers {
    # Azure Resource Manager provider for creating Azure resources
    # Used for: Text Analytics, Resource Groups, Role Assignments
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Allow minor/patch updates, lock major version
    }

    # Azure Active Directory provider for identity management
    # Used for: Service Principal, App Registration
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"  # Allow minor/patch updates, lock major version
    }

    # Random provider for generating unique resource names
    # Used for: Ensuring globally unique Text Analytics resource names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Optional: Configure remote backend for team collaboration
  # Uncomment and configure for production use
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstate"
  #   container_name       = "tfstate"
  #   key                  = "redaction.terraform.tfstate"
  # }
}

# ============================================================================
# AZURE RESOURCE MANAGER PROVIDER
# ============================================================================
# Configure Azure Resource Manager provider for creating Azure resources.
#
# Authentication: Uses Azure CLI credentials by default (az login).
# Best Practice: Use Service Principal or Managed Identity in CI/CD.
# ============================================================================

provider "azurerm" {
  # Enable all features (required for azurerm 3.x)
  features {
    # Configure resource group deletion behavior
    resource_group {
      # Prevent accidental deletion of non-empty resource groups
      prevent_deletion_if_contains_resources = false
    }

    # Configure Key Vault behavior (if using Key Vault)
    key_vault {
      # Purge Key Vault on delete (vs soft delete)
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    # Configure Cognitive Services behavior
    cognitive_account {
      # Purge Cognitive Services on delete
      purge_soft_delete_on_destroy = true
    }
  }

  # Optional: Explicitly specify subscription
  # subscription_id = var.azure_subscription_id
}

# ============================================================================
# AZURE ACTIVE DIRECTORY PROVIDER
# ============================================================================
# Configure Azure AD provider for identity and access management.
#
# Authentication: Inherits credentials from Azure CLI or environment.
# Best Practice: Use same authentication as azurerm provider.
# ============================================================================

provider "azuread" {
  # Optional: Explicitly specify tenant
  # tenant_id = var.azure_tenant_id
}

# ============================================================================
# DATA SOURCES
# ============================================================================
# Query existing Azure resources for reference.
# Best Practice: Use data sources instead of hardcoding values.
# ============================================================================

# Get current Azure client configuration
# Used for: Retrieving tenant ID, subscription ID
data "azurerm_client_config" "current" {}

# Get current user/service principal details
# Used for: Adding current user as Cognitive Services admin
data "azuread_client_config" "current" {}
