# ============================================================================
# VPC (VIRTUAL PRIVATE CLOUD) - COMPLETE IMPLEMENTATION
# ============================================================================
#
# WHAT THIS FILE CREATES:
# -----------------------
# 1. VPC with customizable CIDR block
# 2. Public Subnets (2 AZs) - for Load Balancers, NAT Gateways
# 3. Private Subnets (2 AZs) - for Lambda, EC2, Databases
# 4. Internet Gateway - allows public subnet to access internet
# 5. NAT Gateways (2) - allows private subnet to access internet (outbound only)
# 6. Route Tables - defines where traffic goes
# 7. VPC Flow Logs - records all network traffic for debugging/security
# 8. DNS Support - enables DNS hostnames
#
# WHY THIS CONFIGURATION?
# -----------------------
# ✅ High Availability: 2 Availability Zones (if one fails, other works)
# ✅ Security: Private subnets have no direct internet access
# ✅ Best Practice: Follows AWS Well-Architected Framework
# ✅ Production-Ready: Includes monitoring (flow logs)
# ✅ Cost-Optimized: Can disable HA for dev (1 NAT instead of 2)
#
# TERRAFORM COMMANDS:
# -------------------
# terraform init      # Download required providers
# terraform plan      # Preview what will be created
# terraform apply     # Create the resources
# terraform destroy   # Delete everything
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------
# Automatically get available availability zones in current region

data "aws_availability_zones" "available" {
  state = "available"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# ----------------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------------
# WHAT: Your private network in AWS
# WHY: Isolate your resources from other AWS customers
# COST: FREE

resource "aws_vpc" "main" {
  # CIDR Block: IP address range for VPC
  # 10.0.0.0/16 = 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
  cidr_block = var.vpc_cidr

  # Enable DNS hostnames: Resources get friendly names like "ec2-xxx.amazonaws.com"
  # WITHOUT: You'd have to remember "10.0.1.25"
  # WITH: You can use "my-db.us-east-1.rds.amazonaws.com"
  enable_dns_hostnames = true

  # Enable DNS support: Allows resources to resolve DNS names
  # Always keep this TRUE
  enable_dns_support = true

  # Enable ClassicLink: For legacy EC2-Classic instances
  # Usually FALSE (EC2-Classic is deprecated)
  enable_classiclink = false

  # Enable ClassicLink DNS Support
  enable_classiclink_dns_support = false

  # Assign IPv6 CIDR block
  # Set to TRUE if you need IPv6 support (most apps don't need this)
  assign_generated_ipv6_cidr_block = false

  # Tags: EVERY resource should have tags!
  # Why? Billing, organization, automation
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.project_name}-vpc-${var.environment}"
      Description = "Main VPC for ${var.project_name}"
      Component   = "Network"
      IPv4CIDR    = var.vpc_cidr
    }
  )
}

# ----------------------------------------------------------------------------
# INTERNET GATEWAY
# ----------------------------------------------------------------------------
# WHAT: Gateway to the internet (like your home's front door)
# WHY: Without IGW, nothing can access the internet
# COST: FREE
# LIMIT: 1 per VPC (you can't have multiple front doors)

resource "aws_internet_gateway" "main" {
  # Attach to VPC
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-igw-${var.environment}"
      Purpose   = "Allow public subnets to access internet"
      Component = "Network"
    }
  )
}

# ----------------------------------------------------------------------------
# PUBLIC SUBNETS
# ----------------------------------------------------------------------------
# WHAT: Subnets with direct internet access
# WHY: For resources that need to be accessed from internet (Load Balancers)
# COST: FREE
# BEST PRACTICE: Only put Load Balancers, NAT Gateways, Bastion hosts here

# Public Subnet in Availability Zone A
resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id

  # CIDR: 10.0.1.0/24 = 256 IP addresses (10.0.1.0 to 10.0.1.255)
  # Actually usable: 251 IPs (AWS reserves 5 IPs per subnet)
  cidr_block = var.public_subnet_a_cidr

  # Availability Zone: us-east-1a (or first available AZ in your region)
  # Why AZ matters: Physical data center location for redundancy
  availability_zone = data.aws_availability_zones.available.names[0]

  # Map public IP on launch: Automatically assign public IP to EC2 instances
  # Usually TRUE for public subnets, FALSE for private subnets
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name                     = "${var.project_name}-public-a-${var.environment}"
      Type                     = "Public"
      AvailabilityZone         = data.aws_availability_zones.available.names[0]
      CIDR                     = var.public_subnet_a_cidr
      "kubernetes.io/role/elb" = "1" # For Kubernetes Load Balancers (if using EKS)
    }
  )
}

