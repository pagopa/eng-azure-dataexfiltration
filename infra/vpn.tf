resource "azurerm_subnet" "vpn_snet" {
  name                 = "GatewaySubnet" # must be exactly this value
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = var.cidr_vpn_subnet
}

data "azuread_application" "vpn_app" {
  display_name = format("dvopla-%s-app-vpn", var.env_short) # subscription vpn app
}

module "vpn" {
  source                = "./.terraform/modules/__v3__/vpn_gateway/"
  name                  = format("%s-vpn", local.project)
  resource_group_name   = azurerm_resource_group.vnet_rg.name
  sku                   = "VpnGw1"
  pip_sku               = "Standard"
  pip_allocation_method = "Static"
  location              = var.location
  subnet_id             = azurerm_subnet.vpn_snet.id
  vpn_client_configuration = [
    {
      address_space         = ["172.16.1.0/24"],
      vpn_client_protocols  = ["OpenVPN"],
      aad_audience          = data.azuread_application.vpn_app.application_id
      aad_issuer            = "https://sts.windows.net/${data.azurerm_subscription.current.tenant_id}/"
      aad_tenant            = "https://login.microsoftonline.com/${data.azurerm_subscription.current.tenant_id}"
      radius_server_address = null
      radius_server_secret  = null
      revoked_certificate   = []
      root_certificate      = []
    }
  ]
  tags = var.tags
}
