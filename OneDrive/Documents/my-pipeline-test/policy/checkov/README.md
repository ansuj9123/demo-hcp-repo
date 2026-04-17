# Checkov Policies

Checkov is an infrastructure-as-code scanning tool for policy enforcement and compliance checks.

## Configuration

Checkov configuration and policies can be customized for specific compliance requirements.

## Key Capabilities

- Framework checks: Terraform, Kubernetes, CloudFormation, etc.
- CIS Benchmarks compliance
- Security best practices
- Custom policies support

## Running Locally

```bash
# Install Checkov
pip install checkov

# Run security scan
checkov --directory infra/ --framework terraform --format json --output-file checkov-report.json

# View results
checkov --directory infra/ --framework terraform --compact
```

## Custom Policies

Place custom Checkov policies in this directory to extend default checks.

## References

- [Checkov Documentation](https://www.checkov.io/)
- [Bridgecrew Policies](https://www.bridgecrew.cloud/)
