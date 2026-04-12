provider "aws" {
  region = "ap-south-1"
}

# --- 1. NETWORK SETUP (Since you have no default VPC) ---

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Playflix-VPC"
  }
}

# Create an Internet Gateway so the server can access the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Create a public subnet where the EC2 instance will be launched
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "Playflix-Subnet"
  }
}

# Create a route table to send internet traffic through the internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Playflix-Public-RouteTable"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- 2. SECURITY GROUP (Firewall) ---

resource "aws_security_group" "web_sg" {
  name        = "playflix-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow HTTP traffic on port 80
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH traffic on port 22
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Playflix-Security-Group"
  }
}

# --- 3. SERVER (EC2 INSTANCE) ---

# Automatically fetch the latest Ubuntu 22.04 AMI for the selected region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official Ubuntu owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the EC2 instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = "my-devops-key"   # Make sure this key pair exists in AWS EC2 console
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Install Docker automatically when the EC2 instance starts
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Playflix-Server"
  }
}

# Output the public IP of the EC2 instance
output "server_ip" {
  value = aws_instance.app_server.public_ip
}