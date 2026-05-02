# ============================================================
# Networking Module
# Creates: VPC, public subnet, IGW, route table, security groups
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------------
# Security Group: Confluent / Kafka EC2
# ----------------------------------------------------------
resource "aws_security_group" "kafka" {
  name        = "${var.name_prefix}-kafka-sg"
  description = "Security group for Confluent Kafka EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH – admin access only from operator IP
  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Confluent Control Center UI
  ingress {
    description = "Confluent Control Center UI from operator IP"
    from_port   = 9021
    to_port     = 9021
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Kafka Connect REST API
  ingress {
    description = "Kafka Connect REST API from operator IP"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Kafka broker – allow DB instance (same VPC) to reach broker
  ingress {
    description = "Kafka broker from VPC (Debezium to Kafka)"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Schema Registry (used internally by Connect)
  ingress {
    description = "Schema Registry from VPC"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound (needed for apt, Confluent repos, AWS APIs, S3 Tables)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-kafka-sg"
  }
}

# ----------------------------------------------------------
# Security Group: PostgreSQL EC2
# ----------------------------------------------------------
resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-database-sg"
  description = "Security group for PostgreSQL EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH – admin access only from operator IP
  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # PostgreSQL – only reachable from the Kafka security group (Debezium)
  ingress {
    description     = "PostgreSQL from Kafka instance (Debezium CDC)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.kafka.id]
  }

  # All outbound (apt, OS updates)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-database-sg"
  }
}
