output "ansible_server_ip" {
  value = aws_instance.ansible_server.public_ip
}

output "ansible_clients_ips" {
  value = [for instance in aws_instance.ansible_clients : instance.public_ip]
}

output "private_key_location" {
  value = local_file.private_key_pem.filename
}

