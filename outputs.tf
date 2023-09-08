output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.aws_debian_12.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.aws_debian_12.private_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.aws_debian_12.id
}

output "instance_availability_zone" {
  description = "Availability Zone of the EC2 instance"
  value       = aws_instance.aws_debian_12.availability_zone
}

output "instance_security_group_ids" {
  description = "Security Group IDs attached to the EC2 instance"
  value       = aws_instance.aws_debian_12.security_groups
}

output "public_key_openssh" {
  value = tls_private_key.rsa_4096.public_key_openssh
}

output "private_key_pem" {
  value = tls_private_key.rsa_4096.private_key_pem
  sensitive = true
}
