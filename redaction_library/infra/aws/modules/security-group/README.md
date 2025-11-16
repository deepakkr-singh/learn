# Security Groups - Your AWS Firewall

## 🎯 What is a Security Group?

**Simple Explanation:**
A Security Group is a virtual firewall that controls what traffic can come IN to your AWS resources and go OUT from them.

Think of it like a bouncer at a nightclub:
- **Ingress Rules** = Who can enter the club (incoming traffic)
- **Egress Rules** = Where people can go when they leave (outgoing traffic)
- **Stateful** = If someone comes in, they can automatically leave (no need for separate exit rule)

**Technical Definition:**
A security group acts as a virtual firewall for your AWS resources (EC2, Lambda, RDS, etc.) to control inbound and outbound traffic at the resource level.

---

## 🤔 Why Do I Need Security Groups?

### Without Security Groups:
- Anyone on the internet could access your database directly
- Attackers could scan and attack your servers
- No control over what your Lambda can access
- Major security vulnerability!

### With Security Groups:
✅ **Control Access**: Only allow specific sources to connect
✅ **Protect Databases**: Only app servers can connect, not the internet
✅ **Defense in Depth**: Multiple layers of security
✅ **Compliance**: Meet security requirements (HIPAA, SOC2, etc.)
✅ **Easy to Manage**: Change rules without touching resources

---

## 📊 Real-World Example

### Scenario: E-commerce Website

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
│                    (Customers)                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ PUBLIC SUBNET                                          │ │
│  │                                                         │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ ALB (Load Balancer)                              │  │ │
│  │  │ Security Group: alb-sg                           │  │ │
│  │  │                                                   │  │ │
│  │  │ INGRESS RULES:                                   │  │ │
│  │  │ ✓ Port 443 (HTTPS) from 0.0.0.0/0               │  │ │
│  │  │ ✓ Port 80 (HTTP) from 0.0.0.0/0                 │  │ │
│  │  │                                                   │  │ │
│  │  │ EGRESS RULES:                                    │  │ │
│  │  │ ✓ All traffic to anywhere (forward to backend)  │  │ │
│  │  └────────┬─────────────────────────────────────────┘  │ │
│  └───────────┼────────────────────────────────────────────┘ │
│              │                                               │
│  ┌───────────┼────────────────────────────────────────────┐ │
│  │ PRIVATE SUBNET                                         │ │
│  │      ┌────┴────────────────────────────────────────┐   │ │
│  │      │ Lambda (API)                                 │   │ │
│  │      │ Security Group: lambda-sg                    │   │ │
│  │      │                                               │   │ │
│  │      │ INGRESS RULES:                               │   │ │
│  │      │ ✗ NONE (Lambda triggered by events)         │   │ │
│  │      │                                               │   │ │
│  │      │ EGRESS RULES:                                │   │ │
│  │      │ ✓ All traffic (connect to DB, call APIs)    │   │ │
│  │      └────────┬─────────────────────────────────────┘   │ │
│  │               │                                          │ │
│  │      ┌────────┴─────────────────────────────────────┐   │ │
│  │      │ RDS Database                                  │   │ │
│  │      │ Security Group: rds-sg                        │   │ │
│  │      │                                                │   │ │
│  │      │ INGRESS RULES:                                │   │ │
│  │      │ ✓ Port 5432 from lambda-sg ONLY              │   │ │
│  │      │ ✗ NOT from internet (secure!)                │   │ │
│  │      │                                                │   │ │
│  │      │ EGRESS RULES:                                 │   │ │
│  │      │ ✓ All traffic (for extensions, replication)  │   │ │
│  │      └───────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Traffic Flow:**
1. Customer → ALB (allowed by alb-sg)
2. ALB → Lambda (allowed by lambda-sg egress and ALB egress)
3. Lambda → RDS (allowed by rds-sg: only from lambda-sg)
4. Internet → RDS (BLOCKED! No rule allowing it)

---

## 🔑 Key Concepts

### 1. Stateful vs Stateless

