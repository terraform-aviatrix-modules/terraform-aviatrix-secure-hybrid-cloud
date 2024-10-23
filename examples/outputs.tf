output "gatus_dashboard_urls" {
  value = {
    aws   = "http://${module.avx_hybrid_cloud.aws_instance.public_ip}"
    azure = "http://${module.avx_hybrid_cloud.azure_instance.public_ip_address}"
    edge  = "http://${module.avx_hybrid_cloud.edge_test_instance_pip}"
  }
  description = "URLs for the gatus dashboards"
}
