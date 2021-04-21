terraform {
  required_version = ">= 0.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.56.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  tags = {
    "Project" : "pangeo-forge-azure-bakery",
    "Client" : "Planetary Computer",
    "Owner" : var.owner,
    "Stack" : var.identifier
  }
}

resource "azurerm_resource_group" "bakery_resource_group" {
  name     = "${var.identifier}-bakery-resource-group"
  location = var.region
  tags     = local.tags
}

resource "azurerm_kubernetes_cluster" "bakery_cluster" {
  name                = "${var.identifier}-bakery-cluster"
  location            = azurerm_resource_group.bakery_resource_group.location
  resource_group_name = azurerm_resource_group.bakery_resource_group.name
  dns_prefix          = "${var.identifier}-bakery-cluster"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  tags = local.tags
}
