output "spoke_vpc_id" {
  description = "Existing Spoke VPC ID"
  value       = data.aws_vpc.spoke.id
}

output "private_subnet_ids" {
  description = "Existing private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "app_instance_id" {
  description = "Private application EC2"
  value       = module.app_rds.app_instance_id
}

output "app_private_ip" {
  description = "Application private IP"
  value       = module.app_rds.app_private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.app_rds.rds_endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.app_rds.rds_port
} 