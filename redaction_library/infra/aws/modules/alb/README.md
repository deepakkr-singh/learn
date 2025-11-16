# ALB (Application Load Balancer) - Traffic Distributor

## 🎯 What is ALB?

**Simple Explanation:**
ALB (Application Load Balancer) is like a traffic cop at a busy intersection. Instead of all cars (users) trying to reach the same destination (server), the traffic cop directs them to multiple available roads (servers) to balance the load and prevent congestion.

Think of it as:
- **Without ALB** = One restaurant with one cash register (customers wait in long line)
- **With ALB** = Same restaurant with 5 cash registers (customers distributed evenly, no waiting)

**Real-World Analogy:**
- **Customer Service Call Center** = ALB routes incoming calls to available agents
- **Airport Security** = TSA directs passengers to shortest checkpoint line
- **Grocery Store** = "Next customer please" system across multiple checkout lanes

**Technical Definition:**
An Application Load Balancer distributes incoming HTTP/HTTPS traffic across multiple targets (EC2 instances, containers, Lambda functions, or IP addresses) in multiple Availability Zones. It operates at Layer 7 (application layer) and can make routing decisions based on URL paths, hostnames, headers, and query parameters.

---

## 🤔 Why Do I Need ALB?

### Without ALB (Single Server):

```
PROBLEMS with single server:

1. Single point of failure (server dies → app dies)
2. Can't handle high traffic (limited capacity)
3. No zero-downtime deployments
4. No geographic redundancy
5. Slow for some users (far from server)
6. Manual failover required

Example: E-commerce site during Black Friday
Server 1 (alone) → 10,000 requests/sec → CRASH!
→ Website down
→ Revenue lost
```

---

### With ALB:

```
BENEFITS:

✅ High availability (multiple servers in multiple AZs)
✅ Auto-scaling (add/remove servers based on traffic)
✅ Health checks (remove unhealthy servers automatically)
✅ Zero-downtime deployments (rolling updates)
✅ SSL/TLS termination (ALB handles HTTPS encryption)
✅ Path-based routing (/api → API servers, /admin → admin servers)
✅ Sticky sessions (same user → same server)
✅ Built-in security (AWS Shield DDoS protection)

Example: Same Black Friday scenario
ALB → 10,000 requests/sec → Distributed across 10 servers
→ Each server: 1,000 req/sec (manageable)
→ Website stays up!
```

**Cost:**
- ALB: ~$16/month base + $0.008 per LCU-hour
- Cheaper than API Gateway for high traffic (> 10M requests/month)
- More expensive than API Gateway for low traffic

---

## 📊 Real-World Example

### Scenario: E-commerce Website (Black Friday Sale)

**Without ALB:**
```
Internet → Single EC2 Instance (8GB RAM, 4 vCPU)

Normal traffic: 100 req/sec → Works fine
Black Friday: 5,000 req/sec → Server CRASHES!

Problem:
- Can't handle sudden traffic spike
- Customers get error pages
- Revenue lost
- Manual intervention needed to restart server
```

**With ALB:**
```
Internet → ALB → 5 EC2 Instances (auto-scaled to 20 during sale)

Normal traffic: 100 req/sec → ALB routes to 2 instances (50 req/sec each)
Black Friday: 5,000 req/sec → ALB routes to 20 instances (250 req/sec each)

Benefits:
- Automatic scaling (Auto Scaling Group monitors CPU/memory)
- If 1 server dies, ALB removes it and routes to healthy ones
- Zero downtime during deployments
- SSL certificate managed at ALB level (not on each server)
```

**Cost Example:**
- Without ALB: 1 large EC2 instance (c5.4xlarge) = $490/month
- With ALB: ALB ($25/month) + 5 small EC2 (t3.medium × 5) = $170/month
- **Savings: 65%!** (plus better reliability)

---

## 🔑 Key Concepts

### 1. Target Groups

**What is it?**
A target group is a set of servers (EC2, Fargate, Lambda, IP addresses) that ALB sends traffic to.

```
ALB
  └─ Target Group 1 (API Servers)
      ├─ EC2-1 (healthy ✓)
      ├─ EC2-2 (healthy ✓)
      └─ EC2-3 (unhealthy ✗ - not receiving traffic)
```

**Example:**
```hcl
resource "aws_lb_target_group" "api" {
  name     = "api-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
```

---

### 2. Listeners

**What is it?**
A listener checks for connection requests from clients on a specific port and protocol.

