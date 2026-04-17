# Azure Infrastructure CI/CD Pipeline

Production-style Infrastructure-as-Code pipeline using Terraform, GitHub Actions, and Azure.

## 🎯 Features

- **Terraform IaC**: Modular, reusable infrastructure components
- **GitHub Actions CI/CD**: Automated testing, planning, and deployment
- **Manual Approval Gates**: Environment-based deployment protection
- **Security-First**: TFSec scanning, RBAC, encryption, soft-delete enabled
- **Remote State**: Secure, versioned state management in Azure Storage
- **Drift Detection**: Scheduled scans to catch infrastructure drift
- **Single Environment**: Sandbox for development/testing (scales to multiple environments)

## 🏗️ Architecture

```
GitHub Repository
├── Pull Request
│   ├── CI Checks (fmt, validate, lint, security scan)
│   ├── Terraform Plan
│   ├── PR Comment with Summary
│   └── Review & Merge
├── Main Branch (Merged PR)
│   ├── Plan Workflow Runs
│   ├── Apply Workflow Waits for Approval
│   └── Manual Approval in GitHub Environment
└── Apply Executes
    └── Infrastructure Updated in Azure
```

## 📋 Prerequisites

- GitHub account with repository access
- Azure subscription (Owner/Contributor role)
- Local machine with bash/shell
- Basic knowledge of Terraform and Azure

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone repository
git clone <repo-url>
cd my-pipeline-test

# Install tools
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh

# Login to Azure
az login
```

### 2. Create Service Principal

```bash
# Create SP for GitHub Actions
az ad sp create-for-rbac \
  --name "github-pipeline-sp" \
  --role "Contributor" \
  --sdk-auth > sp-credentials.json

# Save sp-credentials.json content for GitHub (next step)
```

### 3. Configure GitHub

1. Go to repository **Settings → Environments**
2. Create environment named: **sandbox**
3. Add secret **AZURE_CREDENTIALS** (paste entire sp-credentials.json)
4. Set "Deployment protection rules" → "Require reviewers" (yourself or team)

### 4. Deploy Infrastructure

```bash
# Create feature branch
git checkout -b feature/bootstrap

# Update configuration
nano bootstrap/sandbox.tfvars        # Set IDs and unique storage name
nano infra/environments/sandbox/sandbox.tfvars  # Set location, etc.

# Commit and push
git add bootstrap/ infra/environments/sandbox/
git commit -m "feat: configure bootstrap and sandbox"
git push origin feature/bootstrap

# Create PR → Merge when CI passes

# After merge: Go to Actions tab → Approve "Apply" workflow
```

Infrastructure deployed! 🎉

## 📁 Repository Structure

```
.
├── .github/
│   ├── CODEOWNERS               # Code ownership
│   ├── dependabot.yml           # Dependency updates
│   └── workflows/
│       ├── ci.yml               # PR checks
│       ├── plan.yml             # Terraform plan
│       ├── apply.yml            # Terraform apply (requires approval)
│       ├── drift.yml            # Scheduled drift detection
│       └── reusable-terraform.yml  # Shared workflow
│
├── bootstrap/                   # Remote state backend setup
│   ├── README.md
│   ├── main.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── sandbox.tfvars
│
├── infra/
│   ├── README.md
│   ├── globals/                 # Shared configuration
│   │   ├── versions.tf
│   │   ├── providers.tf
│   │   ├── locals.tf
│   │   └── variables.tf
│   ├── modules/                 # Reusable components
│   │   ├── naming/
│   │   ├── networking/
│   │   ├── identity/
│   │   ├── keyvault/
│   │   ├── storage/
│   │   ├── log-analytics/
│   │   └── app/
│   └── environments/
│       └── sandbox/             # Sandbox environment (add staging, prod, etc.)
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── sandbox.tfvars
│
├── policy/                      # Security scanning
│   ├── tfsec/
│   ├── checkov/
│   └── README.md
│
├── scripts/
│   ├── install-tools.sh         # Install local dependencies
│   └── terraform-wrapper.sh     # Local development helper
│
├── docs/
│   ├── setup.md                 # Setup instructions
│   ├── security.md              # Security best practices
│   └── operations.md            # Operational procedures
│
├── .editorconfig                # Editor settings
├── .gitignore                   # Git ignore rules
├── Makefile                     # Useful commands
└── README.md                    # This file
```

## 🔄 Workflows

### CI Workflow (PR Checks)

Triggered on pull request to `main` or `develop`.

**Steps:**

1. Terraform format check (`terraform fmt -check`)
2. Terraform validation (`terraform validate`)
3. TFLint linting (`tflint`)
4. TFSec security scan (`tfsec`)
5. Terraform plan (no apply)

**Status:** Must pass before merge

### Plan Workflow (PR Summary)

Triggered on pull request.

**Steps:**

1. Authenticate to Azure
2. Run `terraform plan`
3. Comment on PR with plan summary

**Output:** PR comment with resource changes

### Apply Workflow (Deployment)

Triggered on push to `main` or `develop`.

**Steps:**

1. Run `terraform plan`
2. **WAIT**: Requires manual approval in GitHub Environment
3. After approval: `terraform apply`
4. Regular applies run without approval (first run must be approved)

**Protection:** Environment "sandbox" has "Required reviewers" setting

### Drift Workflow (Scheduled)

Runs nightly and on manual trigger.

**Steps:**

1. Authenticate to Azure
2. Run `terraform refresh` and `terraform plan`
3. If drift detected: Create GitHub Issue
4. If no drift: Close existing drift issues

**Output:** Issue tracking infrastructure drift

## 📚 Documentation

- **[Setup Guide](docs/setup.md)** - Getting started from zero
- **[Security Guide](docs/security.md)** - Architecture, authentication, best practices
- **[Operations Guide](docs/operations.md)** - Managing infrastructure, troubleshooting

## 🔒 Security Features

✅ **Authentication**

- Service Principal with client secret (temporary)
- Scoped to single Azure subscription
- Rotatable credentials

✅ **Authorization**

- GitHub Environment protection with required approvers
- RBAC for deployed resources
- Least privilege IAM roles

✅ **Infrastructure**

- HTTPS-only storage accounts
- Key Vault soft-delete + purge protection
- Network Security Groups per subnet
- Managed identities for service authentication

✅ **State**

- Remote backend in Azure Storage (private container)
- Versioning and soft-delete enabled
- RBAC-based access control
- HTTPS encrypted in transit

✅ **CI/CD**

- Minimal GitHub Actions permissions
- Manual approval gates for production changes
- Secret scanning in workflows
- Dependency vulnerability scanning (Dependabot)

## 🪜 Commands

Use the Makefile for common operations:

```bash
make help           # Show all commands
make install        # Install tools
make check          # Check tools and authentication
make fmt            # Format Terraform files
make validate       # Validate Terraform
make lint           # Run TFLint
make scan           # Security scan
make init           # Initialize Terraform
make plan           # Plan sandbox
make apply          # Apply sandbox (requires approval)
make destroy        # Destroy sandbox (interactive)
make wrapper-help   # Show wrapper script commands
```

Or use scripts directly:

```bash
./scripts/terraform-wrapper.sh check
./scripts/terraform-wrapper.sh full-check
./scripts/terraform-wrapper.sh plan
```

## 🔄 CI/CD Flow

### For Infrastructure Changes

```
1. Create feature branch
   git checkout -b feature/add-storage

