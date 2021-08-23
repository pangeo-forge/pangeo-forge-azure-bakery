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
