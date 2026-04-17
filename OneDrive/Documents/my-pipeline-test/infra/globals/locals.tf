locals {
  metadata = {
    project     = var.project_name
    environment = var.environment
    location    = var.location
  }

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  )
}
