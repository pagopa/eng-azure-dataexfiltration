module "dns_vnet" {
  source              = "./.terraform/modules/__v3__/virtual_network/"
  name                = format("%s-dns-vnet", local.project)
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name
  address_space       = var.dns_cidr_vnet
  tags                = var.tags
}

resource "azurerm_subnet" "dns_inbound_snet" {
  name                 = format("%s-dns-inbound-snet", local.project)
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.dns_vnet.name
  address_prefixes     = var.cidr_dns_inbound_subnet

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
      name = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "dns_outbound_snet" {
  name                 = format("%s-dns-outbound-snet", local.project)
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = module.dns_vnet.name
  address_prefixes     = var.cidr_dns_outbound_subnet

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
      name = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_private_dns_resolver" "dns" {
  name                = format("%s-dnspr", local.project)
  resource_group_name = azurerm_resource_group.vnet_rg.name
  location            = azurerm_resource_group.vnet_rg.location
  virtual_network_id  = module.dns_vnet.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "dns" {
  name                    = format("%s-dnsin", local.project)
  private_dns_resolver_id = azurerm_private_dns_resolver.dns.id
  location                = azurerm_private_dns_resolver.dns.location
  ip_configurations {
    private_ip_allocation_method = "Static"
    subnet_id                    = azurerm_subnet.dns_inbound_snet.id
    private_ip_address           = cidrhost(azurerm_subnet.dns_inbound_snet.address_prefixes[0], 4)
  }

  tags = var.tags
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "dns" {
  name                    = format("%s-dnsout", local.project)
  private_dns_resolver_id = azurerm_private_dns_resolver.dns.id
  location                = azurerm_private_dns_resolver.dns.location
  subnet_id               = azurerm_subnet.dns_outbound_snet.id

  tags = var.tags
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "dns" {
  name                                       = format("%s-dnsfrs", local.project)
  resource_group_name                        = azurerm_resource_group.vnet_rg.name
  location                                   = azurerm_resource_group.vnet_rg.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.dns.id]

  tags = var.tags
}

resource "azurerm_private_dns_resolver_virtual_network_link" "dns" {
  name                      = module.vnet.name
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns.id
  virtual_network_id        = module.vnet.id
}

resource "azurerm_private_dns_resolver_forwarding_rule" "deny_all" {
  name                      = "deny-all"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns.id
  domain_name               = "."
  enabled                   = true
  target_dns_servers {
    ip_address = "127.0.0.1"
    port       = 53
  }
}

resource "azurerm_private_dns_resolver_forwarding_rule" "allow" {
  for_each                  = toset(var.dns_allowed_domains)
  name                      = "allow-${trim(replace(each.key, ".", "-"), "-")}"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns.id
  domain_name               = each.key
  enabled                   = true
  target_dns_servers {
    ip_address = azurerm_private_dns_resolver_inbound_endpoint.dns.ip_configurations[0].private_ip_address
    port       = 53
  }
}
