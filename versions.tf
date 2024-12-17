terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = ">= 3.2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.14"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.7.0"
      version = ">= 5.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }
  required_version = ">= 1.5.0"
}
