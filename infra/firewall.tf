module "firewall_management_snet" {
  source               = "./.terraform/modules/__v3__/subnet/"
  name                 = "AzureFirewallManagementSubnet" # must be exactly this value
  address_prefixes     = var.cidr_firewall_management_subnet
  resource_group_name  = azurerm_resource_group.firewall_vnet_rg.name
  virtual_network_name = module.firewall_vnet.name
}

module "firewall_snet" {
  source               = "./.terraform/modules/__v3__/subnet/"
  name                 = "AzureFirewallSubnet" # must be exactly this value
  address_prefixes     = var.cidr_firewall_subnet
  resource_group_name  = azurerm_resource_group.firewall_vnet_rg.name
  virtual_network_name = module.firewall_vnet.name
}

resource "azurerm_public_ip" "firewall" {
  name                = format("%s-firewall-pip", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_vnet_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_public_ip" "firewall_management" {
  name                = format("%s-firewall-management-pip", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_vnet_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_firewall" "firewall" {
  name                = format("%s-firewall", local.project)
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_vnet_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  zones               = [1, 2, 3]
  firewall_policy_id  = azurerm_firewall_policy.main.id
  threat_intel_mode   = "Alert"

  ip_configuration {
    name                 = azurerm_public_ip.firewall.name
    public_ip_address_id = azurerm_public_ip.firewall.id
    subnet_id            = module.firewall_snet.id
  }

  management_ip_configuration {
    name                 = azurerm_public_ip.firewall_management.name
    public_ip_address_id = azurerm_public_ip.firewall_management.id
    subnet_id            = module.firewall_management_snet.id
  }

  tags = var.tags
}

resource "azurerm_firewall_policy" "main" {
  name                = format("%s-firewall-policy", local.project)
  resource_group_name = azurerm_resource_group.firewall_vnet_rg.name
  location            = var.location
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = format("%s-firewall", local.project)
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
