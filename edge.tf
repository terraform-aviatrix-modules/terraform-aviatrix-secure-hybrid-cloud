module "edge" {
  source              = "terraform-aviatrix-modules/gcp-edge-demo/aviatrix"
  version             = "3.2.0"
  region              = var.gcp_region
  pov_prefix          = "aviatrix"
  host_vm_size        = var.instance_sizes["edge"]
  test_vm_size        = var.instance_sizes["gcp"]
  host_vm_cidr        = "10.40.251.16/28"
  host_vm_asn         = 64900
  host_vm_count       = 1
  edge_vm_asn         = 64581
  edge_lan_cidr       = "10.40.251.0/29"
  edge_image_filename = var.edge_image_filename
  edge_image_location = var.edge_image_location
  test_vm_internet_ingress_ports = [
    "80"
  ]
  test_vm_metadata_startup_script = templatefile("${path.module}/templates/gatus.tpl", {
    name     = var.edge_instance_name
    cloud    = "Edge"
    interval = var.gatus_interval
    inter    = "${var.gatus_private_ips["aws"]},${var.gatus_private_ips["azure"]}"
    password = var.password
  })
  external_cidrs = []
  transit_gateways = [
    module.backbone.transit["aws"].transit_gateway.gw_name,
    module.backbone.transit["azure"].transit_gateway.gw_name,
  ]
}

resource "google_compute_firewall" "rfc1918_ingress" {
  name    = "rfc1918-ingress"
  network = "aviatrix-vpc"

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  target_tags   = ["test-instance"]
  depends_on    = [module.edge]
}

