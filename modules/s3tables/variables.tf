variable "name_prefix" {
  description = "Prefix for naming S3 Tables resources"
  type        = string
}

variable "namespace_name" {
  description = "S3 Tables namespace name"
  type        = string
  default     = "cdc"
}

variable "table_name" {
  description = "Iceberg table name"
  type        = string
  default     = "orders"
}