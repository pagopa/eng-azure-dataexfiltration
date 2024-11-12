resource "azurerm_dns_zone" "dns_zone" {
  name                = format("%s.%s", var.dns_zone_product_prefix, var.external_domain)
  resource_group_name = azurerm_resource_group.vnet_rg.name
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.vnet_rg.name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "privatelink_azurewebsites_net" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.vnet_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_blob_core_windows_net_vnet" {
  name                  = module.vnet.name
  resource_group_name   = azurerm_resource_group.vnet_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
  virtual_network_id    = module.vnet.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_azurewebsites_net_vnet" {
  name                  = module.vnet.name
  resource_group_name   = azurerm_resource_group.vnet_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_azurewebsites_net.name
  virtual_network_id    = module.vnet.id
  registration_enabled  = false

  tags = var.tags
}
