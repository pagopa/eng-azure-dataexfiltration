resource "azurerm_subnet" "dns_firewall_management_snet" {
  name                 = "AzureFirewallManagementSubnet" # must be exactly this value
  resource_group_name  = azurerm_resource_group.firewall_vnet_rg.name
  virtual_network_name = module.firewall_vnet.name
  address_prefixes     = var.cidr_firewall_management_subnet
}

moved {
  from = module.firewall_management_snet.azurerm_subnet.this
  to   = azurerm_subnet.dns_firewall_management_snet
}

resource "azurerm_subnet" "dns_firewall_snet" {
  name                 = "AzureFirewallSubnet" # must be exactly this value
  resource_group_name  = azurerm_resource_group.firewall_vnet_rg.name
  virtual_network_name = module.firewall_vnet.name
  address_prefixes     = var.cidr_firewall_subnet
}

moved {
  from = module.firewall_snet.azurerm_subnet.this
  to   = azurerm_subnet.dns_firewall_snet
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
    subnet_id            = azurerm_subnet.dns_firewall_snet.id
  }

  management_ip_configuration {
    name                 = azurerm_public_ip.firewall_management.name
    public_ip_address_id = azurerm_public_ip.firewall_management.id
    subnet_id            = azurerm_subnet.dns_firewall_management_snet.id
  }

  tags = var.tags
}

resource "azurerm_firewall_policy" "main" {
  name                = format("%s-firewall-policy", local.project)
  resource_group_name = azurerm_resource_group.firewall_vnet_rg.name
  location            = var.location
}

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name                = format("%s-rule-collection-group", local.project)
  firewall_policy_id  = azurerm_firewall_policy.main.id
  priority            = 100
  
  application_rule_collection {
    name     = format("%s-application-rule-collection", local.project)
    action   = "Allow"
    priority = 100
    
    dynamic "rule" {
    for_each = var.application_rules
    
    content {
      name             = rule.value.name
      dynamic "protocols" {
        for_each = rule.value.protocols
        content {
             type = protocols.value.type
             port = protocols.value.port
        }
      }
      source_addresses = rule.value.source_ips
      destination_fqdns = rule.value.destination_fqdns
    }
  }
  }
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
