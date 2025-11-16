# EC2 (Elastic Compute Cloud) - Virtual Servers in AWS

## What is EC2?

EC2 is like **renting a computer in the cloud**. Instead of buying a physical server, you rent virtual servers (called instances) from AWS.

**Real-World Analogy:**
```
Renting an Apartment (EC2)
├─ Choose size (1BR, 2BR, 3BR) → Instance Type (t3.micro, t3.small, t3.medium)
├─ Choose location (NYC, LA, SF) → Availability Zone (us-east-1a, us-west-2b)
├─ Choose furniture (furnished/empty) → AMI (pre-installed software or blank)
├─ Pay rent monthly → Pay per hour/second
└─ Can upgrade/downgrade anytime → Resize instance
```

## When to Use EC2?

Use EC2 when you need:
1. **Full control** over the operating system (install anything you want)
2. **Long-running applications** (databases, web servers, game servers)
3. **Legacy applications** that can't run in containers or serverless
4. **Specific software** that requires OS-level access
5. **GPU/specialized hardware** for ML/rendering

Don't use EC2 when:
- You just need to run code occasionally → Use Lambda
- You want to avoid server management → Use Fargate
- You need auto-scaling web apps → Use Elastic Beanstalk or Fargate

## EC2 vs Other Compute Options

| Feature | EC2 | Lambda | Fargate |
|---------|-----|--------|---------|
| **Management** | You manage OS | AWS manages everything | AWS manages OS |
| **Cost** | Pay per hour | Pay per request | Pay per second |
| **Startup Time** | 60-180 seconds | 1-10 seconds | 20-100 seconds |
| **Running Time** | Unlimited | 15 min max | Unlimited |
| **Use Case** | Databases, legacy apps | Event-driven code | Containerized apps |

## Should I Create One EC2 Instance or Multiple?

**One EC2 Instance:**
- Development/testing environment
- Small personal projects
- Single-purpose servers (database, monitoring)
- Cost is a concern

**Multiple EC2 Instances:**
- Production applications (high availability)
- Different environments (dev, staging, prod)
- Load balancing (distribute traffic)
- Different instance types for different workloads

**Real-World Example:**
```
E-commerce Application
├─ 3 web servers (t3.medium) → Handle user traffic
├─ 2 app servers (c5.large) → Process orders
├─ 1 database server (r5.xlarge) → Store data
└─ 1 bastion host (t3.micro) → SSH access
```

## Key Concepts

### 1. Instance Types (Size of Your Server)

**Format:** `Family.Size`
- Family = Purpose (t = general, c = compute, r = memory, etc.)
- Size = Resources (nano, micro, small, medium, large, xlarge, etc.)

```
Common Instance Types:
├─ t3.micro    → 1 vCPU, 1 GB RAM   → $7/month  → Dev/test
├─ t3.small    → 2 vCPU, 2 GB RAM   → $15/month → Small apps
├─ t3.medium   → 2 vCPU, 4 GB RAM   → $30/month → Web servers
├─ t3.large    → 2 vCPU, 8 GB RAM   → $60/month → Larger apps
├─ c5.large    → 2 vCPU, 4 GB RAM   → $62/month → CPU-intensive
├─ r5.large    → 2 vCPU, 16 GB RAM  → $100/month → Databases
└─ g4dn.xlarge → 4 vCPU, 16 GB, GPU → $400/month → ML/rendering
```

**Instance Families:**
- **T (t3, t3a)** - General purpose, burstable (good for most apps)
- **C (c5, c6)** - Compute optimized (CPU-heavy workloads)
- **R (r5, r6)** - Memory optimized (databases, caching)
- **M (m5, m6)** - Balanced (mix of CPU and memory)
- **G (g4, g5)** - GPU instances (ML, gaming, rendering)
- **I (i3, i4i)** - Storage optimized (data warehouses)

### 2. AMI (Amazon Machine Image) - What's Pre-installed

AMI is like a **snapshot of a hard drive** with pre-installed software.

