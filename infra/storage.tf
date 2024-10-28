resource "azurerm_resource_group" "storage_rg" {
  name     = "${local.project}-storage-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "storage" {
  name                          = replace("${local.project}-storage-sa", "-", "")
  resource_group_name           = azurerm_resource_group.storage_rg.name
  location                      = azurerm_resource_group.storage_rg.location
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${azurerm_storage_account.storage.name}-blob-pep"
  location            = azurerm_resource_group.storage_rg.location
  resource_group_name = azurerm_resource_group.storage_rg.name
  subnet_id           = module.private_endpoint_snet.id

  private_service_connection {
    name                           = "${azurerm_storage_account.storage.name}-blob-pep"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_blob_core_windows_net.id]
  }

  tags = var.tags
}
