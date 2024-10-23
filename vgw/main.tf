resource "random_string" "random" {
  length           = 12
  upper            = true
  special          = true
  override_special = "._"
}

resource "aws_customer_gateway" "this" {
  bgp_asn    = var.transit_asn
  ip_address = var.transit_gw.eip
  type       = "ipsec.1"

  tags = {
    Name = "avx-transit-aws"
  }
}

resource "aws_vpn_gateway" "this" {
  vpc_id          = var.spoke_vpc.vpc_id
  amazon_side_asn = 65000

  tags = {
    Name = "aws-spoke-vpc"
  }
}

resource "aws_vpn_connection" "this" {
  vpn_gateway_id        = aws_vpn_gateway.this.id
  customer_gateway_id   = aws_customer_gateway.this.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_inside_cidr   = "169.254.100.0/30"
  tunnel1_preshared_key = random_string.random.id
}

resource "aws_route" "this" {
  route_table_id         = var.spoke_vpc.public_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = aws_vpn_gateway.this.id
}

resource "aviatrix_transit_external_device_conn" "this" {
  vpc_id             = var.transit_vpc.vpc_id
  connection_name    = "aws-vgw"
  gw_name            = var.transit_gw.gw_name
  connection_type    = "bgp"
  bgp_local_as_num   = var.transit_asn
  bgp_remote_as_num  = 65000
  remote_gateway_ip  = aws_vpn_connection.this.tunnel1_address
  pre_shared_key     = random_string.random.id
  local_tunnel_cidr  = "169.254.100.2/30,169.254.101.9/30"
  remote_tunnel_cidr = "169.254.100.1/30,169.254.101.10/30"
}
