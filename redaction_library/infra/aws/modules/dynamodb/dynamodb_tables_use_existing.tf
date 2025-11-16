# ============================================================================
# USE EXISTING DYNAMODB TABLES (CREATED BY PLATFORM/APP TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Platform/App Team has already created DynamoDB tables.
# You just need to reference the existing tables for your application.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE new DynamoDB tables, use dynamodb_tables_create.tf instead.
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Table Names or ARNs:
#    - Main table name/ARN
#    - Table partition key name
#    - Table sort key name (if exists)
#
# 2. Confirm permissions:
#    - Does my Lambda/application role have dynamodb:GetItem permission?
#    - Does my role have dynamodb:PutItem, dynamodb:UpdateItem, dynamodb:DeleteItem?
#    - Does my role have dynamodb:Query, dynamodb:Scan?
#    - Is the table encrypted? If yes, do I have KMS key access?
#
# 3. Table configuration details:
#    - What is the partition key name and type?
#    - What is the sort key name and type (if exists)?
#    - Are there any GSIs I can query?
#    - Is DynamoDB Streams enabled? If yes, what's the stream ARN?
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for table names/ARNs (use email template in README.md)
# 2. Fill in the table names in variables.tf or terraform.tfvars
# 3. Reference these tables in your Lambda/application code
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING DYNAMODB TABLES
# ----------------------------------------------------------------------------

# Main table
data "aws_dynamodb_table" "main" {
  count = var.existing_main_table_name != "" ? 1 : 0

  name = var.existing_main_table_name
}

# Users table
data "aws_dynamodb_table" "users" {
  count = var.existing_users_table_name != "" ? 1 : 0

  name = var.existing_users_table_name
}

# Orders table
data "aws_dynamodb_table" "orders" {
  count = var.existing_orders_table_name != "" ? 1 : 0

  name = var.existing_orders_table_name
}

# Sessions table
data "aws_dynamodb_table" "sessions" {
  count = var.existing_sessions_table_name != "" ? 1 : 0

  name = var.existing_sessions_table_name
}

# Custom table
data "aws_dynamodb_table" "custom" {
  count = var.existing_custom_table_name != "" ? 1 : 0

  name = var.existing_custom_table_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "main_table_arn" {
  description = "ARN of the main table (existing)"
  value       = var.existing_main_table_name != "" ? data.aws_dynamodb_table.main[0].arn : null
}

output "main_table_name" {
  description = "Name of the main table (existing)"
  value       = var.existing_main_table_name != "" ? data.aws_dynamodb_table.main[0].name : null
}

output "main_table_stream_arn" {
  description = "Stream ARN of the main table (existing)"
  value       = var.existing_main_table_name != "" ? data.aws_dynamodb_table.main[0].stream_arn : null
}

output "users_table_arn" {
  description = "ARN of the users table (existing)"
  value       = var.existing_users_table_name != "" ? data.aws_dynamodb_table.users[0].arn : null
}

output "users_table_name" {
  description = "Name of the users table (existing)"
  value       = var.existing_users_table_name != "" ? data.aws_dynamodb_table.users[0].name : null
}

output "orders_table_arn" {
  description = "ARN of the orders table (existing)"
  value       = var.existing_orders_table_name != "" ? data.aws_dynamodb_table.orders[0].arn : null
}

output "orders_table_name" {
  description = "Name of the orders table (existing)"
  value       = var.existing_orders_table_name != "" ? data.aws_dynamodb_table.orders[0].name : null
}

output "sessions_table_arn" {
  description = "ARN of the sessions table (existing)"
  value       = var.existing_sessions_table_name != "" ? data.aws_dynamodb_table.sessions[0].arn : null
}

output "sessions_table_name" {
  description = "Name of the sessions table (existing)"
  value       = var.existing_sessions_table_name != "" ? data.aws_dynamodb_table.sessions[0].name : null
}

output "custom_table_arn" {
  description = "ARN of the custom table (existing)"
  value       = var.existing_custom_table_name != "" ? data.aws_dynamodb_table.custom[0].arn : null
}

output "custom_table_name" {
  description = "Name of the custom table (existing)"
  value       = var.existing_custom_table_name != "" ? data.aws_dynamodb_table.custom[0].name : null
}

# Summary output
output "dynamodb_tables_summary" {
  description = "Summary of all existing DynamoDB tables"
  value = {
    main_table = var.existing_main_table_name != "" ? {
      name       = data.aws_dynamodb_table.main[0].name
      arn        = data.aws_dynamodb_table.main[0].arn
      hash_key   = data.aws_dynamodb_table.main[0].hash_key
      range_key  = data.aws_dynamodb_table.main[0].range_key
      stream_arn = data.aws_dynamodb_table.main[0].stream_arn
    } : "not provided"

    users_table = var.existing_users_table_name != "" ? {
      name      = data.aws_dynamodb_table.users[0].name
      arn       = data.aws_dynamodb_table.users[0].arn
      hash_key  = data.aws_dynamodb_table.users[0].hash_key
      range_key = data.aws_dynamodb_table.users[0].range_key
    } : "not provided"

    orders_table = var.existing_orders_table_name != "" ? {
      name      = data.aws_dynamodb_table.orders[0].name
      arn       = data.aws_dynamodb_table.orders[0].arn
      hash_key  = data.aws_dynamodb_table.orders[0].hash_key
      range_key = data.aws_dynamodb_table.orders[0].range_key
    } : "not provided"

    sessions_table = var.existing_sessions_table_name != "" ? {
      name      = data.aws_dynamodb_table.sessions[0].name
      arn       = data.aws_dynamodb_table.sessions[0].arn
      hash_key  = data.aws_dynamodb_table.sessions[0].hash_key
      range_key = data.aws_dynamodb_table.sessions[0].range_key
    } : "not provided"

    custom_table = var.existing_custom_table_name != "" ? {
      name      = data.aws_dynamodb_table.custom[0].name
      arn       = data.aws_dynamodb_table.custom[0].arn
      hash_key  = data.aws_dynamodb_table.custom[0].hash_key
      range_key = data.aws_dynamodb_table.custom[0].range_key
    } : "not provided"
  }
}
