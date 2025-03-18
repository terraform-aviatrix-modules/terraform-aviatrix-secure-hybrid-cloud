module "backbone" {
  source          = "terraform-aviatrix-modules/backbone/aviatrix"
  version         = "v1.3.1"
  transit_firenet = local.backbone
  peering_mode    = var.transit_peering ? "custom" : "none"
  peering_map = var.transit_peering ? {
    peering1 : {
      gw1_name                                    = module.backbone.transit["aws"].transit_gateway.gw_name,
      gw2_name                                    = module.backbone.transit["azure"].transit_gateway.gw_name,
      enable_insane_mode_encryption_over_internet = var.enable_hpe
      enable_max_performance                      = var.enable_hpe
      gateway1_excluded_network_cidrs             = ["0.0.0.0/0"],
      gateway2_excluded_network_cidrs             = ["0.0.0.0/0"],
      tunnel_count                                = var.enable_hpe ? 2 : null
    }
  } : null
}
