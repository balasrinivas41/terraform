provider "aws" {
  region = "ap-south-1"
}

# Generate a local SSH private key
resource "tls_private_key" "example_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-ap-south1-key"
  public_key = tls_private_key.example_key.public_key_openssh
}

# Security Group to allow SSH
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH from anywhere"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your IP for more security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "ubuntu_ec2" {
  ami                    = "ami-03f4878755434977f"  # Ubuntu 22.04 LTS in ap-south-1
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Ubuntu-AP-South-Terraform"
  }
}

# Save private key locally
resource "local_file" "private_key_pem" {
  content              = tls_private_key.example_key.private_key_pem
  filename             = "${path.module}/terraform-ap-south-key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

