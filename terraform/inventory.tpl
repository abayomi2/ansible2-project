[grafana_server]
${grafana_ip}

[prometheus_server]
${prometheus_ip}

[host_servers]
%{ for host in app_hosts ~}
${host}
%{ endfor ~}

[all:vars]
ansible_user=ubuntu
