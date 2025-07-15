terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "centralus"
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

data "azurerm_client_config" "current" {}

# This is the module call
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "avm-managedcluster" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.2.5"

  default_node_pool = {
    name       = "default"
    vm_size    = "Standard_DS2_v2"
    node_count = 3

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location            = azurerm_resource_group.this.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  local_account_disabled = false
  diagnostic_settings = {
    to_la = {
      name                  = "to-la"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
  dns_prefix = "mjgtest"
  managed_identities = {
    system_assigned = true
  }
  network_profile = {
    network_plugin = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
  }
}

output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "The name of the resource group"
}

output "aks_cluster_name" {
  value       = module.avm-managedcluster.name
  description = "The name of the AKS cluster"
}