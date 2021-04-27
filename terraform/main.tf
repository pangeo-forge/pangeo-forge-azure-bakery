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

resource "azurerm_log_analytics_workspace" "bakery_logs_workspace" {
  name                = "${var.identifier}-bakery-logs-workspace"
  location            = azurerm_resource_group.bakery_resource_group.location
  resource_group_name = azurerm_resource_group.bakery_resource_group.name
  retention_in_days   = 30
  tags                = local.tags
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

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.bakery_logs_workspace.id
    }
  }

  tags = local.tags
}

resource "azurerm_storage_account" "bakery_flow_storage_account" {
  name                     = substr("${var.identifier}bakeryflowstorageaccount", 0, 24)
  resource_group_name      = azurerm_resource_group.bakery_resource_group.name
  location                 = azurerm_resource_group.bakery_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

resource "azurerm_storage_container" "bakery_flow_storage_container" {
  name                  = "${var.identifier}-bakery-flow-storage-container"
  storage_account_name  = azurerm_storage_account.bakery_flow_storage_account.name
  container_access_type = "private"
}
