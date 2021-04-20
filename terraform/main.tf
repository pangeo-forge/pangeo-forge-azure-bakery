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
    "Project": "pangeo-forge-azure-bakery",
    "Client": "Planetary Computer",
    "Owner": var.owner,
    "Stack": var.identifier
  }
}

resource "azurerm_resource_group" "bakery_resource_group" {
  name     = "${var.identifier}-resource-group"
  location = var.region
  tags = local.tags
}
