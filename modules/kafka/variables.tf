variable "name_prefix" {
  description = "Prefix for naming Kafka resources"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for Kafka EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Kafka"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Kafka EC2"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Kafka EC2"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}