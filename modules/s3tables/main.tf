# ============================================================
# S3 Tables Module
# Creates S3 Table Bucket, namespace, and Iceberg orders table
# ============================================================

resource "aws_s3tables_table_bucket" "main" {
  name = "${var.name_prefix}-table-bucket"
}

resource "aws_s3tables_namespace" "cdc" {
  namespace        = var.namespace_name
  table_bucket_arn = aws_s3tables_table_bucket.main.arn
}

# Iceberg table: orders
# Schema defined explicitly per assignment requirements:
#   id, customer_name, amount, status, created_at  — business columns
#   __op          — CDC operation type (c=create, u=update, d=delete)
#   __source_ts   — original DB change timestamp (epoch ms from Debezium)
resource "aws_s3tables_table" "orders" {
  name             = var.table_name
  namespace        = aws_s3tables_namespace.cdc.namespace
  table_bucket_arn = aws_s3tables_table_bucket.main.arn
  format           = "ICEBERG"

  metadata {
    iceberg {
      schema {
        # Business columns (from PostgreSQL orders table)
        field {
          name     = "id"
          type     = "int"
          required = true
        }
        field {
          name     = "customer_name"
          type     = "string"
          required = true
        }
        field {
          name     = "amount"
          type     = "decimal(10, 2)"
          required = true
        }
        field {
          name     = "status"
          type     = "string"
          required = true
        }
        field {
          name     = "created_at"
          type     = "timestamptz"
          required = false
        }

        # CDC metadata columns (added by Debezium ExtractNewRecordState SMT)
        field {
          name     = "__op"
          type     = "string"
          required = false
        }
        field {
          name     = "__source_ts_ms"
          type     = "long"
          required = false
        }
      }
    }
  }
}
