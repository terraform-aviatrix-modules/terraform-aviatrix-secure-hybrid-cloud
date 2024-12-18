# Azure spoke - ARS/NVA
resource "azurerm_resource_group" "spoke_azure" {
  name     = "spoke-azure"
  location = var.azure_region
}

resource "azurerm_route_table" "spoke_azure_public" {
  location                      = var.azure_region
  name                          = "spoke-azure-public-rt"
  resource_group_name           = azurerm_resource_group.spoke_azure.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route_table" "spoke_azure_private" {
  location            = var.azure_region
  name                = "spoke-azure-private-rt"
  resource_group_name = azurerm_resource_group.spoke_azure.name
}

module "spoke_azure" {
  source              = "Azure/vnet/azurerm"
  version             = "5.0.1"
  vnet_name           = "spoke-azure"
  resource_group_name = azurerm_resource_group.spoke_azure.name
  vnet_location       = azurerm_resource_group.spoke_azure.location
  use_for_each        = true
  address_space       = ["10.2.2.0/24"]
  subnet_names        = ["private-subnet", "public-subnet"]
  subnet_prefixes     = [cidrsubnet("10.2.2.0/24", 4, 0), cidrsubnet("10.2.2.0/24", 4, 2)]
  route_tables_ids = {
    private-subnet = azurerm_route_table.spoke_azure_private.id,
    public-subnet  = azurerm_route_table.spoke_azure_public.id,
  }
}

data "azurerm_virtual_network" "spoke_azure" {
  name                = module.spoke_azure.vnet_name
  resource_group_name = azurerm_resource_group.spoke_azure.name
  depends_on = [
    module.spoke_azure
  ]
}

resource "azurerm_virtual_network" "ars" {
  name                = "ars-vnet"
  address_space       = ["10.2.4.0/24"]
  resource_group_name = azurerm_resource_group.spoke_azure.name
  location            = azurerm_resource_group.spoke_azure.location
}

# azure route server
resource "azurerm_subnet" "ars" {
  name                 = "RouteServerSubnet"
  virtual_network_name = azurerm_virtual_network.ars.name
  resource_group_name  = azurerm_resource_group.spoke_azure.name
  address_prefixes     = ["10.2.4.0/27"]
}

resource "azurerm_subnet" "nva" {
  name                 = "NvaSubnet"
  virtual_network_name = azurerm_virtual_network.ars.name
  resource_group_name  = azurerm_resource_group.spoke_azure.name
  address_prefixes     = ["10.2.4.32/28"]
}

