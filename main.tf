# Variables
variable "aws_access_key" {
  description = "AWS account access key"
}

variable "aws_secret_key" {
  description = "AWS account secret key"
}

variable "key_name" {
  description = "Nom de la paire de clé créee dans AWS"
}

# Provider
provider "aws" {
  region     = "eu-west-3"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Création du VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

# Création du sous-réseau
resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "MainSubnet"
  }
}

# Création du groupe de sécurité
resource "aws_security_group" "main_sg" {
  name        = "MainSecurityGroup"
  description = "Main security group for VPC"
  vpc_id      = aws_vpc.main.id

  # Règles entrantes pour SSH et HTTP
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

  # Règle sortante par défaut
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data
data "template_file" "nginx_playbook" {
  template = file("${path.module}/playbooks/install_nginx_playbook.yml")
}

# Resources
# RSA key of size 4096 bits
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

# Debian12 instance on AWS
resource "aws_instance" "aws_debian_12" {
  ami           = "ami-0f014d1f920a73971"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name        = "Debi"
    Environment = "Test"
  }

  connection {
    host        = aws_instance.aws_debian_12.public_ip
    type        = "ssh"
    user        = "admin"
    private_key = tls_private_key.rsa_4096.private_key_pem
  }

  # Execution des commandes dans l'instance cible pour installer Ansible et jouer un playbook local
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ansible",
      "echo 'localhost ansible_connection=local' > /tmp/hosts",
      "echo '${data.template_file.nginx_playbook.rendered}' > /tmp/install_nginx_playbook.yml",
      "ansible-playbook -i /tmp/hosts /tmp/install_nginx_playbook.yml"
    ]
  }
}

resource "null_resource" "copy_nginx_status" {
  triggers = {
    instance_id = aws_instance.aws_debian_12.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      scp -i k -o StrictHostKeyChecking=no admin@${aws_instance.aws_debian_12.public_ip}:/tmp/nginx_status.txt .\\services\\nginx_status.txt
    EOT
  }
}
