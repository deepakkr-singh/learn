# Fargate - Serverless Containers

## 🎯 What is Fargate?

**Simple Explanation:**
Fargate is like Uber for Docker containers. You tell AWS "I need to run this container," and AWS runs it for you without you managing any servers. You don't worry about EC2 instances, scaling, or server maintenance - just run your containers.

Think of it as:
- **EC2 (Traditional)** = Owning a car (you maintain it, park it, pay for gas even when parked)
- **Fargate** = Uber (you pay only when you use it, no maintenance, someone else handles everything)

**Real-World Analogy:**
- **EC2** = Owning a restaurant kitchen (buy equipment, hire chefs, maintain everything)
- **Fargate** = Ghost kitchen/cloud kitchen (pay per order, someone else manages infrastructure)
- **Lambda** = Food delivery app (even simpler, but limited to specific tasks)

**Technical Definition:**
AWS Fargate is a serverless compute engine for containers that works with Amazon ECS (Elastic Container Service) and EKS (Elastic Kubernetes Service). It removes the need to provision and manage servers, letting you focus on building and deploying containerized applications.

---

## 🤔 Why Do I Need Fargate?

### Without Fargate (EC2 + Docker):

```
PROBLEMS with managing EC2 instances:

1. Manual server management (OS patches, security updates)
2. Capacity planning (how many instances?)
3. Pay for idle servers (even when not running containers)
4. Complex auto-scaling setup
5. Server failures require manual intervention
6. Wasted resources (over-provisioning for peak traffic)

Example: Running a microservice
- Buy 3 EC2 instances (t3.medium) = $75/month
- Only 30% utilized on average
- Wasted cost: $52.50/month!
```

---

### With Fargate:

```
BENEFITS:

✅ Serverless (no EC2 instances to manage)
✅ Pay only for what you use (per second billing)
✅ Auto-scaling built-in (scales containers, not servers)
✅ No capacity planning needed
✅ AWS manages infrastructure (OS patches, security)
✅ Right-sized resources (request exactly what you need)
✅ Faster deployments (no server provisioning)

Example: Same microservice
- Fargate: ~$30/month (only for actual usage)
- Savings: 60%!
```

**Cost:**
- vCPU: $0.04048/hour
- Memory: $0.004445/GB/hour
- Example: 1 vCPU + 2GB RAM = ~$35/month (if running 24/7)
- But you can stop tasks when not needed!

---

## 📊 Real-World Example

### Scenario: E-commerce Backend API (Microservices)

**EC2 Approach (Old Way):**
```
3 EC2 instances (t3.medium) running 24/7:
- Instance 1: Auth service + User service
- Instance 2: Order service + Payment service
- Instance 3: Inventory service + Notification service

Problems:
- All services share same server (resource contention)
- Can't scale individual services independently
- Wasted resources at night (low traffic)
- Manual deployment to each instance

Cost: $75/month (running 24/7)
```

**Fargate Approach (Better Way):**
```
6 independent Fargate tasks:
- Task 1: Auth service (0.25 vCPU, 512MB) → Only during login hours
- Task 2: User service (0.5 vCPU, 1GB) → Scales 1-5 based on load
- Task 3: Order service (1 vCPU, 2GB) → Scales 2-20 during sales
- Task 4: Payment service (1 vCPU, 2GB) → Always 2 tasks (high availability)
- Task 5: Inventory service (0.5 vCPU, 1GB) → 1 task normally, 5 during peak
- Task 6: Notification service (0.25 vCPU, 512MB) → Event-driven scaling

Benefits:
- Each service scales independently
- Pay only for what you use
- No idle servers at night
- Zero-downtime deployments

Cost: ~$45/month (40% savings)
Savings during low traffic: 70%!
```

---

## 🔑 Key Concepts

### 1. Tasks and Services

**Task:**
A single running container (or group of containers that run together).

```
Task = One instance of your application

Example:
Task 1: nginx container + app container (running together)
Task 2: Another copy of same containers
Task 3: Another copy...
```

**Service:**
Manages multiple tasks (ensures desired number of tasks are always running).

```
Service = Manager that maintains tasks

Example:
Service: "web-api"
  ├─ Desired count: 3 tasks
  ├─ Task 1 (healthy ✓)
  ├─ Task 2 (healthy ✓)
  └─ Task 3 (healthy ✓)

If Task 2 crashes → Service automatically starts new Task 4
```

---

