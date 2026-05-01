output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "kafka_security_group_id" {
  description = "Security group ID for Kafka EC2"
  value       = aws_security_group.kafka.id
}

output "database_security_group_id" {
  description = "Security group ID for PostgreSQL EC2"
  value       = aws_security_group.database.id
}