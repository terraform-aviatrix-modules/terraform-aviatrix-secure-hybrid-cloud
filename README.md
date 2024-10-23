# terraform-aviatrix-secure-hybrid-cloud

## Description

This Terraform module deploys deploys an application VNET/VPC and [Gatus](https://gatus.io/) test instance in three clouds - `AWS`, `Azure`, and `GCP`. Each gatus instance is attempting to communicate to the other 2 over various ports. An Aviatrix transit backbone is deployed across `AWS` and `Azure`. Connectivity between the backbone and the application VNET/VPC is achieved by:

- `AWS` - BGP connection between an `AWS` Aviatrix transit gateway and `AWS` customer gateway via site-to-cloud vpn OR `AWS` transit gateway via IPSec over GRE.
- `Azure` - BGP connection between Azure route server and the `Azure` Aviatrix transit gateway with an NVA (network virtual appliance) propagating the spoke cidr to ARS.
- `GCP` - Aviatrix Edge as spoke.

### Diagram

The following depicts the topology deployed.

#### VGW

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-secure-hybrid-cloud/blob/main/img/vgw.png?raw=true" height="250">

#### TGW

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-secure-hybrid-cloud/blob/main/img/tgw.png?raw=true" height="250">

### Compatibility

| Module version | Terraform version | Controller version | Terraform provider version |
| :------------- | :---------------- | :----------------- | :------------------------- |
| v1.0.0         | >= 1.5.0          | >= 7.1             | ~>3.1.0                    |

## Usage Example

```terraform
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "avx_hybrid_cloud" {
  source              = "terraform-aviatrix-modules/secure-hybrid-cloud/aviatrix"
  version             = "1.0.0"
  avx_aws_account     = var.avx_aws_account
  avx_azure_account   = var.avx_azure_account
  password            = var.controller_password
  my_ip               = "${chomp(data.http.myip.response_body)}/32"
  vgw_or_tgw          = "vgw"
  edge_image_filename = "${path.module}/avx-gateway-avx-g3-202405121500.qcow2"
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

See [example terraform](examples). You may need to modify the csp providers to match your method used for authentication and account/subscription/project selection for each cloud. **NOTE:** If you modify the example provider regions, you should pass the same region into the module. See attributes below.

## Module Attributes

### Required

| key                 | value                                                  |
| :------------------ | :----------------------------------------------------- |
| avx_aws_account     | The name of the aws account onboarded to aviatrix      |
| avx_azure_account   | The name of the azure account onboarded to aviatrix    |
| password            | Password used for instances                            |
| my_ip               | Source ip for the deploying user                       |
| edge_image_filename | Full file path to the edge qcow on disk                |
| edge_image_location | Full file path to the edge qcow hosted in a gcp bucket |

**Note:** One of either `edge_image_filename` or `edge_image_locaton` is required.

### Optional

| Key                 |                                                                                                          Default value | Description                                     |
| :------------------ | ---------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------- |
| aws_region          |                                                                                                              us-east-1 | Aws region - must match provider region         |
| azure_region        |                                                                                                             Central US | Azure region                                    |
| gcp_region          |                                                                                                               us-west2 | Gcp region - must match provider region         |
| instance_sizes      | <br>aws = "t3.micro"</br><br>gcp = "n1-standard-1"</br><br>azure = "Standard_B1ms"</br><br>edge = "n1-standard-2"</br> | Instance sizes for each cloud provider          |
| gatus_private_ips   |                                   <br>aws = "10.1.2.40"</br><br>edge = "10.40.251.29"</br><br>azure = "10.2.2.40"</br> | Private ips for the gatus instances             |
| edge_instance_name  |                                                                                                          edge-instance | Name of the edge gatus instance                 |
| aws_instance_name   |                                                                                                           aws-instance | Name of the aws gatus instance                  |
| azure_instance_name |                                                                                                         azure-instance | Name of the azure gatus instance                |
| gatus_interval      |                                                                                                                      5 | Interval for gatus polling (in seconds)         |
| inbound_tcp         |                                                                                                     80 = ["0.0.0.0/0"] | Inbound tcp ports for gatus instances           |
| quagga_asn          |                                                                                                                  65516 | Quagga asn                                      |
| vgw_or_tgw          |                                                                                                                    vgw | Aws connectivity via aws transit or vpn gateway |

## Outputs

This module will return the following outputs:

| key                    | description                                         |
| :--------------------- | :-------------------------------------------------- |
| aws_instance           | The aws gatus instance with all of its attributes   |
| azure_instance         | The azure gatus instance with all of its attributes |
| edge_test_instance_pip | The edge gatus instance's public ip                 |

## Requirements

Before deploying this infrastructure, ensure that you meet the following requirements:

### Aviatrix Platform

Aviatrix Controller and Copilot instances deployed and configured with cloud accounts for `AWS` and `Azure`.

### Cloud Accounts

The following CSP accounts are required.

- AWS account
- Azure subscription
- GCP Project

### Edge

**QCOW2 File**: A qcow2 disk image is required for the kvm guest deployed in `GCP`. Ensure you have this file in the same folder as your terraform configuration or in a gcp bucket before starting the deployment. Using a gcp bucket saves the time to upload during deployment.

| Controller version | Ubuntu version | Qcow file                             |
| :----------------- | :------------- | :------------------------------------ |
| v7.1.x             | u18            | avx-edge-kvm-7.1-2023-04-24.qcow2     |
| v7.1.x             | u22            | avx-gateway-avx-g3-202405121500.qcow2 |

### Terraform

**Terraform Version 1.5.0 or later**: This module requires Terraform 1.5.0 or higher. You can install the latest version from the official Terraform website [here](https://www.terraform.io/downloads.html).

## Gatus Dashboards

Each gatus dashboard for a particular cloud depicts the real-time connectivity to the other 2 clouds. For example, the `Azure` dashboard would depict connectivity to `AWS` and `Edge`.

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-secure-hybrid-cloud/blob/main/img/gatus.png?raw=true" height="250">
