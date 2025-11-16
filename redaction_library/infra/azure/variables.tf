# ============================================================================
# INPUT VARIABLES
# ============================================================================
# Define configurable parameters for the infrastructure.
#
# Purpose: Make infrastructure reusable across environments (dev/staging/prod).
# Best Practice: Provide defaults for non-sensitive values, require sensitive ones.
#
# Usage:
#   terraform apply -var="environment=prod" -var="location=westus"
#   Or create terraform.tfvars file with variable values.
# ============================================================================

# ----------------------------------------------------------------------------
# ENVIRONMENT CONFIGURATION
# ----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod). Used for resource naming and tagging."
  type        = string
  default     = "dev"

  # Validate environment name
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name. Used as prefix for all resources."
  type        = string
  default     = "redaction"

  # Validate project name (lowercase alphanumeric only)
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric characters only."
  }
}

# ----------------------------------------------------------------------------
# AZURE CONFIGURATION
# ----------------------------------------------------------------------------

variable "location" {
  description = "Azure region for resources. Choose closest to your users for lower latency."
  type        = string
  default     = "eastus"

  # Common regions: eastus, westus, westeurope, southeastasia
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group. If empty, uses project_name-rg."
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# TEXT ANALYTICS CONFIGURATION
# ----------------------------------------------------------------------------

variable "text_analytics_sku" {
  description = "Text Analytics pricing tier. F0=Free (5K texts/month), S=Standard ($2 per 1K texts)."
  type        = string
  default     = "F0"  # Free tier for development

  # Validate SKU
  validation {
    condition     = contains(["F0", "S", "S0", "S1", "S2", "S3", "S4"], var.text_analytics_sku)
    error_message = "SKU must be one of: F0 (Free), S/S0-S4 (Standard)."
  }
}

variable "text_analytics_name" {
  description = "Name of the Text Analytics resource. If empty, auto-generates unique name."
  type        = string
  default     = ""

  # Must be globally unique across Azure
  # If empty, will use: {project_name}-ta-{random_suffix}
}

variable "enable_public_network_access" {
  description = "Allow public network access to Text Analytics. Set false for production with private endpoints."
  type        = bool
  default     = true  # Allow public access for development
}

# ----------------------------------------------------------------------------
# SERVICE PRINCIPAL CONFIGURATION
# ----------------------------------------------------------------------------

variable "service_principal_name" {
  description = "Display name for the Service Principal (App Registration)."
  type        = string
  default     = ""

  # If empty, uses: {project_name}-{environment}-sp
}

variable "client_secret_expiration_days" {
  description = "Number of days until client secret expires. Recommended: 90 days, Max: 730 days."
  type        = number
  default     = 90

  # Best Practice: Short-lived secrets (90 days) for security
  # Requires periodic rotation
  validation {
    condition     = var.client_secret_expiration_days >= 30 && var.client_secret_expiration_days <= 730
    error_message = "Secret expiration must be between 30 and 730 days."
  }
}

# ----------------------------------------------------------------------------
# IAM CONFIGURATION
# ----------------------------------------------------------------------------

variable "cognitive_services_role" {
  description = "Azure RBAC role for Service Principal access to Text Analytics."
  type        = string
  default     = "Cognitive Services User"

  # Options:
  # - "Cognitive Services User": Read-only access (recommended)
  # - "Cognitive Services Contributor": Read-write access
  # Best Practice: Use least privilege (User role)
}

# ----------------------------------------------------------------------------
# TAGGING CONFIGURATION
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags to apply to all resources. Used for cost tracking and organization."
  type        = map(string)
  default = {
    Project     = "Redaction Library"
    ManagedBy   = "Terraform"
    Purpose     = "PII Detection"
    CostCenter  = "Engineering"
  }

  # Add custom tags as needed:
  # Owner       = "team-name"
  # Environment = "production"
}

# ----------------------------------------------------------------------------
# FEATURE FLAGS
# ----------------------------------------------------------------------------

variable "enable_diagnostic_logs" {
  description = "Enable diagnostic logs for Text Analytics. Requires Log Analytics workspace."
  type        = bool
  default     = false

  # Set true for production monitoring
  # Requires additional Log Analytics workspace resource
}

variable "enable_managed_identity" {
  description = "Enable System-Assigned Managed Identity for Text Analytics resource."
  type        = bool
  default     = false

  # Useful if Text Analytics needs to access other Azure resources
  # Not required for basic PII detection
}

# ----------------------------------------------------------------------------
# NETWORKING (ADVANCED)
# ----------------------------------------------------------------------------

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access Text Analytics. Empty = allow all."
  type        = list(string)
  default     = []

  # Example: ["203.0.113.0/24", "198.51.100.0/24"]
  # Use with enable_public_network_access = true
}

variable "virtual_network_id" {
  description = "Virtual Network ID for private endpoint (advanced). Leave empty for public access."
  type        = string
  default     = ""

  # Requires enable_public_network_access = false
  # For production deployments with private networking
}

# ----------------------------------------------------------------------------
# COMPUTED LOCALS
# ----------------------------------------------------------------------------
# These are derived from variables above, not directly configurable.
# ============================================================================

locals {
  # Resource Group name: Use provided or generate from project name
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-${var.environment}-rg"

  # Service Principal name: Use provided or generate
  service_principal_name = var.service_principal_name != "" ? var.service_principal_name : "${var.project_name}-${var.environment}-sp"

  # Text Analytics name: Use provided or generate with random suffix
  text_analytics_name = var.text_analytics_name != "" ? var.text_analytics_name : "${var.project_name}-ta-${var.environment}-${random_string.suffix.result}"

  # Merge default tags with custom tags, add environment
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Location    = var.location
    }
  )

  # Calculate secret expiration date
  secret_end_date = timeadd(timestamp(), "${var.client_secret_expiration_days * 24}h")
}
