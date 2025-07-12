# outputs.tf
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    grafana_ip     = aws_instance.grafana.public_ip,
    prometheus_ip  = aws_instance.prometheus.public_ip,
    app_hosts      = [aws_instance.app_host.public_ip] # Update if you have multiple
  })
  filename = "../ansible/inventory/production.ini"
}
# resource "local_file" "ansible_playbook" {
#   content = templatefile("${path.module}/playbook.tpl", {
#     grafana_ip     = aws_instance.grafana.public_ip,
#     prometheus_ip  = aws_instance.prometheus.public_ip,
#     app_hosts      = [aws_instance.app_host.public_ip] # Update if you have multiple
#   })
#   filename = "../ansible/playbooks/production.yml"
# }
output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
}
output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}
output "app_host_public_ip" {
  value = aws_instance.app_host.public_ip
}
