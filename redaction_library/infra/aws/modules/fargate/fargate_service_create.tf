# ============================================================================
# CREATE FARGATE SERVICE (ECS on Fargate)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage Fargate services to run
# containerized applications without managing EC2 instances.
#
# WHAT THIS FILE CREATES:
# -----------------------
# - ECS Cluster
# - ECS Task Definition (container blueprint)
# - ECS Service (manages tasks)
# - CloudWatch Log Group (container logs)
# - IAM roles (execution role, task role)
# - Auto-scaling (optional)
#
# COMMON USE CASES:
# -----------------
# 1. Microservices (REST APIs, GraphQL)
# 2. Long-running web applications
# 3. Background workers
# 4. Scheduled tasks (cron jobs)
# 5. WebSocket servers
#
# ============================================================================

# ----------------------------------------------------------------------------
# ECS CLUSTER
# ----------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  count = var.create_cluster ? 1 : 0

  name = var.cluster_name != "" ? var.cluster_name : "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = var.cluster_name != "" ? var.cluster_name : "${var.project_name}-${var.environment}-cluster"
      Environment = var.environment
    }
  )
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "main" {
  count = var.create_service ? 1 : 0

  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "/ecs/${var.service_name}"
    }
  )
}

# ----------------------------------------------------------------------------
# TASK DEFINITION
# ----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "main" {
  count = var.create_service ? 1 : 0

  family                   = var.task_family_name != "" ? var.task_family_name : "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image
    cpu       = var.container_cpu
    memory    = var.container_memory
    essential = true

    portMappings = var.container_port != 0 ? [{
      containerPort = var.container_port
      protocol      = "tcp"
    }] : []

    environment = [
      for key, value in var.environment_variables : {
        name  = key
        value = value
      }
    ]

    secrets = [
      for key, value in var.secrets : {
        name      = key
        valueFrom = value
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main[0].name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = var.service_name
      }
    }

    healthCheck = var.health_check_command != "" ? {
      command     = split(",", var.health_check_command)
      interval    = var.health_check_interval
      timeout     = var.health_check_timeout
      retries     = var.health_check_retries
      startPeriod = var.health_check_start_period
    } : null
  }])

  tags = merge(
    var.common_tags,
    {
      Name = var.task_family_name != "" ? var.task_family_name : "${var.project_name}-${var.environment}-task"
    }
  )
}

# ----------------------------------------------------------------------------
# ECS SERVICE
# ----------------------------------------------------------------------------

resource "aws_ecs_service" "main" {
  count = var.create_service ? 1 : 0

  name            = var.service_name
  cluster         = var.create_cluster ? aws_ecs_cluster.main[0].id : var.existing_cluster_id
  task_definition = aws_ecs_task_definition.main[0].arn
  desired_count   = var.desired_count
  launch_type     = var.use_fargate_spot ? null : "FARGATE"

  # Fargate Spot
  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = var.fargate_spot_weight
      base              = var.fargate_spot_base
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  # Service discovery
  dynamic "service_registries" {
    for_each = var.service_discovery_arn != "" ? [1] : []
    content {
      registry_arn = var.service_discovery_arn
    }
  }

  # Deployment configuration
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  # Health check grace period (for ALB)
  health_check_grace_period_seconds = var.target_group_arn != "" ? var.health_check_grace_period : null

  # Enable ECS Exec (for debugging)
  enable_execute_command = var.enable_ecs_exec

  tags = merge(
    var.common_tags,
    {
      Name        = var.service_name
      Environment = var.environment
    }
  )

  # Ignore desired_count changes (managed by auto-scaling)
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ----------------------------------------------------------------------------
# AUTO-SCALING
# ----------------------------------------------------------------------------

# Auto-scaling target
resource "aws_appautoscaling_target" "ecs" {
  count = var.create_service && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.create_cluster ? aws_ecs_cluster.main[0].name : var.existing_cluster_name}/${aws_ecs_service.main[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based auto-scaling policy
resource "aws_appautoscaling_policy" "ecs_cpu" {
  count = var.create_service && var.enable_autoscaling && var.autoscaling_cpu_target > 0 ? 1 : 0

  name               = "${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

# Memory-based auto-scaling policy
resource "aws_appautoscaling_policy" "ecs_memory" {
  count = var.create_service && var.enable_autoscaling && var.autoscaling_memory_target > 0 ? 1 : 0

  name               = "${var.service_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_region" "current" {}

# ============================================================================
# OUTPUTS
# ============================================================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.main[0].id : null
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.main[0].arn : null
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.main[0].name : null
}

output "service_id" {
  description = "ID of the ECS service"
  value       = var.create_service ? aws_ecs_service.main[0].id : null
}

output "service_name" {
  description = "Name of the ECS service"
  value       = var.create_service ? aws_ecs_service.main[0].name : null
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = var.create_service ? aws_ecs_task_definition.main[0].arn : null
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = var.create_service ? aws_ecs_task_definition.main[0].family : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.create_service ? aws_cloudwatch_log_group.main[0].name : null
}

# Summary output
output "fargate_summary" {
  description = "Summary of created Fargate resources"
  value = var.create_service ? {
    cluster_name        = var.create_cluster ? aws_ecs_cluster.main[0].name : var.existing_cluster_name
    service_name        = aws_ecs_service.main[0].name
    task_definition     = aws_ecs_task_definition.main[0].family
    desired_count       = var.desired_count
    cpu                 = var.task_cpu
    memory              = var.task_memory
    container_image     = var.container_image
    autoscaling_enabled = var.enable_autoscaling
  } : "not created"
}