### 2. Task Definitions

**What is it?**
A blueprint for your container (like a recipe).

```
Task Definition includes:
- Which Docker image to use
- How much CPU/memory needed
- Environment variables
- Port mappings
- IAM role for permissions
- Logging configuration
```

**Example:**
```json
{
  "family": "web-api",
  "containerDefinitions": [{
    "name": "app",
    "image": "myapp:latest",
    "cpu": 256,
    "memory": 512,
    "portMappings": [{
      "containerPort": 8080,
      "protocol": "tcp"
    }],
    "environment": [
      {"name": "ENV", "value": "production"}
    ]
  }]
}
```

---

### 3. CPU and Memory Configurations

**Valid Combinations:**
Fargate has specific CPU/memory combinations you must use.

```
CPU → Memory options

0.25 vCPU → 512MB, 1GB, 2GB
0.5 vCPU  → 1GB, 2GB, 3GB, 4GB
1 vCPU    → 2GB, 3GB, 4GB, 5GB, 6GB, 7GB, 8GB
2 vCPU    → 4GB to 16GB (1GB increments)
4 vCPU    → 8GB to 30GB (1GB increments)
```

**How to choose:**
```
Small API (Node.js):     0.25 vCPU, 512MB  = $9/month
Medium API (Python):     0.5 vCPU, 1GB     = $18/month
Large API (Java):        1 vCPU, 2GB       = $35/month
Database (PostgreSQL):   2 vCPU, 8GB       = $105/month
ML Service:              4 vCPU, 16GB      = $210/month
```

---

### 4. Networking Modes

**awsvpc (Only mode for Fargate):**
Each task gets its own ENI (Elastic Network Interface) with its own private IP.

```
VPC (10.0.0.0/16)
  └─ Private Subnet (10.0.1.0/24)
      ├─ Task 1: IP 10.0.1.10
      ├─ Task 2: IP 10.0.1.11
      └─ Task 3: IP 10.0.1.12

Each task has its own security group
```

---

### 5. Service Discovery

**What is it?**
Automatically register tasks in Route53 so other services can find them.

```
Without Service Discovery:
Service A needs to talk to Service B
→ How does A find B's IP? (IP changes when tasks restart!)

With Service Discovery:
Service A calls: http://service-b.local:8080
→ AWS automatically resolves to current IP of Service B
```

**Example:**
```hcl
resource "aws_service_discovery_service" "api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

# Now you can call: http://api.myapp.local
```

---

### 6. Auto-Scaling

**Target Tracking:**
Automatically scale based on metrics.

```
Auto-Scaling Rule:
- If CPU > 70% → Add more tasks
- If CPU < 30% → Remove tasks
- Min tasks: 2
- Max tasks: 10

Example:
Normal load: 2 tasks (CPU 30%)
Lunch rush:  6 tasks (CPU 65%)
Night time:  2 tasks (CPU 15%)
```

**Scheduled Scaling:**
Scale at specific times.

```
Monday-Friday 9 AM: Scale to 10 tasks
Monday-Friday 6 PM: Scale to 2 tasks
Weekend:            Scale to 1 task
```

---

## 🛠️ Common Fargate Patterns

### Pattern 1: Simple API Service

**Use Case:** REST API backend

```hcl
resource "aws_ecs_cluster" "main" {
  name = "api-cluster"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "api-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"   # 0.25 vCPU
  memory                   = "512"   # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "api"
    image = "myapp/api:latest"
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
    environment = [
      {name = "ENV", value = "production"}
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/api"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "api"
      }
    }
  }])
}

resource "aws_ecs_service" "api" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.private_subnet_a_id, var.private_subnet_b_id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }
}
```

---

### Pattern 2: Scheduled Task (Cron Job)

**Use Case:** Nightly database backup

```hcl
resource "aws_cloudwatch_event_rule" "nightly_backup" {
  name                = "nightly-backup"
  schedule_expression = "cron(0 2 * * ? *)"  # 2 AM daily
}

resource "aws_cloudwatch_event_target" "backup_task" {
  rule      = aws_cloudwatch_event_rule.nightly_backup.name
  arn       = aws_ecs_cluster.main.arn
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.backup.arn
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = [var.private_subnet_a_id]
      security_groups  = [aws_security_group.backup.id]
      assign_public_ip = false
    }
  }
}
```

---

### Pattern 3: Multi-Container Task (Sidecar)

**Use Case:** Application + Log forwarder

