# Naming module to generate consistent resource names
module "naming" {
  source = "../../modules/naming"

  project     = var.project_name
  environment = var.environment
  location    = var.location
}

# Primary resource group
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group_name
  location = var.location

  tags = var.tags
}

# Networking module
module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_name          = module.naming.vnet_name
  vnet_cidr          = var.vnet_cidr
  subnet_name        = module.naming.subnet_name
  subnet_cidr        = var.subnet_cidr

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Identity module - User Assigned Managed Identity
module "identity" {
  source = "../../modules/identity"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  identity_name      = module.naming.user_assigned_identity_name

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Key Vault module
module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  key_vault_name     = module.naming.key_vault_name
  tenant_id          = data.azurerm_client_config.current.tenant_id

  enable_rbac_authorization   = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Storage module
module "storage" {
  source = "../../modules/storage"

  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  storage_account_name    = module.naming.storage_account_name
  account_tier            = "Standard"
  account_replication_type = "GRS"
  enable_https_only       = true
  enable_soft_delete      = true
  soft_delete_retention_days = 30
  min_tls_version         = "TLS1_2"

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Log Analytics module
module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  workspace_name     = module.naming.log_analytics_workspace_name
  sku                = "PerGB2018"
  retention_in_days  = 30

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}

# App Service module (placeholder)
module "app" {
  source = "../../modules/app"

  resource_group_name     = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  app_service_plan_name  = "${module.naming.app_service_name}-plan"
  app_service_name       = module.naming.app_service_name
  os_type                = "Linux"
  sku                    = "B1"

  tags = var.tags

  depends_on = [azurerm_resource_group.main]
}
