output "resource_group_name" {
  description = "Name of the primary resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the primary resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.networking.subnet_id
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.keyvault.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.vault_uri
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.log_analytics.id
}

output "app_service_id" {
  description = "ID of the App Service"
  value       = module.app.app_service_id
}

output "app_service_hostname" {
  description = "Default hostname of the App Service"
  value       = module.app.app_service_default_hostname
}

output "user_assigned_identity_id" {
  description = "ID of the user assigned identity"
  value       = module.identity.id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the user assigned identity"
  value       = module.identity.principal_id
}
