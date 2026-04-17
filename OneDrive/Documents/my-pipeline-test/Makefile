# Makefile for Terraform Infrastructure Pipeline

.PHONY: help install check fmt validate lint scan init full-check plan apply destroy outputs clean wrapper-help

help:
	@echo "Terraform Infrastructure Pipeline"
	@echo "=================================="
	@echo ""
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  install       Install all required tools (scripts/install-tools.sh)"
	@echo "  check         Check tools and Azure authentication"
	@echo "  fmt           Format all Terraform files"
	@echo "  validate      Validate Terraform configuration"
	@echo "  lint          Run TFLint checks"
	@echo "  scan          Run security scans (TFSec)"
	@echo "  init          Initialize Terraform environments"
	@echo "  full-check    Run fmt, validate, lint, scan"
	@echo "  plan          Plan sandbox infrastructure changes"
	@echo "  apply         Apply sandbox infrastructure (requires approval)"
	@echo "  destroy       Destroy sandbox infrastructure (interactive)"
	@echo "  outputs       Show Terraform outputs"
	@echo "  clean         Clean Terraform cache and plans"
	@echo "  wrapper-help  Show terraform-wrapper.sh help"
	@echo ""
	@echo "Examples:"
	@echo "  make check"
	@echo "  make full-check"
	@echo "  make fmt"
	@echo "  make plan"
	@echo "  make apply"
	@echo ""

install:
	@chmod +x scripts/install-tools.sh
	@./scripts/install-tools.sh

check:
	@./scripts/terraform-wrapper.sh check

fmt:
	@./scripts/terraform-wrapper.sh fmt

validate:
	@./scripts/terraform-wrapper.sh validate

lint:
	@./scripts/terraform-wrapper.sh lint

scan:
	@./scripts/terraform-wrapper.sh scan

init:
	@./scripts/terraform-wrapper.sh init

full-check:
	@./scripts/terraform-wrapper.sh full-check

plan:
	@./scripts/terraform-wrapper.sh plan

apply:
	@./scripts/terraform-wrapper.sh apply

destroy:
	@./scripts/terraform-wrapper.sh destroy

outputs:
	@./scripts/terraform-wrapper.sh outputs

wrapper-help:
	@./scripts/terraform-wrapper.sh help

clean:
	@echo "Cleaning Terraform cache..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfplan" -type f -delete
	@find . -name "tfplan.bin" -type f -delete
	@find . -name "plan.txt" -type f -delete
	@echo "✅ Clean complete"

.PHONY: info
info:
	@echo "Bootstrap Configuration:"
	@cd bootstrap && terraform output backend_config 2>/dev/null || echo "Run 'make plan' in bootstrap first"
	@echo ""
	@echo "Sandbox Outputs:"
	@cd infra/environments/sandbox && terraform output 2>/dev/null || echo "Run 'make plan' first"
