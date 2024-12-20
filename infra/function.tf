resource "azurerm_resource_group" "function_rg" {
  location = var.location
  name     = "${local.project}-function-rg"

  tags = var.tags
}

resource "azurerm_service_plan" "function" {
  name                     = "${local.project}-asp"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.function_rg.name
  sku_name                 = "B1"
  worker_count             = 1
  os_type                  = "Linux"
  per_site_scaling_enabled = false
  zone_balancing_enabled   = false

  tags = var.tags
}

resource "azurerm_storage_account" "function" {
  name                     = replace("${local.project}funcst", "-", "")
  location                 = var.location
  resource_group_name      = azurerm_resource_group.function_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_private_endpoint" "function_blob" {
  name                = "${azurerm_storage_account.function.name}-blob-pep"
  location            = azurerm_resource_group.function_rg.location
  resource_group_name = azurerm_resource_group.function_rg.name
  subnet_id           = azurerm_subnet.private_endpoint_snet.id

  private_service_connection {
    name                           = "${azurerm_storage_account.function.name}-blob-pep"
    private_connection_resource_id = azurerm_storage_account.function.id
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
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet_route_table_association" "function_snet_to_firewall" {
  subnet_id      = azurerm_subnet.function_snet.id
  route_table_id = azurerm_route_table.to_firewall.id
}

resource "azurerm_linux_function_app" "function" {
  name                          = "${local.project}-func"
  resource_group_name           = azurerm_resource_group.function_rg.name
  location                      = var.location
  public_network_access_enabled = false
  storage_account_name          = azurerm_storage_account.function.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.function.id
  virtual_network_subnet_id     = azurerm_subnet.function_snet.id

  client_certificate_enabled = false
  https_only                 = false

  site_config {
    always_on               = true
    use_32_bit_worker       = false
    ftps_state              = "Disabled"
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    vnet_route_all_enabled  = true


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
  name                = "${azurerm_linux_function_app.function.name}-site-pep"
  location            = var.location
  resource_group_name = azurerm_resource_group.function_rg.name
  subnet_id           = azurerm_subnet.private_endpoint_snet.id

  private_service_connection {
    name                           = "${azurerm_linux_function_app.function.name}-site-pep"
    private_connection_resource_id = azurerm_linux_function_app.function.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_azurewebsites_net.id]
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "function_to_storage_blob" {
  scope                = azurerm_storage_account.function.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.function.identity[0].principal_id
}

resource "random_id" "function_key" {
  byte_length = 16
}

resource "null_resource" "function_deploy" {
  depends_on = [azurerm_role_assignment.function_to_storage_blob]

  triggers = {
    deploy_version      = "1.0" # change me to redeploy
    function_name       = azurerm_linux_function_app.function.name
    resource_group_name = azurerm_resource_group.function_rg.name
    key                 = random_id.function_key.hex
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
