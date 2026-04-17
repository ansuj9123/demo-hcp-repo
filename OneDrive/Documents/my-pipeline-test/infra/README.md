# Terraform Infrastructure - Sandbox Environment

This directory contains the Terraform configuration for the sandbox environment.

## Structure

```
.
├── main.tf           # Main infrastructure configuration using modules
├── variables.tf      # Input variables
├── outputs.tf        # Output values
└── sandbox.tfvars    # Sandbox environment-specific values
```

## Running Locally

### Prerequisites

```bash
# Install Terraform (v1.6.0+)
terraform version

# Install Azure CLI
az --version

# Set Azure subscription
az account set --subscription "<SUBSCRIPTION_ID>"

# Create service principal and obtain credentials
az ad sp create-for-rbac --name "terraform-sp" --sdk-auth
```

### Local Development

```bash
# Initialize Terraform (uses local state for dev)
terraform init -backend=false

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan infrastructure
terraform plan -var-file=sandbox.tfvars -out=tfplan.bin

# Apply infrastructure
terraform apply tfplan.bin

# View outputs
terraform output

# Clean up
terraform destroy -var-file=sandbox.tfvars
```

## Running in CI/CD

The GitHub Actions workflows handle remote state and authentication automatically:

1. **CI workflow** (`ci.yml`): Runs format, validate, lint, and plan checks
2. **Plan workflow** (`plan.yml`): Generates terraform plan for PRs
3. **Apply workflow** (`apply.yml`): Applies changes when PR is merged to main

### State Backend Configuration

The remote state is stored in Azure Storage with the following configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "st<random>tfstate"
    container_name       = "tfstate"
    key                  = "sandbox/terraform.tfstate"
  }
}
```

To migrate to remote state:

```bash
cd bootstrap
terraform apply

# Then update versions.tf backend block with values from bootstrap output
cd ../environments/sandbox
terraform init  # Confirm migration
```

## Modules Used

- **naming**: Generates consistent Azure resource names
- **networking**: VNet, subnets, NSGs
- **identity**: User-assigned managed identities
- **keyvault**: Secure key management (RBAC, soft-delete, purge protection)
- **storage**: Secure storage accounts (HTTPS-only, versioning, soft-delete)
- **log-analytics**: Monitoring and logging
- **app**: App Service (placeholder for your application)

## Key Configuration Values

Update `sandbox.tfvars` with your specific values:

- `project_name`: Project identifier used for naming
- `location`: Azure region (default: eastus)
- `vnet_cidr`: Virtual network address space
- `subnet_cidr`: Subnet address space
- `tags`: Resource tags for organization and billing

## Security Best Practices Implemented

✅ HTTPS-only for storage accounts  
✅ Private endpoints for Key Vault  
✅ RBAC for access control  
✅ Soft delete and versioning enabled  
✅ Purge protection on Key Vault  
✅ User-assigned managed identities  
✅ NSGs for network segmentation  
✅ Remote state in encrypted storage

## Troubleshooting

### "Resource already exists"

Resources may exist from a previous deployment. Options:

```bash
# Import existing resources
terraform import module.networking.azurerm_virtual_network.main /subscriptions/...

# Or remove from state and re-apply
terraform state rm module.networking.azurerm_virtual_network.main
```

### "Backend not initialized"

Ensure bootstrap has completed and backend configuration is set in versions.tf:

```bash
cd bootstrap
terraform apply -var-file=sandbox.tfvars
# Copy output backend_config values
```

### State lock

```bash
# List locks
terraform force-unlock <LOCK_ID>
```

## Next Steps

1. Update `sandbox.tfvars` with your values
2. Run bootstrap to create remote state
3. Push to main branch to trigger CI/CD pipeline
4. Approve apply in GitHub Environment protection rules