```
AMI Types:
├─ Amazon Linux 2023 → AWS's Linux (free, optimized for AWS)
├─ Ubuntu 22.04      → Popular Linux distro
├─ Windows Server    → Windows OS (costs extra)
├─ Custom AMI        → Your own image (pre-configured apps)
└─ Marketplace AMI   → Pre-built (WordPress, databases, etc.)
```

**Real-World Example:**
```
Without AMI:
1. Launch blank server
2. Install Nginx
3. Install Node.js
4. Configure firewall
5. Deploy app
Total: 30 minutes

With Custom AMI:
1. Launch server with everything pre-installed
Total: 2 minutes
```

### 3. Storage (EBS - Elastic Block Store)

**Types of Storage:**

```
gp3 (General Purpose SSD) - Default choice
├─ Performance: 3,000 IOPS, 125 MB/s
├─ Cost: $0.08/GB/month
└─ Use case: Most applications

gp2 (Previous generation)
├─ Performance: Scales with size (3 IOPS per GB)
├─ Cost: $0.10/GB/month
└─ Use case: Legacy apps

io2 (Provisioned IOPS SSD) - High performance
├─ Performance: Up to 64,000 IOPS
├─ Cost: $0.125/GB/month + $0.065/IOPS
└─ Use case: Databases, critical apps

st1 (Throughput Optimized HDD) - Big files
├─ Performance: 500 IOPS, 500 MB/s throughput
├─ Cost: $0.045/GB/month
└─ Use case: Big data, log processing

sc1 (Cold HDD) - Infrequent access
├─ Performance: 250 IOPS, 250 MB/s throughput
├─ Cost: $0.015/GB/month
└─ Use case: Archives, backups
```

**Instance Store (Ephemeral Storage):**
- Free storage attached to instance
- LOST when instance stops (temporary only!)
- Very fast (NVMe SSDs)
- Use for: temporary files, caches, buffers

### 4. Networking

**Public IP vs Private IP:**
```
Private IP (10.0.1.50)
├─ Only accessible within VPC
├─ Free
└─ Use for: Internal communication

Public IP (dynamically assigned)
├─ Changes when instance stops/starts
├─ Free
└─ Use for: Testing, temporary access

Elastic IP (static public IP)
├─ Stays same even if instance stops
├─ Costs $0.005/hour when NOT attached
└─ Use for: Production servers, DNS records
```

**Security Groups (Firewall):**
```
Default (locked down):
├─ Inbound: Nothing allowed
└─ Outbound: Everything allowed

Web Server:
├─ Inbound: Port 80 (HTTP), 443 (HTTPS), 22 (SSH)
└─ Outbound: Everything

Database:
├─ Inbound: Port 3306 (MySQL) from app servers only
└─ Outbound: Nothing (no internet access)
```

### 5. User Data (Startup Script)

User Data runs **once** when instance launches.

```bash
#!/bin/bash
# Update packages
yum update -y

# Install Nginx
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx

# Create welcome page
echo "<h1>Server is running!</h1>" > /usr/share/nginx/html/index.html
```

**Common Uses:**
- Install software
- Configure applications
- Download code from S3
- Register with load balancer
- Join domain/cluster

### 6. Instance States

```
Instance Lifecycle:
├─ pending    → Instance is launching (you're charged)
├─ running    → Instance is running (you're charged)
├─ stopping   → Instance is shutting down
├─ stopped    → Instance is off (no compute charges, storage charges apply)
├─ terminated → Instance is deleted (no charges)
└─ rebooting  → Instance is restarting
```

**Cost Impact:**
- **Running** → Full charges (compute + storage)
- **Stopped** → Storage charges only (~$0.10/GB/month)
- **Terminated** → No charges (instance is deleted)

### 7. Placement Groups

How instances are physically arranged in AWS data centers.

```
Cluster Placement Group
├─ All instances in same rack (low latency)
├─ Same AZ only
└─ Use for: HPC, big data, low-latency apps

Spread Placement Group
├─ Each instance on different hardware (high availability)
├─ Max 7 instances per AZ
└─ Use for: Critical apps, databases

Partition Placement Group
├─ Instances grouped into partitions (different racks)
├─ Up to 7 partitions per AZ
└─ Use for: Hadoop, Cassandra, Kafka
```

