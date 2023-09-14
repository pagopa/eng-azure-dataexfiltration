resource "azurerm_dns_zone" "dns_zone" {
  name                = format("%s.%s", var.dns_zone_product_prefix, var.external_domain)
  resource_group_name = azurerm_resource_group.rg_vnet.name
}

resource "azurerm_dns_a_record" "appservice" {
  name                = "appservice"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg_vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgateway.id
}

resource "azurerm_dns_a_record" "apim" {
  name                = "apim"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg_vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgateway.id
}

resource "azurerm_dns_a_record" "aks" {
  name                = "aks"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg_vnet.name
  ttl                 = 30
  target_resource_id  = azurerm_public_ip.appgateway.id
}