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

resource "azurerm_storage_container" "bakery_flow_cache_container" {
  name                  = "${var.identifier}-bakery-flow-cache-container"
  storage_account_name  = azurerm_storage_account.bakery_flow_storage_account.name
  container_access_type = "private"
}