2. Update Terraform code
   nano infra/environments/sandbox/main.tf

3. Commit and push
   git add -A
   git commit -m "feat: add storage module"
   git push origin feature/add-storage

4. Create Pull Request on GitHub
   - CI workflows run automatically
   - Plan is posted as PR comment
   - Review plan and approve

5. Merge PR to main
   - Plan workflow runs
   - Apply workflow waits for approval

6. Approve Deployment
   - Go to Actions tab → Apply workflow
   - Click "Review deployments"
   - Approve "sandbox" environment
   - Apply proceeds automatically

7. Verify
   - Check Actions logs
   - View outputs: terraform output
```

## 📊 Supported Azure Resources

Pre-configured modules for:

- **Naming** - Consistent resource naming
- **Networking** - VNets, subnets, NSGs
- **Identity** - User-assigned managed identities
- **Key Vault** - Secure secret management
- **Storage** - Secure blob storage
- **Log Analytics** - Monitoring and logging
- **App Service** - Web application hosting

Extend by creating new modules in `infra/modules/`

## 🚀 Scaling to Multiple Environments

To add a new environment (e.g., staging):

```bash
# Copy sandbox to staging
cp -r infra/environments/sandbox infra/environments/staging

# Update configuration
nano infra/environments/staging/staging.tfvars

# Update workflows to support staging
# (add staging job to apply.yml)

# Create GitHub Environment "staging" with secrets
# Settings → Environments → staging

# Deploy
git add infra/environments/staging
git commit -m "feat: add staging environment"
git push origin feature/add-staging-environment
```

## 🐛 Troubleshooting

### PR checks failing?

1. **Format errors**: `make fmt`
2. **Validation errors**: `make validate`
3. **Lint errors**: `make lint`
4. **Security issues**: Check TFSec output in GitHub

### Apply workflow failing?

1. Check Actions logs for error
2. Verify Azure credentials in GitHub Environment secrets
3. Ensure service principal has correct roles
4. Run locally: `terraform plan -var-file=sandbox.tfvars`

### Need help?

1. Review [Operations Guide](docs/operations.md)
2. Check [Security Guide](docs/security.md)
3. See docs/ directory for detailed guides
4. Review GitHub Actions logs (Actions tab)

## 🔄 Future Enhancements

- [ ] Switch to OIDC authentication (eliminate secrets)
- [ ] Add staging and production environments
- [ ] Implement cost controls and alerts
- [ ] Add pre-commit hooks for local validation
- [ ] Integrate with Azure Monitor for alerting
- [ ] Add backup and disaster recovery procedures
- [ ] Implement GitOps with sealed secrets

## 📝 Best Practices Implemented

✅ Modular Terraform code (DRY principle)  
✅ Automated testing and scanning  
✅ Manual approval gates for destructive changes  
✅ Environment isolation (separate state per environment)  
✅ Security by default (HTTPS, encryption, RBAC)  
✅ Infrastructure as Code (version controlled, auditable)  
✅ Drift detection (scheduled compliance checks)  
✅ Comprehensive documentation

## 📖 References

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Provider Reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Workflows](https://docs.github.com/en/actions)
- [Azure Best Practices](https://docs.microsoft.com/en-us/azure/architecture/framework/)

## 📄 License

[Add your license here]

## 🤝 Contributing

[Add contribution guidelines here]

## 💬 Support

For issues or questions:

1. Check documentation in `docs/`
2. Review GitHub Issues
3. Open a new issue with detailed context

---

**Happy infrastructure coding! 🚀**
# Test
