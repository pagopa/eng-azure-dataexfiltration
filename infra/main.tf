terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.71.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "=1.12.1"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "ac17914c-79bf-48fa-831e-1359ef74c1d5"
}

provider "azapi" {}

module "v3" {
  # source            = "git::https://github.com/pagopa/terraform-azurerm-v3.git?ref=v7.5.0"
  source = "git::github.com/pagopa/terraform-azurerm-v3.git?ref=154b3975a3d7f96a2f314b1215398c36451b5686"
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}