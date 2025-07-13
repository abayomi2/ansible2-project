Production-Grade Application Deployment with Terraform and Ansible
This project automates the deployment of a containerized application and a full observability stack (Prometheus & Grafana) on AWS. It follows Infrastructure as Code (IaC) and Configuration Management best practices to create a secure, scalable, and repeatable production-grade environment.

This document provides a complete, end-to-end guide, including one-time setup, manual deployment, CI/CD automation, and a full troubleshooting reference based on real-world debugging.

Table of Contents
Architecture

Features

Project Structure

Prerequisites

Part 1: One-Time Backend Setup (Manual)

Part 2: Local Project Configuration

Part 3: Automated Deployment via CI/CD

Part 4: Verification and Access

Troubleshooting Guide

Cleanup

Architecture
This project uses a decoupled architecture where infrastructure provisioning is handled by Terraform and server configuration is managed by Ansible.

Terraform: Provisions all necessary AWS resources, including:

A remote backend using S3 for state storage and DynamoDB for state locking.

Three EC2 instances (for the Application, Prometheus, and Grafana).

Three granular Security Groups to enforce a strict network firewall.

An SSH key pair for secure access.

After provisioning, Terraform dynamically generates an inventory file for Ansible.

Ansible: Configures the provisioned EC2 instances using a role-based structure:

common: Installs common packages on all servers.

app_host: Installs Docker and deploys the specified containerized application.

node_exporter: Installs and runs Node Exporter on the application host to collect system metrics.

prometheus: Installs and configures Prometheus. It's configured to scrape metrics from Node Exporter using the server's private IP and load critical alerting rules.

grafana: Installs and configures Grafana. It automatically adds Prometheus as a data source (using its private IP) and imports a complete, pre-configured dashboard from a local JSON file.

CI/CD with GitHub Actions:

A complete workflow automates the terraform apply and ansible-playbook steps on every push to the main branch, ensuring continuous deployment.

Features
Fully Automated Deployment: A push to the main branch triggers a complete deployment.

Centralized State Management: Uses an S3 remote backend to securely manage Terraform state, making it safe for team collaboration and CI/CD.

Infrastructure as Code (IaC): All infrastructure is defined in Terraform for consistency and version control.

Configuration as Code: Server state is defined using Ansible Roles for modularity and reusability.

Secure by Default:

Uses SSH keys for access.

Implements the principle of least privilege with strict Security Group rules.

Manages secrets securely using Ansible Vault.

Production-Ready Observability: A complete monitoring and visualization stack is set up with pre-configured alerts and a comprehensive Grafana dashboard.

Project Structure
.
├── .github/workflows/
│   └── deploy.yml            # CI/CD pipeline definition
├── ansible/
│   ├── roles/
│   │   ├── app_host/
│   │   ├── common/
│   │   ├── grafana/
│   │   │   └── files/
│   │   │       └── node_exporter_dashboard.json
│   │   ├── node_exporter/
│   │   └── prometheus/
│   │       └── templates/
│   │           └── alert.rules.yml.j2
│   ├── group_vars/all/
│   │   └── vault.yml
│   ├── inventory/
│   │   └── production.ini    # Dynamically generated
│   ├── ansible.cfg
│   └── main-playbook.yml
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── inventory.tpl
│   ├── create_backend.tf     # For one-time setup
│   └── backend_config.tf     # Configures the remote backend
└── prod-kp.pem

Prerequisites
AWS Account: With credentials configured for the AWS CLI.

Terraform: Installed locally.

Ansible: Installed locally.

AWS CLI: Installed and configured (aws configure).

SSH Key Pair: An SSH key pair created in the target AWS region.

Docker Hub Image: A containerized application image pushed to Docker Hub.

WSL (for Windows users): It is critical to run this project from within the WSL home directory (~/), not from a mounted Windows drive (/mnt/c/).

Part 1: One-Time Backend Setup (Manual)
This foundational step creates the secure backend for your Terraform state. It only needs to be performed once.

Clone the Repository into your WSL Home:

cd ~
git clone <your-repo-url>
cd <your-project-directory>

Configure Backend Files:

