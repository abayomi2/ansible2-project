provider "aws" {
  region = "ap-southeast-2" # Example: Sydney
}

# Security Group for Grafana Server (Allow SSH and your IP for Grafana UI)
resource "aws_security_group" "grafana_sg" {
  name = "grafana-sg"
  # Ingress from your IP for SSH and Grafana UI
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_HOME_OR_OFFICE_IP/32"] # 👈 IMPORTANT
  }
  ingress {
    from_port   = 3000 # Standard Grafana port
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["YOUR_HOME_OR_OFFICE_IP/32"] # 👈 IMPORTANT
  }
}

# Security Group for Prometheus Server (Allow SSH and inbound from Grafana)
resource "aws_security_group" "prometheus_sg" {
  name = "prometheus-sg"
  # Ingress from your IP for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_HOME_OR_OFFICE_IP/32"]
  }
  # Allow traffic from Grafana for scraping
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana_sg.id]
  }
}

# Security Group for App Hosts (Allow SSH, Node Exporter from Prometheus, and App Port)
resource "aws_security_group" "app_host_sg" {
  name = "app-host-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_HOME_OR_OFFICE_IP/32"]
  }
  # Allow traffic from Prometheus for Node Exporter
  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus_sg.id]
  }
  # Allow public traffic to your app
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define EC2 Instances
resource "aws_instance" "grafana" {
  ami           = "ami-00e95a962233b4421" # Ubuntu 22.04 in ap-southeast-2
  instance_type = "t2.micro"
  key_name      = "your-aws-key-name" # 👈 Your AWS key pair
  security_groups = [aws_security_group.grafana_sg.id]

  tags = { Name = "grafana-server" }
}

# ... Define prometheus and app_host instances similarly, attaching their respective security groups ...