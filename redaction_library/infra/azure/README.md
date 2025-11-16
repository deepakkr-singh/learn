# Terraform Configuration for Azure Redaction Library

Infrastructure as Code (IaC) for deploying Azure resources required by the Redaction Library.

---

## What This Creates

| Resource | Purpose | Cost |
|----------|---------|------|
| **Service Principal** | Application identity for secure authentication | Free |
| **Text Analytics** | AI-powered PII detection API | $0-$2000/month |
| **IAM Role Assignment** | Grants Service Principal access to Text Analytics | Free |

---

## Quick Start

### 1. Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# Install Azure CLI
brew install azure-cli  # macOS
# or download from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

### 2. Configure Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars

# Example configuration:
# environment = "dev"
# location = "eastus"
# text_analytics_sku = "F0"  # Free tier
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform (download providers)
terraform init

# Preview changes (dry run)
terraform plan

# Create resources
terraform apply

# Type 'yes' to confirm
```

### 4. Get Credentials

```bash
# View all outputs
terraform output

# Get specific values
terraform output -raw AZURE_CLIENT_ID
terraform output -raw AZURE_CLIENT_SECRET
terraform output -raw AZURE_TENANT_ID
terraform output -raw AZURE_TEXT_ANALYTICS_ENDPOINT

# Auto-create .env file
terraform output -raw dotenv_file_content > ../../.env

echo "✅ .env file created in project root!"
```

### 5. Test Connection

```bash
# Navigate to project root
cd ../..

# Run examples
PYTHONPATH=. python examples/examples.py

# Expected output:
# ✅ All examples pass
```

---

## File Structure

```
terraform/
├── main.tf                    # Provider configuration
├── variables.tf               # Input variables (configurable)
├── service_principal.tf       # Service Principal resources
├── text_analytics.tf          # Text Analytics resources
├── iam.tf                     # IAM role assignments
├── outputs.tf                 # Output values (for .env)
├── terraform.tfvars.example   # Example variable values (safe to commit)
├── terraform.tfvars           # Actual variable values (gitignored)
├── .gitignore                 # Ignore sensitive files
└── README.md                  # This file
```

---

## Configuration Options

### Environment Variables (terraform.tfvars)

```hcl
# Basic configuration
environment                  = "dev"           # dev, staging, prod
project_name                 = "redaction"     # Resource name prefix
location                     = "eastus"        # Azure region

# Text Analytics
text_analytics_sku           = "F0"            # F0 (free) or S (standard)
enable_public_network_access = true            # true = public, false = private

# Security
client_secret_expiration_days = 90             # Rotate every 90 days
cognitive_services_role       = "Cognitive Services User"  # Read-only

# Tags
tags = {
  Project    = "Redaction Library"
  ManagedBy  = "Terraform"
  Owner      = "platform-team"
}
```

### SKU Options

| SKU | Price | Free Tier | Limits | Use Case |
|-----|-------|-----------|--------|----------|
| **F0** | $0 | 5,000 texts/month | 20 req/min | Development, testing |
| **S** | $2 per 1,000 texts | None | 1,000 req/sec | Production |

---

## Common Commands

### Deployment

```bash
# Initialize (first time only)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Apply without confirmation prompt
terraform apply -auto-approve

# Apply specific resource
terraform apply -target=azurerm_cognitive_account.text_analytics
```

### Management

```bash
# View current state
terraform show

# List all resources
terraform state list

# View specific resource
terraform state show azurerm_cognitive_account.text_analytics

# Refresh state from Azure
terraform refresh

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output AZURE_CLIENT_ID

# View without quotes
terraform output -raw AZURE_CLIENT_SECRET

# Export to JSON
terraform output -json > outputs.json

# Create .env file
terraform output -raw dotenv_file_content > ../../.env
```

### Cleanup

```bash
# Destroy all resources
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=azurerm_cognitive_account.text_analytics
```

---

## Multi-Environment Setup

### Option 1: Separate State Files (Workspaces)

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev

# Deploy to current workspace
terraform apply -var="environment=dev"
```

### Option 2: Separate Directories

```
terraform/
├── dev/
│   ├── main.tf -> ../main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf -> ../main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf -> ../main.tf
    └── terraform.tfvars
```

