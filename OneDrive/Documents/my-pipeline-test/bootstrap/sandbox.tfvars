# Bootstrap environment values for sandbox
# Update these values for your specific deployment

azure_subscription_id = "f13329d5-3730-4ac3-8eb7-a991d63d8baa"
azure_tenant_id       = "54becd67-0ef0-488b-9a62-29a1c9ad93d2"

environment              = "sandbox"
location                 = "westeurope"
resource_group_name      = "rg-tfstate"
storage_account_name     = "anzzstfstate1"  # Must be globally unique, lowercase alphanumeric only
container_name           = "tfstate"
state_key_name           = "sandbox/terraform.tfstate"
service_principal_object_id = null  # Add object ID after creating SP if needed

tags = {
  Environment = "sandbox"
  ManagedBy   = "Terraform"
  Purpose     = "TerraformState"
}
