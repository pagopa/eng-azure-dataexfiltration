resource "azurerm_resource_group" "storage_rg" {
  name     = "${local.project}-storage-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "storage" {
  name                     = replace("${local.project}-storage-sa","-","")
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  tags = var.tags
}
