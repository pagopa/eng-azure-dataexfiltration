resource "azurerm_resource_group" "rg_api" {
  name     = format("%s-apim-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "apim_snet" {
  source                                    = "./.terraform/modules/v3/subnet/"
  name                                      = format("%s-apim-snet", local.project)
  address_prefixes                          = var.cidr_apim_subnet
  resource_group_name                       = azurerm_resource_group.rg_vnet.name
  virtual_network_name                      = module.vnet.name
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Web"]
}

module "apim" {
  source                  = "./.terraform/modules/v3/api_management/"
  name                    = format("%s-apim", local.project)
  subnet_id               = module.apim_snet.id
  location                = azurerm_resource_group.rg_api.location
  resource_group_name     = azurerm_resource_group.rg_api.name
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