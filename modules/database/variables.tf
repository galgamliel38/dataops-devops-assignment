variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for the PostgreSQL EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for PostgreSQL"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the PostgreSQL EC2 instance in"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the PostgreSQL EC2 instance"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}
