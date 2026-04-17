# Sandbox environment terraform values
# Update these for your deployment

project_name = "myapp"
environment  = "sandbox"

azure_subscription_id = "f13329d5-3730-4ac3-8eb7-a991d63d8baa"
azure_tenant_id       = "54becd67-0ef0-488b-9a62-29a1c9ad93d2"

location    = "westeurope"
vnet_cidr   = "10.0.0.0/16"

tags = {
  Environment = "sandbox"
  ManagedBy   = "Terraform"
  CostCenter  = "engineering"
}
