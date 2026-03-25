.PHONY: help init plan apply destroy validate fmt clean

ENV_DIR := environments/dev

help:
	@echo "Available targets:"
	@echo "  init       - Initialize Terraform"
	@echo "  validate   - Validate Terraform configuration"
	@echo "  fmt        - Format Terraform files"
	@echo "  plan       - Show Terraform plan"
	@echo "  apply      - Apply Terraform configuration"
	@echo "  destroy    - Destroy Terraform managed resources"
	@echo "  clean      - Clean temporary files and state"
	@echo "  output     - Display Terraform outputs"
	@echo "  state      - Show Terraform state"
	@echo "  refresh    - Refresh Terraform state"
	@echo ""
	@echo "Backend targets:"
	@echo "  backend-setup  - Setup remote state backend (S3 + DynamoDB)"
	@echo "  backend-clean  - DELETE remote state backend (⚠️  DESTRUCTIVE)"

init:
	@cd $(ENV_DIR) && terraform init

validate:
	@cd $(ENV_DIR) && terraform validate

fmt:
	@terraform fmt -recursive .

plan:
	@cd $(ENV_DIR) && terraform plan -out=tfplan

apply: plan
	@cd $(ENV_DIR) && terraform apply tfplan

destroy:
	@cd $(ENV_DIR) && terraform destroy

clean:
	@cd $(ENV_DIR) && rm -rf .terraform tfplan tfplan.json .terraform.lock.hcl

output:
	@cd $(ENV_DIR) && terraform output

state:
	@cd $(ENV_DIR) && terraform state list

refresh:
	@cd $(ENV_DIR) && terraform refresh

# Backend management targets
backend-setup:
	@echo "Setting up remote state backend..."
	@bash scripts/setup-remote-state.sh

backend-clean:
	@echo "⚠️  WARNING: This will DELETE your remote state backend!"
	@echo "Proceeding with cleanup..."
	@bash scripts/cleanup-remote-state.sh

# Development targets
dev-init: init validate fmt
	@echo "Development environment initialized"

doc:
	@echo "See README.md for comprehensive documentation"

check:
	@echo "Checking Terraform configuration..."
	@terraform fmt -recursive -check .
	@cd $(ENV_DIR) && terraform validate
