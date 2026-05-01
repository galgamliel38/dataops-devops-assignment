output "aws_region" {
  description = "AWS region used for this deployment"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "database_public_ip" {
  description = "Public IP of the PostgreSQL EC2 instance"
  value       = module.database.database_public_ip
}

output "database_private_ip" {
  description = "Private IP of the PostgreSQL EC2 instance"
  value       = module.database.database_private_ip
}
output "kafka_public_ip" {
  description = "Public IP of the Kafka EC2 instance"
  value       = module.kafka.kafka_public_ip
}

output "kafka_private_ip" {
  description = "Private IP of the Kafka EC2 instance"
  value       = module.kafka.kafka_private_ip
}

output "control_center_url" {
  description = "URL for Confluent Control Center"
  value       = module.kafka.control_center_url
}
output "s3tables_table_bucket_arn" {
  description = "S3 Tables table bucket ARN"
  value       = module.s3tables.table_bucket_arn
}

output "s3tables_namespace" {
  description = "S3 Tables namespace"
  value       = module.s3tables.namespace
}

output "orders_iceberg_table_name" {
  description = "Orders Iceberg table name"
  value       = module.s3tables.orders_table_name
}