### 8. Instance Metadata

Every EC2 instance can access information about itself.

```bash
# Get instance ID
curl http://169.254.169.254/latest/meta-data/instance-id

# Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Get IAM role credentials
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/role-name

# Get user data
curl http://169.254.169.254/latest/user-data
```

**Why This Matters:**
- Applications can discover their own configuration
- Auto-configure based on environment
- Retrieve temporary IAM credentials
- No need to hardcode values

## Common Patterns

### Pattern 1: Simple Web Server

```
Use Case: Host a website or API
├─ Instance Type: t3.small (2 vCPU, 2 GB RAM)
├─ AMI: Amazon Linux 2023
├─ Storage: 8 GB gp3
├─ Security Group: Allow 80 (HTTP), 443 (HTTPS), 22 (SSH)
├─ User Data: Install Nginx/Apache
└─ Cost: ~$15/month
```

### Pattern 2: Auto-Scaling Web Application

```
Use Case: Handle variable traffic
├─ Launch Template: t3.medium with app pre-installed
├─ Auto Scaling Group: Min 2, Max 10 instances
├─ Load Balancer: Distribute traffic
├─ Scaling Policy: CPU > 70% → add instances
└─ Cost: $30-300/month (based on traffic)
```

### Pattern 3: Database Server

```
Use Case: Self-managed database (PostgreSQL, MySQL)
├─ Instance Type: r5.large (2 vCPU, 16 GB RAM)
├─ AMI: Ubuntu with database pre-installed
├─ Storage: 100 GB io2 (high IOPS)
├─ Security Group: Port 5432/3306 from app servers only
├─ Private subnet (no public IP)
├─ Daily snapshots (backups)
└─ Cost: ~$150/month
```

### Pattern 4: Bastion Host (Jump Server)

```
Use Case: Secure SSH access to private instances
├─ Instance Type: t3.micro (1 vCPU, 1 GB RAM)
├─ Public subnet with Elastic IP
├─ Security Group: SSH (22) from your IP only
├─ Private instances: Allow SSH from bastion only
└─ Cost: ~$7/month
```

### Pattern 5: Spot Instances (90% Savings)

```
Use Case: Fault-tolerant, batch processing
├─ Spot Price: 70-90% cheaper than On-Demand
├─ Can be interrupted with 2-minute warning
├─ Use for: CI/CD builds, data processing, rendering
├─ Don't use for: Databases, critical apps
└─ Cost: $1.50/month instead of $15/month
```

## Boot Time and Performance

### Boot Time (Cold Start)

```
EC2 Boot Process:
├─ Request instance          → 0-5 seconds
├─ Allocate hardware         → 5-15 seconds
├─ Boot OS from AMI          → 20-40 seconds
├─ Run user data script      → 10-60 seconds (depends on script)
└─ Application startup       → 5-30 seconds (depends on app)

Total Boot Time: 60-180 seconds (1-3 minutes)
```

**Comparison:**
- **Lambda Cold Start:** 1-10 seconds
- **Fargate Cold Start:** 20-100 seconds
- **EC2 Cold Start:** 60-180 seconds
- **EC2 Warm (already running):** 0 seconds (instant)

**How to Minimize Boot Time:**
1. Use custom AMI with pre-installed software
2. Keep user data script minimal
3. Use faster instance types (c5 vs t3)
4. Pre-warm instances (keep some running)

### Performance Characteristics

**Network Performance:**
```
Instance Type    Network Speed
├─ t3.micro      Up to 5 Gbps (burstable)
├─ t3.small      Up to 5 Gbps
├─ t3.medium     Up to 5 Gbps
├─ m5.large      Up to 10 Gbps
├─ c5.4xlarge    Up to 10 Gbps
└─ c5.24xlarge   100 Gbps
```

