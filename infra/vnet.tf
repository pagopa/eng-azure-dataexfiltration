resource "azurerm_resource_group" "vnet" {
  name     = format("%s-vnet-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "./.terraform/modules/v3/virtual_network/"
  name                = format("%s-vnet", local.project)
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  address_space       = var.cidr_vnet
  tags                = var.tags
}

resource "azurerm_public_ip" "appgw" {
  name                = format("%s-appgw-pip", local.project)
  resource_group_name = azurerm_resource_group.vnet.name
  location            = azurerm_resource_group.vnet.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = var.tags
}