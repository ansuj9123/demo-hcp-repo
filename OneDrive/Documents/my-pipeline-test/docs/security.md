# Security Guide

Security best practices and architecture for the Terraform CI/CD pipeline.

## Overview

This pipeline implements multiple layers of security:

1. **Authentication & Authorization**: Service Principal with role-based access
2. **State Management**: Encrypted remote state in Azure Storage
3. **Infrastructure Security**: Azure best practices (HTTPS-only, encryption, RBAC)
4. **CI/CD Security**: GitHub Actions with minimal permissions, manual approvals
5. **Secret Management**: GitHub Environments for scoped secrets

## Service Principal Authentication (Temporary)

Currently, the pipeline uses Service Principal authentication with client secret. **This is temporary** and should be replaced with OIDC for production.

### Current Approach: SP + Client Secret

✅ **Pros:**

- Works immediately for testing
- No infrastructure changes needed
- Familiar authentication method

❌ **Cons:**

- Long-lived credentials that could be compromised
- Requires manual secret rotation
- Less auditable than OIDC
- Secrets stored in GitHub (even as Environment secrets)

### Temporary SP Setup

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-pipeline-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/<SUBSCRIPTION_ID>" \
  --sdk-auth > sp-credentials.json

# Contents stored in GitHub Environment secret: AZURE_CREDENTIALS
```

## Future: OIDC Authentication (Recommended)

For production, migrate to OpenID Connect (OIDC) for keyless authentication.

### OIDC Advantages

✅ **No Long-lived Secrets:**

- Subject token created per GitHub Actions run
- Token valid for 15 minutes only
- No persistent credentials stored

✅ **Better Auditing:**

- Trace actions to specific GitHub Actions runs
- Full transparency in audit logs
- Conditional access policies supported

✅ **Scalability:**

- Works across multiple repositories
- Federated trust model
- No secret rotation required

### OIDC Migration Plan

```bash
# 1. Create Federated Identity Credential
az identity federated-credential create \
  --identity-name "github-actions-identity" \
  --resource-group "rg-terraform" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:OWNER/REPO:environment:sandbox" \
  --audience "api://AzureADTokenExchange"

# 2. Update GitHub workflow to use new authentication
# Change from: secrets.AZURE_CREDENTIALS
# To: Use azure/login action with client-id, tenant-id, subscription-id (no secret!)

# 3. Test with feature branch before full migration
```

See Azure documentation for detailed OIDC setup:
https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure

## State Management Security

### Remote State Security

Terraform state contains sensitive data (resource IDs, connection strings, etc.).

**Configured Security Controls:**

✅ **Private Storage Container**

- No public access (access_type = "private")
- RBAC required to access

✅ **HTTPS Only**

- All traffic encrypted in transit
- TLS 1.2 minimum

✅ **Encryption at Rest**

- Azure Storage encryption enabled by default
- Customer-managed keys supported (future enhancement)

✅ **Access Control**

- Service Principal has Storage Blob Data Contributor role
- No shared access keys enabled
- Audit logging enabled in bootstrap

✅ **Versioning & Recovery**

- Soft delete enabled (90 days retention)
- Blob versioning enabled
- Point-in-time recovery possible

### Local State Handling

**Never commit state files to Git:**

✅ Currently configured:

- `.gitignore` excludes `*.tfstate*` files
- CI/CD always uses remote state
- No local state uploaded to repository

### State Access in CI/CD

GitHub Actions jobs access state via:

1. Azure Login action (authenticates with service principal)
2. Terraform backend initialization
3. Storage account connection via private network (future enhancement)

## Infrastructure Security

### Key Vault

✅ **Secure by Default:**

- RBAC enabled (not legacy access policies)
- Soft delete: 90 days
- Purge protection: enabled
- Managed identity access (preferred over storage account keys)

✅ **Future Enhancements:**

```hcl
# Private endpoint (restrict to VNet)
resource "azurerm_private_endpoint" "keyvault" {
  # ...
}

# Customer-managed keys for encryption
resource "azurerm_key_vault_key" "encryption" {
  # ...
}
```

### Storage Accounts

✅ **Secure by Default:**

- HTTPS only (no HTTP)
- TLS 1.2 minimum
- Public network access disabled
- Shared access keys disabled (use RBAC)
- Versioning enabled
- Soft delete enabled (30 days)

✅ **Future Enhancements:**

```hcl
# Firewall rules
network_rules {
  default_action = "Deny"
  bypass = ["AzureServices"]
}

