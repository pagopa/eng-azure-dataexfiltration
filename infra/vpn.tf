module "vpn_snet" {
  source                                    = "./.terraform/modules/v3/subnet/"
  name                                      = "GatewaySubnet"
  address_prefixes                          = var.cidr_vpn_subnet
  resource_group_name                       = azurerm_resource_group.vnet.name
  virtual_network_name                      = module.vnet.name
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Web"]
}

data "azuread_application" "vpn_app" {
  display_name = format("%s-app-vpn", local.project)
}

module "vpn" {
  source              = "./.terraform/modules/v3/vpn_gateway/"
  name                = format("%s-vpn", local.project)
  resource_group_name = azurerm_resource_group.vnet.name
  sku                 = "VpnGw1"
  pip_sku             = "Basic"
  location            = var.location
  subnet_id           = module.vpn_snet.id
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