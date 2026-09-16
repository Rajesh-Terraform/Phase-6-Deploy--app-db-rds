data "aws_vpc" "spoke" {
  filter {
    name   = "cidr"
    values = [var.spoke_vpc_cidr]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.spoke.id]
  }

  tags = {
    Tier = "private"
  }
}

module "app_rds" {
  source = "./modules/app-rds"

  vpc_id             = data.aws_vpc.spoke.id
  private_subnet_ids = data.aws_subnets.private.ids

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}   