# App Module (Placeholder)
# Provides minimal App Service configuration as a placeholder
# Expand this module based on your application requirements

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "app_service_plan_name" {
  description = "Name of the App Service plan"
  type        = string
}

variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
}

variable "sku" {
  description = "SKU for the App Service plan"
  type        = string
  default     = "B1"
}

variable "os_type" {
  description = "OS type for the App Service plan"
  type        = string
  default     = "Linux"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku

  tags = var.tags
}

resource "azurerm_linux_web_app" "main" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false
  }

  tags = var.tags
}

output "app_service_id" {
  value = azurerm_linux_web_app.main.id
}

output "app_service_default_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}
