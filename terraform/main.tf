# main.tf
provider "aws" {
  region = "us-east-1" # Example: Sydney
}

# Security Group for Grafana Server (Allow SSH and your IP for Grafana UI)
resource "aws_security_group" "grafana_sg" {
  name = "grafana-sg"
  # Ingress from your IP for SSH and Grafana UI
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 👈 IMPORTANT change to your office IP/32
  }
  ingress {
    from_port   = 3000 # Standard Grafana port
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["101.191.163.18/32"] # 👈 IMPORTANT YOUR_HOME_OR_OFFICE_IP/32
  }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1" # "-1" means all protocols
  cidr_blocks = ["0.0.0.0/0"]
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
    cidr_blocks = ["0.0.0.0/0"] # 👈 IMPORTANT change to your office IP/32
  }
  # Allow traffic from Grafana for scraping
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana_sg.id]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["101.191.163.18/32"]
  }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1" # "-1" means all protocols
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for App Hosts (Allow SSH, Node Exporter from Prometheus, and App Port)
resource "aws_security_group" "app_host_sg" {
  name = "app-host-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 👈 IMPORTANT change to your office IP/32
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
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1" # "-1" means all protocols
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define EC2 Instances
# main.tf (Corrected)

resource "aws_instance" "grafana" {
  ami                   = "ami-020cba7c55df1f615" # This also needs to be fixed, see below
  instance_type         = "t2.micro"
  key_name              = "prod-kp"
  vpc_security_group_ids = [aws_security_group.grafana_sg.id] # 👈 Use this instead

  tags = { Name = "grafana-server" }
}

# ... Define prometheus and app_host instances similarly, attaching their respective security groups ...
resource "aws_instance" "prometheus" {
  ami           = "ami-020cba7c55df1f615" # Ubuntu 24.04 in us-east-1
  instance_type = "t2.micro"
  key_name      = "prod-kp" # 👈 Your AWS key pair
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id] # 👈 Use this instead
  tags = { Name = "prometheus-server" }
}
resource "aws_instance" "app_host" {
  ami           = "ami-020cba7c55df1f615" # Ubuntu 24.04 in us-east-1
  instance_type = "t2.micro"
  key_name      = "prod-kp" # 👈 Your AWS key pair
  vpc_security_group_ids = [aws_security_group.app_host_sg.id] # 👈 Use this instead
  tags = { Name = "app-host" }
}