**Security Groups are STATEFUL:**
```
Example: Someone connects to your server on port 443

What happens:
1. Ingress rule allows connection IN on port 443
2. Response automatically allowed OUT (no egress rule needed)

Why? Security Group remembers the connection
```

**NACL (Network ACL) is STATELESS:**
```
Example: Same connection

What happens:
1. Inbound rule needed for port 443
2. Outbound rule ALSO needed for response
3. Must configure both directions

Why? NACL doesn't remember connections
```

**When to use:**
- **Security Groups**: 99% of the time (simpler, more common)
- **NACL**: Additional subnet-level protection (advanced)

---

### 2. Ingress vs Egress

**INGRESS (Inbound) Rules:**
- Who can connect TO your resource
- Example: Allow HTTPS from internet to ALB

```hcl
ingress {
  description = "Allow HTTPS from internet"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # From anywhere
}
```

**EGRESS (Outbound) Rules:**
- Where your resource can connect TO
- Example: Allow Lambda to connect to internet/databases

```hcl
egress {
  description = "Allow all outbound"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"  # All protocols
  cidr_blocks = ["0.0.0.0/0"]  # To anywhere
}
```

---

### 3. CIDR Blocks vs Security Groups

**CIDR Blocks (IP-based):**
```hcl
cidr_blocks = ["203.0.113.0/24"]  # Specific IP range
cidr_blocks = ["0.0.0.0/0"]       # Anywhere (use carefully!)
```

**Pros:**
- Simple to understand
- Good for external sources (your office IP)

**Cons:**
- IPs can change
- Hard to manage many IPs

---

**Security Groups (Reference-based):**
```hcl
security_groups = [aws_security_group.lambda.id]
```

**Pros:**
- More secure (resources, not IPs)
- IPs can change, rule doesn't break
- Easy to update

**Cons:**
- Only works within same VPC
- Can't reference internet sources

---

### 4. Default Behavior

**When you create a security group:**
```
Default INGRESS: DENY ALL (nothing can connect in)
Default EGRESS: ALLOW ALL (can connect to anywhere)
```

**Why?**
- Secure by default (closed unless you open it)
- Most resources need outbound (updates, APIs, databases)

---

## 🛠️ Common Security Group Patterns

### Pattern 1: ALB (Public Load Balancer)

**Use Case**: Public-facing application

```hcl
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (redirect to HTTPS)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to backend
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Why this works:**
- Public ALB needs to accept internet traffic (0.0.0.0/0)
- HTTP allowed for redirect to HTTPS
- Egress allows forwarding to backend servers

---

### Pattern 2: Lambda Function

**Use Case**: Serverless API processing

```hcl
resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Lambda outbound access"
  vpc_id      = var.vpc_id

  # NO INGRESS RULES!
  # Lambda triggered by events, doesn't accept connections

  # Allow outbound (databases, APIs, internet)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Why no ingress?**
- Lambda doesn't accept incoming connections
- Triggered by events (API Gateway, SQS, S3, etc.)
- Only needs outbound to call databases/APIs

---

### Pattern 3: RDS Database

**Use Case**: PostgreSQL database in private subnet