resource "azurerm_public_ip" "ars" {
  name                = "ars-pip"
  resource_group_name = azurerm_resource_group.spoke_azure.name
  location            = azurerm_resource_group.spoke_azure.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "default" {
  name                             = "backbone-route-server"
  resource_group_name              = azurerm_resource_group.spoke_azure.name
  location                         = azurerm_resource_group.spoke_azure.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars.id
  subnet_id                        = azurerm_subnet.ars.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "transit_gw" {
  name            = "transit-gw-bgp"
  route_server_id = azurerm_route_server.default.id
  peer_asn        = local.backbone["azure"].transit_asn
  peer_ip         = module.backbone.transit["azure"].transit_gateway.bgp_lan_ip_list[0]
}

resource "azurerm_route_server_bgp_connection" "transit_gw_2" {
  name            = "transit-gw-bgp-2"
  route_server_id = azurerm_route_server.default.id
  peer_asn        = local.backbone["azure"].transit_asn
  peer_ip         = module.backbone.transit["azure"].transit_gateway.ha_bgp_lan_ip_list[0]
}

data "azurerm_subscription" "current" {}

resource "azurerm_virtual_network_peering" "ars_transit" {
  name                         = "ars-transit"
  remote_virtual_network_id    = module.backbone.transit["azure"].vpc.azure_vnet_resource_id
  resource_group_name          = azurerm_resource_group.spoke_azure.name
  virtual_network_name         = azurerm_virtual_network.ars.name
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true

  depends_on = [
    azurerm_route_server.default
  ]
}

resource "azurerm_virtual_network_peering" "transit_ars" {
  name                         = "transit-ars"
  remote_virtual_network_id    = azurerm_virtual_network.ars.id
  resource_group_name          = module.backbone.transit["azure"].vpc.resource_group
  virtual_network_name         = module.backbone.transit["azure"].vpc.name
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = true

  depends_on = [
    azurerm_virtual_network_peering.ars_transit,
    azurerm_route_server.default
  ]
}

resource "azurerm_virtual_network_peering" "spoke_ars" {
  name                         = "spoke-ars"
  remote_virtual_network_id    = azurerm_virtual_network.ars.id
  resource_group_name          = azurerm_resource_group.spoke_azure.name
  virtual_network_name         = module.spoke_azure.vnet_name
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = false

  depends_on = [
    azurerm_route_server.default,
    azurerm_virtual_network_peering.ars_spoke
  ]
}

resource "azurerm_virtual_network_peering" "ars_spoke" {
  name                         = "ars-spoke"
  remote_virtual_network_id    = module.spoke_azure.vnet_id
  resource_group_name          = azurerm_resource_group.spoke_azure.name
  virtual_network_name         = azurerm_virtual_network.ars.name
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false

  depends_on = [
    azurerm_route_server.default
  ]
}

resource "aviatrix_transit_external_device_conn" "azure_ars" {
  vpc_id                    = module.backbone.transit["azure"].vpc.vpc_id
  connection_name           = "azure-rs-spoke"
  gw_name                   = module.backbone.transit["azure"].transit_gateway.gw_name
  connection_type           = "bgp"
  tunnel_protocol           = "LAN"
  remote_vpc_name           = format("%s:%s:%s", azurerm_virtual_network.ars.name, azurerm_resource_group.spoke_azure.name, data.azurerm_subscription.current.subscription_id)
  ha_enabled                = true
  bgp_local_as_num          = local.backbone["azure"].transit_asn
  bgp_remote_as_num         = azurerm_route_server.default.virtual_router_asn
  backup_bgp_remote_as_num  = azurerm_route_server.default.virtual_router_asn
  remote_lan_ip             = tolist(azurerm_route_server.default.virtual_router_ips)[0]
  backup_remote_lan_ip      = tolist(azurerm_route_server.default.virtual_router_ips)[1]
  enable_bgp_lan_activemesh = true
  depends_on                = [azurerm_virtual_network_peering.transit_ars]
}

# nva
resource "azurerm_network_interface" "nva" {
  name                  = "nva"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.spoke_azure.name
  ip_forwarding_enabled = true
  ip_configuration {
    name                          = "nva"
    subnet_id                     = azurerm_subnet.nva.id
    public_ip_address_id          = azurerm_public_ip.nva.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.4.40"
  }
}

resource "azurerm_public_ip" "nva" {
  allocation_method   = "Static"
  location            = var.azure_region
  name                = "nva-pip"
  resource_group_name = azurerm_resource_group.spoke_azure.name
  sku                 = "Standard"
}

resource "azurerm_route" "spoke_nva" {
  name                   = "spoke_nva"
  resource_group_name    = azurerm_resource_group.spoke_azure.name
  route_table_name       = azurerm_route_table.spoke_azure_private.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.nva.private_ip_address
}

resource "azurerm_route" "spoke_nva_public_10" {
  name                   = "spoke_nva_public_10"
  resource_group_name    = azurerm_resource_group.spoke_azure.name
  route_table_name       = azurerm_route_table.spoke_azure_public.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.nva.private_ip_address
}

resource "azurerm_route" "spoke_nva_public_192" {
  name                   = "spoke_nva_public_192"
  resource_group_name    = azurerm_resource_group.spoke_azure.name
  route_table_name       = azurerm_route_table.spoke_azure_public.name
  address_prefix         = "192.168.0.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.nva.private_ip_address
}

resource "azurerm_route" "spoke_nva_public_172" {
  name                   = "spoke_nva_public_172"
  resource_group_name    = azurerm_resource_group.spoke_azure.name
  route_table_name       = azurerm_route_table.spoke_azure_public.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.nva.private_ip_address
}

resource "azurerm_linux_virtual_machine" "nva" {
  name                  = "nva"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.spoke_azure.name
  network_interface_ids = [azurerm_network_interface.nva.id]
  admin_username        = "nva_user"
  admin_password        = var.password
  computer_name         = "nva"
  size                  = "Standard_B1ls"
  custom_data = base64encode(templatefile("${path.module}/templates/quagga.tpl",
    {
      asn_quagga      = var.quagga_asn
      bgp_routerId    = azurerm_network_interface.nva.ip_configuration[0].private_ip_address
      bgp_network1    = tolist(module.spoke_azure.vnet_address_space)[0]
      bgp_network2    = tolist(azurerm_virtual_network.ars.address_space)[0]
      routeserver_IP1 = tolist(azurerm_route_server.default.virtual_router_ips)[0]
      routeserver_IP2 = tolist(azurerm_route_server.default.virtual_router_ips)[1]
  }))
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_security_group" "nva" {
  name                = "nva"
  resource_group_name = azurerm_resource_group.spoke_azure.name
  location            = var.azure_region
}

resource "azurerm_network_interface_security_group_association" "nva" {
  network_interface_id      = azurerm_network_interface.nva.id
  network_security_group_id = azurerm_network_security_group.nva.id
}

resource "azurerm_network_security_rule" "nva_rfc_1918" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "nva-rfc-1918"
  priority                    = 100
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_azure.name
  network_security_group_name = azurerm_network_security_group.nva.name
}

resource "azurerm_network_security_rule" "nva_ssh" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "nva-ssh"
  priority                    = 110
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = var.my_ip
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_azure.name
  network_security_group_name = azurerm_network_security_group.nva.name
}

