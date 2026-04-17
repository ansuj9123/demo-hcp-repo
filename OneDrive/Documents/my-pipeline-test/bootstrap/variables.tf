variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "sandbox"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name for Terraform state resources"
  type        = string
  default     = "rg-tfstate"
}

variable "storage_account_name" {
  description = "Storage account name for Terraform state (must be globally unique, lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "container_name" {
  description = "Storage container name for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "state_key_name" {
  description = "Key name for Terraform state file"
  type        = string
  default     = "sandbox/terraform.tfstate"
}

variable "service_principal_object_id" {
  description = "Object ID of the service principal for RBAC assignment (from 'az ad sp show' output)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "sandbox"
    ManagedBy   = "Terraform"
    Purpose     = "TerraformState"
  }
}
