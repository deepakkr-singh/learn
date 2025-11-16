# ============================================================================
# SECURITY GROUPS - CREATE NEW (COMMON PATTERNS)
# ============================================================================
#
# WHAT THIS FILE CREATES:
# -----------------------
# Security Groups for common AWS services with best practice rules
#
# WHAT IS A SECURITY GROUP?
# -------------------------
# A security group is a virtual firewall that controls traffic to/from AWS resources.
# Think of it like a bouncer at a club - decides who gets in and who can leave.
#
# IMPORTANT CONCEPTS:
# ------------------
# - STATEFUL: If you allow incoming traffic, response is automatically allowed
# - INGRESS: Incoming traffic (who can connect TO your resource)
# - EGRESS: Outgoing traffic (where your resource can connect TO)
# - Default: All inbound BLOCKED, all outbound ALLOWED
#
# WHEN TO USE THIS FILE:
# ----------------------
# - You're creating new security groups for your application
# - You have permission to create security groups
# - Small/medium companies or dev environments
#
# WHEN NOT TO USE:
# ----------------
# - Enterprise with centralized security groups → use security_group_use_existing.tf
# - Network Team manages all security groups → request SG IDs from them
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------

# Get VPC ID (you must have VPC created or referenced first)
data "aws_vpc" "main" {
  id = var.vpc_id
}

# ----------------------------------------------------------------------------
# PATTERN 1: ALB (APPLICATION LOAD BALANCER) SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: Load balancers in public subnet
# PURPOSE: Allow internet traffic to reach your ALB
# COMMON PORTS: 80 (HTTP), 443 (HTTPS)

resource "aws_security_group" "alb" {
  count = var.create_alb_sg ? 1 : 0

  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer - allows HTTP/HTTPS from internet"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES (Incoming Traffic)
  # ---------------------------------

  # Rule 1: Allow HTTPS from anywhere (recommended)
  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Anyone on internet can access

    # Why 0.0.0.0/0?
    # Your website/API needs to be accessible to everyone
    # ALB is in public subnet specifically for this purpose
  }

  # Rule 2: Allow HTTP from anywhere (for redirect to HTTPS)
  ingress {
    description = "Allow HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Anyone can access

    # Why allow HTTP?
    # ALB can redirect HTTP → HTTPS automatically
    # Without this, users typing http:// would get connection refused
  }

  # EGRESS RULES (Outgoing Traffic)
  # ---------------------------------

  # Rule 1: Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic to backend services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]

    # Why allow all?
    # ALB needs to forward requests to backend (Lambda, EC2, Fargate)
    # Backend could be on any port (80, 8080, 3000, etc.)
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-alb-sg-${var.environment}"
      Purpose     = "Allow HTTP/HTTPS traffic from internet to ALB"
      ResourceType = "Application Load Balancer"
    }
  )
}

# ----------------------------------------------------------------------------
# PATTERN 2: LAMBDA SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: Lambda functions in private subnet
# PURPOSE: Allow Lambda to connect to databases/services and internet
# NOTE: Lambda doesn't accept incoming connections (no ingress rules needed)

resource "aws_security_group" "lambda" {
  count = var.create_lambda_sg ? 1 : 0

  name        = "${var.project_name}-lambda-sg-${var.environment}"
  description = "Security group for Lambda functions - allows outbound connections to databases and internet"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES: NONE!
  # --------------------
  # Lambda functions don't accept incoming connections
  # They are triggered by events (API Gateway, SQS, S3, etc.)
  # The only exception is if Lambda is behind an ALB (see pattern below)

  # EGRESS RULES (Outgoing Traffic)
  # ---------------------------------

  # Rule 1: Allow all outbound traffic
  egress {
    description = "Allow Lambda to connect to internet, databases, and AWS services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

    # Why allow all?
    # Lambda may need to:
    # - Download npm packages (internet)
    # - Connect to DynamoDB (AWS service)
    # - Connect to RDS database (port 5432 or 3306)
    # - Call external APIs
    # - Write to S3
  }

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-lambda-sg-${var.environment}"
      Purpose      = "Allow Lambda outbound connections"
      ResourceType = "AWS Lambda"
    }
  )
}

