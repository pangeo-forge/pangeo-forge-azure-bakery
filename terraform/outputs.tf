output "bakery_resource_group_name" {
  value = azurerm_resource_group.bakery_resource_group.name
}

output "bakery_cluster_name" {
  value = azurerm_kubernetes_cluster.bakery_cluster.name
}