```hcl
resource "aws_ecs_task_definition" "app_with_sidecar" {
  family                   = "app-sidecar"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"   # 0.5 vCPU (shared)
  memory                   = "1024"  # 1GB (shared)

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "myapp:latest"
      cpu   = 256  # Half of total CPU
      memory = 512  # Half of total memory
      portMappings = [{
        containerPort = 8080
      }]
    },
    {
      name  = "log-forwarder"
      image = "fluent/fluentd:latest"
      cpu   = 256
      memory = 512
      # Sidecar reads logs from app container
    }
  ])
}
```

---

## ⚡ Cold Start, Concurrency & Scaling Behavior

### Cold Start Time

**What is cold start?**
Time it takes to start a new Fargate task from zero.

```
Cold Start Process:
1. Pull Docker image from ECR → 10-30 seconds
2. Start container → 5-10 seconds
3. Application initialization → varies (5-60 seconds)

Total Cold Start: 20-100 seconds (depends on image size and app)
```

**Comparison:**
```
Lambda Cold Start:     1-10 seconds (small functions)
Fargate Cold Start:    20-100 seconds (containers)
EC2 Boot:             60-180 seconds (full servers)
```

**How to minimize:**
```
✅ Use smaller Docker images (Alpine Linux vs Ubuntu)
   - Ubuntu image: 1.5GB → 30 second pull
   - Alpine image: 100MB → 5 second pull

✅ Keep minimum tasks running (avoid scaling to zero)
   - Min tasks: 1 (always warm, ~$18/month)
   - Min tasks: 0 (cold start every time, but save money)

✅ Optimize application startup
   - Load configs lazily
   - Cache dependencies
   - Use health check start period
```

---

### Concurrency Model

**How many requests can one Fargate task handle?**

Unlike Lambda (which handles 1 request per invocation), Fargate tasks are long-running and handle multiple concurrent requests.

```
Single Fargate Task (API server):
- Can handle: 10-1000+ concurrent requests
- Depends on: Application code, CPU/memory, request complexity

Example API (Node.js, 0.5 vCPU, 1GB):
├─ Request 1 → Processing
├─ Request 2 → Processing
├─ Request 3 → Processing
├─ ...
└─ Request 50 → Processing (all at same time!)
```

**Key Difference from Lambda:**
```
Lambda:
- 100 requests → 100 Lambda invocations (parallel)
- Each handles 1 request at a time

Fargate:
- 100 requests → 1-10 Fargate tasks (depends on load)
- Each task handles 10-50 concurrent requests
```

---

### Scaling Behavior

**Question: If 100 requests come at once, do I get 100 Fargate tasks?**

**Answer: NO!** Fargate doesn't scale per request. It scales per task based on **CPU/memory utilization**.

```
Scenario: 100 requests arrive simultaneously

Current state:
- 2 Fargate tasks running
- Each can handle ~50 concurrent requests
- Total capacity: ~100 requests ✓

What happens:
1. ALB distributes requests:
   - Task 1: Receives 50 requests
   - Task 2: Receives 50 requests

2. CPU monitoring (Auto-scaling watches CPU):
   - Task 1 CPU: 85% (high!)
   - Task 2 CPU: 85% (high!)
   - Average CPU: 85% > 70% threshold

3. Auto-scaling triggers:
   - Wait 60 seconds (scale_out_cooldown)
   - If still high → Launch 2 more tasks
   - Now: 4 tasks total

4. New distribution:
   - Each task now handles ~25 requests
   - CPU drops to ~45%
   - System stable
```

**Timeline:**
```
T+0s:    100 requests arrive
         2 tasks handling load (struggling, 85% CPU)

T+60s:   Auto-scaling alarm triggers
         Launching 2 new tasks...

T+90s:   New tasks starting (pulling image)

T+120s:  New tasks ready
         4 tasks now handling load (comfortable, 45% CPU)
```

**Problem: What happens during the 2-minute gap?**

```
Options:

1. Tasks handle the load (slower responses)
   - Response time: 500ms → 2000ms
   - Some requests timeout
   - User sees slow performance

2. Pre-scale (anticipate traffic)
   - Schedule scaling before traffic spike
   - Example: Scale to 10 tasks before Black Friday sale
   - Costs more but no performance degradation

3. Use provisioned scaling (target tracking)
   - Set aggressive targets (50% CPU instead of 70%)
   - System scales up faster
```

---

