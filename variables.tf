variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name prefix applied to all resource names"
  type        = string
  default     = "dataops-devops"
}

variable "environment" {
  description = "Environment label (e.g. home-assignment, staging, prod)"
  type        = string
  default     = "home-assignment"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format (e.g. 1.2.3.4/32) – restricts SSH and UI access"
  type        = string
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "database_instance_type" {
  description = "EC2 instance type for the PostgreSQL instance"
  type        = string
  default     = "t3.micro"
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Confluent Platform (t3.xlarge recommended – Control Center is memory-heavy)"
  type        = string
  default     = "t3.xlarge"
}
