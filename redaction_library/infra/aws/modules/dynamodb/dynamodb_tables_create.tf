# ============================================================================
# CREATE DYNAMODB TABLES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage DynamoDB tables for NoSQL storage.
# You have full control over table configuration, indexes, and capacity settings.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - DynamoDB table with partition key (and optional sort key)
# - Global Secondary Indexes (GSI) for alternate query patterns
# - Local Secondary Indexes (LSI) for alternate sort keys
# - Encryption at rest with KMS
# - Point-in-time recovery for backups
# - DynamoDB Streams for change capture
# - Auto-scaling (if using provisioned capacity)
#
# COMMON USE CASES:
# -----------------
# 1. User profiles and sessions
# 2. Order history and transactions
# 3. Product catalog
# 4. Time-series data (IoT, logs)
# 5. Caching layer
#
# ============================================================================

# ----------------------------------------------------------------------------
# MAIN DYNAMODB TABLE
# ----------------------------------------------------------------------------

resource "aws_dynamodb_table" "main" {
  count = var.create_table ? 1 : 0

  name           = var.table_name != "" ? var.table_name : "${var.project_name}-${var.environment}-${var.table_purpose}"
  billing_mode   = var.billing_mode
  hash_key       = var.partition_key_name
  range_key      = var.sort_key_name != "" ? var.sort_key_name : null

  # Provisioned capacity (only if billing_mode = PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Stream configuration
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  # Table class (STANDARD or STANDARD_INFREQUENT_ACCESS)
  table_class = var.table_class

  # Deletion protection
  deletion_protection_enabled = var.deletion_protection_enabled

  # Partition key attribute
  attribute {
    name = var.partition_key_name
    type = var.partition_key_type
  }

  # Sort key attribute (optional)
  dynamic "attribute" {
    for_each = var.sort_key_name != "" ? [1] : []
    content {
      name = var.sort_key_name
      type = var.sort_key_type
    }
  }

  # Additional attributes for GSI/LSI
  dynamic "attribute" {
    for_each = var.additional_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = global_secondary_index.value.projection_type

      # Non-key attributes to project (only if projection_type = INCLUDE)
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)

      # Provisioned throughput for GSI (only if table billing_mode = PROVISIONED)
      read_capacity  = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", 5) : null
      write_capacity = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", 5) : null
    }
  }

  # Local Secondary Indexes
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  # TTL (Time to Live)
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  # Encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

  # Replica configuration (for global tables)
  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
      kms_key_arn = lookup(var.replica_kms_keys, replica.value, null)
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = var.table_name != "" ? var.table_name : "${var.project_name}-${var.environment}-${var.table_purpose}"
      Environment = var.environment
      Purpose     = var.table_purpose
    }
  )

  # Lifecycle - prevent accidental table deletion
  lifecycle {
    prevent_destroy = false
  }
}

# ----------------------------------------------------------------------------
# AUTO-SCALING (Only for Provisioned Capacity)
# ----------------------------------------------------------------------------

# Auto-scaling target for table read capacity
resource "aws_appautoscaling_target" "table_read" {
  count = var.create_table && var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_read_max_capacity
  min_capacity       = var.read_capacity
  resource_id        = "table/${aws_dynamodb_table.main[0].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

# Auto-scaling policy for table read capacity
resource "aws_appautoscaling_policy" "table_read" {
  count = var.create_table && var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${aws_dynamodb_table.main[0].name}-read-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.table_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_read_target
  }
}

# Auto-scaling target for table write capacity
resource "aws_appautoscaling_target" "table_write" {
  count = var.create_table && var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_write_max_capacity
  min_capacity       = var.write_capacity
  resource_id        = "table/${aws_dynamodb_table.main[0].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

# Auto-scaling policy for table write capacity
resource "aws_appautoscaling_policy" "table_write" {
  count = var.create_table && var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${aws_dynamodb_table.main[0].name}-write-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.table_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.table_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.table_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_write_target
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = var.create_table ? aws_dynamodb_table.main[0].id : null
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = var.create_table ? aws_dynamodb_table.main[0].arn : null
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = var.create_table ? aws_dynamodb_table.main[0].name : null
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = var.create_table && var.stream_enabled ? aws_dynamodb_table.main[0].stream_arn : null
}

output "table_stream_label" {
  description = "Timestamp of when DynamoDB stream was enabled"
  value       = var.create_table && var.stream_enabled ? aws_dynamodb_table.main[0].stream_label : null
}

# Summary output
output "table_summary" {
  description = "Summary of created DynamoDB table"
  value = var.create_table ? {
    name           = aws_dynamodb_table.main[0].name
    arn            = aws_dynamodb_table.main[0].arn
    billing_mode   = var.billing_mode
    partition_key  = var.partition_key_name
    sort_key       = var.sort_key_name != "" ? var.sort_key_name : "none"
    stream_enabled = var.stream_enabled
    encrypted      = var.kms_key_id != "" ? "KMS" : "AWS Managed"
    purpose        = var.table_purpose
  } : "not created"
}
