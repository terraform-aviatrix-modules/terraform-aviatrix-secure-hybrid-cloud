variable "avx_aws_account" {
  type        = string
  description = "The name of the aws account onboarded to aviatrix"
  default     = "aws-account"
}

variable "avx_azure_account" {
  type        = string
  description = "The name of the azure account onboarded to aviatrix"
  default     = "azure-account"
}

variable "controller_password" {
  type        = string
  description = "Password for the aviatrix controller"
}

variable "controller_username" {
  type        = string
  description = "Username for the aviatrix controller"
}

variable "controller_address" {
  type        = string
  description = "URL or ip of the aviatrix controller"
}

variable "gcp_project" {
  type        = string
  description = "Gcp Project"
}

variable "aws_region" {
  type        = string
  description = "Aws region"
  default     = "us-east-1"
}

variable "gcp_region" {
  type        = string
  description = "Gcp region"
  default     = "us-west2"
}
