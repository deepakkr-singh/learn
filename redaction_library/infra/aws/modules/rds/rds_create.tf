# ============================================================================
# CREATE NEW RDS DATABASE
# ============================================================================

resource "aws_db_instance" "this" {
  count = var.create_rds ? 1 : 0

  # Database Configuration
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Database Credentials
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  port                   = var.port

  # Backup and Maintenance
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # High Availability
  multi_az               = var.multi_az
  deletion_protection    = var.deletion_protection

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_role_arn

  # Performance Insights
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Parameter Group
  parameter_group_name = var.parameter_group_name

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-db"
      Environment = var.environment
    }
  )
}

# Outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = var.create_rds ? aws_db_instance.this[0].id : null
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = var.create_rds ? aws_db_instance.this[0].arn : null
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_rds ? aws_db_instance.this[0].endpoint : null
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = var.create_rds ? aws_db_instance.this[0].address : null
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = var.create_rds ? aws_db_instance.this[0].port : null
}

output "db_instance_name" {
  description = "Database name"
  value       = var.create_rds ? aws_db_instance.this[0].db_name : null
}
