module "firewall_snet" {
  source               = "./.terraform/modules/v3/subnet/"
  name                 = "AzureFirewallSubnet" # must be exactly this value
  address_prefixes     = var.cidr_firewall_subnet
  resource_group_name  = azurerm_resource_group.firewall_vnet.name
  virtual_network_name = module.firewall_vnet.name
}

resource "azurerm_public_ip" "firewall" {
  name                = format("%s-firewall-pip", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_vnet.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = format("%s-firewall", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_vnet.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.firewall_snet.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}