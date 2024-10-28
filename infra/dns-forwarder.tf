module "dns_forwarder_vm_image" {
  source              = "./.terraform/modules/__v3__/dns_forwarder_vm_image/"
  resource_group_name = azurerm_resource_group.vnet_rg.name
  location            = azurerm_resource_group.vnet_rg.location
  image_name          = "${local.project}-dns-forwarder-ubuntu2204-image"
  image_version       = "v1"
  subscription_id     = data.azurerm_subscription.current.subscription_id
  prefix              = local.project
}

module "dns_forwarder" {
  source = "./.terraform/modules/__v3__/dns_forwarder_lb_vmss/"

  name                  = local.project
  virtual_network_name  = module.vnet.name
  resource_group_name   = azurerm_resource_group.vnet_rg.name
  location              = azurerm_resource_group.vnet_rg.location
  subscription_id       = data.azurerm_subscription.current.subscription_id
  source_image_name     = module.dns_forwarder_vm_image.custom_image_name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  address_prefixes_vmss = var.cidr_dns_forwarder_vmss_subnet[0]
  address_prefixes_lb   = var.cidr_dns_forwarder_lb_subnet[0]
  key_vault_id          = module.key_vault.id

  tags = var.tags
}
