# Identity Module
# Provides User Assigned Managed Identity configuration

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "identity_name" {
  description = "Name of the user assigned identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_user_assigned_identity" "main" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

output "id" {
  value = azurerm_user_assigned_identity.main.id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}
