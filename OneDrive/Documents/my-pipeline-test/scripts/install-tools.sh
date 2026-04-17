#!/usr/bin/env bash
# install-tools.sh
# Installs required tools for local Terraform development and CI/CD

set -e

echo "🔧 Installing development tools..."

# Detect OS
OS_TYPE=$(uname -s)

# Install Terraform
echo "Installing Terraform..."
if command -v terraform &> /dev/null; then
    echo "✅ Terraform is already installed: $(terraform version | head -1)"
else
    if [ "$OS_TYPE" == "Darwin" ]; then
        brew install terraform
    elif [ "$OS_TYPE" == "Linux" ]; then
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
        sudo apt-get update && sudo apt-get install terraform
    else
        echo "⚠️  Manual installation required for $OS_TYPE"
        echo "   Visit: https://www.terraform.io/downloads.html"
    fi
fi

# Install Azure CLI
echo "Installing Azure CLI..."
if command -v az &> /dev/null; then
    echo "✅ Azure CLI is already installed: $(az --version | head -1)"
else
    if [ "$OS_TYPE" == "Darwin" ]; then
        brew install azure-cli
    elif [ "$OS_TYPE" == "Linux" ]; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        echo "⚠️  Manual installation required for $OS_TYPE"
        echo "   Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    fi
fi

# Install TFLint
echo "Installing TFLint..."
if command -v tflint &> /dev/null; then
    echo "✅ TFLint is already installed: $(tflint --version)"
else
    if [ "$OS_TYPE" == "Darwin" ]; then
        brew install tflint
    elif [ "$OS_TYPE" == "Linux" ]; then
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi
fi

# Install TFSec
echo "Installing TFSec..."
if command -v tfsec &> /dev/null; then
    echo "✅ TFSec is already installed: $(tfsec --version)"
else
    if [ "$OS_TYPE" == "Darwin" ]; then
        brew install tfsec
    elif [ "$OS_TYPE" == "Linux" ]; then
        curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
    fi
fi

# Install jq (JSON processor)
echo "Installing jq..."
if command -v jq &> /dev/null; then
    echo "✅ jq is already installed: $(jq --version)"
else
    if [ "$OS_TYPE" == "Darwin" ]; then
        brew install jq
    elif [ "$OS_TYPE" == "Linux" ]; then
        sudo apt-get install -y jq
    fi
fi

# Install pre-commit (optional but recommended)
echo "Installing pre-commit..."
if command -v pre-commit &> /dev/null; then
    echo "✅ pre-commit is already installed: $(pre-commit --version)"
else
    if [ "$OS_TYPE" == "Darwin" ] || [ "$OS_TYPE" == "Linux" ]; then
        pip install pre-commit
    fi
fi

echo ""
echo "✅ All tools installed successfully!"
echo ""
echo "🔍 Installed versions:"
terraform -version | head -1
az --version | head -1
tflint --version
tfsec --version
echo "jq: $(jq --version)"
echo ""
echo "📚 Next steps:"
echo "1. Configure Azure authentication: az login"
echo "2. Set default subscription: az account set --subscription <SUBSCRIPTION_ID>"
echo "3. Review bootstrap/README.md for first-time setup"
echo "4. Run: make help (to see available commands)"
