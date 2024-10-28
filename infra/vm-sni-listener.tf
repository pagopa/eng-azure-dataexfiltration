resource "random_password" "vm-sni-listener" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_resource_group" "vnet_sni_listener_rg" {
  name     = format("%s-vnet_sni_listener-rg", local.project)
  location = var.location
  tags     = var.tags
}

module "sni_listener_vnet" {
  source              = "./.terraform/modules/__v3__/virtual_network/"
  name                = format("%s-sni_listener_vnet", local.project)
  location            = azurerm_resource_group.vnet_sni_listener_rg.location
  resource_group_name = azurerm_resource_group.vnet_sni_listener_rg.name
  address_space       = var.cidr_sni_listener_vnet 
  tags                = var.tags
}

module "sni_listener_snet" {
  source                                    = "./.terraform/modules/__v3__/subnet/"
  name                                      = format("%s-sni_listener-snet", local.project)
  address_prefixes                          = var.cidr_sni_listener_subnet
  resource_group_name                       = azurerm_resource_group.vnet_sni_listener_rg.name
  virtual_network_name                      = module.sni_listener_vnet.name
}

resource "azurerm_linux_virtual_machine" "vm-sni-listener" {
  name                            = format("%s-sni-listener", local.project)
  location                        = var.location
  resource_group_name             = azurerm_resource_group.vnet_sni_listener_rg.name
  network_interface_ids           = [azurerm_network_interface.vm-sni-listener.id]
  size                            = "Standard_B1ls"
  disable_password_authentication = false

  admin_username = "azureuser"
  admin_password = random_password.vm-sni-listener.result

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_ZRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "vm_sni_listener_password" {
  name         = "${local.project}-vm"
  value        = random_password.vm-sni-listener.result
  key_vault_id = module.key_vault.id

  tags = var.tags
}

resource "azurerm_public_ip" "vm-sni-listener-ip" {
  name                = "${local.project}-vm-sni-listener-ip"
  resource_group_name = azurerm_resource_group.vnet_sni_listener_rg.name
  location            = var.location
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_interface" "vm-sni-listener" {
  name                 = format("%s-vm-sni-listener-nic", local.project)
  location             = var.location
  resource_group_name  = azurerm_resource_group.vnet_sni_listener_rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = format("%s-vm-sni-listener-nic", local.project)
    subnet_id                     = module.sni_listener_snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-sni-listener-ip.id
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "vm-sni-listener" {
  name                 = format("%s-vm-sni-listener", local.project)
  virtual_machine_id   = azurerm_linux_virtual_machine.vm-sni-listener.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "script" : base64encode(
      file("./init-sni-listener.sh")
    )
  })

  tags = var.tags
}
