module "spoke_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "spoke-aws"
  cidr = "10.1.2.0/24"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = [cidrsubnet("10.1.2.0/24", 4, 0), cidrsubnet("10.1.2.0/24", 4, 1)]
  public_subnets  = [cidrsubnet("10.1.2.0/24", 4, 2), cidrsubnet("10.1.2.0/24", 4, 3)]

  enable_nat_gateway = false
  enable_vpn_gateway = false

}

resource "aws_security_group" "spoke_gatus" {
  name        = "${var.aws_instance_name}-sg"
  description = "Instance security group"
  vpc_id      = module.spoke_vpc.vpc_id
}

resource "aws_security_group_rule" "spoke_gatus_rfc1918" {
  type              = "ingress"
  description       = "Allow all inbound from rfc1918"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  security_group_id = aws_security_group.spoke_gatus.id
}

resource "aws_security_group_rule" "spoke_gatus_inbound_tcp" {
  for_each          = var.inbound_tcp
  type              = "ingress"
  description       = "Allow inbound access from cidrs"
  from_port         = strcontains(each.key, "-") ? split("-", each.key)[0] : each.key
  to_port           = strcontains(each.key, "-") ? split("-", each.key)[1] : each.key
  protocol          = each.key == "0" ? "-1" : "tcp"
  cidr_blocks       = each.value
  security_group_id = aws_security_group.spoke_gatus.id
}

resource "aws_security_group_rule" "spoke_gatus_egress" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.spoke_gatus.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "spoke_gatus" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_sizes["aws"]
  ebs_optimized               = false
  source_dest_check           = false
  monitoring                  = true
  subnet_id                   = module.spoke_vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.spoke_gatus.id]
  private_ip                  = var.gatus_private_ips["aws"]

  user_data = templatefile("${path.module}/templates/gatus.tpl",
    {
      name     = var.aws_instance_name
      cloud    = "AWS"
      interval = var.gatus_interval
      inter    = "${var.gatus_private_ips["azure"]},${var.gatus_private_ips["edge"]}"
      password = var.password
  })

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
  tags = {
    Name = var.aws_instance_name
  }
}

module "vgw" {
  count       = lower(var.vgw_or_tgw) == "vgw" ? 1 : 0
  source      = "./vgw"
  transit_asn = local.backbone["aws"].transit_asn
  transit_gw  = module.backbone.transit["aws"].transit_gateway
  transit_vpc = module.backbone.transit["aws"].vpc
  spoke_vpc   = module.spoke_vpc
}

module "tgw" {
  count       = lower(var.vgw_or_tgw) == "tgw" ? 1 : 0
  source      = "./tgw"
  transit_asn = local.backbone["aws"].transit_asn
  transit_gw  = module.backbone.transit["aws"].transit_gateway
  transit_vpc = module.backbone.transit["aws"].vpc
  spoke_vpc   = module.spoke_vpc
}
