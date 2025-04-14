provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "ansible_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ansible_keypair" {
  key_name   = "ansible-key"
  public_key = tls_private_key.ansible_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ansible_key.private_key_pem
  filename = "${path.module}/ansible-key.pem"
  file_permission = "0400"
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible-sg"
  description = "Allow SSH, HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define common AMI and instance type
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Create 1 Ansible server
resource "aws_instance" "ansible_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ansible_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "ansible-server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y software-properties-common",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.ansible_key.private_key_pem
      host        = self.public_ip
    }
  }
}

# Create 9 Ansible clients using count
resource "aws_instance" "ansible_clients" {
  count                       = 9
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ansible_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "ansible-client-${count.index + 1}"
  }
}

