variable "name_prefix" {
  description = "Prefix for naming networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR format"
  type        = string
}