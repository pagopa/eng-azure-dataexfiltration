#
# general
#

variable "prefix" {
  type = string
  validation {
    condition = (
      length(var.prefix) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type = string
  validation {
    condition = (
      length(var.env) <= 3
    )
    error_message = "Max length is 3 chars."
  }
}

variable "env_short" {
  type = string
  validation {
    condition = (
      length(var.env_short) <= 1
    )
    error_message = "Max length is 1 chars."
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "location_short" {
  type        = string
  description = "Location short like eg: neu, weu.."
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "domain" {
  type = string
  validation {
    condition = (
      length(var.domain) <= 12
    )
    error_message = "Max length is 12 chars."
  }
}

#
# dns
#

variable "external_domain" {
  type        = string
  default     = null
  description = "Domain for delegation"
}

variable "dns_zone_internal_prefix" {
  type        = string
  default     = null
  description = "The dns subdomain."
}

variable "dns_zone_product_prefix" {
  type        = string
  default     = null
  description = "The dns subdomain."
}

#
# vnet
#

variable "cidr_vnet" {
  type        = list(string)
  description = "Address prefixes for vnet"
  default     = null
}

variable "firewall_cidr_vnet" {
  type        = list(string)
  description = "Address prefixes for firewall vnet"
  default     = null
}

variable "dns_cidr_vnet" {
  type        = list(string)
  description = "Address prefixes for dns vnet"
  default     = null
}

#
# private endpoint
#

variable "cidr_private_endpoint_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for private endpoints"
  default     = null
}

#
# dns forwarder
#

variable "cidr_dns_forwarder_vmss_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for dns forwarder vm scale set"
  default     = null
}

variable "cidr_dns_forwarder_lb_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for dns forwarder load balancer"
  default     = null
}

#
# appgw
#

variable "cidr_appgw_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for appgw"
  default     = null
}

#
# apim
#

variable "cidr_apim_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for apim"
  default     = null
}

#
# appservice
#

variable "cidr_appservice_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for appservice"
  default     = null
}

#
# vpn
#

variable "cidr_vpn_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for vpn"
  default     = null
}

#
# firewall
#

variable "cidr_firewall_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for firewall"
  default     = null
}

variable "cidr_firewall_management_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for firewall"
  default     = null
}

variable "application_rules" {
  type        = list(object({
      name              = optional(string)
      protocols         = optional(list(object({
        type = string
        port = number
      })))
      source_ips        = optional(list(string))
      destination_fqdns = optional(list(string))
  }))
  description = "Allowed domain list"
  default     = [{}]
}

#
# dns
#

variable "cidr_dns_inbound_subnet" {
  type        = list(string)
  description = "Address prefixes inbound subnet for dns"
  default     = null
}

variable "cidr_dns_outbound_subnet" {
  type        = list(string)
  description = "Address prefixes outbound subnet for dns"
  default     = null
}

variable "dns_allowed_domains" {
  type        = list(string)
  description = "Allowed domain list"
  default     = []
}

#
# sni-listener
#
variable "cidr_sni_listener_vnet" {
  type        = list(string)
  description = "Address prefixes vnet for sni listener"
  default     = null
}

variable "cidr_sni_listener_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for sni listener"
  default     = null
}

#
#function-app
#

variable "cidr_function_subnet" {
  type        = list(string)
  description = "Address prefixes subnet for function"
  default     = null
}