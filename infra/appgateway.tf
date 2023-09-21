module "app_gw_snet" {
  source                                    = "./.terraform/modules/v3/subnet/"
  name                                      = format("%s-appgw-snet", local.project)
  address_prefixes                          = var.cidr_appgw_subnet
  resource_group_name                       = azurerm_resource_group.vnet.name
  virtual_network_name                      = module.vnet.name
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Web"]
}

module "app_gw" {
  source              = "./.terraform/modules/v3/app_gateway/"
  resource_group_name = azurerm_resource_group.vnet.name
  location            = azurerm_resource_group.vnet.location
  name                = format("%s-appgw", local.project)
  # sku
  sku_name    = "WAF_v2"
  sku_tier    = "WAF_v2"
  waf_enabled = true
  # networking
  subnet_id                   = module.app_gw_snet.id
  public_ip_id                = azurerm_public_ip.appgw.id
  ssl_profiles                = []
  trusted_client_certificates = []
  backends = {
    api_manager = {
      protocol                    = "Http"
      host                        = format("%s-apim.%s", local.project, "azure-api.net")
      port                        = 80
      ip_addresses                = null # with null value use fqdns
      fqdns                       = [format("%s-apim.%s", local.project, "azure-api.net")]
      probe                       = "/api/"
      probe_name                  = "apimanager-probe"
      request_timeout             = 180
      pick_host_name_from_backend = true
    },
    app_service = {
      protocol                    = "Http"
      host                        = format("%s-app-service-docker.%s", local.project, "azurewebsites.net")
      port                        = 80
      ip_addresses                = null # with null value use fqdns
      fqdns                       = [format("%s-app-service-docker.%s", local.project, "azurewebsites.net")]
      probe                       = "/api/"
      probe_name                  = "appservice-probe"
      request_timeout             = 180
      pick_host_name_from_backend = true
    },
  }
  listeners = {
    api_manager = {
      protocol           = "Http"
      host               = format("apim.%s.%s", var.dns_zone_product_prefix, var.external_domain)
      port               = 80
      ssl_profile_name   = null
      firewall_policy_id = null
      certificate = {
        // whatever, ignored with a patched module for now
        name = format("apim.%s.%s", var.dns_zone_product_prefix, var.external_domain)
        id   = null
      }
    },
    app_service = {
      protocol           = "Http"
      host               = format("appservice.%s.%s", var.dns_zone_product_prefix, var.external_domain)
      port               = 80
      ssl_profile_name   = null
      firewall_policy_id = null
      certificate = {
        // whatever, ignored with a patched module for now
        name = format("appservice.%s.%s", var.dns_zone_product_prefix, var.external_domain)
        id   = null
      }
    }
  }
  routes = {
    apim = {
      listener              = "api_manager"
      backend               = "api_manager"
      rewrite_rule_set_name = null
      priority              = 10
    },
    appservice = {
      listener              = "app_service"
      backend               = "app_service"
      rewrite_rule_set_name = null
      priority              = 11
    }
  }
  # identity
  identity_ids = [azurerm_user_assigned_identity.appgw.id]
  # scaling
  app_gateway_min_capacity = 0
  app_gateway_max_capacity = 2
  tags                     = var.tags
}

resource "azurerm_user_assigned_identity" "appgw" {
  resource_group_name = azurerm_resource_group.vnet.name
  location            = azurerm_resource_group.vnet.location
  name                = format("%s-appgw-identity", local.project)
  tags                = var.tags
}