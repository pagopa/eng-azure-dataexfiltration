resource "azurerm_resource_group" "rg_apimanager" {
  name     = format("%s-apimanager-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "apimanager_snet" {
  source                                    = "./.terraform/modules/v3/subnet/"
  name                                      = format("%s-apimanager-snet", local.project)
  address_prefixes                          = var.cidr_apim_subnet
  resource_group_name                       = azurerm_resource_group.vnet.name
  virtual_network_name                      = module.vnet.name
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Web"]
}

module "apimanager" {
  source                  = "./.terraform/modules/v3/api_management/"
  name                    = format("%s-apim", local.project)
  subnet_id               = module.apimanager_snet.id
  location                = azurerm_resource_group.rg_apimanager.location
  resource_group_name     = azurerm_resource_group.rg_apimanager.name
  sku_name                = "Developer_1"
  virtual_network_type    = "Internal"
  redis_connection_string = null
  redis_cache_id          = null
  sign_up_enabled         = false
  lock_enable             = false
  tags                    = var.tags
  publisher_name          = "Azure Data Exfiltration Lab"
  publisher_email         = "pietro.stroia@pagopa.it"
  application_insights = {
    enabled             = false
    instrumentation_key = null
  }
}

module "apimanager_product" {
  source                = "./.terraform/modules/v3/api_management_product/"
  product_id            = "dex"
  description           = "Azure Data Exfiltration Lab Product"
  display_name          = "Azure Data Exfiltration Lab Product"
  api_management_name   = module.apimanager.name
  resource_group_name   = azurerm_resource_group.rg_apimanager.name
  published             = true
  subscription_required = false
  approval_required     = false
}

resource "azurerm_api_management_api" "apimanager_api" {
  name                = format("%s-apimanager-api", local.project)
  resource_group_name = azurerm_resource_group.rg_apimanager.name
  api_management_name = module.apimanager.name
  revision            = "1"
  display_name        = "Azure Data Exfiltration Lab API"
  path                = "api"
  protocols           = ["http"]
  service_url         = format("http://%s-app-service-docker.%s", local.project, "azurewebsites.net")

  import {
    content_format = "openapi"
    content_value  = file("./apimanager-api.yml")
  }
}

resource "azurerm_api_management_product_api" "apimanager_product_api" {
  depends_on          = [module.apimanager, azurerm_api_management_api.apimanager_api]
  api_name            = format("%s-apimanager-api", local.project)
  product_id          = module.apimanager_product.product_id
  api_management_name = module.apimanager.name
  resource_group_name = azurerm_resource_group.rg_apimanager.name
}