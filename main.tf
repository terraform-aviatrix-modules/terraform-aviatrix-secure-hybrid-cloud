module "backbone" {
  source          = "terraform-aviatrix-modules/backbone/aviatrix"
  version         = "v1.2.2"
  transit_firenet = local.backbone
}
