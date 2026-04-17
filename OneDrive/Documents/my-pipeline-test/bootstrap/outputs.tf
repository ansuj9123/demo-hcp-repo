output "resource_group_name" {
  description = "Resource group name for Terraform state"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage account name for Terraform state"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.tfstate.id
}

output "storage_container_name" {
  description = "Storage container name for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Backend configuration to use for remote state (add to main.tf)"
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = var.state_key_name
  }
}

output "next_steps" {
  description = "Instructions for completing bootstrap"
  value = <<-EOT
    1. Copy backend_config output values
    2. Add to infra/environments/sandbox/versions.tf backend block:
       
       terraform {
         backend "azurerm" {
           resource_group_name  = "${azurerm_resource_group.tfstate.name}"
           storage_account_name = "${azurerm_storage_account.tfstate.name}"
           container_name       = "${azurerm_storage_container.tfstate.name}"
           key                  = "${var.state_key_name}"
         }
       }
    
    3. Run: cd ../infra/environments/sandbox && terraform init
    4. Confirm migration to remote state
  EOT
}
