terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.95"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~>2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

module "__v3__" {
  # source            = "git::https://github.com/pagopa/terraform-azurerm-v3.git?ref=v8.53.0"
  source = "git::github.com/pagopa/terraform-azurerm-v3.git?ref=8405da92a68ffc8267fed02a4689e55387299248"
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "random_id" "unique" {
  byte_length = 3
}

output "project" {
  value = local.project
}
