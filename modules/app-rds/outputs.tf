output "app_instance_id" {
  description = "Private application EC2 instance ID"
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "Private application EC2 IP"
  value       = aws_instance.app.private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.db.id
} 