# Setup Guide

Complete setup instructions for the Terraform CI/CD pipeline.

## Prerequisites

- GitHub account with repository access
- Azure subscription with Owner or Contributor role
- Local tools: bash, git, curl (for downloading tools)

## Table of Contents

1. [Local Setup](#local-setup)
2. [Azure Setup](#azure-setup)
3. [GitHub Setup](#github-setup)
4. [Bootstrap Infrastructure](#bootstrap-infrastructure)
5. [First Deployment](#first-deployment)

## Local Setup

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd my-pipeline-test
```

### 2. Install Tools

```bash
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

This installs:

- Terraform v1.6.0+
- Azure CLI
- TFLint (linting)
- TFSec (security scanning)
- jq (JSON processor)

### 3. Verify Installation

```bash
terraform --version
az --version
tflint --version
tfsec --version
```

## Azure Setup

### 1. Login to Azure

```bash
az login

# List available subscriptions
az account list --output table

# Set default subscription
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 2. Create Service Principal for CI/CD

The service principal authenticates GitHub Actions to Azure.

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-pipeline-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)" \
  --sdk-auth > sp-credentials.json

# Display credentials (important for GitHub setup)
cat sp-credentials.json
```

**Important:** Keep `sp-credentials.json` safe. This file contains sensitive credentials.

### 3. Verify Service Principal

```bash
# Get object ID of service principal (needed for bootstrap)
az ad sp show --id "$(jq -r '.clientId' sp-credentials.json)" --query id -o tsv
```

## GitHub Setup

### 1. Create GitHub Environment

1. Go to repository settings → Environments
2. Click "New environment"
3. Name it exactly: **sandbox**
4. Click "Create environment"

### 2. Add Environment Secrets

In the "sandbox" environment, add these secrets:

1. **AZURE_CREDENTIALS**
   - Copy entire contents of `sp-credentials.json` from Azure setup
   - Click "Add secret"

Alternative: Add individual variables instead of AZURE_CREDENTIALS:

```
AZURE_CLIENT_ID: from JSON clientId
AZURE_CLIENT_SECRET: from JSON clientSecret (⚠️ rotate regularly)
AZURE_TENANT_ID: from JSON tenantId
AZURE_SUBSCRIPTION_ID: from JSON subscriptionId
```

### 3. Configure Deployment Protection

In the "sandbox" environment:

1. Click "Deployment branches"
2. Select "Protected branches"
3. Check "Require reviewers"
4. Add required reviewers (yourself or team)
5. Save protection rules

This ensures that `terraform apply` in the apply workflow requires human approval.

### 4. Update Repository Secrets (if using shared values)

Go to Settings → Secrets and variables → Actions

(Optional: Store non-sensitive values here)

## Bootstrap Infrastructure

The bootstrap creates the remote state backend in Azure Storage.

### 1. Update Bootstrap Variables

Edit `bootstrap/sandbox.tfvars`:

```hcl
azure_subscription_id = "YOUR_SUBSCRIPTION_ID"
azure_tenant_id       = "YOUR_TENANT_ID"
storage_account_name  = "stXXXXXXXXtfstate"  # Change XXXXXXXX to unique identifier
service_principal_object_id = "OPTIONAL_SP_OBJECT_ID"
```

### 2. Deploy Bootstrap

```bash
cd bootstrap

# Initialize (uses local state)
terraform init -backend=false

# Review plan
terraform plan -var-file=sandbox.tfvars

# Apply bootstrap resources
terraform apply -var-file=sandbox.tfvars

# Output backend configuration
terraform output backend_config
```

### 3. Configure Remote State

After bootstrap succeeds, migrate to remote state:

```bash
# 1. Copy backend_config output values
# 2. Edit infra/environments/sandbox/versions.tf
# 3. Uncomment and update backend block with values from step 1

# 4. Re-initialize with remote backend
cd ../infra/environments/sandbox
terraform init
# When prompted, confirm migration of state

# Verify state is now remote
terraform state list
```

## First Deployment

### Option A: Deploy via GitHub Actions (Recommended)

```bash
# 1. Update infra/environments/sandbox/sandbox.tfvars with your values
# 2. Push to feature branch
git checkout -b feature/initial-deployment
git add -A
git commit -m "feat: initial infrastructure deployment"
git push origin feature/initial-deployment

# 3. Create pull request
# - GitHub Actions will run CI checks automatically
# - Review plan output in PR comment

# 4. Merge PR to main
# - Plan workflow runs on merge
# - Apply workflow triggers and waits for approval

# 5. Approve apply in GitHub
# - Go to Actions tab
# - Find Apply workflow run
# - Click "Review deployments"
# - Approve sandbox environment
# - Apply will proceed automatically
```

### Option B: Deploy Locally (Development)

```bash
cd infra/environments/sandbox

# Configure values
nano sandbox.tfvars  # Update with your values

# Initialize with remote backend
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=<from-bootstrap>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=sandbox/terraform.tfstate"

# Plan
terraform plan -var-file=sandbox.tfvars -out=tfplan.bin

# Apply
terraform apply tfplan.bin

# View outputs
terraform output
```

## Verification

After deployment, verify infrastructure:

```bash
# Using Terraform
terraform output

# Using Azure CLI
az group list --query "[].name" -o table
az keyvault list --query "[].name" -o table
az storage account list --query "[].name" -o table
```

## Troubleshooting

### "Service principal not authorized"

Verify service principal has correct role:

```bash
az role assignment list --assignee $(jq -r '.clientId' sp-credentials.json)
```

### "Storage account name already taken"

Storage account names are globally unique. Update `bootstrap/sandbox.tfvars`:

```hcl
storage_account_name = "stXXXXXXXXXtfstate"  # Add more unique chars
```

### "State already exists in remote backend"

If migrating existing state:

```bash
cd bootstrap
terraform state rm azurerm_storage_container.tfstate
# Then re-apply bootstrap
```

### "GitHub Actions workflow failed"

Check workflow logs:

1. Go to Actions tab
2. Find failed workflow
3. Expand job logs
4. Check error messages

Common issues:

- ❌ Authentication failed: Verify AZURE_CREDENTIALS secret
- ❌ Backend not found: Ensure bootstrap completed
- ❌ Resource exists: Resources may exist from previous deployment

## Next Steps

1. ✅ Review [Security Guide](security.md)
2. ✅ Review [Operations Guide](operations.md)
3. ✅ Scale to additional environments (staging, production)
4. ✅ Implement OIDC authentication (replace SP secrets)
5. ✅ Set up monitoring and alerting

## Support

For issues or questions:

1. Check troubleshooting section above
2. Review GitHub Actions logs
3. Consult Terraform and Azure documentation
4. Open GitHub issue for bugs
