output "database_instance_id" {
  description = "PostgreSQL EC2 instance ID"
  value       = aws_instance.postgres.id
}

output "database_public_ip" {
  description = "Public IP address of PostgreSQL EC2"
  value       = aws_instance.postgres.public_ip
}

output "database_private_ip" {
  description = "Private IP address of PostgreSQL EC2"
  value       = aws_instance.postgres.private_ip
}