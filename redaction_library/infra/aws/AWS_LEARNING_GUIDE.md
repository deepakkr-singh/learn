# AWS Services - Complete Learning Guide for Beginners

This guide explains every AWS service in simple English with real-world examples, Terraform implementation, and best practices.

## 📚 Table of Contents

1. [AWS Fundamentals - Start Here!](#aws-fundamentals)
2. [Master Architecture](#master-architecture)
3. [VPC (Virtual Private Cloud)](#vpc)
4. [Subnet](#subnet)
5. [Security Group](#security-group)
6. [KMS (Key Management Service)](#kms)
7. [Secrets Manager](#secrets-manager)
8. [IAM (Identity and Access Management)](#iam)
9. [Lambda](#lambda)
10. [API Gateway](#api-gateway)
11. [S3 (Simple Storage Service)](#s3)
12. [SQS (Simple Queue Service)](#sqs)
13. [SNS (Simple Notification Service)](#sns)
14. [DynamoDB](#dynamodb)
15. [ALB (Application Load Balancer)](#alb)
16. [Fargate](#fargate)
17. [EC2 (Elastic Compute Cloud)](#ec2)
18. [Step Functions](#step-functions)

---

## AWS Fundamentals

### 🌐 Common Terms - Learn These First!

Before diving into AWS services, understand these foundational concepts:

#### **Internet vs Intranet**

**Internet (Public Network):**
- Anyone in the world can access
- Example: google.com, facebook.com, your company website
- Traffic flows over public networks
- **Security Risk**: High - exposed to everyone

**Intranet (Private Company Network):**
- Only employees can access (inside company network or via VPN)
- Example: Internal HR portal, employee dashboard, admin tools
- Traffic stays within company network
- **Security Risk**: Low - isolated from public internet

```
Internet Example:
User (anywhere) → https://yourcompany.com → Public Website

Intranet Example:
Employee (VPN) → https://internal.yourcompany.com → Internal Dashboard
```

---

#### **Internal Application vs External Application**

**External Application (Internet-facing):**
- Public users can access
- Exposed to the internet
- Example: E-commerce website, mobile app API, public blog

**Internal Application (Company-only):**
- Only employees/authorized users can access
- NOT exposed to the internet
- Example: Admin panel, employee management system, internal API

---

#### **Backend vs Frontend**

**Frontend:**
- What users see and interact with
- Technologies: React, Vue, Angular, HTML/CSS/JavaScript
- Runs in user's browser
- Example: Website UI, mobile app screen

**Backend:**
- Server-side logic that frontend calls
- Technologies: Python, Node.js, Java, Go
- Runs on AWS (Lambda, EC2, Fargate)
- Example: API that processes login, fetches data from database

```
User Request Flow:
Frontend (Browser) → Backend API (AWS Lambda) → Database (DynamoDB)
                ↓
          Response back to user
```

---

---

#### **VPC: Private or Public?**

**IMPORTANT**: VPC itself is PRIVATE by default!

```
VPC = Your private, isolated network (like your home Wi-Fi)
  ├─ Public Subnet = Can access internet (via Internet Gateway)
  └─ Private Subnet = NO internet access (completely isolated)
```

**Key Understanding:**
- **VPC** = Always private and isolated from other AWS customers
- **Subnets INSIDE VPC** = You choose which ones can access internet

**Without Internet Gateway:**
```
VPC (10.0.0.0/16) - No Internet Gateway
  └─ All subnets are private (no internet access)
```

**With Internet Gateway:**
```
VPC (10.0.0.0/16) - Has Internet Gateway
  ├─ Public Subnet (10.0.1.0/24) - Route to IGW → Internet access
  └─ Private Subnet (10.0.11.0/24) - No route to IGW → No internet
```

**Analogy:**
- VPC = Your house (private property)
- Public Subnet = Living room with windows facing street (visible from outside)
- Private Subnet = Basement (hidden, no windows)

---

### 🏗️ The Nesting Concept (Big Box Inside Small Box)

AWS resources are organized in a hierarchy. Think of it like Russian nesting dolls:

```
┌─────────────────────────────────────────────────────────────┐
│ AWS ACCOUNT (Biggest Box)                                   │
│  Your entire AWS account (billing, root access)             │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ REGION (us-east-1, eu-west-1, etc.)                   │  │
│  │  Geographic location where resources live             │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐ │  │
│  │  │ VPC (Virtual Private Cloud)                      │ │  │
│  │  │  Your private network (10.0.0.0/16)              │ │  │
│  │  │                                                   │ │  │
│  │  │  ┌─────────────────────────────────────────────┐ │ │  │
│  │  │  │ SUBNET (10.0.1.0/24)                        │ │ │  │
│  │  │  │  Section of VPC (Public or Private)         │ │ │  │
│  │  │  │                                              │ │ │  │
│  │  │  │  ┌────────────────────────────────────────┐ │ │ │  │
│  │  │  │  │ RESOURCE (EC2, Lambda, RDS)            │ │ │ │  │
│  │  │  │  │  Your actual application/database      │ │ │ │  │
│  │  │  │  └────────────────────────────────────────┘ │ │ │  │
│  │  │  └─────────────────────────────────────────────┘ │ │  │
│  │  └──────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Real-World Example:**
```
AWS Account: your-company (ID: 123456789012)
  └─ Region: us-east-1 (N. Virginia)
      └─ VPC: production-vpc (10.0.0.0/16)
          ├─ Public Subnet: public-1a (10.0.1.0/24)
          │   └─ ALB: my-load-balancer
          └─ Private Subnet: private-1a (10.0.11.0/24)
              ├─ Lambda: api-function
              ├─ EC2: web-server-1
              └─ RDS: postgres-db
```

**Why This Matters:**
- **Isolation**: Each VPC is isolated from others
- **Security**: Private subnets can't be accessed from internet
- **Organization**: Easy to manage and find resources
- **Billing**: Track costs per region/VPC

---

### 🔀 API Gateway vs Application Load Balancer (ALB)

**IMPORTANT**: API Gateway is NOT a load balancer! They serve different purposes.

| Feature | API Gateway | ALB (Application Load Balancer) |
|---------|-------------|--------------------------------|
| **Location** | OUTSIDE your VPC (AWS-managed service) | INSIDE your VPC |
| **Primary Use** | Expose Lambda/HTTP endpoints as REST/WebSocket APIs | Distribute traffic across EC2/Fargate/Lambda |
| **Best For** | Serverless APIs (Lambda), microservices | Multiple servers (EC2, containers) |
| **Pricing** | Per request ($3.50 per 1M calls) | Per hour ($16/month + usage) |
| **Features** | API keys, rate limiting, caching, API versioning, request validation | Health checks, SSL termination, path-based routing, sticky sessions |
| **Target** | Lambda, HTTP endpoints, AWS services | EC2, Fargate, Lambda, IP addresses |
| **Security** | AWS WAF, API keys, Cognito, Lambda authorizers | Security Groups, AWS WAF, SSL/TLS |
| **Scaling** | Fully automatic (AWS manages) | Automatic but within VPC |

---

#### **When to Use API Gateway?**

✅ **Use API Gateway When:**
- Building serverless APIs (Lambda-based)
- Need API versioning (v1, v2)
- Need request/response transformation
- Need API key management
- Need built-in rate limiting per API key
- Small to medium traffic (cost-effective for < 10M requests/month)

**Example Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              API GATEWAY (AWS Managed, Outside VPC)          │
│              https://api.example.com                         │
│              ├─ /users → Lambda (Get Users)                 │
│              ├─ /orders → Lambda (Get Orders)               │
│              └─ Rate Limiting: 1000 req/sec                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (Your Network)                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Private Subnet                                         │ │
│  │  ├─ Lambda: users-api                                  │ │
│  │  ├─ Lambda: orders-api                                 │ │
│  │  └─ DynamoDB: users-table                              │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Cost**: ~$3.50 per 1M API calls + Lambda costs

---

#### **When to Use ALB (Application Load Balancer)?**

✅ **Use ALB When:**
- Running multiple EC2 instances or Fargate containers
- Need to distribute traffic across servers
- Need path-based routing (/api → servers, /admin → admin servers)
- High traffic workloads (> 10M requests/month)
- Need sticky sessions (user always routed to same server)

**Example Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (Your Network)                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Public Subnet                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ ALB (Load Balancer)                              │  │ │
│  │  │ HTTPS Listener → Routes to 3 EC2 instances       │  │ │
│  │  └────────┬─────────────────────────────────────────┘  │ │
│  └───────────┼────────────────────────────────────────────┘ │
│              │                                               │
│  ┌───────────┼────────────────────────────────────────────┐ │
│  │ Private Subnet                                         │ │
│  │      ┌────┴────┬──────────┬───────────┐                │ │
│  │      ▼         ▼          ▼           │                │ │
│  │   EC2-1     EC2-2      EC2-3          │                │ │
│  │   (Web)     (Web)      (Web)          │                │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Cost**: ~$16/month base + $0.008 per LCU-hour

---

#### **Can You Use Both Together?**

Yes! Common pattern:

```
Internet → API Gateway → ALB → EC2/Fargate

Why?
- API Gateway: Handles API management, rate limiting, caching
- ALB: Distributes traffic to multiple backend servers
```

---

### 🔐 Public ALB vs Private ALB (Internet vs Intranet)

#### **Public ALB (Internet-Facing)**

**Use Case**: External application accessible from the internet

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
│                    (Anyone can access)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Public Subnet (10.0.1.0/24)                            │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ PUBLIC ALB                                       │  │ │
│  │  │ Scheme: internet-facing                          │  │ │
│  │  │ DNS: myapp.example.com                           │  │ │
│  │  │ Security Group: Allow 0.0.0.0/0 (port 443)       │  │ │
│  │  └────────┬─────────────────────────────────────────┘  │ │
│  └───────────┼────────────────────────────────────────────┘ │
│              │                                               │
│  ┌───────────┼────────────────────────────────────────────┐ │
│  │ Private Subnet (10.0.11.0/24)                          │ │
│  │      ┌────┴────┐                                        │ │
│  │      ▼         ▼                                        │ │
│  │   EC2-1     EC2-2     (Backend servers)                │ │
│  │   Security Group: Allow traffic from ALB only          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Configuration:**
```hcl
resource "aws_lb" "public" {
  name               = "public-alb"
  load_balancer_type = "application"
  internal           = false  # Internet-facing
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  security_groups = [aws_security_group.alb_public.id]
}

# ALB Security Group
resource "aws_security_group" "alb_public" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow anyone
  }
}
```

---

#### **Private ALB (Intranet-Only)**

**Use Case**: Internal application only accessible from company network (VPN/Direct Connect)

```
┌─────────────────────────────────────────────────────────────┐
│                 COMPANY NETWORK (Intranet)                   │
│          Employees connected via VPN or Direct Connect       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Private Subnet (10.0.11.0/24)                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ PRIVATE ALB (Internal)                           │  │ │
│  │  │ Scheme: internal                                 │  │ │
│  │  │ DNS: admin.internal.company.com                  │  │ │
│  │  │ Security Group: Allow company CIDR only          │  │ │
│  │  └────────┬─────────────────────────────────────────┘  │ │
│  └───────────┼────────────────────────────────────────────┘ │
│              │                                               │
│  ┌───────────┼────────────────────────────────────────────┐ │
│  │ Private Subnet (10.0.12.0/24)                          │ │
│  │      ┌────┴────┐                                        │ │
│  │      ▼         ▼                                        │ │
│  │   EC2-1     EC2-2     (Admin panel, internal tools)    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Configuration:**
```hcl
resource "aws_lb" "private" {
  name               = "private-alb"
  load_balancer_type = "application"
  internal           = true  # Internal only
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_groups = [aws_security_group.alb_private.id]
}

# ALB Security Group
resource "aws_security_group" "alb_private" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Company network only
  }
}
```

**Key Differences:**
| Feature | Public ALB | Private ALB |
|---------|-----------|-------------|
| **Scheme** | `internal = false` | `internal = true` |
| **Subnet** | Public subnet | Private subnet |
| **Access** | Anyone on internet | Only VPN/Direct Connect users |
| **Security Group** | `0.0.0.0/0` (or specific IPs) | Company CIDR only |
| **Use Case** | E-commerce, public APIs | Admin panels, internal dashboards |

---

### 🛡️ WAF (Web Application Firewall) - Where Does It Sit?

**IMPORTANT**: WAF is NOT inside your VPC. It sits IN FRONT of your ALB/API Gateway/CloudFront.

#### **WAF Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
│                    (Attackers, Users)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS WAF (First Layer)                     │
│              SITS IN FRONT (Not inside VPC)                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ WAF Rules:                                             │ │
│  │  ✓ Block SQL injection                                 │ │
│  │  ✓ Block XSS attacks                                   │ │
│  │  ✓ Rate limiting (1000 req/5min)                       │ │
│  │  ✓ Geo-blocking (block specific countries)            │ │
│  │  ✓ IP blacklist/whitelist                              │ │
│  └────────────────────────┬───────────────────────────────┘ │
└───────────────────────────┼─────────────────────────────────┘
                            │ (Only good traffic passes)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (Your Network)                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Public Subnet                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │ ALB (Second Layer)                               │  │ │
│  │  │ Security Group: Allow specific ports/IPs         │  │ │
│  │  │ SSL/TLS Certificate                              │  │ │
│  │  └────────┬─────────────────────────────────────────┘  │ │
│  └───────────┼────────────────────────────────────────────┘ │
│              │                                               │
│  ┌───────────┼────────────────────────────────────────────┐ │
│  │ Private Subnet (Third Layer)                           │ │
│  │      ┌────┴────┐                                        │ │
│  │      ▼         ▼                                        │ │
│  │   EC2-1     EC2-2                                      │ │
│  │   Security Group: Allow ALB only                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### **How to Attach WAF?**

WAF attaches to (NOT inside VPC):
1. **ALB** (Application Load Balancer)
2. **API Gateway**
3. **CloudFront** (CDN)

**Terraform Example:**
```hcl
# 1. Create WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "alb-waf"
  scope = "REGIONAL"  # For ALB/API Gateway

  default_action {
    allow {}  # Default allow, block based on rules
  }

  # Rule 1: Rate limiting
  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000  # Max 1000 requests per 5 min
        aggregate_key_type = "IP"
      }
    }
  }

  # Rule 2: Block SQL injection
  rule {
    name     = "sql-injection-protection"
    priority = 2

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }
  }

  # Rule 3: Geo-blocking
  rule {
    name     = "geo-block"
    priority = 3

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["CN", "RU"]  # Block China, Russia
      }
    }
  }
}

# 2. Attach WAF to ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.public.arn  # Your ALB
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

**WAF Cost**: ~$5/month base + $1 per rule + $0.60 per 1M requests

---

### 🔒 How Secure is Public ALB Without API Gateway?

**Question**: If I use public ALB instead of API Gateway, is it secure?

**Answer**: Yes, IF you implement proper security layers!

#### **Security Comparison**

| Security Feature | API Gateway | Public ALB + WAF |
|-----------------|-------------|------------------|
| **DDoS Protection** | AWS Shield (automatic) | AWS Shield (automatic) |
| **WAF Support** | Yes | Yes |
| **Rate Limiting** | Built-in (per API key) | WAF rules |
| **SSL/TLS** | Automatic (AWS manages) | You configure |
| **IP Whitelisting** | Resource policy | WAF + Security Groups |
| **Authentication** | Cognito, Lambda authorizers | Cognito + ALB rules |
| **Request Validation** | Built-in | Manual (Lambda/app code) |
| **API Keys** | Built-in | Manual implementation |

#### **Public ALB Security Best Practices**

To match API Gateway security level:

```
Security Layers (Defense in Depth):

1. AWS WAF (First line of defense)
   ✓ Rate limiting
   ✓ SQL injection protection
   ✓ XSS protection
   ✓ Geo-blocking
   ✓ IP blacklist/whitelist

2. ALB (Second layer)
   ✓ Security Group (restrict ports)
   ✓ SSL/TLS certificate
   ✓ HTTPS redirect (force SSL)
   ✓ Cognito authentication

3. Backend Security Group (Third layer)
   ✓ Only allow traffic from ALB
   ✓ No direct internet access

4. Application Layer (Fourth layer)
   ✓ Input validation
   ✓ Authentication/Authorization
   ✓ Logging/Monitoring
```

**Example Secure ALB Configuration:**
```hcl
# 1. ALB with SSL
resource "aws_lb" "public" {
  name               = "secure-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = true  # Prevent accidental deletion
}

# 2. ALB Security Group
resource "aws_security_group" "alb" {
  name = "alb-sg"
  vpc_id = aws_vpc.main.id

  # Allow HTTPS only
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (for redirect to HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. HTTPS Listener with SSL
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Strong encryption
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 4. HTTP to HTTPS Redirect
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"  # Permanent redirect
    }
  }
}

# 5. Backend Security Group (Only allow ALB)
resource "aws_security_group" "backend" {
  name = "backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Only ALB can access
  }
}

# 6. Attach WAF (see previous section)
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.public.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

#### **Cost Comparison**

**Option 1: API Gateway**
- API Gateway: ~$3.50 per 1M requests
- Lambda: ~$0.20 per 1M requests
- **Total**: ~$3.70 per 1M requests

**Option 2: Public ALB + WAF**
- ALB: ~$16/month + $0.008 per LCU-hour (~$25/month total)
- WAF: ~$5/month + $1 per rule (~$10/month total)
- EC2/Fargate: Variable
- **Total**: ~$35/month base + compute costs

**When to Choose ALB over API Gateway?**
- High traffic (> 10M requests/month) - ALB becomes cheaper
- Need sticky sessions
- Running containers (Fargate/ECS)
- Need advanced routing (path-based, host-based)

**When to Choose API Gateway over ALB?**
- Serverless (Lambda-based)
- Low to medium traffic (< 10M requests/month)
- Need built-in API management (versioning, API keys)
- Want AWS to handle all security (less configuration)

---

## Master Architecture

### 🏗️ Complete AWS Infrastructure for a Web Application

```
┌─────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                   │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ROUTE 53 (DNS)                                    │
│                    example.com → ALB                                 │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│              ALB (Application Load Balancer)                         │
│              ├─ HTTPS Listener (Port 443)                           │
│              ├─ SSL Certificate                                     │
│              └─ Routes traffic to Lambda/Fargate/EC2                │
└────────────────────────────┬────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Lambda     │    │   Fargate    │    │     EC2      │
│  Functions   │    │  Containers  │    │   Instances  │
└──────────────┘    └──────────────┘    └──────────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  DynamoDB    │    │      S3      │    │     RDS      │
│  (Database)  │    │   (Files)    │    │  (Database)  │
└──────────────┘    └──────────────┘    └──────────────┘
        │
        ▼
┌──────────────────────────────────────────────────────────────┐
│                    SUPPORTING SERVICES                        │
├──────────────────────────────────────────────────────────────┤
│  SQS: Message Queue (async processing)                       │
│  SNS: Notifications (emails, SMS)                            │
│  Step Functions: Workflow orchestration                      │
│  API Gateway: REST/WebSocket APIs                            │
│  Secrets Manager: Store passwords/keys                       │
│  KMS: Encryption keys                                        │
│  IAM: Access control                                         │
│  CloudWatch: Monitoring/Logs                                 │
└──────────────────────────────────────────────────────────────┘

ALL OF THIS RUNS INSIDE:
┌─────────────────────────────────────────────────────────────────┐
│                           VPC                                    │
│  ┌────────────────┐           ┌────────────────┐               │
│  │ Public Subnet  │           │ Private Subnet │               │
│  │ (ALB, NAT)     │           │ (Lambda, EC2)  │               │
│  └────────────────┘           └────────────────┘               │
│                                                                 │
│  Security Groups: Firewall rules for each service              │
└─────────────────────────────────────────────────────────────────┘
```

### 🎯 Why Do We Need Each Service?

| Service | Purpose | Real-World Example | Who Creates It? | Who Manages It? |
|---------|---------|-------------------|----------------|-----------------|
| **VPC** | Your private network in AWS | Like your home's Wi-Fi network | Network Team | Network Team |
| **Subnet** | Sections within your VPC | Rooms in your house | Network Team | Network Team |
| **Security Group** | Firewall rules | Door locks and security cameras | Network Team OR App Team | App Team (usually) |
| **KMS** | Encryption keys | Master key to unlock encrypted data | Security Team OR App Team | Security Team |
| **Secrets Manager** | Store passwords securely | Password manager (like 1Password) | App Team | App Team |
| **IAM** | User permissions | Who can access what | Security Team OR App Team | Security Team |
| **Lambda** | Run code without servers | Restaurant kitchen (you order, they cook, you don't see the kitchen) | App Team (Developers) | App Team (Developers) |
| **API Gateway** | API endpoint | Restaurant front desk (takes orders, routes to kitchen) | App Team (Developers) | App Team (Developers) |
| **S3** | File storage | Google Drive / Dropbox | App Team (Developers) | App Team (Developers) |
| **SQS** | Message queue | Post office mailbox (async delivery) | App Team (Developers) | App Team (Developers) |
| **SNS** | Send notifications | WhatsApp broadcast | App Team (Developers) | App Team (Developers) |
| **DynamoDB** | NoSQL database | Excel spreadsheet on steroids | App Team (Developers) | App Team (Developers) |
| **ALB** | Load balancer | Traffic cop (directs cars to different lanes) | Network Team OR App Team | Network Team OR App Team |
| **Fargate** | Run containers without managing servers | Uber for containers | App Team (Developers) | App Team (Developers) |
| **EC2** | Virtual servers | Rent a computer in the cloud | App Team (Developers) | App Team (Developers) |
| **Step Functions** | Workflow automation | Assembly line in a factory | App Team (Developers) | App Team (Developers) |

---

### 👥 Understanding Team Responsibilities

In enterprise companies, different teams are responsible for different AWS resources. Here's who typically owns what:

#### **Network Team (Infrastructure Team)**
**Responsible for:**
- VPC (Virtual Private Cloud)
- Subnets (Public and Private)
- Internet Gateways
- NAT Gateways
- Route Tables
- VPC Peering
- Direct Connect / VPN
- Sometimes: ALB (if centralized)

**Why them?**
- They understand network architecture
- They ensure security and compliance
- They manage IP address allocation
- They coordinate with on-premises network

**When you work with them:**
- Creating new applications (need VPC/subnet info)
- Troubleshooting connectivity issues
- Requesting firewall rule changes
- Adding new regions or environments

---

#### **Security Team**
**Responsible for:**
- IAM roles and policies (who can access what)
- KMS encryption keys
- Security policies and compliance
- AWS Organizations and accounts
- CloudTrail (audit logs)
- Sometimes: Security Groups (if centralized)

**Why them?**
- They enforce security standards
- They ensure compliance (HIPAA, SOC2, etc.)
- They manage access control
- They respond to security incidents

**When you work with them:**
- Requesting IAM permissions
- Creating service accounts
- Security reviews before production
- Incident response

---

#### **App Team / Developers (You!)**
**Responsible for:**
- Lambda functions (your application code)
- API Gateway (your APIs)
- S3 buckets (your file storage)
- DynamoDB tables (your databases)
- SQS/SNS (your messaging)
- Fargate/EC2 (your compute)
- Secrets Manager (your secrets)
- Step Functions (your workflows)
- Security Groups (for your applications)

**Why you?**
- You know your application requirements
- You control your application lifecycle
- You deploy and update frequently
- You monitor and troubleshoot your app

**What you do:**
- Write Terraform for your services
- Deploy using CI/CD pipelines
- Monitor application health
- Scale resources based on load

---

### 🤝 Real-World Workflow Example

**Scenario**: You're deploying a new web application

```
Step 1: Request VPC Info
  You → Network Team: "I need VPC and subnet IDs for my app"
  Network Team → You: "Here's the VPC ID and subnet IDs"
  You: Use vpc_use_existing.tf (don't create, just reference)

Step 2: Request IAM Permissions
  You → Security Team: "I need Lambda to access DynamoDB and S3"
  Security Team → You: "Here's the IAM role ARN"
  You: Reference this role in your Lambda Terraform

Step 3: Create Your Resources
  You → AWS (via Terraform):
    - Create Lambda function
    - Create API Gateway
    - Create DynamoDB table
    - Create S3 bucket
    - Create Security Groups for your Lambda
    - Create Secrets Manager for your API keys

Step 4: Deploy and Monitor
  You: Deploy code, monitor CloudWatch, fix issues
```

---

### 📊 Responsibility Matrix

| Task | Network Team | Security Team | App Team (You) |
|------|-------------|--------------|----------------|
| Create VPC | ✅ Owner | ❌ No | ❌ No |
| Create Subnets | ✅ Owner | ❌ No | ❌ No |
| Create Security Groups | 🟡 Sometimes | 🟡 Sometimes | ✅ Usually |
| Create IAM Roles | ❌ No | ✅ Owner | 🟡 Request only |
| Create Lambda | ❌ No | ❌ No | ✅ Owner |
| Create ALB | 🟡 Sometimes | ❌ No | 🟡 Sometimes |
| Create S3 Bucket | ❌ No | ❌ No | ✅ Owner |
| Create KMS Keys | ❌ No | ✅ Owner | 🟡 Request only |
| Troubleshoot Network | ✅ Owner | ❌ No | 🔍 Escalate to them |
| Troubleshoot App | ❌ No | ❌ No | ✅ Owner |
| Security Compliance | ❌ No | ✅ Owner | ✅ Follow their rules |
| Cost Optimization | 🟡 Share | 🟡 Share | ✅ Owner (your resources) |

**Legend:**
- ✅ Owner: You create and manage it
- 🟡 Sometimes: Depends on company policy
- ❌ No: Not your responsibility
- 🔍 Escalate: You can investigate but they fix it

---

### 🏢 Company Size Matters

#### **Startup / Small Company**
```
You (Developer) = Network Team + Security Team + App Team
→ You create EVERYTHING (VPC, Security Groups, IAM, Lambda, etc.)
→ Use vpc_create.tf (create from scratch)
→ Full control, full responsibility
```

#### **Medium Company**
```
Platform Team = Network + Security
App Team (You) = Lambda, API Gateway, DynamoDB, etc.

→ Platform Team creates VPC, IAM roles
→ You create your application resources
→ Use vpc_use_existing.tf (reference their VPC)
```

#### **Large Enterprise**
```
Network Team = VPC, Subnets, NAT Gateways
Security Team = IAM, KMS, compliance
App Team (You) = Lambda, S3, DynamoDB
Platform Team = Shared ALB, monitoring

→ Each team has specific responsibilities
→ You request access, don't create network resources
→ Heavy approval process
→ Use vpc_use_existing.tf + request IAM roles
```

---

## 📂 Module Structure

Each service has its own folder with:

```
modules/
├── vpc/
│   ├── main.tf              # Complete VPC implementation
│   ├── README.md            # What is VPC? Why? How to use?
│   └── examples.tf          # Real-world usage examples
│
├── security-group/
│   ├── main.tf
│   ├── README.md
│   └── examples.tf
│
└── [... other services ...]
```

---

## 🔑 Common Parameters (Used by All Services)

### Tags
Every AWS resource should have tags for:
- **Identification**: Who owns this?
- **Cost tracking**: Which project is this for?
- **Automation**: Filter resources programmatically

**Standard Tags:**
```hcl
tags = {
  Name        = "my-resource-name"
  Environment = "dev"              # dev, staging, prod
  Project     = "redaction-library"
  Owner       = "platform-team"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
  CreatedDate = "2025-11-14"
}
```

### Why Tags Matter?
- **Billing**: See costs per project/team
- **Security**: Identify resources quickly
- **Automation**: "Delete all resources tagged 'Environment=dev'"

---

## 🚀 Getting Started

### Prerequisites
1. AWS Account
2. Terraform installed
3. AWS CLI configured

### Quick Start
```bash
# 1. Navigate to a module
cd modules/vpc

# 2. Initialize Terraform
terraform init

# 3. Review what will be created
terraform plan

# 4. Create resources
terraform apply

# 5. Destroy when done
terraform destroy
```

---

## 📖 Service Deep Dives

Click on each service below for detailed explanation:

1. [VPC - Your Private Network](modules/vpc/README.md)
2. [Security Group - Firewall Rules](modules/security-group/README.md)
3. [KMS - Encryption Keys](modules/kms/README.md)
4. [Secrets Manager - Password Vault](modules/secrets-manager/README.md)
5. [IAM - Access Control](modules/iam/README.md)
6. [Lambda - Serverless Functions](modules/lambda/README.md)
7. [API Gateway - API Management](modules/api-gateway/README.md)
8. [S3 - Object Storage](modules/s3/README.md)
9. [SQS - Message Queue](modules/sqs/README.md)
10. [SNS - Notifications](modules/sns/README.md)
11. [DynamoDB - NoSQL Database](modules/dynamodb/README.md)
12. [ALB - Load Balancer](modules/alb/README.md)
13. [Fargate - Serverless Containers](modules/fargate/README.md)
14. [EC2 - Virtual Servers](modules/ec2/README.md)
15. [Step Functions - Workflows](modules/step-functions/README.md)

---

## 🎓 Learning Path

### Beginner (Start Here)
1. VPC & Subnets (understand networking basics)
2. Security Groups (understand firewall)
3. IAM (understand permissions)
4. S3 (simplest storage service)
5. Lambda (simplest compute service)

### Intermediate
6. API Gateway (expose Lambda as API)
7. DynamoDB (simple database)
8. SQS (async messaging)
9. SNS (notifications)
10. KMS (encryption)
11. Secrets Manager (secret storage)

### Advanced
12. ALB (load balancing)
13. Fargate (container orchestration)
14. EC2 (full server management)
15. Step Functions (complex workflows)

---

## 💡 Best Practices

### 1. **One KMS Key or Multiple?**

**Multiple KMS Keys - Recommended**

```
Why? Security isolation!

Example:
- KMS Key 1: For encrypting Secrets Manager secrets
- KMS Key 2: For encrypting S3 buckets
- KMS Key 3: For encrypting DynamoDB tables

Benefit: If one key is compromised, others are safe.
```

**When to Use Single KMS Key:**
- Very small projects
- Development environment
- Cost-sensitive (each key costs $1/month)

### 2. **Multiple IAM Roles or One?**

**Multiple IAM Roles - Always**

```
Why? Principle of Least Privilege!

Example:
- Lambda Execution Role: Only access DynamoDB + S3
- EC2 Instance Role: Only access S3
- Fargate Task Role: Only access Secrets Manager

Benefit: If Lambda is compromised, attacker can't access EC2 resources.
```

### 3. **Public Subnet vs Private Subnet**

```
Public Subnet: Resources can talk to internet
- Use for: ALB, NAT Gateway, Bastion hosts

Private Subnet: Resources CANNOT talk to internet
- Use for: Lambda, Fargate, EC2, Databases

Why? Security! Keep application servers private, only expose load balancer.
```

### 4. **Security Group vs NACL**

```
Security Group: Firewall for individual resources (STATEFUL)
- Simpler, more commonly used
- Rules apply to specific EC2/Lambda/etc

NACL: Firewall for entire subnet (STATELESS)
- More complex
- Rules apply to all resources in subnet

Recommendation: Use Security Groups for most cases.
```

---

## 🔒 Security Checklist

Before deploying to production:

- [ ] All data encrypted at rest (KMS)
- [ ] All data encrypted in transit (TLS/SSL)
- [ ] Secrets never in code (use Secrets Manager)
- [ ] Principle of least privilege (minimal IAM permissions)
- [ ] Private subnets for application tier
- [ ] Security groups limit access (not 0.0.0.0/0)
- [ ] VPC flow logs enabled
- [ ] CloudTrail enabled for audit
- [ ] MFA enabled for all users
- [ ] Regular backups enabled

---

## 💰 Cost Optimization

| Service | Free Tier | Cost After Free Tier |
|---------|-----------|---------------------|
| Lambda | 1M requests/month | $0.20 per 1M requests |
| S3 | 5GB storage | $0.023/GB/month |
| DynamoDB | 25GB storage | $0.25/GB/month |
| API Gateway | 1M calls/month | $3.50 per 1M calls |
| KMS | 20,000 requests/month | $1/key + $0.03/10K requests |
| Secrets Manager | 30-day trial | $0.40/secret/month |
| ALB | None | $16/month + $0.008/LCU-hour |
| Fargate | None | $0.04048/vCPU-hour |
| EC2 t2.micro | 750 hours/month | $8.50/month (t2.micro) |

**Pro Tip**: Start with Lambda + API Gateway (cheapest), scale to Fargate/EC2 if needed.

---

## 🆘 Troubleshooting

### Common Issues

1. **"Access Denied" errors**
   - Check IAM roles/policies
   - Check security group rules
   - Check VPC/subnet configuration

2. **"Timeout" errors**
   - Check security group outbound rules
   - Check subnet route table (NAT gateway)
   - Increase Lambda timeout

3. **"Resource not found"**
   - Check region (resources are region-specific)
   - Check resource exists in AWS Console

---

## 📞 Support

Each module has detailed README with:
- What is this service?
- Why do I need it?
- How to create it?
- How to use it?
- Common issues & solutions

---

Next: [Start with VPC Module →](modules/vpc/README.md)