# Private endpoint
resource "azurerm_private_endpoint" "storage" {
  # ...
}
```

### Network Security

✅ **Configured:**

- Network Security Group per subnet
- Firewall rules to be defined per application

❌ **To Add:**

- Private endpoints for Azure services
- Azure Firewall (if needed)
- Conditional access policies

## GitHub Actions Security

### Permissions

All workflows use minimal permissions principle:

```yaml
permissions:
  contents: read # Can read repo code
  pull-requests: write # Can comment on PRs
  # NO write access to main branch
  # NO access to all secrets
```

### Environment Protection

The `sandbox` environment has:

1. **Deployment protection rules**: Requires manual approval before apply
2. **Required reviewers**: Team members must approve deployments
3. **IP restrictions** (optional): Can restrict to organization IPs

### Secret Management

✅ **Best Practices:**

- Secrets stored in GitHub Environment (scoped to sandbox)
- No secret printing in logs
- Actions run in subprocess with separate secrets
- Audit logs track secret access

✅ **Rotation Plan:**

- SP client secret should be rotated quarterly
- Use Azure Key Vault for secret management (future)
- Implement automated rotation

## Scanning & Compliance

### Security Scanning Tools

**TFSec** (runs in CI):

- Detects misconfigurations in Terraform
- Checks against CIS benchmarks
- SARIF report integrated with GitHub Security tab

**Checkov** (optional):

- Infrastructure-as-code policy enforcement
- CIS compliance checks
- Custom policies supported

### Compliance Standards

Infrastructure follows:

✅ **Azure Security Baselines**

- CIS Benchmarks for Azure
- Azure Well-Architected Framework security pillar
- NIST cybersecurity framework alignment

✅ **Best Practices**

- Least privilege access (principle of)
- Defense in depth (multiple security layers)
- Encryption in transit and at rest
- Audit logging enabled

## Incident Response

### If Service Principal Secret is Compromised

1. **Immediate Actions:**

   ```bash
   # Disable compromised secret
   az ad app credential delete --id CLIENT_ID --key-id CREDENTIAL_ID

   # Create new service principal
   az ad sp create-for-rbac ...

   # Rotate GitHub secrets
   # Settings → Environments → sandbox → Update AZURE_CREDENTIALS
   ```

2. **Investigation:**
   - Review Azure Activity Logs: `az monitor activity-log list`
   - Check GitHub Actions audit log
   - List recent deployments: `terraform state list`

3. **Recovery:**
   - Re-deploy affected resources if modified
   - Verify state file integrity: `terraform validate`
   - Run security scans

### If GitHub Actions Workflow is Compromised

1. **Immediate Actions:**
   - Disable workflow: `.github/workflows/apply.yml` → disable
   - Revoke recent approvals
   - Verify recent deployments against approved PRs

2. **Investigation:**
   - Check GitHub Actions logs
   - Review Azure Activity Logs for unauthorized changes
   - Audit terraform state for unexpected resources

3. **Recovery:**
   - If infrastructure was modified, `terraform destroy` or rollback
   - Update service principal credentials
   - Review and strengthen approval process

## Monitoring & Logging

### Azure Activity Logs

All Terraform deployments are logged in Azure Activity Logs:

```bash
# View recent deployments
az monitor activity-log list \
  --max-events 20 \
  --query "[].{time:eventTimestamp, operation:operationName, user:caller}"
```

### GitHub Actions Audit Log

Track all workflow runs and approvals:

1. Go to Settings → Audit log
2. Filter by "workflow" or "environment"
3. Review approval history

### Application Insights (Future)

Add monitoring to deployed applications:

```hcl
resource "azurerm_application_insights" "app" {
  # ...
}
```

## Checklist

Before production deployment:

- [ ] ✅ Service principal least privilege verified
- [ ] ✅ GitHub Environment protection rules configured
- [ ] ✅ Deployment requires manual approval
- [ ] ✅ Audit logging enabled
- [ ] ✅ State backend secured (HTTPS, RBAC, versioning)
- [ ] ✅ Key Vault soft-delete and purge protection
- [ ] ✅ Storage accounts HTTPS-only
- [ ] ✅ Network security groups configured
- [ ] ✅ Security scanning integrated in CI
- [ ] ✅ Incident response plan documented

## Future Enhancements

1. **Keyless Authentication (OIDC)**
   - Eliminate long-lived secrets
   - Improve auditability

2. **Private Endpoints**
   - Restrict traffic to Azure services
   - Remove public internet exposure

3. **Azure Policy**
   - Enforce compliance rules
   - Prevent non-compliant deployments

4. **Secrets Rotation**
   - Automated credential rotation
   - Zero-downtime updates

5. **Advanced Threat Protection**
   - Defender for Cloud integration
   - Real-time alerts

## References

- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [Terraform State Security](https://www.terraform.io/cloud-docs/state)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
