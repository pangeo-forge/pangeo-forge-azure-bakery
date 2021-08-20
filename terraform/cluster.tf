resource "azurerm_kubernetes_cluster" "bakery_cluster" {
  name                = "${var.identifier}-bakery-cluster"
  location            = azurerm_resource_group.bakery_resource_group.location
  resource_group_name = azurerm_resource_group.bakery_resource_group.name
  dns_prefix          = "${var.identifier}-bakery-cluster"

  default_node_pool {
    name                = "default"
    max_count           = 100
    min_count           = 1
    vm_size             = "standard_d4_v4"
    os_disk_size_gb     = 30
    enable_auto_scaling = true
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
