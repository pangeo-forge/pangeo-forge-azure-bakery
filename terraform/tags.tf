locals {
  tags = {
    "Project" : "pangeo-forge-azure-bakery",
    "Client" : "Planetary-Computer",
    "Owner" : var.owner,
    "Stack" : var.identifier
  }
}