```
ALB
  ├─ Listener 1: Port 80 (HTTP) → Redirect to HTTPS
  ├─ Listener 2: Port 443 (HTTPS) → Forward to Target Group
  └─ Listener 3: Port 8080 (Custom) → Forward to Admin Target Group
```

**Example:**
```hcl
# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
```

---

### 3. Health Checks

**What is it?**
ALB periodically sends requests to check if targets are healthy. Unhealthy targets don't receive traffic.

```
Health Check Process:

Every 30 seconds:
  ALB → GET /health → Server 1
  Server 1 → 200 OK → Healthy ✓

  ALB → GET /health → Server 2
  Server 2 → 500 Error → Mark as suspect
  (Wait 30 seconds)

  ALB → GET /health → Server 2
  Server 2 → 500 Error → Mark as UNHEALTHY ✗
  → Remove from rotation (no more traffic)
```

**Settings:**
- **Interval**: How often to check (30 seconds default)
- **Timeout**: How long to wait for response (5 seconds default)
- **Healthy threshold**: Consecutive successes needed to mark healthy (2 default)
- **Unhealthy threshold**: Consecutive failures to mark unhealthy (2 default)

---

### 4. Routing Rules (Path-Based, Host-Based)

**Path-Based Routing:**
Route based on URL path.

```
https://example.com/api/*      → API Target Group
https://example.com/admin/*    → Admin Target Group
https://example.com/static/*   → Static Target Group (S3)
```

**Host-Based Routing:**
Route based on hostname.

```
api.example.com     → API Target Group
admin.example.com   → Admin Target Group
www.example.com     → Web Target Group
```

**Example:**
```hcl
# Path-based rule
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
```

---

### 5. Sticky Sessions (Session Affinity)

**What is it?**
Ensure the same user always connects to the same server.

**Why needed?**
Some applications store session data locally on server (not in database).

```
Without Sticky Sessions:
User → Request 1 → Server 1 (creates session)
User → Request 2 → Server 2 (no session found, user logged out!)

With Sticky Sessions:
User → Request 1 → Server 1 (creates session)
User → Request 2 → Server 1 (session found, user stays logged in!)
User → Request 3 → Server 1 (same server)
```

**Configuration:**
```hcl
resource "aws_lb_target_group" "app" {
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400  # 1 day
    enabled         = true
  }
}
```

---

### 6. SSL/TLS Termination

**What is it?**
ALB handles HTTPS encryption/decryption, backend servers receive plain HTTP.

```
Internet (HTTPS) → ALB (decrypts) → Backend (HTTP)
                   ↑
                SSL Certificate
                (from ACM)
```

**Benefits:**
- ✅ SSL certificate managed in one place (ALB)
- ✅ Backend servers don't need SSL setup
- ✅ Better performance (offload encryption to ALB)

---

## 🛠️ Common ALB Patterns

### Pattern 1: Internet-Facing ALB (Public Application)

**Use Case:** E-commerce website, public APIs

```hcl
resource "aws_lb" "public" {
  name               = "public-alb"
  load_balancer_type = "application"
  internal           = false  # Internet-facing
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id]
  security_groups    = [aws_security_group.alb_public.id]

  enable_deletion_protection = true
  enable_http2               = true

  tags = {
    Name        = "Public ALB"
    Environment = "prod"
  }
}

# Security Group: Allow HTTPS from anywhere
resource "aws_security_group" "alb_public" {
  name   = "alb-public-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
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
```

---

### Pattern 2: Internal ALB (Private Application)

**Use Case:** Admin panels, internal dashboards

```hcl
resource "aws_lb" "private" {
  name               = "private-alb"
  load_balancer_type = "application"
  internal           = true  # Internal only
  subnets            = [var.private_subnet_a_id, var.private_subnet_b_id]
  security_groups    = [aws_security_group.alb_private.id]

  tags = {
    Name        = "Private ALB"
    Environment = "prod"
  }
}

# Security Group: Allow only from VPN/company network
resource "aws_security_group" "alb_private" {
  name   = "alb-private-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Company network only
  }
}
```

---

### Pattern 3: Multi-Path Routing

**Use Case:** Microservices architecture

```hcl
# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Rule 1: /api/* → API servers
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# Rule 2: /admin/* → Admin servers
resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }
}
```

---

## 🤔 Should I Create One ALB or Multiple ALBs?

### The Question

Your company has:
- Public website
- Public API
- Internal admin panel
- Internal monitoring dashboard

Do you create:
- **Option A**: One ALB for everything
- **Option B**: Separate ALB for each application
- **Option C**: One public ALB + one internal ALB

