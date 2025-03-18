variable "avx_aws_account" {
  type        = string
  description = "The name of the aws account onboarded to aviatrix"
}

variable "avx_azure_account" {
  type        = string
  description = "The name of the azure account onboarded to aviatrix"
}

variable "password" {
  type        = string
  description = "Password used for instances"
}

variable "aws_region" {
  type        = string
  description = "Aws region"
  default     = "us-east-1"
}

variable "azure_region" {
  type        = string
  description = "Azure region"
  default     = "Central US"
}

variable "gcp_region" {
  type        = string
  description = "Gcp region"
  default     = "us-west2"
}

variable "instance_sizes" {
  type        = map(string)
  description = "Instance sizes for each cloud provider"
  default = {
    aws   = "t3.micro"
    gcp   = "n1-standard-1"
    azure = "Standard_B1ms"
    edge  = "n1-standard-2"
  }
}

variable "gatus_private_ips" {
  type        = map(string)
  description = "Private ips for the gatus instances"
  default = {
    aws   = "10.1.2.40"
    edge  = "10.40.251.29"
    azure = "10.2.2.40"
  }
}

variable "edge_instance_name" {
  type        = string
  description = "Name of the edge gatus instance"
  default     = "edge-instance"
}

variable "aws_instance_name" {
  type        = string
  description = "Name of the aws gatus instance"
  default     = "aws-instance"
}

variable "azure_instance_name" {
  type        = string
  description = "Name of the azure gatus instance"
  default     = "azure-instance"
}

variable "gatus_interval" {
  type        = string
  description = "Interval for gatus polling (in seconds)"
  default     = "5"
}

variable "inbound_tcp" {
  type        = map(list(string))
  description = "Inbound tcp ports for gatus instances"
  default = {
    80 = ["0.0.0.0/0"]
  }
}

variable "quagga_asn" {
  type        = number
  description = "Quagga asn"
  default     = 65516
}

variable "my_ip" {
  type        = string
  description = "Source ip for the deploying user"
}

variable "edge_attachment" {
  type        = bool
  description = "Attach edge to the transits"
  default     = true
}

variable "edge_image_filename" {
  type        = string
  description = "Full file path to the edge qcow"
  default     = null
}

variable "edge_image_location" {
  type        = string
  description = "Full file path to the edge qcow hosted in a gcp bucket"
  default     = null
}

variable "transit_peering" {
  type        = bool
  description = "Peer transit gateways"
  default     = true
}


variable "vgw_or_tgw" {
  type        = string
  description = "Aws connectivity via aws transit or vpn gateway"
  default     = "vgw"
  validation {
    condition     = contains(["vgw", "tgw"], lower(var.vgw_or_tgw))
    error_message = "Invalid AWS gateway option. Choose vgw or tgw."
  }
}

variable "enable_hpe" {
  description = "Enable high performance encryption on the edge to transit attachment"
  default     = true
}
