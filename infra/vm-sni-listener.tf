resource "azurerm_resource_group" "vm_sni_listener_rg" {
  name     = format("%s-vm-sni-listener-rg", local.project)
  location = var.location
  tags     = var.tags
}

resource "random_password" "vm_sni_listener" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "vm_sni_listener_password" {
  name         = "${local.project}-vm-sni-listener-password"
  value        = random_password.vm_sni_listener.result
  key_vault_id = module.key_vault.id

  tags = var.tags
}

module "sni_listener_vnet" {
  source              = "./.terraform/modules/__v3__/virtual_network/"
  name                = format("%s-vm-sni-listener-vnet", local.project)
  location            = azurerm_resource_group.vm_sni_listener_rg.location
  resource_group_name = azurerm_resource_group.vm_sni_listener_rg.name
  address_space       = var.cidr_sni_listener_vnet
  tags                = var.tags
}

resource "azurerm_subnet" "vm_sni_listener_snet" {
  name                 = format("%s-vm-sni-listener-snet", local.project)
  resource_group_name  = azurerm_resource_group.vm_sni_listener_rg.name
  virtual_network_name = module.sni_listener_vnet.name
  address_prefixes     = var.cidr_sni_listener_subnet
}

resource "azurerm_linux_virtual_machine" "vm_sni_listener" {
  name                            = format("%s-vm-sni-listener", local.project)
  location                        = azurerm_resource_group.vm_sni_listener_rg.location
  resource_group_name             = azurerm_resource_group.vm_sni_listener_rg.name
  network_interface_ids           = [azurerm_network_interface.vm_sni_listener.id]
  size                            = "Standard_B1ls"
  disable_password_authentication = false

  admin_username = "azureuser"
  admin_password = random_password.vm_sni_listener.result

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

resource "azurerm_public_ip" "vm_sni_listener_ip" {
  name                = "${local.project}-vm-sni-listener-ip"
  location            = azurerm_resource_group.vm_sni_listener_rg.location
  resource_group_name = azurerm_resource_group.vm_sni_listener_rg.name
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_interface" "vm_sni_listener" {
  name                 = format("%s-vm-sni-listener-nic", local.project)
  location             = var.location
  resource_group_name  = azurerm_resource_group.vm_sni_listener_rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = format("%s-vm-sni-listener-nic", local.project)
    subnet_id                     = azurerm_subnet.vm_sni_listener_snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_sni_listener_ip.id
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "vm_sni_listener" {
  name                 = format("%s-vm-sni-listener", local.project)
  virtual_machine_id   = azurerm_linux_virtual_machine.vm_sni_listener.id
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

output "vm_sni_listener_public_ip_address" {
  value = azurerm_public_ip.vm_sni_listener_ip.ip_address
}