# Public Subnet in Availability Zone B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name                     = "${var.project_name}-public-b-${var.environment}"
      Type                     = "Public"
      AvailabilityZone         = data.aws_availability_zones.available.names[1]
      CIDR                     = var.public_subnet_b_cidr
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# ----------------------------------------------------------------------------
# PRIVATE SUBNETS
# ----------------------------------------------------------------------------
# WHAT: Subnets WITHOUT direct internet access
# WHY: For resources that should NOT be exposed to internet (databases, app servers)
# COST: FREE
# BEST PRACTICE: Put 95% of your resources here!

# Private Subnet in Availability Zone A
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  # Map public IP: FALSE for private subnets
  # Resources here will NOT get public IPs
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name                              = "${var.project_name}-private-a-${var.environment}"
      Type                              = "Private"
      AvailabilityZone                  = data.aws_availability_zones.available.names[0]
      CIDR                              = var.private_subnet_a_cidr
      "kubernetes.io/role/internal-elb" = "1" # For Kubernetes internal LBs
    }
  )
}

# Private Subnet in Availability Zone B
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name                              = "${var.project_name}-private-b-${var.environment}"
      Type                              = "Private"
      AvailabilityZone                  = data.aws_availability_zones.available.names[1]
      CIDR                              = var.private_subnet_b_cidr
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

# ----------------------------------------------------------------------------
# ELASTIC IPS FOR NAT GATEWAYS
# ----------------------------------------------------------------------------
# WHAT: Static public IP addresses
# WHY: NAT Gateways need a public IP to route traffic to internet
# COST: FREE if attached to running instance, $3.60/month if not attached
# NOTE: EIP is automatically deleted when NAT Gateway is destroyed

# EIP for NAT Gateway in AZ A
resource "aws_eip" "nat_a" {
  # Domain: VPC (not EC2-Classic)
  domain = "vpc"

  # Depends on Internet Gateway existing first
  # Why? EIP needs to be able to route to internet
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-nat-eip-a-${var.environment}"
      Purpose          = "NAT Gateway Elastic IP for AZ A"
      AvailabilityZone = data.aws_availability_zones.available.names[0]
    }
  )
}

# EIP for NAT Gateway in AZ B
# Only create if high availability is enabled
resource "aws_eip" "nat_b" {
  count = var.enable_nat_gateway_ha ? 1 : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-nat-eip-b-${var.environment}"
      Purpose          = "NAT Gateway Elastic IP for AZ B"
      AvailabilityZone = data.aws_availability_zones.available.names[1]
    }
  )
}

# ----------------------------------------------------------------------------
# NAT GATEWAYS
# ----------------------------------------------------------------------------
# WHAT: One-way door to internet (outbound only)
# WHY: Allows private subnets to download updates without exposing them
# COST: $0.045/hour (~$32/month per NAT Gateway)
# BEST PRACTICE: 2 NAT Gateways (one per AZ) for high availability

# NAT Gateway in AZ A
resource "aws_nat_gateway" "nat_a" {
  # Allocation ID: The Elastic IP to use
  allocation_id = aws_eip.nat_a.id

  # Subnet: Must be in PUBLIC subnet
  # Why? NAT Gateway needs internet access via Internet Gateway
  subnet_id = aws_subnet.public_a.id

  # Wait for Internet Gateway to be created first
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-nat-a-${var.environment}"
      Purpose          = "NAT Gateway for private subnets in AZ A"
      AvailabilityZone = data.aws_availability_zones.available.names[0]
    }
  )
}

# NAT Gateway in AZ B (High Availability)
# Only create if HA is enabled
# WHY: If NAT in AZ A fails, private subnets in AZ B still have internet access
resource "aws_nat_gateway" "nat_b" {
  count = var.enable_nat_gateway_ha ? 1 : 0

  allocation_id = aws_eip.nat_b[0].id
  subnet_id     = aws_subnet.public_b.id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-nat-b-${var.environment}"
      Purpose          = "NAT Gateway for private subnets in AZ B (HA)"
      AvailabilityZone = data.aws_availability_zones.available.names[1]
    }
  )
}

