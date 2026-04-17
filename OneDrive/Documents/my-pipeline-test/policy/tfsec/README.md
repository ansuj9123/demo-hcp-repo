# TFSec Policies

TFSec scans Terraform code for security issues and compliance violations.

## Configuration

TFSec runs as part of the CI pipeline. Configuration can be customized in `.tfsec` directory.

## Key Checks

- **Azure Storage**: HTTPS-only, encryption, private endpoints
- **Key Vault**: Soft delete, purge protection, RBAC
- **Virtual Networks**: NSG rules, private endpoints
- **Identity**: RBAC assignments, managed identities
- **Encryption**: TLS versions, encryption at rest/transit

## Running Locally

```bash
# Install TFSec
brew install tfsec  # macOS
choco install tfsec  # Windows
# or download from: https://github.com/aquasecurity/tfsec

# Run scan
tfsec infra/ bootstrap/ -f json > tfsec-report.json

# View HTML report
tfsec infra/ bootstrap/ -f sarif > tfsec-report.sarif
```

## Suppressing Checks

Add comments to Terraform files to suppress specific TFSec checks:

```hcl
# tfsec:skip=AVD-AZU-001
resource "azurerm_storage_account" "example" {
  # ...
}
```

## References

- [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
- [Azure Security Recommendations](https://docs.microsoft.com/en-us/azure/security/)
