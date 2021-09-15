resource "azurerm_kubernetes_cluster" "bakery_cluster" {
  name                = "${var.identifier}-bakery-cluster"
  location            = azurerm_resource_group.bakery_resource_group.location
  resource_group_name = azurerm_resource_group.bakery_resource_group.name
  dns_prefix          = "${var.identifier}-bakery-cluster"

  default_node_pool {
    name                = "system"
    max_count           = null
    min_count           = null
    node_count          = 1
    vm_size             = "standard_d4_v4"
    os_disk_size_gb     = 512
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  auto_scaler_profile {
    scale_down_delay_after_add = "2m"
    scale_down_unneeded        = "2m"
  }


  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "compute" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.bakery_cluster.id
  name                = "compute"
  max_count           = 100
  min_count           = 0
  vm_size             = "standard_f8s_v2"
  os_disk_size_gb     = 512
  enable_auto_scaling = true

  tags = local.tags
}