# ----------------------------------------------------------------------------
# PATTERN 3: RDS DATABASE SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: RDS databases in private subnet
# PURPOSE: Allow only application servers (Lambda/EC2) to connect
# IMPORTANT: Should NEVER allow 0.0.0.0/0 (internet access)

resource "aws_security_group" "rds" {
  count = var.create_rds_sg ? 1 : 0

  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS database - allows connections from application servers only"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES (Incoming Traffic)
  # ---------------------------------

  # Rule 1: Allow PostgreSQL from Lambda security group
  ingress {
    description     = "Allow PostgreSQL from Lambda functions"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.create_lambda_sg ? [aws_security_group.lambda[0].id] : []

    # Why security_groups instead of cidr_blocks?
    # More secure! Only resources with Lambda SG can connect
    # Even if IP changes, security group relationship remains
  }

  # Rule 2: Allow MySQL from Lambda (if using MySQL instead)
  # Uncomment if using MySQL/MariaDB
  # ingress {
  #   description     = "Allow MySQL from Lambda functions"
  #   from_port       = 3306
  #   to_port         = 3306
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.lambda[0].id]
  # }

  # Rule 3: Allow from EC2 if you have EC2 instances
  # ingress {
  #   description     = "Allow PostgreSQL from EC2 instances"
  #   from_port       = 5432
  #   to_port         = 5432
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.ec2[0].id]
  # }

  # EGRESS RULES (Outgoing Traffic)
  # ---------------------------------

  # Databases typically don't need outbound access
  # But you might need it for:
  # - Replication to another database
  # - Extensions that fetch data
  # - Notifications (via SNS/SQS)

  egress {
    description = "Allow all outbound (usually not needed for databases)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-rds-sg-${var.environment}"
      Purpose      = "Restrict database access to application servers only"
      ResourceType = "RDS Database"
    }
  )
}

# ----------------------------------------------------------------------------
# PATTERN 4: EC2 WEB SERVER SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: EC2 instances running web applications (behind ALB)
# PURPOSE: Allow traffic from ALB only, block direct internet access

resource "aws_security_group" "ec2_web" {
  count = var.create_ec2_web_sg ? 1 : 0

  name        = "${var.project_name}-ec2-web-sg-${var.environment}"
  description = "Security group for EC2 web servers - allows traffic from ALB only"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES (Incoming Traffic)
  # ---------------------------------

  # Rule 1: Allow HTTP from ALB only
  ingress {
    description     = "Allow HTTP from Application Load Balancer only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []

    # Why not 0.0.0.0/0?
    # EC2 is in PRIVATE subnet
    # Only ALB (in public subnet) should access it
    # Direct internet access = security risk
  }

  # Rule 2: Allow custom application port (if not using port 80)
  ingress {
    description     = "Allow traffic on custom app port from ALB"
    from_port       = var.ec2_app_port
    to_port         = var.ec2_app_port
    protocol        = "tcp"
    security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []
  }

  # Rule 3: SSH access (for debugging - restrict to your IP!)
  ingress {
    description = "Allow SSH from bastion host or your office IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks  # NEVER use 0.0.0.0/0 for SSH!

    # Security Best Practice:
    # Only allow SSH from:
    # - Your office IP (e.g., 203.0.113.0/24)
    # - Bastion host security group
    # - VPN IP range
  }

  # EGRESS RULES (Outgoing Traffic)
  # ---------------------------------

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

    # Why?
    # EC2 needs to:
    # - Download updates (apt/yum)
    # - Connect to databases
    # - Call external APIs
    # - Write to S3
  }

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-ec2-web-sg-${var.environment}"
      Purpose      = "Allow web traffic from ALB, block direct internet access"
      ResourceType = "EC2 Web Server"
    }
  )
}

