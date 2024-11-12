resource "azurerm_public_ip" "app_gateway" {
  name                = "${local.project}-appgtw-pip"
  resource_group_name = azurerm_resource_group.vnet_rg.name
  location            = azurerm_resource_group.vnet_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "app_gateway_snet" {
  name                 = format("%s-appgtw-snet", local.project)
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = var.cidr_appgw_subnet
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "${local.project}-appgtw"
  resource_group_name = azurerm_resource_group.vnet_rg.name
  location            = azurerm_resource_group.vnet_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${local.project}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gateway_snet.id
  }

  frontend_port {
    name = "${local.project}-appgtw-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.project}-appgtw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name  = "${local.project}-appgtw-bp"
    fqdns = ["${azurerm_linux_function_app.function.name}.azurewebsites.net"]
  }

  backend_http_settings {
    name                                = "${local.project}-appgtw-backend-setting"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "${local.project}-appgtw-listener"
    frontend_ip_configuration_name = "${local.project}-appgtw-frontend-ip"
    frontend_port_name             = "${local.project}-appgtw-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.project}-appgtw-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "${local.project}-appgtw-listener"
    backend_address_pool_name  = "${local.project}-appgtw-bp"
    backend_http_settings_name = "${local.project}-appgtw-backend-setting"
  }
}