### Scaling Examples

**Example 1: Gradual Traffic Increase**
```
Time    | Requests | CPU  | Tasks | Action
--------|----------|------|-------|---------------------------
9:00 AM | 100      | 40%  | 2     | Normal operation
10:00AM | 500      | 75%  | 2     | CPU high, scaling up...
10:01AM | 500      | 75%  | 4     | New tasks launched
10:05AM | 500      | 38%  | 4     | Stable
11:00AM | 200      | 25%  | 4     | CPU low, scaling down...
11:06AM | 200      | 50%  | 2     | Tasks reduced

Cost: $36/month (2 tasks) + $72 for 1 hour peak = $39/month
```

**Example 2: Sudden Traffic Spike (DDoS or viral event)**
```
Time    | Requests | CPU  | Tasks | Action
--------|----------|------|-------|---------------------------
2:00 PM | 100      | 40%  | 2     | Normal
2:01 PM | 10,000   | 100% | 2     | OVERLOAD! Tasks struggling
2:02 PM | 10,000   | 100% | 4     | Scaling up (not enough)
2:03 PM | 10,000   | 100% | 8     | Still scaling...
2:04 PM | 10,000   | 95%  | 16    | Almost there...
2:05 PM | 10,000   | 75%  | 20    | MAX CAPACITY REACHED

Problem: 4 minutes of degraded performance!

Solution: Use WAF rate limiting or CloudFront
```

**Example 3: Scheduled Scaling (Predictable Traffic)**
```
# Scale up before traffic spike
resource "aws_appautoscaling_scheduled_action" "scale_up" {
  name               = "scale-up-morning"
  service_namespace  = "ecs"
  resource_id        = "service/my-cluster/api-service"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = "cron(0 8 * * MON-FRI *)"  # 8 AM weekdays

  scalable_target_action {
    min_capacity = 10
    max_capacity = 50
  }
}

# Scale down after hours
resource "aws_appautoscaling_scheduled_action" "scale_down" {
  name               = "scale-down-evening"
  schedule           = "cron(0 18 * * MON-FRI *)"  # 6 PM weekdays

  scalable_target_action {
    min_capacity = 2
    max_capacity = 10
  }
}

Cost Savings: $300/month → $100/month (67% reduction)
```

---

### Lambda vs Fargate Scaling Comparison

```
Scenario: 1000 requests arrive at once

Lambda:
├─ Instant scaling → 1000 invocations in parallel
├─ Cold start: 1-10 seconds for each new invocation
├─ Each handles 1 request
├─ Cost: $0.20 per 1M requests
└─ Best for: Spiky, unpredictable traffic

Fargate:
├─ Gradual scaling → 2 tasks → 4 tasks → 8 tasks (over 5 minutes)
├─ Cold start: 20-100 seconds per new task
├─ Each handles 50-100 concurrent requests
├─ Cost: $18/month per task (if running 24/7)
└─ Best for: Sustained traffic, long-running processes

Verdict:
- Sudden spike (0 → 1000 requests):    Lambda wins (instant scale)
- Sustained load (1000 requests/min):  Fargate wins (cheaper)
- Unpredictable (0-1000-0-1000):      Lambda wins (scales to zero)
- Constant (500 requests/min):         Fargate wins (always warm)
```

---

### Best Practices for Production

```
1. Never scale to zero in production
   ✅ Min tasks: 2 (high availability)
   ❌ Min tasks: 0 (save money but slow cold starts)

2. Set aggressive health check grace periods
   ✅ health_check_grace_period_seconds = 300 (5 minutes)
   ❌ health_check_grace_period_seconds = 10 (tasks killed during startup)

3. Use smaller Docker images
   ✅ Alpine-based: 50-200MB (fast pull)
   ❌ Ubuntu-based: 1-2GB (slow pull)

4. Pre-scale for known traffic
   ✅ Schedule scaling before Black Friday
   ❌ Let auto-scaling react during sale (too slow)

5. Set proper auto-scaling targets
   ✅ CPU target: 50-60% (aggressive, fast scaling)
   ❌ CPU target: 90% (conservative, slow scaling, poor UX)

6. Monitor scaling metrics
   ✅ Set CloudWatch alarms for:
      - Task count (detect scaling issues)
      - CPU utilization (ensure not overloaded)
      - Response time (user experience)
```

---

## 🤔 Should I Use Fargate or EC2 or Lambda?

### The Question

You need to run a containerized application. What do you choose?