# ----------------------------------------------------------------------------
# PATTERN 5: BASTION HOST SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: Bastion/Jump server in public subnet
# PURPOSE: SSH gateway to access private resources

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${var.project_name}-bastion-sg-${var.environment}"
  description = "Security group for Bastion host - SSH gateway to private resources"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES (Incoming Traffic)
  # ---------------------------------

  # Rule 1: Allow SSH from your office/VPN only
  ingress {
    description = "Allow SSH from authorized IPs only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr_blocks  # Your office IP only!

    # CRITICAL SECURITY:
    # NEVER use 0.0.0.0/0 for bastion!
    # This is your gateway to private resources
    # Only allow specific IP addresses
  }

  # EGRESS RULES (Outgoing Traffic)
  # ---------------------------------

  # Allow SSH to private resources
  egress {
    description = "Allow SSH to private EC2 instances"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]  # Only within VPC
  }

  # Allow HTTPS for updates
  egress {
    description = "Allow HTTPS for package updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-bastion-sg-${var.environment}"
      Purpose      = "SSH gateway to private resources"
      ResourceType = "Bastion Host"
      Critical     = "true"  # Extra monitoring needed
    }
  )
}

# ----------------------------------------------------------------------------
# PATTERN 6: ELASTICACHE (REDIS/MEMCACHED) SECURITY GROUP
# ----------------------------------------------------------------------------
# WHO USES IT: ElastiCache clusters in private subnet
# PURPOSE: Allow connections from application servers only

resource "aws_security_group" "elasticache" {
  count = var.create_elasticache_sg ? 1 : 0

  name        = "${var.project_name}-elasticache-sg-${var.environment}"
  description = "Security group for ElastiCache - allows connections from application servers"
  vpc_id      = data.aws_vpc.main.id

  # INGRESS RULES (Incoming Traffic)
  # ---------------------------------

  # Rule 1: Allow Redis from Lambda
  ingress {
    description     = "Allow Redis from Lambda functions"
    from_port       = 6379  # Default Redis port
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.create_lambda_sg ? [aws_security_group.lambda[0].id] : []
  }

  # Rule 2: Allow Memcached (if using Memcached instead of Redis)
  # ingress {
  #   description     = "Allow Memcached from Lambda"
  #   from_port       = 11211
  #   to_port         = 11211
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.lambda[0].id]
  # }

  # EGRESS RULES
  # ------------
  # ElastiCache typically doesn't need outbound

  tags = merge(
    var.common_tags,
    {
      Name         = "${var.project_name}-elasticache-sg-${var.environment}"
      Purpose      = "Allow cache access from application servers only"
      ResourceType = "ElastiCache"
    }
  )
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = var.create_alb_sg ? aws_security_group.alb[0].id : null
}

output "lambda_security_group_id" {
  description = "ID of Lambda security group"
  value       = var.create_lambda_sg ? aws_security_group.lambda[0].id : null
}

output "rds_security_group_id" {
  description = "ID of RDS security group"
  value       = var.create_rds_sg ? aws_security_group.rds[0].id : null
}

output "ec2_web_security_group_id" {
  description = "ID of EC2 web server security group"
  value       = var.create_ec2_web_sg ? aws_security_group.ec2_web[0].id : null
}

output "bastion_security_group_id" {
  description = "ID of Bastion host security group"
  value       = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
}

output "elasticache_security_group_id" {
  description = "ID of ElastiCache security group"
  value       = var.create_elasticache_sg ? aws_security_group.elasticache[0].id : null
}

output "security_group_summary" {
  description = "Summary of created security groups"
  value = {
    alb_sg         = var.create_alb_sg ? aws_security_group.alb[0].id : "not created"
    lambda_sg      = var.create_lambda_sg ? aws_security_group.lambda[0].id : "not created"
    rds_sg         = var.create_rds_sg ? aws_security_group.rds[0].id : "not created"
    ec2_web_sg     = var.create_ec2_web_sg ? aws_security_group.ec2_web[0].id : "not created"
    bastion_sg     = var.create_bastion_sg ? aws_security_group.bastion[0].id : "not created"
    elasticache_sg = var.create_elasticache_sg ? aws_security_group.elasticache[0].id : "not created"
  }
}
