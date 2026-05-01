variable "name_prefix" {
  description = "Prefix for naming database resources"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for the database EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for PostgreSQL"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the database EC2"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the database EC2"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}