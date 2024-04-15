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

cidr_vnet = ["10.0.0.0/16"]

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