**Storage Performance:**
```
gp3 Volume (default):
├─ 3,000 IOPS baseline (125 MB/s)
├─ Can provision up to 16,000 IOPS (1,000 MB/s)
└─ Consistent performance

Instance Store (ephemeral):
├─ NVMe SSD
├─ Very fast (up to 2 million IOPS)
└─ Lost on stop/terminate
```

**CPU Credits (T-series instances):**
```
T-series (t3.micro, t3.small) use CPU credits:

Normal State:
├─ Baseline: 20% CPU usage (always allowed)
├─ Earns credits when below baseline
└─ Spends credits when above baseline

Burst Mode:
├─ Can use 100% CPU temporarily
├─ Uses accumulated credits
└─ Credits refill when idle

Credit Exhausted:
├─ Performance drops to baseline (20%)
└─ Enable Unlimited Mode: Pay extra for bursts
```

## Request Handling and Scaling

### How EC2 Handles Concurrent Requests

```
Single EC2 Instance (t3.medium running Nginx):
├─ Can handle 100-1000 concurrent connections
├─ Depends on: App code, database, memory
└─ Performance degrades as load increases

Question: If 1000 requests come at once, do I get 1000 EC2 instances?

Answer: NO! EC2 doesn't auto-scale by default.

Scenario 1: WITHOUT Auto-Scaling
─────────────────────────────────
Current state: 1 EC2 instance running

T+0s:    1000 requests arrive
         1 instance handling all (overwhelmed, slow)
         Users see: Slow responses, timeouts
         Status: Instance at 100% CPU, crashing

Result: BAD - No new instances created automatically


Scenario 2: WITH Auto-Scaling
──────────────────────────────
Current state: 2 EC2 instances behind load balancer

T+0s:    1000 requests arrive
         Load balancer distributes across 2 instances
         Each handling ~500 requests (struggling, 90% CPU)

T+60s:   CloudWatch alarm triggers (CPU > 70%)
         Auto Scaling launches 2 new instances

T+180s:  New instances booted and healthy
         Load balancer distributes across 4 instances
         Each handling ~250 requests (comfortable, 50% CPU)

T+300s:  Auto Scaling evaluates again
         Still high load, launches 2 more instances

T+480s:  Now 6 instances total
         Each handling ~167 requests (easy, 30% CPU)
         Users see: Fast responses
```

### Scaling Timeline

```
Step-by-Step Scaling Process:

1. CloudWatch Alarm Triggered (60 seconds)
   ├─ Metric: Average CPU > 70% for 2 minutes
   └─ Action: Trigger Auto Scaling policy

2. Auto Scaling Decision (5 seconds)
   ├─ Calculate: How many instances to add?
   └─ Launch new instances

3. Instance Launch (60-180 seconds)
   ├─ Allocate hardware
   ├─ Boot OS
   ├─ Run user data
   └─ Start application

4. Health Checks (30-60 seconds)
   ├─ Instance passes health check
   └─ Load balancer starts sending traffic

5. Total Time: 2-6 minutes from spike to new capacity
```

**This Means:**
- EC2 auto-scaling is NOT instant (unlike Lambda)
- You need to handle traffic spikes during scale-up
- Options:
  1. Over-provision (keep extra instances running)
  2. Use aggressive scaling policies (scale faster)
  3. Increase instance size (bigger instances handle more)
  4. Use caching (CloudFront, ElastiCache)

### Scaling Comparison

```
Scenario: Website goes viral, traffic jumps 0 → 10,000 requests/min

Lambda:
├─ Instant scaling → Handles 10,000 concurrent invocations
├─ Cold start: 1-10 seconds per new invocation
├─ Cost: Pay only for actual requests
└─ Result: ✓ Handles spike perfectly

EC2 Auto-Scaling:
├─ Gradual scaling → 2 instances → 4 → 8 → 16 (over 10 minutes)
├─ Cold start: 60-180 seconds per new instance
├─ Initial instances overwhelmed (first 2-3 minutes)
├─ Cost: Pay for all running instances
└─ Result: ⚠️ Initial slowness, then stable

EC2 Pre-provisioned:
├─ No scaling needed → Already running 20 instances
├─ Instantly handles traffic
├─ Cost: Pay for 20 instances 24/7 (expensive)
└─ Result: ✓ Handles spike, but wasteful

Recommendation:
├─ Unpredictable spikes → Lambda
├─ Predictable traffic → EC2 with Auto-Scaling
└─ Always-on, steady traffic → EC2 (cheapest)
```

