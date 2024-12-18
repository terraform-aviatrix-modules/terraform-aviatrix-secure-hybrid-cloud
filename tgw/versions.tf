terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = ">= 3.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }
  required_version = ">= 1.5.0"
}
