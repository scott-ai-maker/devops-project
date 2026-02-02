terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  # Backend configuration for remote state
  # Commented out for initial setup - will use local state first
  # Uncomment and configure after storage account is ready
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatee9403b4d"
  #   container_name       = "tfstate"
  #   key                  = "devops-demo.tfstate"
  # }
}

provider "azurerm" {
  # Skip automatic resource provider registration (providers already registered manually)
  skip_provider_registration = true
  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Azure Container Registry Module
module "acr" {
  source = "./modules/acr"

  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  tags                = var.tags

  depends_on = [module.resource_group]
}

# Azure Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  name                = var.key_vault_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags

  depends_on = [module.resource_group]
}

# AKS Cluster Module
module "aks" {
  source = "./modules/aks"

  name                = var.aks_cluster_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  dns_prefix          = var.aks_dns_prefix

  # Node pool configuration
  node_count   = var.aks_node_count
  node_vm_size = var.aks_node_vm_size

  # Network configuration
  network_plugin = "azure"
  network_policy = "azure"

  # RBAC and security
  enable_rbac = true

  tags = var.tags

  depends_on = [module.resource_group, module.acr]
}

# Attach ACR to AKS - allows AKS to pull images from ACR without credentials
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = module.aks.kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true

  depends_on = [module.aks, module.acr]
}
