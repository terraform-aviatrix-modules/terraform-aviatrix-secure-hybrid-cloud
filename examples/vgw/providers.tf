provider "aviatrix" {
  username      = var.controller_username
  password      = var.controller_password
  controller_ip = var.controller_address
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
