data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -------------------------
# App Security Group
# -------------------------

resource "aws_security_group" "app" {
  name        = "phase6-app-sg"
  description = "Security group for Phase 6 application"
  vpc_id      = var.vpc_id

  egress {
    description = "HTTPS to VPC endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.1.0.0/16"]
  }

  tags = {
    Name = "phase6-app-sg"
  }
}

# -------------------------
# Database Security Group
# -------------------------

resource "aws_security_group" "db" {
  name        = "phase6-db-sg"
  description = "Security group for Phase 6 RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Database outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "phase6-db-sg"
  }
}

# -------------------------
# SSM IAM Role
# -------------------------

resource "aws_iam_role" "ssm" {
  name = "phase6-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "phase6-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "phase6-ssm-profile"
  role = aws_iam_role.ssm.name
}

# -------------------------
# Private EC2
# -------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = var.private_subnet_ids[0]

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  tags = {
    Name = "phase6-private-app"
  }
}

# -------------------------
# RDS Subnet Group
# -------------------------

resource "aws_db_subnet_group" "this" {
  name = "phase6-db-subnet-group" 

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "phase6-db-subnet-group"
  }
}

# -------------------------
# RDS PostgreSQL
# -------------------------

resource "aws_db_instance" "postgres" {
  identifier = "phase6-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 0

  deletion_protection = false

  skip_final_snapshot = true

  tags = {
    Name = "phase6-postgres"
  }
}

# -------------------------
# SSM Interface Endpoints
# -------------------------

locals {
  ssm_endpoints = [
    "ssm",
    "ssmmessages",
    "ec2messages"
  ]

  ecr_endpoints = [
    "ecr.api",
    "ecr.dkr"
  ]
}

resource "aws_security_group" "endpoints" {
  name        = "phase6-endpoints-sg"
  description = "Security group for Phase 6 VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from Spoke VPC"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    description = "Endpoint outbound"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "phase6-endpoints-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(local.ssm_endpoints)

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.ap-south-1.${each.value}"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoints.id
  ]

  tags = {
    Name = "phase6-${each.value}-endpoint"
  }
}

# -------------------------
# ECR Interface Endpoints
# -------------------------

resource "aws_vpc_endpoint" "ecr" {
  for_each = toset(local.ecr_endpoints)

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.ap-south-1.${each.value}"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoints.id
  ]

  tags = {
    Name = "phase6-${each.value}-endpoint"
  }
}

# -------------------------
# S3 Gateway Endpoint
# -------------------------

data "aws_route_tables" "private" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = var.vpc_id

  service_name = "com.amazonaws.ap-south-1.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = data.aws_route_tables.private.ids

  tags = {
    Name = "phase6-s3-endpoint"
  }
}    