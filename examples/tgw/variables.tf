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

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription id"
}

variable "azure_application_id" {
  type        = string
  description = "Azure application id"
}

variable "azure_application_key" {
  type        = string
  description = "Azure application key"
}

variable "azure_directory_id" {
  type        = string
  description = "Azure directory id"
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
