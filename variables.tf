variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for naming AWS resources"
  type        = string
  default     = "dataops-devops"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "home-assignment"
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR format, used to restrict SSH and UI access"
  type        = string
}

variable "ubuntu_ami_id" {
  description = "Ubuntu AMI ID used for EC2 instances"
  type        = string
}

variable "ec2_key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "database_instance_type" {
  description = "EC2 instance type for PostgreSQL"
  type        = string
  default     = "t3.micro"
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka and Confluent Platform"
  type        = string
  default     = "t3.medium"
}