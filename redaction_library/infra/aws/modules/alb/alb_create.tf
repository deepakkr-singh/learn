# ============================================================================
# CREATE APPLICATION LOAD BALANCER (ALB)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage an Application Load Balancer
# to distribute traffic across multiple targets (EC2, Fargate, Lambda, IPs).
#
# WHAT THIS FILE CREATES:
# -----------------------
# - Application Load Balancer (ALB)
# - Target Groups for routing
# - Listeners (HTTP/HTTPS)
# - Listener Rules (path-based, host-based routing)
# - Security Groups for ALB
#
# COMMON USE CASES:
# -----------------
# 1. Distribute traffic across multiple EC2 instances
# 2. Zero-downtime deployments (rolling updates)
# 3. Path-based routing (/api → API servers, /web → web servers)
# 4. SSL/TLS termination (HTTPS handling)
# 5. Health checks and auto-recovery
#
# ============================================================================

# ----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# ----------------------------------------------------------------------------

resource "aws_lb" "main" {
  count = var.create_alb ? 1 : 0

  name               = var.alb_name != "" ? var.alb_name : "${var.project_name}-${var.environment}-${var.alb_purpose}"
  load_balancer_type = "application"
  internal           = var.internal
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  # Deletion protection
  enable_deletion_protection = var.enable_deletion_protection

  # HTTP/2 and gRPC support
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # Idle timeout
  idle_timeout = var.idle_timeout

  # Access logs
  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name        = var.alb_name != "" ? var.alb_name : "${var.project_name}-${var.environment}-${var.alb_purpose}"
      Environment = var.environment
      Purpose     = var.alb_purpose
      Type        = var.internal ? "internal" : "internet-facing"
    }
  )
}

# ----------------------------------------------------------------------------
# TARGET GROUPS
# ----------------------------------------------------------------------------

# Main target group
resource "aws_lb_target_group" "main" {
  count = var.create_alb && var.create_target_group ? 1 : 0

  name                 = var.target_group_name != "" ? var.target_group_name : "${var.project_name}-${var.environment}-tg"
  port                 = var.target_port
  protocol             = var.target_protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay

  # Health check
  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  # Stickiness (session affinity)
  dynamic "stickiness" {
    for_each = var.stickiness_enabled ? [1] : []
    content {
      type            = var.stickiness_type
      cookie_duration = var.stickiness_cookie_duration
      enabled         = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.target_group_name != "" ? var.target_group_name : "${var.project_name}-${var.environment}-tg"
    }
  )
}

# Additional target groups
resource "aws_lb_target_group" "additional" {
  for_each = var.additional_target_groups

  name                 = each.value.name
  port                 = each.value.port
  protocol             = lookup(each.value, "protocol", "HTTP")
  vpc_id               = var.vpc_id
  target_type          = lookup(each.value, "target_type", "instance")
  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  health_check {
    enabled             = true
    path                = lookup(each.value, "health_check_path", "/health")
    port                = lookup(each.value, "health_check_port", "traffic-port")
    protocol            = lookup(each.value, "health_check_protocol", "HTTP")
    interval            = lookup(each.value, "health_check_interval", 30)
    timeout             = lookup(each.value, "health_check_timeout", 5)
    healthy_threshold   = lookup(each.value, "health_check_healthy_threshold", 2)
    unhealthy_threshold = lookup(each.value, "health_check_unhealthy_threshold", 2)
    matcher             = lookup(each.value, "health_check_matcher", "200")
  }

  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness_enabled", false) ? [1] : []
    content {
      type            = lookup(each.value, "stickiness_type", "lb_cookie")
      cookie_duration = lookup(each.value, "stickiness_cookie_duration", 86400)
      enabled         = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = each.value.name
    }
  )
}

# ----------------------------------------------------------------------------
# LISTENERS
# ----------------------------------------------------------------------------

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count = var.create_alb && var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.create_target_group ? aws_lb_target_group.main[0].arn : var.default_target_group_arn
  }
}

# HTTP Listener (redirect to HTTPS or forward)
resource "aws_lb_listener" "http" {
  count = var.create_alb && var.enable_http ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type = var.http_redirect_to_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.http_redirect_to_https ? [1] : []
      content {
        port        = var.https_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.http_redirect_to_https ? null : (var.create_target_group ? aws_lb_target_group.main[0].arn : var.default_target_group_arn)
  }
}

# ----------------------------------------------------------------------------
# LISTENER RULES
# ----------------------------------------------------------------------------

# Path-based routing rules
resource "aws_lb_listener_rule" "path_rules" {
  for_each = var.path_based_rules

  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }
}

# Host-based routing rules
resource "aws_lb_listener_rule" "host_rules" {
  for_each = var.host_based_rules

  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  condition {
    host_header {
      values = each.value.host_headers
    }
  }

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "alb_id" {
  description = "ID of the ALB"
  value       = var.create_alb ? aws_lb.main[0].id : null
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = var.create_alb ? aws_lb.main[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = var.create_alb ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53)"
  value       = var.create_alb ? aws_lb.main[0].zone_id : null
}

output "target_group_arn" {
  description = "ARN of the main target group"
  value       = var.create_alb && var.create_target_group ? aws_lb_target_group.main[0].arn : null
}

output "target_group_name" {
  description = "Name of the main target group"
  value       = var.create_alb && var.create_target_group ? aws_lb_target_group.main[0].name : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.create_alb && var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.create_alb && var.enable_http ? aws_lb_listener.http[0].arn : null
}

# Summary output
output "alb_summary" {
  description = "Summary of created ALB"
  value = var.create_alb ? {
    name           = aws_lb.main[0].name
    dns_name       = aws_lb.main[0].dns_name
    type           = var.internal ? "internal" : "internet-facing"
    https_enabled  = var.enable_https
    http_enabled   = var.enable_http
    target_group   = var.create_target_group ? aws_lb_target_group.main[0].name : "not created"
    purpose        = var.alb_purpose
  } : "not created"
}
