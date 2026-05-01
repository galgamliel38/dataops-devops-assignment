resource "aws_s3tables_table_bucket" "main" {
  name = "${var.name_prefix}-table-bucket"
}

resource "aws_s3tables_namespace" "cdc" {
  namespace        = var.namespace_name
  table_bucket_arn = aws_s3tables_table_bucket.main.arn
}

resource "aws_s3tables_table" "orders" {
  name             = var.table_name
  namespace        = aws_s3tables_namespace.cdc.namespace
  table_bucket_arn = aws_s3tables_table_bucket.main.arn
  format           = "ICEBERG"
}