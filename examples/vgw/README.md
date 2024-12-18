### Usage Example AWS VGW

In this example, the `secure-hybrid-cloud` module deploys spoke connectivity using aws site-to-site vpn.

```hcl
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
  enable_hpe          = true
  edge_image_filename = "${path.module}/avx-gateway-avx-g3-202409102334.qcow2"
}

output "gatus_dashboard_urls" {
  value = {
    aws   = "http://${module.avx_hybrid_cloud.aws_instance.public_ip}"
    azure = "http://${module.avx_hybrid_cloud.azure_instance.public_ip_address}"
    edge  = "http://${module.avx_hybrid_cloud.edge_test_instance_pip}"
  }
  description = "URLs for the gatus dashboards"
}
```
