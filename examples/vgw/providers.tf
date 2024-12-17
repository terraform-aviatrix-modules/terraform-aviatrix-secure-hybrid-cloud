provider "aviatrix" {
  username      = var.controller_username
  password      = var.controller_password
  controller_ip = var.controller_address
}

provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "google" {
  project = var.gcp_project
  region  = "us-west2"
}
