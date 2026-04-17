#!/usr/bin/env bash
# terraform-wrapper.sh
# Wrapper script for local Terraform operations with validation and best practices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}"
}

check_tools() {
    local required_tools=("terraform" "az" "tflint" "tfsec" "jq")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool not found. Run: ./scripts/install-tools.sh"
            exit 1
        fi
    done
    
    log_success "All required tools found"
}

check_authentication() {
    if ! az account show &> /dev/null; then
        log_error "Not authenticated with Azure. Run: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query 'name' -o tsv)
    log_success "Authenticated to Azure subscription: $subscription"
}

format_terraform() {
    local dirs=("$@")
    
    log_info "Formatting Terraform files..."
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            terraform -chdir="$dir" fmt -recursive
            log_success "Formatted: $dir"
        fi
    done
}

validate_terraform() {
    local dirs=("$@")
    
    log_info "Validating Terraform configuration..."
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            pushd "$dir" > /dev/null
            terraform init -backend=false
            terraform validate
            popd > /dev/null
            log_success "Validated: $dir"
        fi
    done
}

lint_terraform() {
    local dirs=("$@")
    
    log_info "Linting Terraform files with TFLint..."
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            pushd "$dir" > /dev/null
            tflint --init || true
            tflint --format compact || true
            popd > /dev/null
            log_success "Linted: $dir"
        fi
    done
}

scan_security() {
    local dirs=("$@")
    
    log_info "Scanning for security issues with TFSec..."
    tfsec "${dirs[@]}" --format pretty || true
    log_success "Security scan complete"
}

init_environments() {
    log_info "Initializing Terraform environments..."
    
    # Bootstrap
    pushd "$PROJECT_ROOT/bootstrap" > /dev/null
    terraform init -backend=false
    log_success "Initialized: bootstrap"
    popd > /dev/null
    
    # Sandbox environment
    pushd "$PROJECT_ROOT/infra/environments/sandbox" > /dev/null
    terraform init -backend=false
    log_success "Initialized: sandbox environment"
    popd > /dev/null
}

plan_sandbox() {
    log_info "Planning Terraform for sandbox environment..."
    
    pushd "$PROJECT_ROOT/infra/environments/sandbox" > /dev/null
    terraform plan -var-file=sandbox.tfvars -out=tfplan.bin
    popd > /dev/null
    
    log_success "Plan complete: tfplan.bin"
}

apply_sandbox() {
    log_info "Applying Terraform for sandbox environment..."
    
    pushd "$PROJECT_ROOT/infra/environments/sandbox" > /dev/null
    
    if [ ! -f tfplan.bin ]; then
        log_error "No plan found. Run: $0 plan first"
        exit 1
    fi
    
    terraform apply -no-color tfplan.bin
    popd > /dev/null
    
    log_success "Apply complete"
}

destroy_sandbox() {
    log_warn "Destroying sandbox infrastructure..."
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Destroy cancelled"
        exit 0
    fi
    
    pushd "$PROJECT_ROOT/infra/environments/sandbox" > /dev/null
    terraform destroy -var-file=sandbox.tfvars
    popd > /dev/null
    
    log_success "Destroy complete"
}

output_values() {
    log_info "Terraform outputs for sandbox..."
    
    pushd "$PROJECT_ROOT/infra/environments/sandbox" > /dev/null
    terraform output
    popd > /dev/null
}

show_help() {
    cat << EOF
Terraform Wrapper - Local Development Tool

Usage: $0 <command> [options]

Commands:
    check               Check all tools and authentication
    fmt                 Format all Terraform files
    validate            Validate Terraform configuration
    lint                Run TFLint checks
    scan                Run security scans (TFSec)
    init                Initialize Terraform environments
    plan                Plan sandbox infrastructure
    apply               Apply sandbox infrastructure
    destroy             Destroy sandbox infrastructure
    outputs             Show Terraform outputs
    full-check          Run fmt, validate, lint, scan
    help                Show this help message

Examples:
    $0 check
    $0 full-check
    $0 fmt
    $0 plan
    $0 apply
    $0 destroy

Environment Variables:
    TF_LOG              Set to DEBUG for verbose logging
    TF_VAR_*            Pass Terraform variables

EOF
}

# Main script
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    
    case "$command" in
        check)
            check_tools
            check_authentication
            ;;
        fmt)
            format_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            ;;
        validate)
            validate_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            ;;
        lint)
            lint_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            ;;
        scan)
            scan_security "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            ;;
        init)
            check_tools
            check_authentication
            init_environments
            ;;
        plan)
            check_tools
            check_authentication
            plan_sandbox
            ;;
        apply)
            check_tools
            check_authentication
            apply_sandbox
            ;;
        destroy)
            check_tools
            check_authentication
            destroy_sandbox
            ;;
        outputs)
            outputs_values
            ;;
        full-check)
            check_tools
            check_authentication
            format_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            validate_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            lint_terraform "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            scan_security "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/infra"
            log_success "Full check complete"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
