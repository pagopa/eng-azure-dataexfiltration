resource "azurerm_resource_group" "rg_appservice" {
  name     = format("%s-appservice-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "appservice_snet" {
  source                                    = "./.terraform/modules/v3/subnet/"
  name                                      = format("%s-appservice-snet", local.project)
  address_prefixes                          = var.cidr_appservice_subnet
  resource_group_name                       = azurerm_resource_group.vnet.name
  virtual_network_name                      = module.vnet.name
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.Web"]
}

resource "azurerm_service_plan" "app_docker" {

  name                = format("%s-plan-appservice-docker", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_appservice.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}

module "appservice" {
  source              = "./.terraform/modules/v3/app_service/"
  resource_group_name = azurerm_resource_group.rg_appservice.name
  location            = var.location
  plan_type           = "external"
  plan_id             = azurerm_service_plan.app_docker.id
  name                = format("%s-app-service-docker", local.project)
  client_cert_enabled = false
  https_only          = false
  always_on           = false
  docker_image        = "ghcr.io/pagopa/eng-data-exfiltration-demo"
  docker_image_tag    = "latest"
  #health_check_path   = "/status"
  app_settings = {
    TIMEOUT_DELAY = 300
    # Integration with private DNS (see more: https://docs.microsoft.com/en-us/answers/questions/85359/azure-app-service-unable-to-resolve-hostname-of-vi.html)
    WEBSITE_DNS_SERVER                  = "168.63.129.16"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                       = 80
    # DOCKER_REGISTRY_SERVER_URL      = "https://${module.acr[0].login_server}"
    # DOCKER_REGISTRY_SERVER_USERNAME = module.acr[0].admin_username
    # DOCKER_REGISTRY_SERVER_PASSWORD = module.acr[0].admin_password
  }
  allowed_subnets = [module.apimanager_snet.id, module.app_gw_snet.id]
  allowed_ips     = []
  subnet_id       = module.appservice_snet.id
  tags            = var.tags
}