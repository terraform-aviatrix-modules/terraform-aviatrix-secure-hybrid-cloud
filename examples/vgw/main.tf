data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "avx_hybrid_cloud" {
  source              = "terraform-aviatrix-modules/secure-hybrid-cloud/aviatrix"
  version             = "1.1.0"
  avx_aws_account     = var.avx_aws_account
  avx_azure_account   = var.avx_azure_account
  password            = var.controller_password
  my_ip               = "${chomp(data.http.myip.response_body)}/32"
  vgw_or_tgw          = "vgw"
  edge_image_filename = "${path.module}/avx-gateway-avx-g3-202405121500.qcow2"
}
