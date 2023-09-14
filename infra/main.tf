terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.71.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = "ac17914c-79bf-48fa-831e-1359ef74c1d5"
}

module "v3" {
  # source            = "git::https://github.com/pagopa/terraform-azurerm-v3.git?ref=v7.5.0"
  source = "git::github.com/pagopa/terraform-azurerm-v3.git/"
}