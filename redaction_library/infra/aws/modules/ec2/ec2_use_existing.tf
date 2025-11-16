# ============================================================================
# USE EXISTING EC2 RESOURCES
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this when you need to reference existing EC2 instances, AMIs, or
# resources created outside of this module (e.g., by Platform Team).
#
# WHAT YOU NEED FROM PLATFORM TEAM:
# ---------------------------------
# 1. Instance Information:
#    - Instance ID(s) or Name tags
#    - Instance type and configuration
#    - Subnet IDs and security groups
#
# 2. AMI Information:
#    - Custom AMI IDs (if using company-approved images)
#    - AMI naming conventions
#
# 3. Networking:
#    - VPC ID and subnet IDs
#    - Security group IDs
#    - Route table configurations
#
# 4. IAM:
#    - Instance profile ARN
#    - Required IAM policies
#
# HOW TO USE:
# -----------
# 1. Ask Platform Team for resource IDs/names
# 2. Use data sources below to fetch existing resources
# 3. Reference outputs in your configurations
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING EC2 INSTANCES
# ----------------------------------------------------------------------------

# Fetch instance by ID
data "aws_instance" "by_id" {
  count = var.existing_instance_id != "" ? 1 : 0

  instance_id = var.existing_instance_id
}

# Fetch instances by tag
data "aws_instances" "by_tags" {
  count = var.existing_instance_tags != {} ? 1 : 0

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }

  dynamic "filter" {
    for_each = var.existing_instance_tags
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING AMIs
# ----------------------------------------------------------------------------

# Fetch specific AMI by ID
data "aws_ami" "by_id" {
  count = var.existing_ami_id != "" ? 1 : 0

  owners = ["self", "amazon"]

  filter {
    name   = "image-id"
    values = [var.existing_ami_id]
  }
}

# Fetch latest AMI by name pattern
data "aws_ami" "by_name" {
  count = var.existing_ami_name_filter != "" ? 1 : 0

  most_recent = true
  owners      = var.existing_ami_owner != "" ? [var.existing_ami_owner] : ["self", "amazon"]

  filter {
    name   = "name"
    values = [var.existing_ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Fetch Amazon Linux 2023 (latest)
data "aws_ami" "amazon_linux_2023" {
  count = var.use_amazon_linux_2023 ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Fetch Ubuntu (latest)
data "aws_ami" "ubuntu" {
  count = var.use_ubuntu ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING SECURITY GROUPS
# ----------------------------------------------------------------------------

data "aws_security_group" "by_id" {
  count = var.existing_security_group_id != "" ? 1 : 0

  id = var.existing_security_group_id
}

data "aws_security_group" "by_name" {
  count = var.existing_security_group_name != "" ? 1 : 0

  name = var.existing_security_group_name
}

data "aws_security_groups" "by_tags" {
  count = var.existing_security_group_tags != {} ? 1 : 0

  dynamic "filter" {
    for_each = var.existing_security_group_tags
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING KEY PAIRS
# ----------------------------------------------------------------------------

data "aws_key_pair" "existing" {
  count = var.existing_key_pair_name != "" ? 1 : 0

  key_name = var.existing_key_pair_name
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING IAM RESOURCES
# ----------------------------------------------------------------------------

data "aws_iam_role" "existing" {
  count = var.existing_iam_role_name != "" ? 1 : 0

  name = var.existing_iam_role_name
}

data "aws_iam_instance_profile" "existing" {
  count = var.existing_iam_instance_profile_name != "" ? 1 : 0

  name = var.existing_iam_instance_profile_name
}

# ----------------------------------------------------------------------------
# DATA SOURCES - EXISTING LOAD BALANCERS
# ----------------------------------------------------------------------------

data "aws_lb" "existing" {
  count = var.existing_lb_name != "" ? 1 : 0

  name = var.existing_lb_name
}

data "aws_lb_target_group" "existing" {
  count = var.existing_target_group_name != "" ? 1 : 0

  name = var.existing_target_group_name
}

# ============================================================================
# OUTPUTS
# ============================================================================

# Instance outputs
output "existing_instance_id" {
  description = "ID of existing instance"
  value       = var.existing_instance_id != "" ? data.aws_instance.by_id[0].id : null
}

output "existing_instance_private_ip" {
  description = "Private IP of existing instance"
  value       = var.existing_instance_id != "" ? data.aws_instance.by_id[0].private_ip : null
}

output "existing_instance_public_ip" {
  description = "Public IP of existing instance"
  value       = var.existing_instance_id != "" ? data.aws_instance.by_id[0].public_ip : null
}

output "existing_instances_by_tags" {
  description = "IDs of instances found by tags"
  value       = var.existing_instance_tags != {} ? data.aws_instances.by_tags[0].ids : []
}

# AMI outputs
output "existing_ami_id" {
  description = "ID of existing AMI"
  value = var.existing_ami_id != "" ? data.aws_ami.by_id[0].id : (
    var.existing_ami_name_filter != "" ? data.aws_ami.by_name[0].id : (
      var.use_amazon_linux_2023 ? data.aws_ami.amazon_linux_2023[0].id : (
        var.use_ubuntu ? data.aws_ami.ubuntu[0].id : null
      )
    )
  )
}

output "existing_ami_name" {
  description = "Name of existing AMI"
  value = var.existing_ami_id != "" ? data.aws_ami.by_id[0].name : (
    var.existing_ami_name_filter != "" ? data.aws_ami.by_name[0].name : (
      var.use_amazon_linux_2023 ? data.aws_ami.amazon_linux_2023[0].name : (
        var.use_ubuntu ? data.aws_ami.ubuntu[0].name : null
      )
    )
  )
}

# Security group outputs
output "existing_security_group_id" {
  description = "ID of existing security group"
  value = var.existing_security_group_id != "" ? data.aws_security_group.by_id[0].id : (
    var.existing_security_group_name != "" ? data.aws_security_group.by_name[0].id : null
  )
}

output "existing_security_groups_by_tags" {
  description = "IDs of security groups found by tags"
  value       = var.existing_security_group_tags != {} ? data.aws_security_groups.by_tags[0].ids : []
}

# Key pair output
output "existing_key_pair_name" {
  description = "Name of existing key pair"
  value       = var.existing_key_pair_name != "" ? data.aws_key_pair.existing[0].key_name : null
}

# IAM outputs
output "existing_iam_role_arn" {
  description = "ARN of existing IAM role"
  value       = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : null
}

output "existing_iam_instance_profile_arn" {
  description = "ARN of existing IAM instance profile"
  value       = var.existing_iam_instance_profile_name != "" ? data.aws_iam_instance_profile.existing[0].arn : null
}

# Load balancer outputs
output "existing_lb_arn" {
  description = "ARN of existing load balancer"
  value       = var.existing_lb_name != "" ? data.aws_lb.existing[0].arn : null
}

output "existing_target_group_arn" {
  description = "ARN of existing target group"
  value       = var.existing_target_group_name != "" ? data.aws_lb_target_group.existing[0].arn : null
}

# Summary output
output "existing_resources_summary" {
  description = "Summary of all existing resources"
  value = {
    instance = var.existing_instance_id != "" ? {
      id         = data.aws_instance.by_id[0].id
      type       = data.aws_instance.by_id[0].instance_type
      private_ip = data.aws_instance.by_id[0].private_ip
      public_ip  = data.aws_instance.by_id[0].public_ip
    } : "not provided"

    ami = var.existing_ami_id != "" ? data.aws_ami.by_id[0].id : (
      var.existing_ami_name_filter != "" ? data.aws_ami.by_name[0].id : (
        var.use_amazon_linux_2023 ? data.aws_ami.amazon_linux_2023[0].id : (
          var.use_ubuntu ? data.aws_ami.ubuntu[0].id : "not provided"
        )
      )
    )

    security_group = var.existing_security_group_id != "" ? data.aws_security_group.by_id[0].id : (
      var.existing_security_group_name != "" ? data.aws_security_group.by_name[0].id : "not provided"
    )

    key_pair = var.existing_key_pair_name != "" ? data.aws_key_pair.existing[0].key_name : "not provided"

    iam_role = var.existing_iam_role_name != "" ? data.aws_iam_role.existing[0].arn : "not provided"
  }
}
