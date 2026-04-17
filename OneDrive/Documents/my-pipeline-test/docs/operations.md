# Operations Guide

Operational procedures for managing the Terraform CI/CD pipeline.

## Table of Contents

1. [Viewing Infrastructure](#viewing-infrastructure)
2. [Common Operations](#common-operations)
3. [State Management](#state-management)
4. [Troubleshooting](#troubleshooting)
5. [Disaster Recovery](#disaster-recovery)
6. [Scaling](#scaling)

## Viewing Infrastructure

### Via Terraform

```bash
cd infra/environments/sandbox

# Show all resources
terraform state list

# Show specific resource details
terraform state show azurerm_resource_group.main

# Show all outputs
terraform output

# Show specific output
terraform output resource_group_name
```

### Via Azure CLI

```bash
# List resource groups
az group list --query "[].{name:name, location:location}" -o table

# List all resources in group
az resource list --resource-group "rg-snd-myapp" -o table

# List specific resource types
az keyvault list -o table
az storage account list --query "[].{name:name, kind:kind}" -o table
```

### Via Azure Portal

1. Login to https://portal.azure.com
2. Search for resource group: "rg-snd-myapp"
3. View all resources in group
4. Click individual resources for details

## Common Operations

### Adding a New Resource

1. **Define in Terraform module:**

```hcl
# infra/modules/example/main.tf
resource "azurerm_example" "main" {
  name                = var.example_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

output "id" {
  value = azurerm_example.main.id
}
```

2. **Use in environment:**

```hcl
# infra/environments/sandbox/main.tf
module "example" {
  source = "../../modules/example"

  example_name        = "example-name"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}
```

3. **Deploy via PR:**

```bash
git checkout -b feature/add-example-resource
# ... make changes ...
git commit -am "feat: add example resource"
git push origin feature/add-example-resource
```

4. **Create PR and approve:**
   - GitHub Actions runs CI checks
   - Review plan output
   - Merge PR
   - Apply workflow runs autonomously
   - Approve deployment in GitHub

### Modifying Existing Resources

1. **Update resource definition:**

```hcl
resource "azurerm_key_vault" "main" {
  # ... existing config ...
  soft_delete_retention_days = 60  # Changed from 90
}
```

2. **Plan changes:**

```bash
cd infra/environments/sandbox
terraform plan -var-file=sandbox.tfvars
```

3. **Review output:**
   - `~` means resource will be modified
   - `-/+` means resource will be destroyed and recreated
   - `+` means resource will be created

4. **Deploy via PR** (same as above)

### Scaling Infrastructure

To add new environment (e.g., staging):

```bash
# 1. Copy sandbox to staging
cp -r infra/environments/sandbox infra/environments/staging

# 2. Update staging.tfvars
nano infra/environments/staging/staging.tfvars

# 3. Create GitHub Environment
# Settings → Environments → New: "staging"
# Add secrets (same AZURE_CREDENTIALS or use different SP)

# 4. Update workflows to support staging
# .github/workflows/apply.yml → add staging job

# 5. Deploy
git checkout -b feature/add-staging-environment
git add infra/environments/staging
git commit -m "feat: add staging environment"
git push origin feature/add-staging-environment
```

## State Management

### Understanding Terraform State

State file contains current infrastructure configuration. Critical for Terraform to work correctly.

```bash
# View state (JSON format)
terraform state pull | jq '.'

# View resource in state
terraform state show azurerm_resource_group.main

# List all resources in state
terraform state list

# Remove resource from state (dangerous!)
terraform state rm module.storage.azurerm_storage_account.main
```

### State Backup

State is automatically backed up in Azure Storage:

```bash
# View state file versions
az storage blob list \
  --account-name "st<random>tfstate" \
  --container-name "tfstate" \
  --query "[].[name,properties.contentLength]" -o table

# Download specific state version
az storage blob download \
  --account-name "st<random>tfstate" \
  --container-name "tfstate" \
  --name "sandbox/terraform.tfstate" \
  --file terraform_backup.tfstate
```

### State Recovery

If state is corrupted or lost:

```bash
# 1. List backup versions
az storage blob list-versions \
  --account-name "st<random>tfstate" \
  --container-name "tfstate" \
  --name "sandbox/terraform.tfstate" \
  -o table

# 2. Restore from backup
az storage blob copy start \
  --account-name "st<random>tfstate" \
  --container-name "tfstate" \
  --source-blob "sandbox/terraform.tfstate" \
  --source-container "tfstate" \
  --destination-blob "sandbox/terraform.tfstate.recovered"

# 3. Review recovery
terraform state pull < terraform_recovered.tfstate

# 4. Apply recovery (careful!)
# Restore file and manually review before applying
```

### Importing Existing Resources

If resources exist outside Terraform (manual creation):

```bash
# 1. Find resource ID
az resource list --query "[?name=='existing-resource'].id" -o tsv

# 2. Import to state
terraform import azurerm_storage_account.main \
  /subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Storage/storageAccounts/<NAME>

# 3. Define resource in Terraform
# Update main.tf with resource definition

# 4. Verify import
terraform plan  # Should show no changes
```

## Troubleshooting

### Common Issues

#### Issue: "Resource already exists"

```
Error: creating Storage Account: storageaccounts.StorageAccountsClient#CreateOrUpdate:
Failure sending request: StatusCode=409 --->
Failure responding with status code: 409 (Conflict)
```

**Causes:**

- Resource created manually outside Terraform
- Previous deployment partially applied
- Name already exists globally (e.g., storage account)

**Solutions:**

```bash
# Option 1: Import existing resource
terraform import azurerm_storage_account.main <RESOURCE_ID>

# Option 2: Destroy and recreate (if safe)
terraform destroy -var-file=sandbox.tfvars
terraform apply -var-file=sandbox.tfvars

# Option 3: Manually delete in Azure Portal and re-apply
az resource delete --ids <RESOURCE_ID>
terraform apply -var-file=sandbox.tfvars
```

#### Issue: "State is locked"

```
Error acquiring the state lock: error acquiring the lock:
Error getting metadata for blob "tfstate": Lease already in progress
```

**Cause:** Another Terraform operation is running or previous operation crashed.

**Solution:**

```bash
# Wait for operation to complete (usually a few minutes)
# Or force unlock (use with caution):
terraform force-unlock <LOCK_ID>

# Check lock ID from error message or:
az storage blob show \
  --account-name "st<random>tfstate" \
  --container-name "tfstate" \
  --name "sandbox/terraform.tfstate" \
  --query "properties.lease"
```

#### Issue: "Authentication failed"

```
Error: Error acquiring Azure access token for service principal credentials
```

**Causes:**

- Service principal credentials expired or rotated
- Network connectivity issue
- Azure subscription access revoked

**Solutions:**

```bash
# Verify SP credentials (local)
az login --service-principal \
  -u $(jq -r '.clientId' sp-credentials.json) \
  -p $(jq -r '.clientSecret' sp-credentials.json) \
  --tenant $(jq -r '.tenantId' sp-credentials.json)

# Verify SP has correct role in Azure
az role assignment list --assignee $(jq -r '.clientId' sp-credentials.json)

# Check GitHub secret is correct
# Settings → Environments → sandbox → AZURE_CREDENTIALS

# Verify firewall/network connectivity
az account show  # Should succeed if authenticated
```

#### Issue: "Drift detection found changes"

Infrastructure actual state doesn't match Terraform configuration.

**Causes:**

- Manual changes in Azure Portal
- Resource auto-scaling or updates
- Other automation (e.g., Azure Policies)
- Terraform code changes not yet applied

**Resolution:**

```bash
# Option 1: Refresh state without changes
terraform refresh -var-file=sandbox.tfvars
terraform plan -var-file=sandbox.tfvars  # Should show no changes

# Option 2: Update Terraform to match actual state
# Edit main.tf or variables
# Review changes
terraform plan -var-file=sandbox.tfvars

# Option 3: Reconcile actual state with Terraform
# Determine whether:
# - Terraform should be updated to match Azure
# - Azure should be updated to match Terraform
# Apply accordingly
```

### Getting Help

1. **Check logs:**
   - GitHub Actions: Actions tab → workflow → job logs
   - Azure: Activity Logs → recent events
   - Terraform: `TF_LOG=DEBUG terraform plan`

2. **Enable debug logging:**

   ```bash
   export TF_LOG=DEBUG
   terraform plan -var-file=sandbox.tfvars
   ```

3. **Validate configuration:**

   ```bash
   terraform init -backend=false
   terraform validate
   terraform fmt -check
   ```

4. **Check resource state:**
   ```bash
   terraform state show azurerm_resource_group.main
   az resource show --ids <RESOURCE_ID>
   ```

## Disaster Recovery

### Scenario: Accidental Resource Deletion

```bash
# 1. Identify deleted resource
terraform state list  # See what's in state
terraform plan  # Will show resource needs to be recreated

# 2. Option A: Restore from state backup
terraform state pull > current_state.json
# Review and restore from backup

# 3. Option B: Re-apply
terraform apply -var-file=sandbox.tfvars  # Will recreate

# 4. Verify recovery
terraform state show <RESOURCE>
az resource list --resource-group <RG>
```

### Scenario: Incorrect Configuration Applied

```bash
# 1. Identify problem
terraform plan -var-file=sandbox.tfvars  # Shows what's different

# 2. Fix in code
nano infra/environments/sandbox/main.tf  # Fix the issue

# 3. Apply corrected configuration
terraform plan -var-file=sandbox.tfvars
terraform apply -var-file=sandbox.tfvars
```

### Scenario: Need to Rollback Entire Environment

```bash
# 1. Identify target state (commit hash)
git log --oneline  | head -20

# 2. Check out previous state
git show <COMMIT_HASH>:infra/environments/sandbox/main.tf

# 3. Verify what will change
terraform plan -var-file=sandbox.tfvars

# 4. Apply previous state
# Update code to previous version
git checkout <COMMIT_HASH> -- infra/
terraform apply -var-file=sandbox.tfvars
```

## Monitoring & Alerts

### Viewing Costs

```bash
# Azure cost analysis
az costmanagement query create-or-update \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query-parameters ...

# Or via Azure Portal:
# Cost Management + Billing → Cost analysis
```

### Setting Up Alerts

Useful alerts for sandboxquality monitoring:

1. **Budget alerts** (prevent cost surprises)
2. **Failed deployments** (GitHub Actions notifications)
3. **Resource health** (Azure alerts)

### Log Analytics Queries

```kusto
// Recent deployments
AzureActivity
| where OperationName contains "DeploymentOperations"
| project TimeGenerated, OperationName, Caller, Status
| order by TimeGenerated desc

// Failed operations
AzureActivity
| where Status == "Failed"
| project TimeGenerated, OperationName, ResourceGroup
| order by TimeGenerated desc
```

## Best Practices

✅ **Always use pull requests** for infrastructure changes  
✅ **Review plan output** before approving apply  
✅ **Schedule deployments** during business hours when possible  
✅ **Monitor audited logs** after each deployment  
✅ **Keep bootstrap applied** (prevent state loss)  
✅ **Regularly backup state** (done automatically via versioning)  
✅ **Document manual changes** (for auditability)  
✅ **Test in sandbox first** before promoting to other environments

## References

- [Terraform State Management](https://www.terraform.io/language/state)
- [Azure Resource Manager Reference](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/guides)