**Short Answer**:
- **Lambda** for event-driven functions (< 15 min runtime)
- **Fargate** for long-running containers, microservices
- **EC2** for full control, cost optimization at very large scale

---

### Option A: Lambda

```
When to use:
✅ Event-driven (S3 upload, API call, schedule)
✅ Short-lived (< 15 minutes)
✅ Stateless
✅ No complex dependencies
✅ Small code size (< 250MB unzipped)

Cost: $0.20 per 1M requests + $0.0000166667/GB-sec

Examples:
- Image resize on S3 upload
- API endpoints (CRUD operations)
- Scheduled cleanup tasks
- Webhook handlers
```

---

### Option B: Fargate (RECOMMENDED for most containers)

```
When to use:
✅ Long-running services (APIs, web servers)
✅ Microservices architecture
✅ Containers (Docker)
✅ Predictable/variable traffic (auto-scales)
✅ Don't want to manage servers
✅ Modern applications

Cost: ~$35/month per task (1 vCPU, 2GB, 24/7)

Examples:
- REST API backends
- WebSocket servers
- Microservices
- Background workers
- Scheduled jobs
```

---

### Option C: EC2

```
When to use:
✅ Very high scale (100+ containers)
✅ Need full control (custom OS, kernel)
✅ Cost optimization at massive scale
✅ Legacy applications
✅ Reserved Instance savings

Cost: ~$15/month (t3.medium) but must manage servers

Examples:
- Large-scale production (1000s of containers)
- Special compliance requirements
- Custom networking/OS
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Using Public Subnets for Tasks

```hcl
# WRONG - Tasks in public subnet
resource "aws_ecs_service" "bad" {
  network_configuration {
    subnets          = [var.public_subnet_id]
    assign_public_ip = true  # Security risk!
  }
}
```

**Fix:**
```hcl
resource "aws_ecs_service" "good" {
  network_configuration {
    subnets          = [var.private_subnet_id]
    assign_public_ip = false  # Tasks in private subnet
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn  # ALB in public subnet
    # ...
  }
}
```

---

### ❌ Mistake 2: Not Setting Resource Limits

```hcl
# WRONG - No CPU/memory limits
resource "aws_ecs_task_definition" "bad" {
  # Missing cpu and memory!
  # Tasks will fail to start
}
```

**Fix:**
```hcl
resource "aws_ecs_task_definition" "good" {
  cpu    = "256"   # Required for Fargate
  memory = "512"   # Required for Fargate
}
```

---

### ❌ Mistake 3: Not Enabling CloudWatch Logs

```hcl
# WRONG - No logging
container_definitions = jsonencode([{
  name  = "app"
  image = "myapp:latest"
  # Missing logConfiguration!
  # Can't debug issues!
}])
```

**Fix:**
```hcl
container_definitions = jsonencode([{
  name  = "app"
  image = "myapp:latest"
  logConfiguration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = "/ecs/app"
      "awslogs-region"        = "us-east-1"
      "awslogs-stream-prefix" = "app"
    }
  }
}])
```

---

## 🎯 Best Practices

1. **Use Private Subnets** (tasks behind ALB, not directly exposed)
2. **Enable CloudWatch Logs** (always log container output)
3. **Set Health Checks** (ALB + ECS health checks)
4. **Use Task Role** (grant minimal IAM permissions)
5. **Enable Auto-Scaling** (scale based on CPU/memory)
6. **Use Service Discovery** (for inter-service communication)
7. **Tag Everything** (cost tracking and resource management)

---

## 💰 Fargate Pricing

**Compute:**
- vCPU: $0.04048/hour
- Memory: $0.004445/GB/hour

**Examples:**
```
Tiny Task (0.25 vCPU, 512MB):
- vCPU: $0.04048 × 0.25 = $0.01012/hour
- Memory: $0.004445 × 0.5 = $0.002223/hour
Total: ~$0.0123/hour = ~$9/month (24/7)

Small Task (0.5 vCPU, 1GB):
Total: ~$18/month (24/7)

Medium Task (1 vCPU, 2GB):
Total: ~$35/month (24/7)

Large Task (2 vCPU, 8GB):
Total: ~$105/month (24/7)
```

**Spot Fargate (70% cheaper):**
- Same as regular Fargate but can be interrupted
- Use for non-critical workloads

---

**Next**: See complete implementations in [fargate_create.tf](./fargate_create.tf)