```hcl
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from application only"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL from Lambda ONLY
  ingress {
    description     = "PostgreSQL from Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]  # NOT 0.0.0.0/0!
  }

  # Allow outbound (for replication, extensions)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Why security_groups not cidr_blocks?**
- More secure (only Lambda can connect)
- Even if Lambda IP changes, rule still works
- Prevents accidental internet exposure

---

### Pattern 4: EC2 Web Server (Behind ALB)

**Use Case**: EC2 running web application

```hcl
resource "aws_security_group" "ec2_web" {
  name        = "ec2-web-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB ONLY
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow SSH from your office IP
  ingress {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Your office IP!
  }

  # Allow outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Security layers:**
1. ALB is public (accepts internet traffic)
2. EC2 is private (only accepts ALB traffic)
3. SSH only from your office (for debugging)

---

### Pattern 5: Bastion Host (Jump Server)

**Use Case**: SSH gateway to private resources

```hcl
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "SSH gateway"
  vpc_id      = var.vpc_id

  # Allow SSH from your office ONLY
  ingress {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # NEVER use 0.0.0.0/0!
  }

  # Allow SSH to VPC resources
  egress {
    description = "SSH to VPC resources"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # Only within VPC
  }

  # Allow HTTPS for updates
  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Critical security:**
- NEVER allow 0.0.0.0/0 for SSH inbound
- Bastion is gateway to private resources
- Compromise = entire infrastructure at risk

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Opening SSH to 0.0.0.0/0

```hcl
# WRONG - NEVER DO THIS!
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Anyone can try to SSH!
}
```

**Why wrong?**
- Allows anyone on internet to attempt SSH
- Attackers constantly scan for open SSH
- Prime target for brute force attacks

**Fix:**
```hcl
# CORRECT
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["203.0.113.0/24"]  # Only your office IP
}
```

---

### ❌ Mistake 2: Database Exposed to Internet

```hcl
# WRONG - Database shouldn't be public!
ingress {
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Anyone can try to connect!
}
```

**Why wrong?**
- Exposes database to internet attacks
- Risk of data breach
- Violates compliance requirements

**Fix:**
```hcl
# CORRECT - Only application servers
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  security_groups = [aws_security_group.lambda.id]  # Only Lambda
}
```

---

### ❌ Mistake 3: Allowing All Protocols

```hcl
# WRONG - Too permissive!
ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"  # All protocols
  cidr_blocks = ["0.0.0.0/0"]
}
```

**Why wrong?**
- Opens ALL ports to internet
- Principle of least privilege violated
- Massive security risk

**Fix:**
```hcl
# CORRECT - Only specific ports needed
ingress {
  from_port   = 443  # HTTPS only
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

---

### ❌ Mistake 4: No Description

```hcl
# WRONG - No context
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**Why wrong?**
- Future you won't remember why this exists
- Team members confused
- Hard to audit

**Fix:**
```hcl
# CORRECT - Clear purpose
ingress {
  description = "Allow HTTPS from internet for public website"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

---

## 🔄 CREATE vs USE EXISTING

### Decision Tree

```
Do you need to create new security groups?
│
├─ YES → I have permission and want full control
│         └─ Use: security_group_create.tf
│            ✓ Create custom security groups
│            ✓ Define your own rules
│            ✓ Best for: Startups, dev environments
│
└─ NO → Network/Security Team created them
          └─ Use: security_group_use_existing.tf
             ✓ Reference existing security groups
             ✓ No new resources created
             ✓ Best for: Enterprise, production
```

---

## 📋 QUESTIONNAIRE: Using Existing Security Groups

### Before You Start

If your Network/Security Team has already created security groups, gather this information:

### ✅ Required Information

#### 1. Which Resources Do You Need Security Groups For?

```
□ ALB (Application Load Balancer)
□ Lambda functions
□ RDS database
□ EC2 instances
□ Bastion host
□ ElastiCache (Redis/Memcached)
```

#### 2. Security Group IDs

```
ALB Security Group:
  SG ID: sg-_________________
  Purpose: ___________________
  Allowed ports: _____________

Lambda Security Group:
  SG ID: sg-_________________
  Purpose: ___________________
  Allowed outbound: __________

RDS Security Group:
  SG ID: sg-_________________
  Purpose: ___________________
  Allowed sources: ___________

EC2 Security Group:
  SG ID: sg-_________________
  Purpose: ___________________
  Allowed ports: _____________
```

#### 3. Confirm Rules with Team

```
Question: What ports are open in ALB security group?
Answer: Port 443 (HTTPS) and port 80 (HTTP) from 0.0.0.0/0

Question: Can Lambda access RDS?
Answer: Yes, rds-sg allows port 5432 from lambda-sg

Question: Can I SSH to EC2 instances?
Answer: Yes, from bastion-sg only
```

---

### 🤔 Common Questions

#### Q1: Do I need to know the security group rules?

**Answer**: Yes, helpful but not required

**What you MUST know:**
- Security Group IDs
- Which resources use which SG

**What's HELPFUL to know:**
- What ports are open
- What sources are allowed
- Any restrictions

**Why?**
- Troubleshooting connectivity issues
- Understanding security posture
- Planning changes

---

#### Q2: Can I add rules to existing security groups?

**Answer**: Depends on company policy

**Scenario 1: You own the SG**
```
Yes! You can add rules via Terraform
```

**Scenario 2: Security Team owns it**
```
No! Request changes through their process
Don't modify directly - could break other apps
```

**How to check:**
```bash
# Check who created the security group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Look for tags:
# ManagedBy: security-team → Don't modify
# ManagedBy: app-team → You can modify (if it's yours)
```

---

#### Q3: What if I need a new rule in existing SG?

**Answer**: Follow company process

**Step 1: Check if rule exists**
```bash
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].IpPermissions'
```

**Step 2: If rule doesn't exist, request it**
```
Email to Security/Network Team:

Subject: Security Group Rule Request

Hi Team,

I need to add a rule to sg-xxxxx (lambda-sg):

FROM: Lambda Security Group (sg-yyyyy)
TO: RDS Security Group (sg-zzzzz)
PORT: 5432 (PostgreSQL)
PURPOSE: Allow Lambda to query database for API responses

Please let me know if you need more information.
```

**Step 3: They approve and add the rule**

---

#### Q4: How do I verify security group configuration?

**Answer**: Use Terraform validation output

```bash
terraform output validation_info

# Output shows:
validation_info = {
  lambda_sg_details = {
    id          = "sg-0abc123"
    name        = "production-lambda-sg"
    description = "Lambda function security group"
    vpc_id      = "vpc-0def456"
  }
}
```

**Verify with team:**
1. ID matches what they gave you
2. VPC ID is correct
3. Name makes sense

---

## 📝 Email Template: Request Security Group Info

```
Subject: Security Group IDs Request for [Project Name]

Hi [Network/Security Team],

I'm setting up infrastructure for [project name] and need security group information.

RESOURCES NEEDED:
-----------------
□ ALB (Application Load Balancer) - public-facing
□ Lambda functions - API processing
□ RDS PostgreSQL database - data storage
□ EC2 instances (optional) - background jobs

INFORMATION NEEDED:
-------------------
For each resource above, please provide:
1. Security Group ID (e.g., sg-0abc123...)
2. Security Group Name
3. Brief description of what traffic is allowed
4. Any restrictions I should know about

TRAFFIC REQUIREMENTS:
---------------------
- ALB: Needs to accept HTTPS (443) from internet
- Lambda: Needs to connect to RDS and call external APIs
- RDS: Only Lambda should be able to connect (port 5432)

QUESTIONS:
----------
1. Are these security groups already created?
2. If not, should I create them or will you?
3. Any security policies I need to follow?

Thanks!
[Your Name]
```

---

## 🎯 Best Practices

### 1. Principle of Least Privilege

**What**: Only allow minimum access needed

```hcl
# BAD - Too permissive
ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# GOOD - Specific ports only
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

---

### 2. Use Security Group References

**What**: Reference other SGs instead of IPs when possible

```hcl
# BETTER - Security group reference
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  security_groups = [aws_security_group.lambda.id]
}

# WORSE - IP-based (brittle)
ingress {
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.0.1.0/24"]  # What if Lambda moves?
}
```

---

### 3. Always Add Descriptions

**What**: Document every rule

```hcl
ingress {
  description = "Allow HTTPS from internet for public API"  # Clear purpose!
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

---

### 4. Use Meaningful Names

```hcl
# GOOD
name = "${var.project_name}-lambda-sg-${var.environment}"
# Result: "ecommerce-lambda-sg-production"

# BAD
name = "sg1"  # What is this?
```

---

### 5. Tag Everything

```hcl
tags = {
  Name        = "production-lambda-sg"
  Environment = "production"
  ManagedBy   = "Terraform"
  Team        = "platform"
  Purpose     = "Lambda function security"
}
```

**Why?**
- Easy to find in AWS Console
- Cost tracking
- Automation (delete all dev SGs)
- Compliance audits

---

## 🤔 Should I Create Multiple Security Groups for One Use-Case?

### The Question

You have multiple Lambda functions. Do you create:
- **Option A**: One security group shared by all Lambdas
- **Option B**: One security group per Lambda function

**Short Answer**: Usually **Option A** (one shared SG) is better

---

### Real-World Example

**Scenario**: E-commerce app with 3 Lambda functions

```
Lambda Functions:
1. user-api         (handles user requests)
2. order-processor  (processes orders)
3. inventory-sync   (syncs inventory)

All need:
- Access to RDS database (port 5432)
- Access to ElastiCache Redis (port 6379)
- Outbound internet access (call APIs)
```

#### Option A: One Shared Security Group (RECOMMENDED)

```hcl
# One security group for all Lambdas
resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Shared by all Lambda functions"

  # No ingress (Lambda doesn't accept connections)

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS allows traffic from Lambda SG
resource "aws_security_group" "rds" {
  ingress {
    description     = "PostgreSQL from all Lambdas"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]  # All Lambdas can connect
  }
}

# All 3 Lambdas use the same SG
resource "aws_lambda_function" "user_api" {
  vpc_config {
    security_group_ids = [aws_security_group.lambda.id]
  }
}

resource "aws_lambda_function" "order_processor" {
  vpc_config {
    security_group_ids = [aws_security_group.lambda.id]  # Same SG
  }
}

resource "aws_lambda_function" "inventory_sync" {
  vpc_config {
    security_group_ids = [aws_security_group.lambda.id]  # Same SG
  }
}
```

**Pros:**
- ✅ Simple to manage (1 SG instead of 3)
- ✅ Easy to update rules (change once, affects all)
- ✅ Less AWS resources (lower quota usage)
- ✅ RDS only needs 1 ingress rule
- ✅ Fewer moving parts = less complexity

**Cons:**
- ⚠️ All Lambdas have same access (less granular control)

---

#### Option B: One Security Group Per Lambda (RARELY NEEDED)

```hcl
# Separate security group for each Lambda
resource "aws_security_group" "lambda_user_api" {
  name        = "lambda-user-api-sg"
  description = "Only for user-api Lambda"

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_order_processor" {
  name        = "lambda-order-processor-sg"
  description = "Only for order-processor Lambda"

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_inventory_sync" {
  name        = "lambda-inventory-sync-sg"
  description = "Only for inventory-sync Lambda"

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS needs 3 ingress rules now!
resource "aws_security_group" "rds" {
  ingress {
    description     = "PostgreSQL from user-api Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_user_api.id]
  }

  ingress {
    description     = "PostgreSQL from order-processor Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_order_processor.id]
  }

  ingress {
    description     = "PostgreSQL from inventory-sync Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_inventory_sync.id]
  }
}
```

**Pros:**
- ✅ Maximum granular control
- ✅ Can track which Lambda accesses what
- ✅ Can revoke one Lambda's access without affecting others

**Cons:**
- ❌ More security groups to manage (3x the work)
- ❌ More complex Terraform code
- ❌ RDS needs multiple ingress rules
- ❌ Harder to maintain and update
- ❌ Uses more AWS quota (max 2,500 SGs per VPC)

---

### When to Use Multiple Security Groups?

#### Use ONE Shared SG When:

**Same Access Requirements:**
```
All Lambdas need:
- Same database access
- Same outbound internet
- Same network permissions
```

**Example scenarios:**
- ✅ Microservices that all need database access
- ✅ API functions that all call same resources
- ✅ Worker functions processing same queue
- ✅ Dev/test environment (keep it simple)

---

#### Use SEPARATE SGs When:

**Different Security Requirements:**

```
Example: Financial application

Lambda 1: Public API
- Needs: Internet access only
- Security: Low sensitivity

Lambda 2: Payment Processor
- Needs: Database + payment gateway
- Security: PCI-DSS compliance required
- Audit: Must track all connections

Lambda 3: Admin Function
- Needs: Database + internal systems
- Security: Extra logging required
```

```hcl
# Different security requirements = different SGs

resource "aws_security_group" "lambda_public_api" {
  name = "lambda-public-api-sg"

  # Only internet access (no database)
  egress {
    description = "HTTPS only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_payment" {
  name = "lambda-payment-sg"

  # Database + specific payment gateway IPs
  egress {
    description = "Payment gateway only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Payment gateway IP
  }

  tags = {
    Compliance = "PCI-DSS"
    Audit      = "true"
  }
}

resource "aws_security_group" "lambda_admin" {
  name = "lambda-admin-sg"

  # Internal network only
  egress {
    description = "Internal network only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # VPC only
  }
}
```

**Use separate SGs when:**
- ✅ Different compliance requirements (PCI-DSS, HIPAA)
- ✅ Different security zones (public, private, restricted)
- ✅ Different network access needs
- ✅ Audit requirements (track specific function access)
- ✅ Zero-trust security model
- ✅ One Lambda needs internet, others don't

---

### Decision Tree

```
Do my resources need EXACTLY the same network access?
│
├─ YES → Use ONE shared security group
│         └─ Simpler, easier to manage
│            Example: All Lambdas need database + internet
│
└─ NO → Do they have DIFFERENT access requirements?
          │
          ├─ Different compliance needs?     → Separate SGs
          ├─ Different security zones?       → Separate SGs
          ├─ One needs internet, one doesn't? → Separate SGs
          └─ Just different functions?       → Still use ONE shared SG!
```

---

### Real-World Company Examples

#### Startup / Small Company (1-20 employees)

```hcl
# Keep it simple - one SG per resource type

resource "aws_security_group" "lambda" {
  name = "lambda-sg"
  # All Lambdas (10+ functions) use this
}

resource "aws_security_group" "rds" {
  name = "rds-sg"
  # All databases use this
}
```

**Why**: Simple, fast to iterate, fewer resources

---

#### Medium Company (20-200 employees)

```hcl
# One SG per environment per resource type

resource "aws_security_group" "lambda_production" {
  name = "lambda-production-sg"
  # All production Lambdas
}

resource "aws_security_group" "lambda_dev" {
  name = "lambda-dev-sg"
  # All dev Lambdas
}

resource "aws_security_group" "rds_production" {
  name = "rds-production-sg"
}

resource "aws_security_group" "rds_dev" {
  name = "rds-dev-sg"
}
```

**Why**: Separate environments, still manageable

---

#### Large Enterprise (200+ employees)

```hcl
# Separate by environment, team, and security zone

resource "aws_security_group" "lambda_platform_public" {
  name = "lambda-platform-public-sg"
  # Platform team public-facing Lambdas
}

resource "aws_security_group" "lambda_platform_internal" {
  name = "lambda-platform-internal-sg"
  # Platform team internal Lambdas
}

resource "aws_security_group" "lambda_payment_pci" {
  name = "lambda-payment-pci-sg"
  # Payment team PCI-compliant Lambdas
  tags = {
    Compliance = "PCI-DSS"
  }
}

resource "aws_security_group" "lambda_healthcare_hipaa" {
  name = "lambda-healthcare-hipaa-sg"
  # Healthcare team HIPAA-compliant Lambdas
  tags = {
    Compliance = "HIPAA"
  }
}
```

**Why**: Compliance, audit, zero-trust security

---

### Best Practice Recommendation

#### Default Strategy: ONE Security Group Per Resource Type

```hcl
# Recommended for most teams

resource "aws_security_group" "alb" {
  name = "alb-sg"
  # All load balancers use this
}

resource "aws_security_group" "lambda" {
  name = "lambda-sg"
  # All Lambda functions use this
}

resource "aws_security_group" "rds" {
  name = "rds-sg"
  # All databases use this
}

resource "aws_security_group" "elasticache" {
  name = "elasticache-sg"
  # All Redis/Memcached use this
}
```

**Why this works:**
- Simple to understand and maintain
- Easy to add new resources (just attach existing SG)
- Reduces complexity
- Good enough for 90% of use cases

**When to add more SGs:**
- Only when you have a specific reason (compliance, security zones)
- Not "just because" you can

---

### Summary

| Scenario | Number of SGs | Reason |
|----------|---------------|--------|
| **5 Lambdas, all need database** | 1 shared SG | Same access requirements |
| **3 Lambdas: 2 need DB, 1 doesn't** | 2 SGs (one for DB access, one without) | Different access needs |
| **Payment Lambda (PCI-DSS) + regular Lambdas** | 2 SGs | Compliance requirement |
| **Dev vs Prod Lambdas** | 2 SGs | Environment separation |
| **10 microservices, all identical access** | 1 shared SG | Keep it simple! |

**Golden Rule**:
> Start with ONE security group per resource type. Only create additional security groups when you have a concrete reason (different access, compliance, security zones). More SGs = more complexity.

---

## 🛠️ Step-by-Step: Create Security Groups

### Step 1: Copy the file

```bash
cd modules/security-group
cp security_group_create.tf main.tf
```

### Step 2: Configure what to create

```hcl
# In your terraform.tfvars
vpc_id              = "vpc-0abc123"    # Your VPC
create_alb_sg       = true             # Create ALB SG
create_lambda_sg    = true             # Create Lambda SG
create_rds_sg       = true             # Create RDS SG
create_ec2_web_sg   = false            # Don't create EC2 SG
```

### Step 3: Run Terraform

```bash
terraform init
terraform plan    # Review what will be created
terraform apply   # Create security groups
```

### Step 4: Use in your resources

```hcl
# In your lambda module
resource "aws_lambda_function" "api" {
  vpc_config {
    security_group_ids = [module.security_group.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }
}
```

---

## 🛠️ Step-by-Step: Use Existing Security Groups

### Step 1: Get IDs from team

Ask Network/Security Team for security group IDs.

### Step 2: Copy the file

```bash
cd modules/security-group
cp security_group_use_existing.tf main.tf
```

### Step 3: Fill in IDs

```hcl
# In your terraform.tfvars
existing_alb_sg    = "sg-0abc123def"
existing_lambda_sg = "sg-0def456ghi"
existing_rds_sg    = "sg-0ghi789jkl"
```

### Step 4: Verify

```bash
terraform plan
terraform output validation_info  # Verify SG details match
```

### Step 5: Use same as created SGs

```hcl
# Same code works for both created and existing!
resource "aws_lambda_function" "api" {
  vpc_config {
    security_group_ids = [module.security_group.lambda_security_group_id]
  }
}
```

---

## 🔒 Security Checklist

Before deploying to production:

- [ ] No SSH (port 22) from 0.0.0.0/0
- [ ] No RDP (port 3389) from 0.0.0.0/0
- [ ] Database ports (3306, 5432) NOT from internet
- [ ] All rules have descriptions
- [ ] Use security group references (not IPs) when possible
- [ ] Follow principle of least privilege
- [ ] Tags applied to all security groups
- [ ] Reviewed by security team (if required)
- [ ] Documented which SG is for what resource

---

## 📊 Comparison: Create vs Use Existing

| Feature | security_group_create.tf | security_group_use_existing.tf |
|---------|--------------------------|-------------------------------|
| **Creates new SGs** | ✅ Yes | ❌ No |
| **Uses existing SGs** | ❌ No | ✅ Yes |
| **Control over rules** | Full control | No control (request changes) |
| **Team approval** | May need approval | Already approved |
| **Terraform state** | Manages SGs | Only references |
| **terraform destroy** | Deletes SGs | Does nothing (SGs stay) |
| **Best for** | Dev, startups | Enterprise, production |
| **Flexibility** | High | Low |
| **Security review** | You handle | Team handled |

---

## 💡 When to Use Which?

### Use `security_group_create.tf` if:
- ✅ Starting new project
- ✅ Dev/test environment
- ✅ Have permission to create SGs
- ✅ Want full control over rules
- ✅ Small/medium company

### Use `security_group_use_existing.tf` if:
- ✅ Enterprise company
- ✅ Production environment
- ✅ Security Team manages SGs
- ✅ Need to follow company standards
- ✅ SGs already exist

---

**Next**: See complete implementations in [security_group_create.tf](./security_group_create.tf) or [security_group_use_existing.tf](./security_group_use_existing.tf)
