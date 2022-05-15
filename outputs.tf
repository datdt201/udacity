output "lb_url" {
  value = "http://${azurerm_public_ip.lb.ip_address}:${var.application_port}"
}