## Cost Optimization

### Pricing Models

```
On-Demand (default):
├─ Pay per hour/second
├─ No commitment
├─ Most expensive
└─ Use for: Short-term, unpredictable workloads

Reserved Instances:
├─ 1 or 3 year commitment
├─ 30-70% savings
├─ Upfront/partial/no upfront payment
└─ Use for: Steady-state workloads (databases, always-on apps)

Spot Instances:
├─ 70-90% savings
├─ Can be interrupted with 2-minute warning
├─ Bid on unused capacity
└─ Use for: Batch jobs, CI/CD, fault-tolerant apps

Savings Plans:
├─ Commit to $ amount per hour (e.g., $10/hour for 1 year)
├─ 30-70% savings
├─ Flexible (any instance type/region)
└─ Use for: Mix of workloads
```

### Cost Examples

```
t3.medium (2 vCPU, 4 GB RAM) - 24/7 for 1 month:

On-Demand:        $30.37/month
Reserved (1 year): $18.98/month (37% savings)
Reserved (3 year): $12.19/month (60% savings)
Spot Instance:     $9.11/month (70% savings)
```

### Cost-Saving Tips

```
1. Right-Size Instances
   ❌ Running t3.xlarge when t3.small is enough
   ✓ Monitor CPU/memory, downsize if underutilized
   Savings: 50-75%

2. Use Auto-Scaling
   ❌ Running 10 instances 24/7 (peak capacity)
   ✓ Scale 2-10 based on demand
   Savings: 40-60%

3. Stop Non-Production Instances
   ❌ Dev/test instances running 24/7 (730 hours/month)
   ✓ Stop after work hours (only 40 hours/week = 160 hours/month)
   Savings: 78%

4. Use Reserved for Steady Workloads
   ❌ On-Demand for database server (always running)
   ✓ Reserved Instance (3 year)
   Savings: 60%

5. Use Spot for Batch Jobs
   ❌ On-Demand for CI/CD builds
   ✓ Spot Instances
   Savings: 70-90%

6. Delete Unused EBS Volumes
   ❌ 100 GB unused volumes from deleted instances
   ✓ Delete or create snapshot then delete
   Savings: $10/month per 100 GB

7. Use Newer Instance Types
   ❌ t2.medium ($30/month)
   ✓ t3.medium ($30/month but 20% better performance)
   Savings: Better performance, same cost
```

## Best Practices

### Production Readiness

```
1. High Availability
   ✓ Deploy across multiple Availability Zones
   ✓ Use Auto Scaling (min 2 instances)
   ✓ Use Load Balancer (ALB/NLB)
   ❌ Single instance in one AZ

2. Backups
   ✓ Enable automated EBS snapshots
   ✓ Create custom AMI of configured instances
   ✓ Test restore procedure
   ❌ No backups

3. Monitoring
   ✓ Enable CloudWatch detailed monitoring
   ✓ Set alarms (CPU, memory, disk, network)
   ✓ Use CloudWatch Logs for application logs
   ❌ No monitoring

4. Security
   ✓ Use private subnets for app/database servers
   ✓ Use bastion host for SSH access
   ✓ Minimal security group rules (least privilege)
   ✓ Use IAM roles (not access keys)
   ✓ Enable encryption for EBS volumes
   ❌ Public instances with wide-open security groups

5. Updates
   ✓ Regularly patch OS and applications
   ✓ Use Systems Manager for patch management
   ✓ Test updates in dev/staging first
   ❌ Never update instances
```

### Disaster Recovery

