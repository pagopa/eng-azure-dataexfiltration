# main vnet

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

# firewall vnet (for Azure Firewall)
resource "azurerm_resource_group" "firewall_vnet" {
  name     = format("%s-firewall-vnet-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "firewall_vnet" {
  source              = "./.terraform/modules/v3/virtual_network/"
  name                = format("%s-firewall-vnet", local.project)
  location            = azurerm_resource_group.firewall_vnet.location
  resource_group_name = azurerm_resource_group.firewall_vnet.name
  address_space       = var.firewall_cidr_vnet
  tags                = var.tags
}

# peering between main vnet and firewall vnet

module "vnet_peering_main_vnet_firewall_vnet" {
  location                         = var.location
  source                           = "./.terraform/modules/v3/virtual_network_peering/"
  source_resource_group_name       = azurerm_resource_group.vnet.name
  source_virtual_network_name      = module.vnet.name
  source_remote_virtual_network_id = module.vnet.id
  source_allow_gateway_transit     = true # needed by vpn gateway for enabling routing from vnet to vnet_integration
  target_resource_group_name       = azurerm_resource_group.firewall_vnet.name
  target_virtual_network_name      = module.firewall_vnet.name
  target_remote_virtual_network_id = module.firewall_vnet.id
  target_use_remote_gateways       = true # needed by vpn gateway for enabling routing from vnet to vnet_integration
}

# associate to each main vnet subnet a new route table

data "azapi_resource_list" "listSubnetsByVnet" {
  type                   = "Microsoft.Network/virtualNetworks/subnets@2021-02-01"
  parent_id              = module.vnet.id
  response_export_values = ["*"]
}

output "subnets" {
  value = data.azapi_resource_list.listSubnetsByVnet.output
}
