# ============================================================
# Root outputs – printed after terraform apply
# ============================================================

output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

output "database_public_ip" {
  description = "Public IP of the PostgreSQL EC2 instance"
  value       = module.database.database_public_ip
}

output "database_private_ip" {
  description = "Private IP of the PostgreSQL EC2 instance (use in Debezium connector)"
  value       = module.database.database_private_ip
}

output "kafka_public_ip" {
  description = "Public IP of the Kafka/Confluent EC2 instance"
  value       = module.kafka.kafka_public_ip
}

output "kafka_private_ip" {
  description = "Private IP of the Kafka/Confluent EC2 instance"
  value       = module.kafka.kafka_private_ip
}

output "control_center_url" {
  description = "Confluent Control Center URL (available ~5 min after apply)"
  value       = module.kafka.control_center_url
}

output "kafka_connect_url" {
  description = "Kafka Connect REST API URL"
  value       = module.kafka.kafka_connect_url
}

output "kafka_iam_role_arn" {
  description = "IAM role ARN attached to the Kafka EC2 instance"
  value       = module.kafka.kafka_iam_role_arn
}

output "s3tables_table_bucket_arn" {
  description = "ARN of the S3 Tables table bucket"
  value       = module.s3tables.table_bucket_arn
}

output "s3tables_table_bucket_name" {
  description = "Name of the S3 Tables table bucket"
  value       = module.s3tables.table_bucket_name
}

output "s3tables_namespace" {
  description = "S3 Tables namespace"
  value       = module.s3tables.namespace
}

output "orders_iceberg_table_arn" {
  description = "ARN of the Iceberg orders table in S3 Tables"
  value       = module.s3tables.orders_table_arn
}