**Short Answer**: **Option C** (One public ALB for internet-facing apps + One internal ALB for private apps)

---

### Option A: Single ALB for Everything

```
One ALB
  ├─ Listener 1 (Port 443): Public website
  ├─ Listener 2 (Port 8080): Public API
  ├─ Listener 3 (Port 9000): Internal admin
  └─ Listener 4 (Port 9001): Internal monitoring
```

**Pros:**
- ✅ Lower cost ($16/month for one ALB vs $64/month for four)
- ✅ Simpler infrastructure

**Cons:**
- ❌ Security risk (mixing public and private traffic)
- ❌ Complex routing rules
- ❌ Blast radius (one ALB failure affects everything)

**Recommendation:** ❌ **Avoid this approach**

---

### Option B: Separate ALB for Each Application

```
ALB 1: Public website
ALB 2: Public API
ALB 3: Internal admin
ALB 4: Internal monitoring
```

**Pros:**
- ✅ Complete isolation
- ✅ Independent scaling
- ✅ Blast radius contained

**Cons:**
- ❌ High cost ($64/month for 4 ALBs)
- ❌ More complexity to manage

**Recommendation:** 🟡 **Only for very large companies**

---

### Option C: Public + Internal ALBs (RECOMMENDED)

```
Public ALB (internet-facing)
  ├─ /api/* → API servers
  └─ /* → Website servers

Internal ALB (private)
  ├─ /admin/* → Admin servers
  └─ /monitoring/* → Monitoring servers
```

**Pros:**
- ✅ Security isolation (public vs private)
- ✅ Reasonable cost ($32/month for 2 ALBs)
- ✅ Simple to manage

**Cons:**
- ⚠️ Still share ALB within same tier

**Recommendation:** ✅ **Best balance for most companies**

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Not Using Multiple Availability Zones

```hcl
# WRONG - Only one subnet (one AZ)
resource "aws_lb" "bad" {
  name    = "single-az-alb"
  subnets = [var.public_subnet_a_id]  # Only one AZ!
  # If AZ goes down → ALB down!
}
```

**Fix:**
```hcl
resource "aws_lb" "good" {
  name    = "multi-az-alb"
  subnets = [
    var.public_subnet_a_id,  # us-east-1a
    var.public_subnet_b_id   # us-east-1b
  ]
  # High availability across multiple AZs
}
```

---

### ❌ Mistake 2: Not Enabling Deletion Protection (Production)

```hcl
# WRONG - Can accidentally delete ALB
resource "aws_lb" "bad" {
  name = "prod-alb"
  # Missing deletion protection!
}
```

**Fix:**
```hcl
resource "aws_lb" "good" {
  name = "prod-alb"
  enable_deletion_protection = true  # Can't delete without disabling first
}
```

---

### ❌ Mistake 3: Allowing HTTP (Not Redirecting to HTTPS)

```hcl
# WRONG - Allowing unencrypted HTTP traffic
resource "aws_lb_listener" "bad" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

**Fix:**
```hcl
# HTTP listener that redirects to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

---

## 🎯 Best Practices

1. **Use Multiple AZs** (always use at least 2 availability zones)
2. **Enable Deletion Protection** (for production ALBs)
3. **Force HTTPS** (redirect HTTP → HTTPS)
4. **Enable Access Logs** (troubleshoot and analyze traffic)
5. **Use WAF** (protect against DDoS, SQL injection, XSS)
6. **Health Check Tuning** (adjust interval and thresholds)
7. **Set Up Alarms** (monitor unhealthy targets, high latency)

---

## 💰 ALB Pricing

**Hourly Cost:**
- ALB: $0.0225/hour = ~$16/month

**LCU (Load Balancer Capacity Unit) Cost:**
- $0.008 per LCU-hour

**What is LCU?**
LCU measures:
1. New connections per second
2. Active connections per minute
3. Processed bytes (bandwidth)
4. Rule evaluations per second

**Examples:**
```
Small App (1,000 requests/min):
- ALB: $16/month
- LCU: ~$6/month
Total: ~$22/month

Medium App (10,000 requests/min):
- ALB: $16/month
- LCU: ~$50/month
Total: ~$66/month

Large App (100,000 requests/min):
- ALB: $16/month
- LCU: ~$500/month
Total: ~$516/month
```

**Free Tier:** None (ALB is not included in free tier)

---

**Next**: See complete implementations in [alb_create.tf](./alb_create.tf)