```
Backup Strategy:
├─ Daily automated EBS snapshots (7 day retention)
├─ Weekly custom AMI (30 day retention)
├─ Off-site backup to different region
└─ Documented restore procedure

Recovery Time Objective (RTO):
├─ From snapshot: 5-10 minutes
├─ From AMI: 2-3 minutes
└─ From cross-region backup: 10-15 minutes
```

## Common Mistakes

```
❌ MISTAKE 1: Using public subnets for everything
Example: Database instance with public IP
Security Risk: Exposed to internet, vulnerable to attacks
Solution: Use private subnets for app/database, public only for bastion/ALB

❌ MISTAKE 2: No backups
Example: Instance terminated, all data lost
Impact: Complete data loss, no recovery
Solution: Enable automated EBS snapshots, create AMI

❌ MISTAKE 3: Wide-open security groups
Example: Security group allows 0.0.0.0/0 on all ports
Security Risk: Anyone can access your instance
Solution: Minimal rules (e.g., SSH from your IP only, HTTP/HTTPS from ALB)

❌ MISTAKE 4: Not using IAM roles
Example: Hardcoded AWS credentials in application code
Security Risk: Credentials leaked, compromised
Solution: Attach IAM role to instance, use instance profile

❌ MISTAKE 5: Wrong instance type
Example: Using t3.nano for database (too small)
Impact: Poor performance, crashes, slow queries
Solution: Right-size based on workload (use r5 for databases)

❌ MISTAKE 6: Forgetting to stop dev instances
Example: Dev instances running 24/7
Impact: Unnecessary costs ($30/month → $360/year)
Solution: Stop after work hours, use auto-shutdown scripts

❌ MISTAKE 7: Not using Auto-Scaling
Example: Manual scaling, waking up at 3am to add instances
Impact: Downtime during traffic spikes, manual intervention
Solution: Configure Auto Scaling Group with appropriate policies

❌ MISTAKE 8: Using instance store for critical data
Example: Database on instance store
Impact: Data lost when instance stops
Solution: Use EBS volumes for persistent data

❌ MISTAKE 9: Single instance (no redundancy)
Example: Single production web server
Impact: Downtime when instance fails
Solution: Use Auto Scaling Group with min 2 instances across AZs

❌ MISTAKE 10: Not monitoring
Example: Instance at 100% CPU for hours, no alerts
Impact: Poor user experience, potential crashes
Solution: CloudWatch alarms for CPU, memory, disk
```

## When to Use EC2 vs Alternatives

```
Use EC2 when:
✓ You need full OS control
✓ Running legacy applications
✓ Long-running processes (24/7)
✓ GPU workloads (ML, rendering)
✓ Custom network configurations
✓ Self-managed databases

Use Lambda when:
✓ Event-driven code
✓ Short-running tasks (< 15 min)
✓ Unpredictable/sporadic workloads
✓ Want zero server management

Use Fargate when:
✓ Containerized applications
✓ Want minimal server management
✓ Long-running containers
✓ Microservices architecture

Use RDS instead of EC2 + database when:
✓ Managed database service
✓ Automated backups and patching
✓ Multi-AZ failover
✓ Don't want to manage database

Use Elastic Beanstalk instead of EC2 when:
✓ Simple web app deployment
✓ Don't want infrastructure management
✓ Auto-scaling and load balancing included
```

## Summary

**EC2 in Simple Terms:**
- Rent virtual servers in AWS cloud
- Full control over OS and software
- Pay per hour/second
- Many instance types for different workloads
- Best for: Long-running apps, legacy software, full control

**Key Decisions:**
1. Instance Type → Based on workload (CPU, memory, GPU)
2. AMI → Operating system and pre-installed software
3. Storage → gp3 for most, io2 for databases
4. Networking → Private subnet for security, public only when needed
5. Auto-Scaling → For production, handle traffic spikes
6. Pricing → On-Demand for testing, Reserved for production

**Quick Start:**
1. Choose instance type (start with t3.small)
2. Choose AMI (Amazon Linux 2023 recommended)
3. Configure networking (VPC, subnet, security group)
4. Add storage (8 GB gp3 minimum)
5. Add user data (startup script)
6. Launch and connect via SSH
