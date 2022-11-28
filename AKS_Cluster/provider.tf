terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.14.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-alef-rg"
    storage_account_name = "tfstatestorealef"
    container_name       = "tf-state"
    key                  = "tf-k8s-cluster.tfstate"
  }
}