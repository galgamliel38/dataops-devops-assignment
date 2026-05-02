output "table_bucket_arn" {
  description = "ARN of the S3 Tables table bucket"
  value       = aws_s3tables_table_bucket.main.arn
}

output "table_bucket_name" {
  description = "Name of the S3 Tables table bucket"
  value       = aws_s3tables_table_bucket.main.name
}

output "namespace" {
  description = "S3 Tables namespace"
  value       = aws_s3tables_namespace.cdc.namespace
}

output "orders_table_name" {
  description = "Iceberg orders table name"
  value       = aws_s3tables_table.orders.name
}

output "orders_table_arn" {
  description = "ARN of the Iceberg orders table"
  value       = aws_s3tables_table.orders.arn
}
