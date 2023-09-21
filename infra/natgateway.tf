module "nat_gw" {
  source              = "./.terraform/modules/v3/nat_gateway/"
  name                = format("%s-natgateway", local.project)
  location            = var.location
  subnet_ids          = []
  resource_group_name = azurerm_resource_group.vnet.name
  zones               = [1] # nat gws do not support multi-AZ
  tags                = var.tags
}