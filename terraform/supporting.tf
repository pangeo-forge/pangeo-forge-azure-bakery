resource "azurerm_resource_group" "bakery_resource_group" {
  name     = "${var.identifier}-bakery-resource-group"
  location = var.region
  tags     = local.tags
}
