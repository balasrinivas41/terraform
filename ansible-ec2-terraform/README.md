
Here's a complete Terraform configuration to:

Create 1 Ansible server + 9 Ansible clients (total 10 EC2 instances).

Install Java, Python, Apache using a bootstrap script via Ansible.

Generate SSH key pairs dynamically within Terraform.

terraform init

terraform apply

chmod 400 ansible-key.pem

scp -i ansible-key.pem ansible-key.pem ubuntu@<ansible-server-ip>:~/

ssh -i ansible-key.pem ubuntu@<ansible_server_ip>

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i hosts ansible/bootstrap.yml

