variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for the Kafka EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (minimum t3.xlarge recommended for Confluent)"
  type        = string
  default     = "t3.xlarge"
}

variable "subnet_id" {
  description = "Subnet ID to launch the Kafka EC2 instance in"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the Kafka EC2 instance"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}