resource "azurerm_network_security_rule" "nva_forward" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "nva-forward"
  priority                    = 110
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_azure.name
  network_security_group_name = azurerm_network_security_group.nva.name
}

resource "azurerm_route_server_bgp_connection" "nva" {
  name            = "nva-to-ars-peer"
  peer_asn        = var.quagga_asn
  peer_ip         = azurerm_network_interface.nva.private_ip_address
  route_server_id = azurerm_route_server.default.id
}

# Azure gatus instance
resource "azurerm_public_ip" "spoke_gatus" {
  count               = 1
  name                = "${var.azure_instance_name}-pub-ip"
  location            = module.spoke_azure.vnet_location
  resource_group_name = azurerm_resource_group.spoke_azure.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "spoke_gatus" {
  name                = var.azure_instance_name
  location            = module.spoke_azure.vnet_location
  resource_group_name = azurerm_resource_group.spoke_azure.name
  ip_configuration {
    name                          = var.azure_instance_name
    subnet_id                     = lookup(module.spoke_azure.vnet_subnets_name_id, "public-subnet")
    private_ip_address_allocation = "Static"
    private_ip_address            = var.gatus_private_ips["azure"]
    public_ip_address_id          = azurerm_public_ip.spoke_gatus[0].id
  }
}

resource "azurerm_linux_virtual_machine" "spoke_gatus" {
  name                            = var.azure_instance_name
  location                        = module.spoke_azure.vnet_location
  resource_group_name             = azurerm_resource_group.spoke_azure.name
  network_interface_ids           = [azurerm_network_interface.spoke_gatus.id]
  admin_username                  = "ubuntu"
  admin_password                  = var.password
  computer_name                   = var.azure_instance_name
  size                            = var.instance_sizes["azure"]
  source_image_id                 = null
  disable_password_authentication = false

  custom_data = base64encode(templatefile("${path.module}/templates/gatus.tpl",
    {
      name     = var.azure_instance_name
      cloud    = "Azure"
      interval = var.gatus_interval
      inter    = "${var.gatus_private_ips["aws"]},${var.gatus_private_ips["edge"]}"
      password = var.password
  }))

  dynamic "source_image_reference" {
    for_each = ["ubuntu"]

    content {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_security_group" "spoke_gatus" {
  name                = var.azure_instance_name
  resource_group_name = azurerm_resource_group.spoke_azure.name
  location            = module.spoke_azure.vnet_location
}

resource "azurerm_network_interface_security_group_association" "spoke_gatus" {
  network_interface_id      = azurerm_network_interface.spoke_gatus.id
  network_security_group_id = azurerm_network_security_group.spoke_gatus.id
}

resource "azurerm_network_security_rule" "spoke_gatus_rfc_1918" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "rfc-1918"
  priority                    = 100
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefixes     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_azure.name
  network_security_group_name = azurerm_network_security_group.spoke_gatus.name
}

resource "azurerm_network_security_rule" "spoke_gatus_inbound_tcp" {
  for_each                    = var.inbound_tcp
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "inbound_tcp_${each.key}"
  priority                    = (index(keys(var.inbound_tcp), each.key) + 101)
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefixes     = each.value
  destination_port_range      = each.key
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.spoke_azure.name
  network_security_group_name = azurerm_network_security_group.spoke_gatus.name
}
