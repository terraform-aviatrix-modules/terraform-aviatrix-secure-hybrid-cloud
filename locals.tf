locals {
  backbone = {
    aws = {
      transit_name        = "transit-aws"
      transit_account     = var.avx_aws_account
      transit_cloud       = "aws"
      transit_cidr        = "10.1.0.0/23"
      transit_region_name = var.aws_region
      transit_asn         = 65101
      transit_ha_gw       = true
    },
    azure = {
      transit_name                        = "transit-azure"
      transit_account                     = var.avx_azure_account
      transit_cloud                       = "azure"
      transit_cidr                        = "10.2.0.0/23"
      transit_region_name                 = var.azure_region
      transit_asn                         = 65102
      transit_ha_gw                       = true
      transit_enable_bgp_over_lan         = true
      transit_bgp_lan_interfaces_count    = 1
      transit_ha_bgp_lan_interfaces_count = 1
      transit_enable_bgp_over_lan         = true
      transit_insane_mode                 = true
    },
  }
}
