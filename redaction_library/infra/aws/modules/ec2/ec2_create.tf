# ============================================================================
# CREATE EC2 INSTANCES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when YOU want to create and manage EC2 instances (virtual servers).
#
# WHAT THIS FILE CREATES:
# -----------------------
# - EC2 Instances (virtual servers)
# - EBS Volumes (storage)
# - Network Interfaces (optional)
# - Auto Scaling Group (optional)
# - Launch Template (for auto-scaling)
# - CloudWatch Alarms (monitoring)
#
# COMMON USE CASES:
# -----------------
# 1. Web servers (Nginx, Apache)
# 2. Application servers (Node.js, Java, Python)
# 3. Database servers (PostgreSQL, MySQL, MongoDB)
# 4. Bastion hosts (SSH jump servers)
# 5. CI/CD build servers
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

data "aws_ami" "selected" {
  count = var.ami_id == "" && var.ami_name_filter != "" ? 1 : 0

  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ----------------------------------------------------------------------------
# KEY PAIR (SSH ACCESS)
# ----------------------------------------------------------------------------

resource "aws_key_pair" "main" {
  count = var.create_key_pair && var.public_key != "" ? 1 : 0

  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.public_key

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-key"
    }
  )
}

# ----------------------------------------------------------------------------
# SECURITY GROUP (FIREWALL)
# ----------------------------------------------------------------------------

resource "aws_security_group" "main" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.project_name}-${var.environment}-${var.instance_name}-sg"
  description = "Security group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-sg"
    }
  )
}

resource "aws_security_group_rule" "ingress" {
  count = var.create_security_group && length(var.security_group_ingress_rules) > 0 ? length(var.security_group_ingress_rules) : 0

  security_group_id = aws_security_group.main[0].id
  type              = "ingress"

  from_port   = var.security_group_ingress_rules[count.index].from_port
  to_port     = var.security_group_ingress_rules[count.index].to_port
  protocol    = var.security_group_ingress_rules[count.index].protocol
  cidr_blocks = lookup(var.security_group_ingress_rules[count.index], "cidr_blocks", null)
  description = lookup(var.security_group_ingress_rules[count.index], "description", "")
}

resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.main[0].id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic"
}

# ----------------------------------------------------------------------------
# IAM ROLE (PERMISSIONS)
# ----------------------------------------------------------------------------

resource "aws_iam_role" "main" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "main" {
  count = var.create_iam_role && length(var.iam_policy_arns) > 0 ? length(var.iam_policy_arns) : 0

  role       = aws_iam_role.main[0].name
  policy_arn = var.iam_policy_arns[count.index]
}

resource "aws_iam_instance_profile" "main" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.project_name}-${var.environment}-${var.instance_name}-profile"
  role = aws_iam_role.main[0].name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-profile"
    }
  )
}

# ----------------------------------------------------------------------------
# EC2 INSTANCE (SINGLE INSTANCE MODE)
# ----------------------------------------------------------------------------

resource "aws_instance" "main" {
  count = var.create_instance && !var.enable_auto_scaling ? var.instance_count : 0

  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.selected[0].id
  instance_type = var.instance_type
  key_name      = var.create_key_pair ? aws_key_pair.main[0].key_name : var.existing_key_name

  subnet_id = var.subnet_ids[count.index % length(var.subnet_ids)]

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.main[0].id] : var.security_group_ids

  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.main[0].name : var.existing_iam_instance_profile

  associate_public_ip_address = var.associate_public_ip

  user_data                   = var.user_data != "" ? var.user_data : null
  user_data_replace_on_change = var.user_data_replace_on_change

  monitoring = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_encrypted && var.kms_key_id != "" ? var.kms_key_id : null

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-${var.environment}-${var.instance_name}-${count.index + 1}-root"
      }
    )
  }

  dynamic "ebs_block_device" {
    for_each = var.additional_ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = lookup(ebs_block_device.value, "iops", null)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
      encrypted             = lookup(ebs_block_device.value, "encrypted", true)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", var.kms_key_id)

      tags = merge(
        var.common_tags,
        {
          Name = "${var.project_name}-${var.environment}-${var.instance_name}-${count.index + 1}-${ebs_block_device.value.device_name}"
        }
      )
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.instance_name}-${count.index + 1}"
      Environment = var.environment
    }
  )

  volume_tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-${count.index + 1}-volume"
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

# ----------------------------------------------------------------------------
# ELASTIC IP (STATIC PUBLIC IP)
# ----------------------------------------------------------------------------

resource "aws_eip" "main" {
  count = var.create_instance && !var.enable_auto_scaling && var.allocate_elastic_ip ? var.instance_count : 0

  instance = aws_instance.main[count.index].id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-${count.index + 1}-eip"
    }
  )
}

