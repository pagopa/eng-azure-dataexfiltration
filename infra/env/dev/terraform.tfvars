#
# general
#

env_short      = "d"
env            = "dev"
prefix         = "dex2"
location       = "westeurope"
location_short = "weu"
domain         = "core"

tags = {
  CreatedBy   = "Terraform"
  Environment = "DEV"
  Owner       = "Azure Data Exfiltration Lab"
  Source      = "https://github.com/pagopa/eng-data-exfiltration-demo"
  CostCenter  = "TS110 - Technology"
}

#
# dns
#

dns_zone_product_prefix  = "dev.dex"
external_domain          = "pagopa.it"
dns_zone_internal_prefix = "internal.dev.dex"

#
# vnet
#

cidr_vnet          = ["10.0.0.0/16"]
firewall_cidr_vnet = ["10.1.0.0/16"]
dns_cidr_vnet      = ["10.3.0.0/16"]

#
# private endpoints
#

cidr_private_endpoint_subnet = ["10.0.250.0/24"]

#
# dns forwarder
#

cidr_dns_forwarder_vmss_subnet = ["10.0.252.0/26"]
cidr_dns_forwarder_lb_subnet   = ["10.0.252.64/26"]

#
# appgw
#

cidr_appgw_subnet = ["10.0.1.0/24"]

#
# apim
#

cidr_apim_subnet = ["10.0.2.0/24"]

#
# appservice
#

cidr_appservice_subnet = ["10.0.3.0/24"]

#
# vpn
#

cidr_vpn_subnet = ["10.0.254.0/24"]

#
# firewall
#
cidr_firewall_subnet            = ["10.1.0.0/24"]
cidr_firewall_management_subnet = ["10.1.1.0/24"]

#
# dns
#

cidr_dns_inbound_subnet  = ["10.3.0.0/24"]
cidr_dns_outbound_subnet = ["10.3.1.0/24"]

dns_allowed_domains = [
  "pagopa.it.",
  "microsoftonline.com.",
  "azure.com.",
  "google.com.",
  "terraform.io.",
  "github.com.",
]

#
# sni-listener
#

cidr_sni_listener_vnet   = ["10.2.0.0/16"]
cidr_sni_listener_subnet = ["10.2.0.0/24"]
