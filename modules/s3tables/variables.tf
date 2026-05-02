variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "namespace_name" {
  description = "Namespace name inside the S3 Table Bucket"
  type        = string
  default     = "cdc"
}

variable "table_name" {
  description = "Iceberg table name"
  type        = string
  default     = "orders"
}
