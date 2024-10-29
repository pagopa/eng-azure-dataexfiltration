resource "azurerm_resource_group" "vm_rg" {
  name     = format("%s-vm-rg", local.project)
  location = var.location
  tags     = var.tags
}

resource "random_password" "vm" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "vm_password" {
  name         = "${local.project}-vm"
  value        = random_password.vm.result
  key_vault_id = module.key_vault.id

  tags = var.tags
}

resource "azurerm_network_interface" "vm" {
  name                 = format("%s-vm-nic", local.project)
  location             = var.location
  resource_group_name  = azurerm_resource_group.vm_rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = format("%s-vm-nic", local.project)
    subnet_id                     = azurerm_subnet.appservice_snet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

output "vm_private_ip_address" {
  value = azurerm_network_interface.vm.private_ip_address
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = format("%s-vm", local.project)
  location                        = var.location
  resource_group_name             = azurerm_resource_group.vm_rg.name
  network_interface_ids           = [azurerm_network_interface.vm.id]
  size                            = "Standard_B1ls"
  disable_password_authentication = false

  admin_username = "azureuser"
  admin_password = random_password.vm.result

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
