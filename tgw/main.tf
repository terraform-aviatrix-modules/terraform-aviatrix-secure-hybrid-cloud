resource "aws_ec2_transit_gateway" "this" {
  description                     = "tgw"
  amazon_side_asn                 = "64512"
  transit_gateway_cidr_blocks     = ["192.168.101.0/24"]
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "tgw"
  }
}

resource "aviatrix_transit_external_device_conn" "this" {
  vpc_id             = var.transit_vpc.vpc_id
  connection_name    = "aws-tgw"
  gw_name            = var.transit_gw.gw_name
  connection_type    = "bgp"
  bgp_local_as_num   = var.transit_asn
  bgp_remote_as_num  = "64512"
  remote_gateway_ip  = "192.168.101.1"
  tunnel_protocol    = "GRE"
  local_tunnel_cidr  = "169.254.101.1/29,169.254.101.9/29"
  remote_tunnel_cidr = "169.254.101.2/29,169.254.101.10/29"
  enable_jumbo_frame = false
}

resource "aws_ec2_transit_gateway_connect" "this" {
  transport_attachment_id                         = aws_ec2_transit_gateway_vpc_attachment.this_transit.id
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_connect_peer" "this" {
  peer_address                  = var.transit_gw.private_ip
  inside_cidr_blocks            = ["169.254.101.0/29"]
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.this.id
  bgp_asn                       = var.transit_asn
  transit_gateway_address       = "192.168.101.1"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this_vpc" {
  subnet_ids                                      = var.spoke_vpc.public_subnets
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = var.spoke_vpc.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this_transit" {
  subnet_ids                                      = [var.transit_vpc.subnets[0].subnet_id, var.transit_vpc.subnets[2].subnet_id]
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = var.transit_vpc.vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "tgw-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this_1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_association" "this_2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this_1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this_2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_connect.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_route" "this" {
  count                  = 2
  route_table_id         = var.transit_vpc.route_tables[count.index]
  destination_cidr_block = "192.168.101.0/24"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "this_10" {
  count                  = 3
  route_table_id         = concat(var.spoke_vpc.public_route_table_ids, var.spoke_vpc.private_route_table_ids)[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "this_172" {
  count                  = 3
  route_table_id         = concat(var.spoke_vpc.public_route_table_ids, var.spoke_vpc.private_route_table_ids)[count.index]
  destination_cidr_block = "172.16.0.0/12"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "this_192" {
  count                  = 3
  route_table_id         = concat(var.spoke_vpc.public_route_table_ids, var.spoke_vpc.private_route_table_ids)[count.index]
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}
