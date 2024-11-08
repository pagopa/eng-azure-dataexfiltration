resource "azurerm_resource_group" "function" {
  location = var.location
  name     = "${local.project}-function-rg"
}

resource "azurerm_service_plan" "this" {
  name                     = "${local.project}-asp"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.function.name
  sku_name                 = "B1"
  worker_count             = 1
  os_type                  = "Linux"
  per_site_scaling_enabled = false
  zone_balancing_enabled   = false

  tags = var.tags
}

resource "azurerm_storage_account" "this" {
  name                     = replace("${local.project}funcst", "-", "")
  location                 = var.location
  resource_group_name      = azurerm_resource_group.function.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_function_blob" {
  name                = "${azurerm_storage_account.this.name}-blob-pep"
  location            = azurerm_resource_group.function.location
  resource_group_name = azurerm_resource_group.function.name
  subnet_id           = azurerm_subnet.private_endpoint_snet.id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-blob-pep"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_blob_core_windows_net.id]
  }

  tags = var.tags
}


resource "azurerm_subnet" "function_snet" {
  name                 = format("%s-function-snet", local.project)
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = var.cidr_function_subnet
  service_endpoints    = ["Microsoft.Web"]

  delegation {
    name = "Microsoft.Web.serverFarms"
    service_delegation { 
     name = "Microsoft.Web/serverFarms"
    }
  }

}


resource "azurerm_subnet_route_table_association" "function_snet_to_firewall" {
  subnet_id      = azurerm_subnet.function_snet.id
  route_table_id = azurerm_route_table.to_firewall.id
}

resource "azurerm_linux_function_app" "this" {
  name                          = "${local.project}-func"
  resource_group_name           = azurerm_resource_group.function.name
  location                      = var.location
  public_network_access_enabled = false
  storage_account_name          = azurerm_storage_account.this.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.this.id
  virtual_network_subnet_id     = azurerm_subnet.function_snet.id
  
  client_certificate_enabled    = false
  https_only                    = false

  site_config {
    always_on                              = true
    use_32_bit_worker                      = false
    ftps_state                             = "Disabled"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    vnet_route_all_enabled                 = true
    

    application_stack {
      node_version = "20"
    }

    cors {
      allowed_origins = [
        "https://portal.azure.com",
      ]
      support_credentials = false
    }
  }

  app_settings = {
    APPINSIGHTS_SAMPLING_PERCENTAGE = 5
    WEBSITE_RUN_FROM_PACKAGE        = 1
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
    ]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "function" {
  name                = "${azurerm_linux_function_app.this.name}-site-pep" 
  location            = var.location
  resource_group_name = azurerm_resource_group.function.name
  subnet_id           = azurerm_subnet.private_endpoint_snet.id

  private_service_connection {
    name                           = "${azurerm_linux_function_app.this.name}-site-pep" 
    private_connection_resource_id = azurerm_linux_function_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

 private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_azurewebsites_net.id]
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "random_id" "key" {
  byte_length = 16
}

resource "null_resource" "deploy" {
  depends_on = [azurerm_role_assignment.this]

  triggers = {
    deploy_version      = "1.2" # change me to redeploy
    function_name       = azurerm_linux_function_app.this.name
    resource_group_name = azurerm_resource_group.function.name
    key                 = random_id.key.hex
  }

  provisioner "local-exec" {
    command = <<EOT
      cd function-app && \
      yarn install && \
      func azure functionapp publish ${self.triggers.function_name} && \
      sleep 180 && \
      az functionapp function keys set -g ${self.triggers.resource_group_name} -n ${self.triggers.function_name} --function-name Proxy --key-name key --key-value ${self.triggers.key}
    EOT
  }
}

resource "azurerm_public_ip" "appgtw_pip" {
  name                = "${local.project}-appgtw-pip"
  resource_group_name = azurerm_resource_group.function.name
  location            = azurerm_resource_group.function.location
  allocation_method   = "Static"
  sku                 = "Standard" 
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = format("%s-appgtw-snet", local.project)
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_application_gateway" "network" {
  name                = "${local.project}-appgtw"
  resource_group_name = azurerm_resource_group.function.name
  location            = azurerm_resource_group.function.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${local.project}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }

  frontend_port {
    name = "${local.project}-appgtw-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.project}-appgtw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgtw_pip.id
  }

  backend_address_pool {
    name  = "${local.project}-appgtw-bp"
    #ip_addresses = [azurerm_private_endpoint.function.private_service_connection[0].private_ip_address ]
    fqdns = ["${azurerm_linux_function_app.this.name}.azurewebsites.net"]
  }

  backend_http_settings {
    name                  = "${local.project}-appgtw-backend-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
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