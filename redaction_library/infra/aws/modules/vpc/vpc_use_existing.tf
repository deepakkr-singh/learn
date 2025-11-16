# ============================================================================
# USE EXISTING VPC (CREATED BY NETWORK TEAM)
# ============================================================================
#
# WHEN TO USE THIS FILE:
# ----------------------
# Use this file when your Network Team has already created the VPC for you.
# You just need to reference the existing VPC and its components.
#
# WHEN NOT TO USE:
# ----------------
# If you need to CREATE a new VPC from scratch, use vpc_create.tf instead.
#
# WHAT YOU NEED FROM NETWORK TEAM:
# ---------------------------------
# Before using this file, ask your Network Team for these values:
# 1. VPC ID (e.g., vpc-0abc123def456789)
# 2. Subnet IDs (both public and private)
# 3. Availability Zones for each subnet
# 4. CIDR blocks for VPC and subnets
# 5. Internet Gateway ID (if using public subnets)
# 6. NAT Gateway IDs (if using private subnets)
# 7. Route Table IDs (optional, for validation)
#
# HOW TO USE:
# -----------
# 1. Copy this file to your project
# 2. Update variables.tf with the values from Network Team
# 3. Run: terraform plan
# 4. Verify outputs match what Network Team provided
#
# ============================================================================

# ----------------------------------------------------------------------------
# DATA SOURCES - FETCH EXISTING VPC RESOURCES
# ----------------------------------------------------------------------------
# WHAT: Data sources let you reference existing AWS resources
# WHY: You don't create them, you just "look them up" and use them
# COST: FREE (you're just reading existing resources)

# ----------------------------------------------------------------------------
# EXISTING VPC
# ----------------------------------------------------------------------------
# WHAT: The VPC that Network Team already created
# INFO NEEDED: VPC ID from Network Team

data "aws_vpc" "existing" {
  # Option 1: Use VPC ID directly (most common)
  id = var.existing_vpc_id

  # Option 2: Find VPC by tags (if you don't have ID)
  # tags = {
  #   Name = "production-vpc"
  # }

  # Option 3: Find VPC by CIDR block
  # cidr_block = "10.0.0.0/16"
}

# ----------------------------------------------------------------------------
# EXISTING PUBLIC SUBNETS
# ----------------------------------------------------------------------------
# WHAT: Subnets with internet access (for Load Balancers, NAT Gateways)
# INFO NEEDED: Subnet IDs from Network Team

data "aws_subnet" "public_a" {
  # Use subnet ID from Network Team
  id = var.existing_public_subnet_a_id

  # Alternative: Find by tags
  # filter {
  #   name   = "tag:Name"
  #   values = ["production-public-a"]
  # }
}

data "aws_subnet" "public_b" {
  id = var.existing_public_subnet_b_id
}

# ----------------------------------------------------------------------------
# EXISTING PRIVATE SUBNETS
# ----------------------------------------------------------------------------
# WHAT: Subnets WITHOUT direct internet access (for Lambda, EC2, Databases)
# INFO NEEDED: Subnet IDs from Network Team

data "aws_subnet" "private_a" {
  id = var.existing_private_subnet_a_id
}

data "aws_subnet" "private_b" {
  id = var.existing_private_subnet_b_id
}

# ----------------------------------------------------------------------------
# EXISTING INTERNET GATEWAY (OPTIONAL)
# ----------------------------------------------------------------------------
# WHAT: Gateway that allows public subnets to access internet
# INFO NEEDED: Internet Gateway ID from Network Team
# WHEN: Only if you need to validate or reference the IGW

data "aws_internet_gateway" "existing" {
  count = var.existing_internet_gateway_id != "" ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]
  }

  # Alternative: Use ID directly
  # internet_gateway_id = var.existing_internet_gateway_id
}

# ----------------------------------------------------------------------------
# EXISTING NAT GATEWAYS (OPTIONAL)
# ----------------------------------------------------------------------------
# WHAT: Allows private subnets to download updates (outbound internet only)
# INFO NEEDED: NAT Gateway IDs from Network Team (if private subnets need internet)
# WHEN: Only if your resources in private subnet need to download packages

data "aws_nat_gateway" "nat_a" {
  count = var.existing_nat_gateway_a_id != "" ? 1 : 0

  id = var.existing_nat_gateway_a_id

  # Alternative: Find by subnet
  # subnet_id = data.aws_subnet.public_a.id
}

data "aws_nat_gateway" "nat_b" {
  count = var.existing_nat_gateway_b_id != "" ? 1 : 0

  id = var.existing_nat_gateway_b_id
}

# ----------------------------------------------------------------------------
# EXISTING ROUTE TABLES (OPTIONAL)
# ----------------------------------------------------------------------------
# WHAT: Rules that define where network traffic goes
# INFO NEEDED: Route Table IDs from Network Team
# WHEN: Only if you need to add custom routes or validate routing

data "aws_route_table" "public" {
  count = var.existing_public_route_table_id != "" ? 1 : 0

  route_table_id = var.existing_public_route_table_id

  # Alternative: Find by subnet association
  # subnet_id = data.aws_subnet.public_a.id
}

data "aws_route_table" "private_a" {
  count = var.existing_private_route_table_a_id != "" ? 1 : 0

  route_table_id = var.existing_private_route_table_a_id
}

data "aws_route_table" "private_b" {
  count = var.existing_private_route_table_b_id != "" ? 1 : 0

  route_table_id = var.existing_private_route_table_b_id
}

