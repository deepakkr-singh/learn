# VPC (Virtual Private Cloud) - Your Private Network in AWS

## 🎯 What is VPC?

**Simple Explanation:**
Think of VPC as your own private neighborhood in AWS. Just like your home has:
- **Walls** (VPC boundary - isolates your network)
- **Rooms** (Subnets - different sections for different purposes)
- **Doors with locks** (Security Groups - control who can enter)
- **Address** (IP addresses - identify each resource)

**Technical Definition:**
A VPC is a logically isolated virtual network in AWS where you launch your resources (EC2, Lambda, RDS, etc.). It provides complete control over your networking environment.

## 🤔 Why Do I Need VPC?

### Without VPC (Old Way - Before 2009):
- All AWS resources shared the same network
- No isolation between customers
- No control over IP ranges
- Security nightmare!

### With VPC (Modern Way):
✅ **Isolation**: Your network is separate from other AWS customers
✅ **Control**: Choose your own IP range (e.g., 10.0.0.0/16)
✅ **Security**: Define firewall rules, subnets, routing
✅ **Compliance**: Meet regulatory requirements (HIPAA, PCI-DSS)
✅ **Hybrid Cloud**: Connect to your on-premises data center

## 📊 Real-World Example

### Scenario: Building a Web Application

```
Your Application Needs:
1. Web servers (need internet access to serve users)
2. Database servers (should NOT have direct internet access - security!)
3. Admin panel (only accessible from your office IP)

VPC Solution:
┌──────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────┐    ┌─────────────────────┐    │
│  │  Public Subnet      │    │  Private Subnet     │    │
│  │  (10.0.1.0/24)      │    │  (10.0.2.0/24)      │    │
│  │                     │    │                     │    │
│  │  - Load Balancer    │    │  - Web Servers      │    │
│  │  - NAT Gateway      │    │  - App Servers      │    │
│  │  - Bastion Host     │    │  - Databases        │    │
│  │                     │    │  - Lambda Functions │    │
│  │  ✓ Internet access  │    │  ✗ No internet      │    │
│  └─────────────────────┘    └─────────────────────┘    │
│                                                          │
│  Internet Gateway (IGW): Allows public subnet to talk   │
│  to internet                                             │
│                                                          │
│  NAT Gateway: Allows private subnet to download updates │
│  (outbound only, no inbound)                             │
└──────────────────────────────────────────────────────────┘
```

## 🏗️ VPC Components Explained

### 1. **CIDR Block (IP Range)**

**What**: The range of IP addresses for your VPC

**Example**: `10.0.0.0/16` means:
- **10.0.0.0** is the base IP
- **/16** means you have 65,536 IP addresses (2^16)
- Range: 10.0.0.0 to 10.0.255.255

**Common CIDR Blocks:**
- `/16` = 65,536 IPs (recommended for production)
- `/24` = 256 IPs (good for dev/test)
- `/20` = 4,096 IPs (medium-sized apps)

**Why it matters:**
- Too small (/28 = 16 IPs): Run out of IPs quickly
- Too large (/8 = 16M IPs): Waste, conflicts with other networks

### 2. **Subnets**

**What**: Subdivisions of your VPC

**Types:**

**Public Subnet:**
- Has route to Internet Gateway
- Resources can be accessed from internet
- **Use for**: Load Balancers, Bastion hosts

**Private Subnet:**
- NO direct route to internet
- Resources hidden from internet
- **Use for**: Application servers, Databases, Lambda

**Why Multiple Subnets?**
✅ Security (isolate public-facing from internal)
✅ High Availability (spread across availability zones)
✅ Compliance (separate production from development)

### 3. **Availability Zones (AZ)**

**What**: Physically separate data centers within a region

**Example**:
```
Region: us-east-1 (N. Virginia)
  ├── AZ: us-east-1a (Data Center A)
  ├── AZ: us-east-1b (Data Center B)
  └── AZ: us-east-1c (Data Center C)
```

**Best Practice**: Always use at least 2 AZs

**Why?**
If one data center catches fire/floods/power outage, your app continues running in the other!

