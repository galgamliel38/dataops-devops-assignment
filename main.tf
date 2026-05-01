locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Assignment  = "DataOps DevOps Engineer"
  }
}

module "networking" {
  source = "./modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  availability_zone  = "eu-west-1a"
  my_ip_cidr         = var.my_ip_cidr
}

module "database" {
  source = "./modules/database"

  name_prefix       = local.name_prefix
  ami_id            = data.aws_ami.ubuntu_2204.id
  instance_type     = var.database_instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.database_security_group_id
  key_name          = var.ec2_key_name
}

module "kafka" {
  source = "./modules/kafka"

  name_prefix       = local.name_prefix
  ami_id            = data.aws_ami.ubuntu_2204.id
  instance_type     = var.kafka_instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.kafka_security_group_id
  key_name          = var.ec2_key_name
}
module "s3tables" {
  source = "./modules/s3tables"

  name_prefix    = local.name_prefix
  namespace_name = "cdc"
  table_name     = "orders"
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}