# ----------------------------------------------------------------------------
# OUTPUTS - SAME AS vpc_create.tf
# ----------------------------------------------------------------------------
# WHAT: Values that other Terraform modules can use
# WHY: Same output structure whether you create or use existing VPC
# BENEFIT: Your Lambda/EC2 code doesn't need to change!

output "vpc_id" {
  description = "ID of the existing VPC"
  value       = data.aws_vpc.existing.id
}

output "vpc_cidr" {
  description = "CIDR block of the existing VPC"
  value       = data.aws_vpc.existing.cidr_block
}

output "public_subnet_ids" {
  description = "List of existing public subnet IDs"
  value       = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of existing private subnet IDs"
  value       = [data.aws_subnet.private_a.id, data.aws_subnet.private_b.id]
}

output "public_subnet_a_id" {
  description = "ID of existing public subnet in AZ A"
  value       = data.aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of existing public subnet in AZ B"
  value       = data.aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "ID of existing private subnet in AZ A"
  value       = data.aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID of existing private subnet in AZ B"
  value       = data.aws_subnet.private_b.id
}

output "internet_gateway_id" {
  description = "ID of the existing Internet Gateway"
  value       = var.existing_internet_gateway_id != "" ? data.aws_internet_gateway.existing[0].id : null
}

output "nat_gateway_a_id" {
  description = "ID of existing NAT Gateway in AZ A"
  value       = var.existing_nat_gateway_a_id != "" ? data.aws_nat_gateway.nat_a[0].id : null
}

output "nat_gateway_b_id" {
  description = "ID of existing NAT Gateway in AZ B"
  value       = var.existing_nat_gateway_b_id != "" ? data.aws_nat_gateway.nat_b[0].id : null
}

output "nat_gateway_a_public_ip" {
  description = "Public IP of existing NAT Gateway in AZ A"
  value       = var.existing_nat_gateway_a_id != "" ? data.aws_nat_gateway.nat_a[0].public_ip : null
}

output "nat_gateway_b_public_ip" {
  description = "Public IP of existing NAT Gateway in AZ B"
  value       = var.existing_nat_gateway_b_id != "" ? data.aws_nat_gateway.nat_b[0].public_ip : null
}

output "availability_zones" {
  description = "Availability zones for the existing subnets"
  value       = [data.aws_subnet.public_a.availability_zone, data.aws_subnet.public_b.availability_zone]
}

# ----------------------------------------------------------------------------
# VALIDATION OUTPUTS (HELPFUL FOR DEBUGGING)
# ----------------------------------------------------------------------------
# WHAT: Extra information to verify everything is correct
# WHY: Easy to spot misconfigurations

output "validation_info" {
  description = "Validation information for existing VPC setup"
  value = {
    vpc_cidr                    = data.aws_vpc.existing.cidr_block
    vpc_dns_support_enabled     = data.aws_vpc.existing.enable_dns_support
    vpc_dns_hostnames_enabled   = data.aws_vpc.existing.enable_dns_hostnames
    public_subnet_a_cidr        = data.aws_subnet.public_a.cidr_block
    public_subnet_b_cidr        = data.aws_subnet.public_b.cidr_block
    private_subnet_a_cidr       = data.aws_subnet.private_a.cidr_block
    private_subnet_b_cidr       = data.aws_subnet.private_b.cidr_block
    public_subnet_a_az          = data.aws_subnet.public_a.availability_zone
    public_subnet_b_az          = data.aws_subnet.public_b.availability_zone
    private_subnet_a_az         = data.aws_subnet.private_a.availability_zone
    private_subnet_b_az         = data.aws_subnet.private_b.availability_zone
    internet_gateway_exists     = var.existing_internet_gateway_id != ""
    nat_gateway_a_exists        = var.existing_nat_gateway_a_id != ""
    nat_gateway_b_exists        = var.existing_nat_gateway_b_id != ""
  }
}

# ----------------------------------------------------------------------------
# VARIABLES NEEDED (Add these to variables.tf)
# ----------------------------------------------------------------------------
# Copy these to your variables.tf file:
/*

# ========================================
# EXISTING VPC VARIABLES
# ========================================
# Use these when Network Team provides VPC

variable "existing_vpc_id" {
  description = "ID of existing VPC (e.g., vpc-0abc123def456789)"
  type        = string
  default     = ""
}

variable "existing_public_subnet_a_id" {
  description = "ID of existing public subnet in AZ A"
  type        = string
  default     = ""
}

variable "existing_public_subnet_b_id" {
  description = "ID of existing public subnet in AZ B"
  type        = string
  default     = ""
}

variable "existing_private_subnet_a_id" {
  description = "ID of existing private subnet in AZ A"
  type        = string
  default     = ""
}

variable "existing_private_subnet_b_id" {
  description = "ID of existing private subnet in AZ B"
  type        = string
  default     = ""
}

variable "existing_internet_gateway_id" {
  description = "ID of existing Internet Gateway (optional)"
  type        = string
  default     = ""
}

variable "existing_nat_gateway_a_id" {
  description = "ID of existing NAT Gateway in AZ A (optional)"
  type        = string
  default     = ""
}

variable "existing_nat_gateway_b_id" {
  description = "ID of existing NAT Gateway in AZ B (optional)"
  type        = string
  default     = ""
}

variable "existing_public_route_table_id" {
  description = "ID of existing public route table (optional)"
  type        = string
  default     = ""
}

variable "existing_private_route_table_a_id" {
  description = "ID of existing private route table A (optional)"
  type        = string
  default     = ""
}

variable "existing_private_route_table_b_id" {
  description = "ID of existing private route table B (optional)"
  type        = string
  default     = ""
}

*/