### 4. **Internet Gateway (IGW)**

**What**: Gateway that allows your VPC to talk to the internet

**Simple Example:**
```
Without IGW: Your house (VPC) has no door - you're trapped inside!
With IGW: Your house has a door - you can go outside and receive visitors.
```

**One IGW per VPC** (you can't have multiple front doors)

### 5. **NAT Gateway**

**What**: Allows private subnets to access internet (outbound only)

**Real-World Example:**
```
Problem: Your database (in private subnet) needs to download security updates.
But: You don't want the database exposed to internet!

Solution: NAT Gateway
- Database sends request → NAT Gateway → Internet
- Downloads updates
- No one from internet can initiate connection to database
```

**Why Not Use Internet Gateway?**
Internet Gateway = Two-way door (anyone can come in)
NAT Gateway = One-way door (you can go out, but no one can come in)

### 6. **Route Tables**

**What**: Rules that determine where network traffic goes

**Example:**

**Public Subnet Route Table:**
```
Destination         Target
10.0.0.0/16        local (stay within VPC)
0.0.0.0/0          igw-xxx (everything else goes to internet)
```

**Private Subnet Route Table:**
```
Destination         Target
10.0.0.0/16        local (stay within VPC)
0.0.0.0/0          nat-xxx (everything else goes through NAT)
```

### 7. **Security Groups**

**What**: Virtual firewall for your resources

**Example:**
```
Web Server Security Group:
  Inbound Rules:
    - Port 443 (HTTPS) from 0.0.0.0/0 (anyone can visit website)
    - Port 22 (SSH) from 1.2.3.4/32 (only my office can SSH)

  Outbound Rules:
    - All traffic to 0.0.0.0/0 (can make any outbound connection)
```

## 🎨 Architecture Patterns

### Pattern 1: Simple 2-Tier (Web + Database)

```
VPC: 10.0.0.0/16
├── Public Subnet A (us-east-1a): 10.0.1.0/24
│   └── Load Balancer
├── Public Subnet B (us-east-1b): 10.0.2.0/24
│   └── Load Balancer
├── Private Subnet A (us-east-1a): 10.0.11.0/24
│   └── Web Server + Database
└── Private Subnet B (us-east-1b): 10.0.12.0/24
    └── Web Server + Database
```

**Cost**: ~$32/month (2 NAT Gateways)

### Pattern 2: 3-Tier (Web + App + Database)

```
VPC: 10.0.0.0/16
├── Public Subnet (us-east-1a): 10.0.1.0/24
│   └── Load Balancer
├── Private Subnet - Web Tier (us-east-1a): 10.0.11.0/24
│   └── Web Servers
├── Private Subnet - App Tier (us-east-1a): 10.0.21.0/24
│   └── Application Servers
└── Private Subnet - Data Tier (us-east-1a): 10.0.31.0/24
    └── Databases
```

**Why?**
- Better security (each tier isolated)
- Easier to scale (scale web tier independently of database)

### Pattern 3: Multi-Region (Disaster Recovery)

```
Primary Region (us-east-1):
VPC: 10.0.0.0/16
├── Public: 10.0.1.0/24
└── Private: 10.0.11.0/24

Backup Region (us-west-2):
VPC: 10.1.0.0/16
├── Public: 10.1.1.0/24
└── Private: 10.1.11.0/24

VPC Peering: Both VPCs can talk to each other
```

## 🔒 Security Best Practices

### ✅ DO:
1. **Use Private Subnets for Everything Except Load Balancers**
   - Lambda → Private
   - EC2 → Private
   - Database → Private
   - Only ALB → Public

2. **Enable VPC Flow Logs**
   - See all network traffic
   - Debug connectivity issues
   - Detect security threats

3. **Use Network ACLs for Extra Security**
   - Subnet-level firewall
   - Blocks traffic before it reaches resources

4. **Enable DNS Hostnames**
   - Easier to remember "db.example.internal" than "10.0.31.5"

### ❌ DON'T:
1. **DON'T Put Everything in Public Subnet**
   - Risk: Direct internet exposure
   - Hackers can scan and attack

2. **DON'T Use /28 CIDR for Production**
   - Only 16 IPs - you'll run out fast!

3. **DON'T Forget to Use Multiple AZs**
   - Single AZ = Single point of failure

## 📝 Terraform Implementation

### Complete VPC with Best Practices

See [`main.tf`](./main.tf) for full implementation.

**What It Creates:**
- ✅ VPC with /16 CIDR
- ✅ 2 Public Subnets (2 AZs)
- ✅ 2 Private Subnets (2 AZs)
- ✅ Internet Gateway
- ✅ 2 NAT Gateways (high availability)
- ✅ Route Tables
- ✅ VPC Flow Logs
- ✅ DNS Enabled
- ✅ All with proper tags

## 🚀 How to Use

### 1. Create VPC

```bash
cd modules/vpc
terraform init
terraform plan
terraform apply
```

### 2. Get VPC ID for Other Services

```bash
terraform output vpc_id
# Output: vpc-0abc123def456789
```

### 3. Use in Lambda/EC2/etc

```hcl
# In your lambda/ec2 module
resource "aws_lambda_function" "my_function" {
  # ... other config ...

  vpc_config {
    subnet_ids         = [var.private_subnet_ids]  # From VPC module
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

## 💰 Cost Breakdown

| Component | Cost | Why? |
|-----------|------|------|
| VPC | $0 | Free! |
| Subnets | $0 | Free! |
| Internet Gateway | $0 | Free! |
| NAT Gateway | $32/month | $0.045/hour per NAT |
| VPC Flow Logs | ~$0.50/month | $0.50 per GB |
| **Total** | **~$33/month** | For HA setup (2 NAT Gateways) |

**Cost Optimization:**
- Dev environment: 1 NAT Gateway = $16/month (no HA)
- Production: 2 NAT Gateways = $32/month (HA)

## 🤔 Common Questions

### Q1: Do I need multiple VPCs?

**Answer**: Usually one VPC per environment

```
Production:    VPC (10.0.0.0/16)
Staging:       VPC (10.1.0.0/16)
Development:   VPC (10.2.0.0/16)
```

**Why?**
- Complete isolation
- Different security rules
- No accidental production changes

### Q2: How many NAT Gateways do I need?

**Answer**:
- **Production**: 2+ (one per AZ for high availability)
- **Dev/Test**: 1 (save money, HA not critical)

**Example:**
```
If NAT Gateway in AZ-A fails:
- With 1 NAT: All private subnets lose internet ❌
- With 2 NATs: Private subnets in AZ-B still work ✅
```

### Q3: Public vs Private - Which subnet for what?

**Public Subnet (Internet-facing):**
- ✅ Application Load Balancer
- ✅ Network Load Balancer
- ✅ NAT Gateway
- ✅ Bastion Host (jump server)
- ❌ Nothing else!

**Private Subnet (Hidden from internet):**
- ✅ Lambda Functions
- ✅ EC2 Instances (web/app servers)
- ✅ Fargate Tasks
- ✅ RDS Databases
- ✅ ElastiCache
- ✅ Everything else!

### Q4: Can I change VPC CIDR after creation?

**Answer**: Yes, but limited

You can ADD a secondary CIDR block:
```
Primary: 10.0.0.0/16
Add:     10.1.0.0/16
```

But you CANNOT change the primary CIDR.

### Q5: What if I run out of IP addresses?

**Solutions:**
1. **Add secondary CIDR block** (best)
2. **Use smaller subnets** (free up IPs)
3. **Create new VPC** (migration required)

## 🔗 How VPC Connects to Other Services

### VPC → Lambda
```hcl
resource "aws_lambda_function" "app" {
  vpc_config {
    subnet_ids         = [module.vpc.private_subnet_ids]
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

### VPC → RDS Database
```hcl
resource "aws_db_subnet_group" "db" {
  subnet_ids = module.vpc.private_subnet_ids
}

resource "aws_db_instance" "db" {
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}
```

### VPC → EC2
```hcl
resource "aws_instance" "web" {
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

## 🎯 Best Practice: One KMS Key or Multiple?

### For VPC-Related Encryption:

**Single KMS Key Approach** ✅ (Recommended for VPC)
```
Why? VPC components don't directly encrypt data.
- VPC Flow Logs → Use CloudWatch Logs KMS key
- VPN Connection → Use VPN-specific KMS key
```

**When You Need Multiple KMS Keys:**
```
NOT for VPC components, but for:
- S3 Bucket → KMS Key 1
- DynamoDB → KMS Key 2
- Secrets Manager → KMS Key 3
```

**Reasoning:**
- VPC is networking (doesn't store data)
- KMS keys are for data encryption
- Each data service should have its own KMS key (security isolation)

## 📚 Next Steps

1. ✅ Create VPC (you are here)
2. → [Create Security Groups](../security-group/README.md)
3. → [Create Lambda in VPC](../lambda/README.md)
4. → [Create RDS in VPC](../rds/README.md)

## 🆘 Troubleshooting

### Issue 1: "No internet access from private subnet"

**Symptom**: Lambda/EC2 in private subnet can't download packages

**Solution**: Check NAT Gateway
```bash
# Verify NAT Gateway exists
aws ec2 describe-nat-gateways --region us-east-1

# Check route table points to NAT
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxx"
```

### Issue 2: "Resources can't talk to each other"

**Symptom**: Lambda can't connect to RDS

**Solution**: Check Security Groups
```hcl
# Lambda Security Group: Allow outbound to RDS port
egress {
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
}

# RDS Security Group: Allow inbound from Lambda
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  security_groups = [aws_security_group.lambda.id]
}
```

### Issue 3: "Running out of IP addresses"

**Solution**: Add secondary CIDR
```hcl
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.0.0/16"
}
```

---

---

## 🚀 QUICK START GUIDE

### Which File Do I Use?

**Simple Answer:**

```
Creating NEW VPC?           → Use: vpc_create.tf
Using EXISTING VPC?         → Use: vpc_use_existing.tf
```

### Scenario 1: Create New VPC (5 minutes)

```bash
# 1. Copy the create file
cp vpc_create.tf main.tf

# 2. Run Terraform
terraform init
terraform plan
terraform apply

# Done! Your VPC is ready.
```

**Cost**: ~$32/month (NAT Gateways)

---

### Scenario 2: Use Existing VPC (30 minutes)

```bash
# 1. Get information from Network Team (use questionnaire below)

# 2. Copy the use existing file
cp vpc_use_existing.tf main.tf

# 3. Copy variables template
cp variables_existing.tf.example variables.tf

# 4. Create terraform.tfvars with Network Team values
cat > terraform.tfvars <<EOF
existing_vpc_id              = "vpc-0abc123def456789"
existing_public_subnet_a_id  = "subnet-111111111"
existing_public_subnet_b_id  = "subnet-222222222"
existing_private_subnet_a_id = "subnet-333333333"
existing_private_subnet_b_id = "subnet-444444444"
EOF

# 5. Verify
terraform init
terraform plan
terraform output validation_info

# 6. Confirm with Network Team, then apply
terraform apply
```

**Cost**: $0 (Network Team pays)

---

## 🔄 CREATE vs USE EXISTING VPC

### Decision Tree: Which File Should I Use?

```
Do you need to create a new VPC?
│
├─ YES → I need to create everything from scratch
│         └─ Use: vpc_create.tf
│            ✓ Creates VPC, subnets, NAT gateways, route tables
│            ✓ Full control over configuration
│            ✓ Best for: New projects, dev environments
│
└─ NO → Network Team already created VPC for me
          └─ Use: vpc_use_existing.tf
             ✓ References existing VPC resources
             ✓ No new infrastructure created
             ✓ Best for: Enterprise environments, production
```

---

## 📋 QUESTIONNAIRE: Using Existing VPC (Network Team Setup)

### Before You Start

If your Network Team has already created the VPC, you need to gather specific information from them. Use this questionnaire as a checklist.

### ✅ Required Information (MUST HAVE)

Ask your Network Team for these values:

#### 1. VPC Information
```
Question: What is the VPC ID?
Answer: vpc-_________________ (e.g., vpc-0abc123def456789)

Question: What is the VPC CIDR block?
Answer: ___.___.___.___ / ___ (e.g., 10.0.0.0/16)
```

#### 2. Public Subnets (For Load Balancers, NAT Gateways)
```
Question: Do we have public subnets?
Answer: □ Yes  □ No

If YES, provide:

Public Subnet A:
  Subnet ID: subnet-_________________
  CIDR Block: ___.___.___.___ / ___
  Availability Zone: ___________ (e.g., us-east-1a)

Public Subnet B:
  Subnet ID: subnet-_________________
  CIDR Block: ___.___.___.___ / ___
  Availability Zone: ___________ (e.g., us-east-1b)
```

#### 3. Private Subnets (For Lambda, EC2, Databases)
```
Question: Do we have private subnets?
Answer: □ Yes  □ No

If YES, provide:

Private Subnet A:
  Subnet ID: subnet-_________________
  CIDR Block: ___.___.___.___ / ___
  Availability Zone: ___________ (e.g., us-east-1a)

Private Subnet B:
  Subnet ID: subnet-_________________
  CIDR Block: ___.___.___.___ / ___
  Availability Zone: ___________ (e.g., us-east-1b)
```

---

### 🔍 Optional Information (MAY NEED)

#### 4. Internet Gateway (If using public subnets)
```
Question: Do public subnets have internet access?
Answer: □ Yes  □ No

If YES, provide:
  Internet Gateway ID: igw-_________________
```

**When you need this:**
- ✅ If you're deploying public-facing Load Balancers
- ✅ If you need to verify internet connectivity
- ❌ Not needed if you're only using private subnets

---

#### 5. NAT Gateways (If private subnets need internet)
```
Question: Do private subnets have outbound internet access?
Answer: □ Yes  □ No

If YES, provide:

NAT Gateway A:
  NAT Gateway ID: nat-_________________
  Public IP: ___.___.___.___
  Location: Public Subnet A

NAT Gateway B (if High Availability):
  NAT Gateway ID: nat-_________________
  Public IP: ___.___.___.___
  Location: Public Subnet B
```

**When you need this:**
- ✅ If Lambda needs to download packages (npm install, pip install)
- ✅ If EC2 needs to download OS updates
- ✅ If you need to call external APIs from private subnet
- ❌ Not needed if resources are completely isolated

**Important Questions to Ask:**
```
1. Is there a NAT Gateway in EACH Availability Zone?
   □ Yes (High Availability - recommended for production)
   □ No (Single NAT - cheaper, but single point of failure)

2. What is the NAT Gateway public IP?
   Why? You may need to whitelist this IP with external APIs
```

---

#### 6. Route Tables (Advanced - Usually not needed)
```
Question: Do you need to validate routing?
Answer: □ Yes  □ No

If YES, provide:

Public Route Table:
  Route Table ID: rtb-_________________
  Routes:
    - Local (VPC CIDR) → local
    - Internet (0.0.0.0/0) → Internet Gateway

Private Route Table A:
  Route Table ID: rtb-_________________
  Routes:
    - Local (VPC CIDR) → local
    - Internet (0.0.0.0/0) → NAT Gateway A

Private Route Table B:
  Route Table ID: rtb-_________________
  Routes:
    - Local (VPC CIDR) → local
    - Internet (0.0.0.0/0) → NAT Gateway B
```

**When you need this:**
- ✅ If you need to add custom routes (VPN, VPC peering)
- ✅ If troubleshooting connectivity issues
- ❌ Not needed for basic usage

---

### 🤔 Common Questions & Answers

#### Q1: Do I need Elastic IPs if using existing VPC?

**Answer**: No

**Why?**
- Elastic IPs are attached to NAT Gateways
- Network Team already created NAT Gateways with Elastic IPs
- You just need the NAT Gateway IDs (not the Elastic IPs directly)

**What you DO need:**
- NAT Gateway IDs (e.g., nat-0abc123)
- NAT Gateway Public IPs (for whitelisting external APIs)

---

#### Q2: Do I need to know about Route Tables?

**Answer**: Usually no, but helpful for troubleshooting

**When you DON'T need Route Table IDs:**
- ✅ You're just deploying Lambda/EC2 in existing subnets
- ✅ Everything works fine (no connectivity issues)

**When you DO need Route Table IDs:**
- ❌ Debugging: "Why can't my Lambda access the internet?"
- ❌ Custom routing: Adding VPN routes, VPC peering
- ❌ Validation: Verifying routes are correct

**Pro Tip**: If you have connectivity issues, ask Network Team:
```
"Can you check if the route table for subnet-xxxxx has a route to the NAT Gateway?"
```

---

#### Q3: What if Network Team only gives me VPC ID?

**Answer**: You can find subnet IDs yourself using AWS CLI

```bash
# Find all subnets in the VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"

# Find public subnets (has route to Internet Gateway)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx" | grep -A 10 igw-

# Find private subnets (has route to NAT Gateway)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx" | grep -A 10 nat-
```

**But it's better to ask Network Team**:
- They know which subnet is for what (public vs private)
- They can tell you the naming convention
- They can provide documentation

---

#### Q4: How do I verify the information is correct?

**Answer**: Run `terraform plan` and check the validation output

After filling in the values, run:
```bash
terraform plan
```

Look for the `validation_info` output:
```
validation_info = {
  vpc_cidr                    = "10.0.0.0/16"         ← Should match Network Team's info
  public_subnet_a_cidr        = "10.0.1.0/24"         ← Should match Network Team's info
  private_subnet_a_cidr       = "10.0.11.0/24"        ← Should match Network Team's info
  nat_gateway_a_exists        = true                  ← Should be true if Network Team said yes
}
```

If any values don't match, contact Network Team!

---

#### Q5: What if I'm missing some optional information?

**Answer**: Start with required info, add optional later if needed

**Phase 1: Start with basics**
```hcl
# terraform.tfvars
existing_vpc_id              = "vpc-0abc123"
existing_public_subnet_a_id  = "subnet-111"
existing_public_subnet_b_id  = "subnet-222"
existing_private_subnet_a_id = "subnet-333"
existing_private_subnet_b_id = "subnet-444"
```

**Phase 2: Add NAT Gateway info (if needed)**
```hcl
# Only add if you get connectivity errors
existing_nat_gateway_a_id = "nat-0abc123"
existing_nat_gateway_b_id = "nat-0def456"
```

**Phase 3: Add route tables (rarely needed)**
```hcl
# Only if Network Team asks or for troubleshooting
existing_public_route_table_id = "rtb-0abc123"
```

---

### 📝 Email Template: Request VPC Information

Use this template to request information from your Network Team:

```
Subject: VPC Information Request for [Project Name]

Hi [Network Team],

We are setting up infrastructure for [project name] and need the VPC information.

REQUIRED INFORMATION:
---------------------
1. VPC ID:
2. VPC CIDR Block:
3. Public Subnet A (ID, CIDR, AZ):
4. Public Subnet B (ID, CIDR, AZ):
5. Private Subnet A (ID, CIDR, AZ):
6. Private Subnet B (ID, CIDR, AZ):

OPTIONAL (if available):
------------------------
7. Internet Gateway ID:
8. NAT Gateway IDs (one per AZ):
9. NAT Gateway Public IPs:

ADDITIONAL QUESTIONS:
---------------------
- Do private subnets have outbound internet access? (Yes/No)
- Is there a NAT Gateway in each Availability Zone? (Yes/No)
- Are there any specific firewall rules or security groups we should know about?

We will use this information to deploy [Lambda/EC2/RDS/etc.] in your VPC.

Thanks!
[Your Name]
```

---

### 🛠️ Step-by-Step: Using Existing VPC

#### Step 1: Get Information from Network Team
Use the questionnaire above to collect all required values.

#### Step 2: Create terraform.tfvars
```hcl
# File: terraform.tfvars

# REQUIRED
existing_vpc_id              = "vpc-0abc123def456789"
existing_public_subnet_a_id  = "subnet-111111"
existing_public_subnet_b_id  = "subnet-222222"
existing_private_subnet_a_id = "subnet-333333"
existing_private_subnet_b_id = "subnet-444444"

# OPTIONAL (add if needed)
existing_internet_gateway_id = "igw-0abc123"
existing_nat_gateway_a_id    = "nat-0abc123"
existing_nat_gateway_b_id    = "nat-0def456"
```

#### Step 3: Use vpc_use_existing.tf
```bash
cd modules/vpc

# Copy the use existing file
cp vpc_use_existing.tf main.tf

# Initialize Terraform
terraform init

# Preview (verify all IDs are correct)
terraform plan

# Check validation output
terraform output validation_info
```

#### Step 4: Verify with Network Team
```bash
# Get the validation output
terraform output validation_info

# Send to Network Team for confirmation:
# "Can you verify these values are correct?"
```

#### Step 5: Use in Your Lambda/EC2 Modules
```hcl
# In your lambda module
module "vpc" {
  source = "./modules/vpc"
}

resource "aws_lambda_function" "my_function" {
  vpc_config {
    subnet_ids = module.vpc.private_subnet_ids  # Same whether create or use existing!
  }
}
```

---

### ⚠️ Common Mistakes to Avoid

#### ❌ Mistake 1: Using Public Subnet for Lambda
```hcl
# WRONG
vpc_config {
  subnet_ids = module.vpc.public_subnet_ids  # Don't do this!
}
```

**Why wrong?** Lambda in public subnet can't access internet (needs NAT Gateway in private subnet)

**Fix:**
```hcl
# CORRECT
vpc_config {
  subnet_ids = module.vpc.private_subnet_ids  # Always use private subnets
}
```

---

#### ❌ Mistake 2: Mixing AZs (Non-matching subnets)
```hcl
# WRONG - Different AZs!
existing_public_subnet_a_id  = "subnet-111"  # us-east-1a
existing_private_subnet_a_id = "subnet-222"  # us-east-1b  ← Wrong AZ!
```

**Why wrong?** Resources in same AZ should be grouped together

**Fix:**
```hcl
# CORRECT
existing_public_subnet_a_id  = "subnet-111"  # us-east-1a
existing_private_subnet_a_id = "subnet-333"  # us-east-1a  ← Same AZ
```

---

#### ❌ Mistake 3: Not Verifying CIDR Blocks
```hcl
# You provide: subnet-111 (10.0.1.0/24)
# Network Team meant: subnet-222 (10.0.1.0/24)
# Result: Wrong subnet, connectivity issues!
```

**Fix:** Always verify with `terraform output validation_info`

---

### 📊 Comparison: Create vs Use Existing

| Feature | vpc_create.tf | vpc_use_existing.tf |
|---------|--------------|---------------------|
| **Creates new VPC** | ✅ Yes | ❌ No |
| **Uses existing VPC** | ❌ No | ✅ Yes |
| **Control over config** | Full control | Limited (use what exists) |
| **Network Team approval** | May need approval | Already approved |
| **Cost** | You pay for NAT ($32/mo) | Network Team pays |
| **Terraform state** | Manages everything | Only references |
| **terraform destroy** | Deletes VPC | Does nothing (VPC stays) |
| **Best for** | Dev, new projects | Enterprise, production |
| **Setup time** | 5 minutes | 30 minutes (gathering info) |
| **Troubleshooting** | Easy (you control it) | Need Network Team help |

---

### 🎯 Which One Should You Use?

#### Use `vpc_create.tf` if:
- ✅ You're starting a new project
- ✅ It's a dev/test environment
- ✅ You have AWS permissions to create VPCs
- ✅ You want full control
- ✅ No Network Team restrictions

#### Use `vpc_use_existing.tf` if:
- ✅ Company has centralized Network Team
- ✅ Production environment (already set up)
- ✅ VPC already exists (you don't have permission to create)
- ✅ Enterprise company with strict network policies
- ✅ Need to share VPC with other teams

---

**Next**: [See Complete Terraform Implementation →](./vpc_create.tf) or [Use Existing VPC →](./vpc_use_existing.tf)
