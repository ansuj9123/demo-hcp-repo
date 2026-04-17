# Naming Module
# Provides consistent naming conventions for Azure resources

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "location" {
  description = "Azure location abbreviated"
  type        = string
}

locals {
  # Location abbreviations
  location_map = {
    "eastus"      = "eus"
    "westus"      = "wus"
    "eastus2"     = "eus2"
    "westus2"     = "wus2"
    "northeurope" = "neu"
    "westeurope"  = "weu"
  }

  loc_short = lookup(local.location_map, var.location, "loc")
  env_short = substr(var.environment, 0, 3)
  proj_short = substr(var.project, 0, 3)
}

output "resource_group_name" {
  value = "rg-${local.env_short}-${local.proj_short}"
}

output "storage_account_name" {
  # Storage account names must be lowercase alphanumeric only, max 24 chars
  value = "st${local.env_short}${local.proj_short}${replace(local.loc_short, "-", "")}"
}

output "key_vault_name" {
  value = "kv-${local.env_short}-${local.proj_short}-${local.loc_short}"
}

output "vnet_name" {
  value = "vnet-${local.env_short}-${local.proj_short}"
}

output "subnet_name" {
  value = "snet-${local.env_short}-${local.proj_short}"
}

output "log_analytics_workspace_name" {
  value = "law-${local.env_short}-${local.proj_short}"
}

output "user_assigned_identity_name" {
  value = "msi-${local.env_short}-${local.proj_short}"
}

output "app_service_name" {
  value = "app-${local.env_short}-${local.proj_short}"
}
