output "database_instance_id" {
  description = "EC2 instance ID of the PostgreSQL instance"
  value       = aws_instance.postgres.id
}

output "database_public_ip" {
  description = "Public IP address of the PostgreSQL EC2 instance"
  value       = aws_instance.postgres.public_ip
}

output "database_private_ip" {
  description = "Private IP address of the PostgreSQL EC2 instance (used in Debezium connector)"
  value       = aws_instance.postgres.private_ip
}
