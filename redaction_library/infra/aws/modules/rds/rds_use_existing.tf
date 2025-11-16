# ============================================================================
# USE EXISTING RDS DATABASE
# ============================================================================

data "aws_db_instance" "existing" {
  count = var.existing_db_identifier != "" ? 1 : 0

  db_instance_identifier = var.existing_db_identifier
}

# Outputs
output "db_instance_id" {
  description = "RDS instance ID (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].id : null
}

output "db_instance_arn" {
  description = "RDS instance ARN (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].db_instance_arn : null
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].endpoint : null
}

output "db_instance_address" {
  description = "RDS instance hostname (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].address : null
}

output "db_instance_port" {
  description = "RDS instance port (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].port : null
}

output "db_instance_name" {
  description = "Database name (existing)"
  value       = var.existing_db_identifier != "" ? data.aws_db_instance.existing[0].db_name : null
}
