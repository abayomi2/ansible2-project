Production-Grade Application Deployment with Terraform and Ansible
This project automates the deployment of a containerized application and a full observability stack (Prometheus & Grafana) on AWS. It follows Infrastructure as Code (IaC) and Configuration Management best practices to create a secure, scalable, and repeatable production-grade environment.

This document provides a complete guide from setup to deployment, incorporating lessons learned from a full debugging cycle.

Table of Contents
Architecture

Features

Project Structure

Prerequisites

Deployment Guide

Step 1: Environment Setup

Step 2: Provision Infrastructure

Step 3: Configure Servers

Step 4: Verify the Deployment

Troubleshooting Common Issues

Next Steps: CI/CD Automation

Cleanup

Architecture
This project uses a decoupled architecture where infrastructure provisioning is handled by Terraform and server configuration is managed by Ansible.

Terraform: Provisions all necessary AWS resources, including:

Three EC2 instances (for the Application, Prometheus, and Grafana).

Three granular Security Groups to enforce a strict network firewall, allowing traffic only where necessary and ensuring services communicate over their private IPs.

An SSH key pair for secure access.

After provisioning, Terraform dynamically generates an inventory file for Ansible.

Ansible: Configures the provisioned EC2 instances using a role-based structure:

common: Installs common packages and sets up basic security on all servers.

app_host: Installs Docker and deploys the specified containerized application.

node_exporter: Installs and runs Node Exporter on the application host to collect system metrics.

prometheus: Installs and configures Prometheus on its dedicated server. It's configured to scrape metrics from Node Exporter using the server's private IP address and load critical alerting rules.

grafana: Installs and configures Grafana. It automatically adds Prometheus as a data source (using its private IP) and imports a complete, pre-configured "Node Exporter Full" dashboard from a local JSON file.

Observability Flow:

Node Exporter exposes metrics on the app server (port 9100).

Prometheus scrapes these metrics over the private network (port 9090).

Grafana queries Prometheus over the private network and visualizes the data (port 3000).

Features
Fully Automated Deployment: From cloud resources to application code, the entire stack is deployed automatically.

Infrastructure as Code (IaC): All infrastructure is defined in Terraform, ensuring consistency and version control.

Configuration as Code: Server state is defined using Ansible Roles, promoting modularity and reusability.

Secure by Default:

Uses SSH keys for access (no password authentication).

Implements the principle of least privilege with strict Security Group rules.

Manages secrets (like the Grafana password) securely using Ansible Vault.

Production-Ready Observability:

A complete monitoring and visualization stack is set up.

Prometheus alerting rules are included for high CPU, memory, and disk usage.

A comprehensive Grafana dashboard is deployed from a local file for consistent, detailed visualization.

Idempotent: Both Terraform and Ansible playbooks can be run multiple times, with the system converging to the same desired state without errors.

Project Structure
.
├── ansible/
│   ├── roles/
│   │   ├── app_host/
│   │   ├── common/
│   │   ├── grafana/
│   │   │   └── files/
│   │   │       └── node_exporter_dashboard.json  # Corrected dashboard
│   │   ├── node_exporter/
│   │   └── prometheus/
│   │       └── templates/
│   │           └── alert.rules.yml.j2          # Alerting rules
│   ├── group_vars/
│   │   └── all/
│   │       └── vault.yml                       # Encrypted secrets
│   ├── inventory/
│   │   └── production.ini                      # Dynamically generated
│   ├── ansible.cfg                             # Ansible configuration
│   └── main-playbook.yml                       # Main playbook
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   └── inventory.tpl
└── prod-kp.pem                                 # SSH Private Key

Prerequisites
AWS Account: With credentials configured for the AWS CLI.

Terraform: Installed locally.

Ansible: Installed locally.

AWS CLI: Installed and configured (aws configure).

SSH Key Pair: An SSH key pair created in the target AWS region.

Docker Hub Image: A containerized application image pushed to Docker Hub.

WSL (for Windows users): It is critical to run this project from within the WSL home directory (~/), not from a mounted Windows drive (/mnt/c/).

Deployment Guide
Step 1: Environment Setup
Clone the Repository into your WSL Home:

cd ~
git clone <your-repo-url>
cd <your-project-directory>

Set File and Directory Permissions:

This is a critical step to avoid file access errors with WSL and Ansible.

# Fix all directory permissions
find . -type d -exec chmod 755 {} \;
# Fix all file permissions
find . -type f -exec chmod 644 {} \;
# Re-secure your private key
chmod 600 prod-kp.pem

Configure Terraform:

In terraform/main.tf, update the cidr_blocks for SSH (port 22) and UI access (ports 3000, 9090) to your personal or office IP address.

Ensure the key_name in the aws_instance resources matches your AWS key pair name.

Configure Ansible:

Create the Vault:

ansible-vault create ansible/group_vars/all/vault.yml

Add your desired Grafana admin password to the vault file:
grafana_admin_password: "YourSecurePassword"

Update Docker Image: In ansible/roles/app_host/tasks/main.yml, update the image parameter in the docker_container task to point to your Docker Hub image and tag.

Update Docker Port Mapping: Ensure the port mapping in the same task is correct for your application (e.g., "8080:80" if your container listens on port 80).

Step 2: Provision Infrastructure with Terraform
Navigate to the Terraform directory:

cd terraform/

Initialize and Apply:

terraform init
terraform apply -auto-approve

This creates all AWS resources and generates ansible/inventory/production.ini.

Step 3: Configure Servers with Ansible
Navigate to the Ansible directory:

cd ../ansible/

Run the Ansible Playbook:

You will be prompted for the vault password you created earlier.

ansible-playbook -i inventory/production.ini main-playbook.yml --ask-vault-pass

Step 4: Verify the Deployment
Application: http://<app_host_public_ip>:8080

Prometheus: http://<prometheus_public_ip>:9090 (Check the "Targets" and "Alerts" pages)

Grafana: http://<grafana_public_ip>:3000

User: admin

Password: The password from your Ansible Vault.

Navigate to the "Node Exporter Full" dashboard to see your populated metrics.

Troubleshooting Common Issues
UNPROTECTED PRIVATE KEY FILE: Your .pem key has the wrong permissions. Run chmod 600 prod-kp.pem.

No such file or directory for JSON file: This is a file permissions issue on your local machine. Run the find ... -exec chmod ... commands from Step 1 again.

Prometheus Target "DOWN" with "context deadline exceeded": This means Prometheus cannot connect to Node Exporter. Ensure your prometheus.yml.j2 template uses the server's private IP (ansible_default_ipv4.address).

Grafana shows "No data": This means Grafana cannot connect to Prometheus. Ensure your grafana role configures the data source with the Prometheus server's private IP.

Next Steps: CI/CD Automation
Now that the manual deployment is perfected, the final step is to automate it with a GitHub Actions workflow. Create a file at .github/workflows/deploy.yml to run the terraform apply and ansible-playbook commands automatically on every push to your main branch.

Cleanup
To avoid ongoing AWS charges, destroy all created resources when you are finished.

Navigate to the Terraform directory:

cd ../terraform/

Destroy all resources:

terraform destroy -auto-approve

