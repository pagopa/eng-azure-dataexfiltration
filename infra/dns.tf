resource "azurerm_dns_zone" "dns_zone" {
  name                = format("%s.%s", var.dns_zone_product_prefix, var.external_domain)
  resource_group_name = azurerm_resource_group.vnet.name
}

resource "azurerm_dns_a_record" "appservice" {
  name                = "appservice"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgw.id
}

resource "azurerm_dns_a_record" "apim" {
  name                = "apim"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgw.id
}

resource "azurerm_dns_a_record" "aks" {
  name                = "aks"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgw.id
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "azure-api.net"
  resource_group_name = azurerm_resource_group.vnet.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_vnet_link" {
  name                  = "link"
  resource_group_name   = azurerm_resource_group.vnet.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = module.vnet.id
}

resource "azurerm_private_dns_a_record" "private_apim" {
  name                = format("%s-apim", local.project)
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_resource_group.vnet.name
  ttl                 = 30
  records             = module.apimanager.private_ip_addresses
}