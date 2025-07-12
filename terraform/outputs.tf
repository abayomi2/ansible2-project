# outputs.tf
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    grafana_ip     = aws_instance.grafana.public_ip,
    prometheus_ip  = aws_instance.prometheus.public_ip,
    app_hosts      = [aws_instance.app_host.public_ip] # Update if you have multiple
  })
  filename = "../ansible/inventory/production.ini"
}