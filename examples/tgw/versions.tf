terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "~> 3.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
    http-full = {
      source  = "salrashid123/http-full"
      version = ">= 1.3.1"
    }
  }
  required_version = ">= 1.5.0"
}