# ----------------------------------------------------------------------------
# ROUTE TABLE - PUBLIC SUBNETS
# ----------------------------------------------------------------------------
# WHAT: Rules that define where network traffic goes
# WHY: Without route table, traffic doesn't know where to go!
# COST: FREE

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route 1: Local traffic (within VPC)
  # Destination: 10.0.0.0/16 (VPC CIDR)
  # Target: local (stay within VPC)
  # This route is automatic - you don't need to define it

  # Route 2: Internet traffic
  # Destination: 0.0.0.0/0 (everything else)
  # Target: Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-public-rt-${var.environment}"
      Type    = "Public"
      Purpose = "Route table for public subnets (internet access via IGW)"
    }
  )
}

# Associate public subnet A with public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Associate public subnet B with public route table
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------------------------------
# ROUTE TABLE - PRIVATE SUBNET A
# ----------------------------------------------------------------------------

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  # Route: Internet traffic goes through NAT Gateway in AZ A
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-private-a-rt-${var.environment}"
      Type             = "Private"
      Purpose          = "Route table for private subnet A (internet via NAT A)"
      AvailabilityZone = data.aws_availability_zones.available.names[0]
    }
  )
}

# Associate private subnet A with its route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

# ----------------------------------------------------------------------------
# ROUTE TABLE - PRIVATE SUBNET B
# ----------------------------------------------------------------------------

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  # If HA enabled: Use NAT Gateway B
  # If HA disabled: Use NAT Gateway A (shared)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway_ha ? aws_nat_gateway.nat_b[0].id : aws_nat_gateway.nat_a.id
  }

  tags = merge(
    var.common_tags,
    {
      Name             = "${var.project_name}-private-b-rt-${var.environment}"
      Type             = "Private"
      Purpose          = var.enable_nat_gateway_ha ? "Route table for private subnet B (internet via NAT B)" : "Route table for private subnet B (internet via NAT A - shared)"
      AvailabilityZone = data.aws_availability_zones.available.names[1]
    }
  )
}

# Associate private subnet B with its route table
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# ----------------------------------------------------------------------------
# VPC FLOW LOGS
# ----------------------------------------------------------------------------
# WHAT: Records all network traffic in your VPC
# WHY: Debugging, security analysis, compliance
# COST: ~$0.50/GB of logs (can add up for busy VPCs)
# BEST PRACTICE: Enable in production, optional in dev

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-flow-logs-role-${var.environment}"
      Purpose = "IAM role for VPC Flow Logs"
    }
  )
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-flow-logs-${var.environment}"
      Purpose = "VPC Flow Logs storage"
    }
  )
}

# VPC Flow Log
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  # What to log
  traffic_type = "ALL" # Options: ACCEPT, REJECT, ALL

  # Where to send logs
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn

  # IAM role
  iam_role_arn = aws_iam_role.flow_logs[0].arn

  # What VPC to monitor
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name    = "${var.project_name}-vpc-flow-log-${var.environment}"
      Purpose = "VPC network traffic monitoring"
    }
  )
}

# ----------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------
# WHAT: Values that other Terraform modules can use
# WHY: Don't hardcode IDs - use outputs for reusability!

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnet_a_id" {
  description = "ID of public subnet in AZ A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of public subnet in AZ B"
  value       = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "ID of private subnet in AZ A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID of private subnet in AZ B"
  value       = aws_subnet.private_b.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_a_id" {
  description = "ID of NAT Gateway in AZ A"
  value       = aws_nat_gateway.nat_a.id
}

output "nat_gateway_b_id" {
  description = "ID of NAT Gateway in AZ B (if HA enabled)"
  value       = var.enable_nat_gateway_ha ? aws_nat_gateway.nat_b[0].id : null
}

output "nat_gateway_a_public_ip" {
  description = "Public IP of NAT Gateway in AZ A"
  value       = aws_eip.nat_a.public_ip
}

output "nat_gateway_b_public_ip" {
  description = "Public IP of NAT Gateway in AZ B (if HA enabled)"
  value       = var.enable_nat_gateway_ha ? aws_eip.nat_b[0].public_ip : null
}

output "availability_zones" {
  description = "Availability zones used"
  value       = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
}