# ----------------------------------------------------------------------------
# LAUNCH TEMPLATE (FOR AUTO-SCALING)
# ----------------------------------------------------------------------------

resource "aws_launch_template" "main" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix   = "${var.project_name}-${var.environment}-${var.instance_name}-lt-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.selected[0].id
  instance_type = var.instance_type
  key_name      = var.create_key_pair ? aws_key_pair.main[0].key_name : var.existing_key_name

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.main[0].id] : var.security_group_ids

  iam_instance_profile {
    name = var.create_iam_role ? aws_iam_instance_profile.main[0].name : var.existing_iam_instance_profile
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = var.root_volume_type
      volume_size           = var.root_volume_size
      delete_on_termination = var.root_volume_delete_on_termination
      encrypted             = var.root_volume_encrypted
      kms_key_id            = var.root_volume_encrypted && var.kms_key_id != "" ? var.kms_key_id : null
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.additional_ebs_volumes
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_type           = block_device_mappings.value.volume_type
        volume_size           = block_device_mappings.value.volume_size
        iops                  = lookup(block_device_mappings.value, "iops", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
        encrypted             = lookup(block_device_mappings.value, "encrypted", true)
        kms_key_id            = lookup(block_device_mappings.value, "kms_key_id", var.kms_key_id)
      }
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
        Name        = "${var.project_name}-${var.environment}-${var.instance_name}"
        Environment = var.environment
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-${var.environment}-${var.instance_name}-volume"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-lt"
    }
  )
}

# ----------------------------------------------------------------------------
# AUTO SCALING GROUP
# ----------------------------------------------------------------------------

resource "aws_autoscaling_group" "main" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix         = "${var.project_name}-${var.environment}-${var.instance_name}-asg-"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period

  launch_template {
    id      = aws_launch_template.main[0].id
    version = "$Latest"
  }

  dynamic "target_group_arns" {
    for_each = var.target_group_arns != [] ? [1] : []
    content {
      target_group_arns = var.target_group_arns
    }
  }

  enabled_metrics = var.asg_enabled_metrics

  dynamic "tag" {
    for_each = merge(
      var.common_tags,
      {
        Name        = "${var.project_name}-${var.environment}-${var.instance_name}"
        Environment = var.environment
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ----------------------------------------------------------------------------
# AUTO SCALING POLICIES
# ----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_up" {
  count = var.enable_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-${var.instance_name}-scale-up"
  scaling_adjustment     = var.asg_scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.asg_scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

resource "aws_autoscaling_policy" "scale_down" {
  count = var.enable_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-${var.instance_name}-scale-down"
  scaling_adjustment     = var.asg_scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.asg_scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

# ----------------------------------------------------------------------------
# CLOUDWATCH ALARMS
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.instance_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_cpu_high_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up[0].arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-cpu-high"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_auto_scaling && var.enable_auto_scaling_policies ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.instance_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.asg_cpu_low_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down[0].arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}-cpu-low"
    }
  )
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = var.create_instance && !var.enable_auto_scaling ? aws_instance.main[*].id : []
}

output "instance_private_ips" {
  description = "Private IPs of EC2 instances"
  value       = var.create_instance && !var.enable_auto_scaling ? aws_instance.main[*].private_ip : []
}

output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = var.create_instance && !var.enable_auto_scaling ? aws_instance.main[*].public_ip : []
}

output "elastic_ips" {
  description = "Elastic IPs allocated to instances"
  value       = var.create_instance && !var.enable_auto_scaling && var.allocate_elastic_ip ? aws_eip.main[*].public_ip : []
}

output "security_group_id" {
  description = "ID of security group"
  value       = var.create_security_group ? aws_security_group.main[0].id : null
}

output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = var.create_iam_role ? aws_iam_role.main[0].arn : null
}

output "autoscaling_group_name" {
  description = "Name of Auto Scaling Group"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.main[0].name : null
}

output "launch_template_id" {
  description = "ID of Launch Template"
  value       = var.enable_auto_scaling ? aws_launch_template.main[0].id : null
}

output "ec2_summary" {
  description = "Summary of EC2 resources"
  value = var.create_instance ? {
    instance_type       = var.instance_type
    ami_id              = var.ami_id != "" ? var.ami_id : (var.ami_name_filter != "" ? data.aws_ami.selected[0].id : "")
    instance_count      = var.enable_auto_scaling ? "${var.asg_min_size}-${var.asg_max_size}" : var.instance_count
    auto_scaling        = var.enable_auto_scaling
    public_ips          = var.associate_public_ip || var.allocate_elastic_ip
    monitoring          = var.enable_detailed_monitoring
  } : "not created"
}
