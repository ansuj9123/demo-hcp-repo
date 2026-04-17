# Security and Policy Scanning

This directory contains security and policy scanning configurations for infrastructure validation.

## Tools

### TFSec

Static analysis tool for detecting security misconfigurations in Terraform code.

- Runs in CI pipeline during PR checks
- Checks for Azure security best practices
- Generates SARIF reports for GitHub integration

### Checkov

Infrastructure-as-code scanning and compliance enforcement.

- Policy-as-code for infrastructure validation
- CIS Benchmarks compliance checking
- Custom policy support

## Integration

Security scans run automatically on:

- **Pull Requests**: CI workflow runs TFSec scans
- **Pre-commit**: Use git hooks to run locally (optional)
- **SLSA Framework**: Attestation and provenance tracking (future enhancement)

## Configuration Files

- `.tfsec/`: TFSec configuration and rules
- `checkov/`: Checkov policies and custom rules

## Running Scans Locally

```bash
# TFSec
tfsec infra/ bootstrap/ -f json

# Checkov
checkov --directory infra/ --framework terraform
```

## Compliance Standards

Infrastructure follows:

- ✅ Azure Security Benchmarks
- ✅ CIS Kubernetes Benchmarks (where applicable)
- ✅ Azure Well-Architected Framework
- ✅ Least privilege access patterns
- ✅ HTTPS and encryption enforcement

## Remediation

When security issues are found:

1. Review the scan report for details
2. Update Terraform code to address findings
3. Add suppressions only when issues are accepted risks (documented)
4. Re-run scans to verify resolution
