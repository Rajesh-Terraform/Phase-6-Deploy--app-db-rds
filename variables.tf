variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "spoke_vpc_cidr" {
  description = "Existing Spoke VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "practice_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
} 