In terraform/create_backend.tf, change the default value for bucket_name to a globally unique name.

In terraform/backend_config.tf, update the bucket value to match the name you just chose.

Temporarily Hide Backend Config: Terraform cannot create its own backend while also trying to use it. Hide the configuration first:

cd terraform
mv backend_config.tf backend_config.tf.hidden

Initialize and Create Backend Resources:

terraform init
# The -target flag ensures only the backend resources are created
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks

Answer yes when prompted.

Restore Backend Config and Migrate State:

mv backend_config.tf.hidden backend_config.tf
# Re-initialize to connect to the new backend and migrate the local state
terraform init -migrate-state

Type yes to approve the migration. Your state is now securely stored in S3.

Part 2: Local Project Configuration
These steps prepare your local project files before letting the CI/CD pipeline take over.

Set File and Directory Permissions:

This is a critical step to avoid file access errors with WSL and Ansible.

cd ~/your-project-directory
# Fix all directory permissions
find . -type d -exec chmod 755 {} \;
# Fix all file permissions
find . -type f -exec chmod 644 {} \;
# Re-secure your private key
chmod 600 prod-kp.pem

Configure Terraform main.tf:

Ensure the key_name in the aws_instance resources matches your AWS key pair name.

For the CI/CD pipeline to work, the security group ingress rules for ports 22 (SSH) and 3000 (Grafana) must be open to 0.0.0.0/0.

Configure Ansible:

Create the Vault:

ansible-vault create ansible/group_vars/all/vault.yml

Add your desired Grafana admin password to the vault file: grafana_admin_password: "YourSecurePassword"

Update Docker Image: In ansible/roles/app_host/tasks/main.yml, update the image parameter and port mapping to match your application.

Commit All Changes:

Commit backend_config.tf, main.tf, your Ansible role changes, and all other files to your repository.

Part 3: Automated Deployment via CI/CD
Add Secrets to GitHub:

Go to your GitHub repository settings: Settings > Secrets and variables > Actions.

Add the following repository secrets:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

AWS_SSH_PRIVATE_KEY (Paste the full content of your .pem file)

ANSIBLE_VAULT_PASSWORD

Push to main:

Push your committed changes to the main branch.

The GitHub Actions workflow defined in .github/workflows/deploy.yml will automatically trigger, provisioning and configuring your entire stack.

Part 4: Verification and Access
Application: http://<app_host_public_ip>:8080

Prometheus: http://<prometheus_public_ip>:9090

Grafana: http://<grafana_public_ip>:3000

User: admin

Password: The password from your Ansible Vault.

Troubleshooting Guide
CI/CD Fails with Duplicate Security Group: The Terraform remote backend is not configured correctly. See Part 1.

CI/CD Fails with Connection timed out on port 22 or 3000: The security group rules for these ports are not open to 0.0.0.0/0, blocking the GitHub Actions runner.

Ansible Fails with UNPROTECTED PRIVATE KEY FILE: Your .pem key has the wrong permissions. Run chmod 600 prod-kp.pem.

Ansible Fails with No such file or directory for JSON file: A file/directory permission issue on your local machine. Run the find ... -exec chmod ... commands from Part 2.

Prometheus Target "DOWN": Your prometheus.yml.j2 template is likely using a public IP. Ensure it uses the private IP (ansible_default_ipv4.address).

Grafana shows "No data": Your Grafana data source is likely configured with a public IP. Ensure the grafana role uses the Prometheus server's private IP.

Cleanup
To avoid ongoing AWS charges, destroy all created resources.

Temporarily Disable Deletion Protection:

In terraform/create_backend.tf, comment out the lifecycle { prevent_destroy = true } block.

Run terraform apply -auto-approve to apply this change.

Destroy Application Infrastructure:

Run terraform destroy -auto-approve. This will destroy the EC2 instances and their security groups.

Destroy Backend Infrastructure:

You may need to manually empty the S3 bucket first using the AWS CLI: aws s3 rm s3://<your-bucket-name> --recursive.

Run terraform destroy -auto-approve again to delete the S3 bucket and DynamoDB table.
