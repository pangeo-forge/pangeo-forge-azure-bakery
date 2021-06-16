output "bakery_resource_group_name" {
  value = azurerm_resource_group.bakery_resource_group.name
}

output "bakery_cluster_name" {
  value = azurerm_kubernetes_cluster.bakery_cluster.name
}

output "bakery_flow_storage_container_name" {
  value = azurerm_storage_container.bakery_flow_storage_container.name
}

output "bakery_flow_storage_account_name" {
  value = azurerm_storage_account.bakery_flow_storage_account.name
}
