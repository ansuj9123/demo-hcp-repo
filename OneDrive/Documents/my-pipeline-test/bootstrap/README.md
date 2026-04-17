# Bootstrap Configuration

This directory contains the Terraform configuration for bootstrapping remote state and foundational Azure resources for the infrastructure pipeline.

## Purpose

- Create Azure Storage Account for remote Terraform state
- Configure state backend with secure settings (HTTPS-only, soft delete, versioning, RBAC)
- Create service principal and role assignments (if needed)
- Set up resource groups for organizing resources

## Setup Instructions

### 1. Prerequisites

```bash
# Install Terraform
terraform --version  # Should be v1.6.0+

# Install Azure CLI
az --version

# Install jq (for parsing JSON)
jq --version
```

### 2. Initial Authentication

```bash
# Login to Azure with your subscription admin account
az login

# Set default subscription
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 3. Create Service Principal (if using Service Principal authentication)

```bash
# Create a service principal for CI/CD
az ad sp create-for-rbac \
  --name "github-pipeline-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/<SUBSCRIPTION_ID>" \
  --sdk-auth > sp-credentials.json

# IMPORTANT: Copy the entire JSON output and store as GitHub Environment secret: AZURE_CREDENTIALS
# The file will contain: clientId, clientSecret, subscriptionId, tenantId
```

### 4. Bootstrap Terraform

```bash
# Initialize Terraform (local state initially)
cd bootstrap
terraform init -backend=false

# Review the plan
terraform plan -var-file=sandbox.tfvars -out=tfplan.bin

# Apply bootstrap resources
terraform apply tfplan.bin

# This creates:
# - Resource group for bootstrap resources
# - Storage account for remote state
# - Storage container for state
# - RBAC role assignments for service principal
```

### 5. Migrate to Remote State

After successful bootstrap apply:

```bash
# Generate backend configuration
terraform output -json backend_config | jq -r 'to_entries[] | "\(.key) = \(.value.value)"' > backend.hcl

# Edit main.tf to add backend configuration (uncomment or add):
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-tfstate"
#     storage_account_name = "st<random>tfstate"
#     container_name       = "tfstate"
#     key                  = "sandbox/terraform.tfstate"
#   }
# }

# Re-initialize with remote backend
terraform init

# Confirm migration when prompted
```

### 6. Verify Remote State

```bash
# Check state is now remote
terraform state list

# View state in Azure Portal:
# - Storage Account > Containers > tfstate > terraform.tfstate blob
```

## Files

- `main.tf` - Resource definitions
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `sandbox.tfvars` - Sandbox environment values

## Security Best Practices

- ✅ State file stored in private Azure Storage container
- ✅ HTTPS-only enabled on storage account
- ✅ Storage account firewall configured (adapt as needed)
- ✅ Soft delete and versioning enabled for recovery
- ✅ RBAC controls for state access
- ✅ Local state files never committed to git

## Troubleshooting

**"Storage account already exists":**

- Storage account names must be globally unique
- Modify the `storage_account_name` variable

**"Access denied" during apply:**

- Verify service principal has Contributor role
- Check subscription is correct: `az account show`

**State locked:**

```bash
# Terraform state is locked, possibly by another apply
# Wait or force-unlock (use with caution):
terraform force-unlock <LOCK_ID>
```

## Next Steps

1. Run bootstrap apply to create state backend
2. Configure GitHub Environment "sandbox" secrets with AZURE_CREDENTIALS
3. Update `.github/workflows/apply.yml` with your storage account details
4. Deploy infrastructure from `infra/environments/sandbox/`