---

## Security Best Practices

### 1. Secret Management

```bash
# ✅ GOOD: Store secrets in .env (gitignored)
terraform output -raw AZURE_CLIENT_SECRET > .secret

# ❌ BAD: Hardcode secrets in code
client_secret = "abc123..."  # NEVER DO THIS
```

### 2. State File Security

```bash
# Use remote backend for team collaboration
# Uncomment in main.tf:
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "redaction.terraform.tfstate"
  }
}

# Initialize with remote backend
terraform init -backend-config="access_key=..."
```

### 3. Secret Rotation

```bash
# Rotate client secret every 90 days

# Step 1: Update expiration in terraform.tfvars
client_secret_expiration_days = 90

# Step 2: Apply changes (creates new secret)
terraform apply

# Step 3: Update .env file
terraform output -raw AZURE_CLIENT_SECRET

# Step 4: Test application
python examples/examples.py

# Step 5: Verify old secret is removed (after grace period)
az ad app credential list --id $(terraform output -raw AZURE_CLIENT_ID)
```

### 4. Least Privilege

```hcl
# ✅ GOOD: Use minimal role
cognitive_services_role = "Cognitive Services User"  # Read-only

# ❌ BAD: Use admin role
cognitive_services_role = "Cognitive Services Contributor"  # Too broad
```

---

## Troubleshooting

### Issue: "Insufficient privileges"

```bash
# Check your Azure permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Required permissions:
# - Create App Registrations
# - Create Cognitive Services
# - Assign IAM roles
```

### Issue: "Resource name already exists"

```bash
# Text Analytics names must be globally unique
# Solution: Change text_analytics_name in terraform.tfvars

text_analytics_name = "my-unique-name-${random_string.suffix.result}"
```

### Issue: "State lock timeout"

```bash
# If terraform is stuck (previous operation didn't complete)
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Issue: "Provider initialization failed"

```bash
# Delete provider cache and reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: "Authentication failed"

```bash
# Re-login to Azure
az logout
az login

# Clear Azure CLI cache
az account clear
az login
```

---

## Cost Estimation

### Development (10,000 texts/month)
```
Text Analytics (F0 Free Tier): $0 (5,000 texts)
Text Analytics (S Standard):   $10 (5,000 texts)
Service Principal:             $0
IAM Role Assignment:           $0
──────────────────────────────────────
Total:                         $10/month
```

### Production (1,000,000 texts/month)
```
Text Analytics (S Standard):   $2,000 (1M texts)
Service Principal:             $0
IAM Role Assignment:           $0
──────────────────────────────────────
Total:                         $2,000/month
```

### Cost Optimization Tips

1. **Use Free Tier for Development**
   ```hcl
   text_analytics_sku = "F0"  # 5,000 free texts/month
   ```

2. **Hybrid Approach** (Local + Cloud)
   ```python
   # Use local regex for known patterns (free)
   # Use cloud AI for complex patterns (paid)
   service = RedactionService(
       use_cloud_detection=True,
       redactors=[EmailRedactor(), PhoneRedactor()]
   )
   ```

3. **Monitor Usage**
   ```bash
   # Enable diagnostic logs
   enable_diagnostic_logs = true

   # Review in Azure Portal → Text Analytics → Metrics
   ```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Azure Login
        run: |
          az login --service-principal \
            -u ${{ secrets.AZURE_CLIENT_ID }} \
            -p ${{ secrets.AZURE_CLIENT_SECRET }} \
            --tenant ${{ secrets.AZURE_TENANT_ID }}

      - name: Terraform Init
        run: terraform init
        working-directory: infra/terraform

      - name: Terraform Plan
        run: terraform plan
        working-directory: infra/terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: infra/terraform
```

---

## Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Text Analytics Docs](https://learn.microsoft.com/en-us/azure/cognitive-services/language-service/)
- [Azure Service Principal Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

## Summary

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize Terraform (first time) |
| `terraform plan` | Preview changes (dry run) |
| `terraform apply` | Create/update resources |
| `terraform output` | View credentials |
| `terraform destroy` | Delete all resources |

**Infrastructure as Code = Reproducible, Secure, Production-Ready** 🚀
