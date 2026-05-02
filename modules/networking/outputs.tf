output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "kafka_security_group_id" {
  description = "Security group ID for the Kafka EC2 instance"
  value       = aws_security_group.kafka.id
}

output "database_security_group_id" {
  description = "Security group ID for the PostgreSQL EC2 instance"
  value       = aws_security_group.database.id
}
