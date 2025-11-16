# RDS (Relational Database Service) - Managed SQL Databases

## 🎯 What is RDS?

**Simple Explanation:**
RDS is like having a professional database administrator (DBA) managing your SQL database 24/7. Instead of installing PostgreSQL or MySQL on a server yourself, AWS handles all the hard parts: backups, updates, scaling, and maintenance.

Think of it as:
- **Self-managed database** = Buying and maintaining your own car
- **RDS** = Uber/Lyft - someone else handles the maintenance, you just use it

**Real-World Analogy:**
- **Traditional database** = Installing PostgreSQL on your laptop, manually backing up, manually updating, crashes when laptop dies
- **RDS** = AWS installs PostgreSQL for you, auto-backups daily, auto-updates, runs on redundant servers, you just connect and use it

**Technical Definition:**
Amazon RDS is a managed relational database service that simplifies setup, operation, and scaling of databases. It supports PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server with automated backups, patching, and monitoring.

---

## 🤔 Why Do I Need RDS?

### Without RDS (Self-Managed Database):

```
PROBLEMS with running PostgreSQL on EC2 yourself:

1. Manual backups (what if you forget?)
2. Manual security patches (hackers exploit outdated databases)
3. No automatic failover (database crashes = app down)
4. Manual scaling (database slow? You manually upgrade)
5. No point-in-time recovery (can't restore to 5 minutes ago)
6. You manage everything (storage, networking, monitoring)

Example: E-commerce site
- Run PostgreSQL on EC2
- Forgot to backup → Database corruption → All orders lost!
- Security patch released → You delay 2 weeks → Database hacked
- Black Friday traffic → Database can't handle load → Site crashes
- Hard drive full → Database stops → 2 AM emergency fixing
```

---

### With RDS:

```
BENEFITS:

✅ Automatic daily backups (retain 1-35 days)
✅ Point-in-time recovery (restore to any second in last 35 days)
✅ Automatic security patches (AWS applies them during maintenance window)
✅ Multi-AZ failover (automatic failover to standby in 60-120 seconds)
✅ Read replicas (scale read traffic across multiple databases)
✅ Automated monitoring (CPU, memory, disk, connections)
✅ Encryption at rest and in transit
✅ Storage autoscaling (automatically add storage when needed)
✅ Maintenance handled by AWS
✅ 99.95% availability SLA

Example: E-commerce site
- RDS PostgreSQL with Multi-AZ enabled
- Automatic backups every night → Can restore from any point
- AWS patches database during maintenance window → Always secure
- Black Friday traffic → Read replicas handle increased load
- Primary database fails → Automatic failover to standby in 90 seconds
```

---

## 📊 Real-World Example

### Scenario: SaaS Application with PostgreSQL

```
┌─────────────────────────────────────────────────────────┐
│                      USERS                               │
│  1000 concurrent users reading/writing data             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│               APPLICATION (Lambda/EC2)                   │
│  Connects to database on: myapp-prod.abc123.rds.aws.com│
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                RDS POSTGRESQL (Multi-AZ)                 │
│                                                          │
│  PRIMARY DATABASE (us-east-1a)                          │
│  ├─ Instance: db.r5.large (2 vCPU, 16 GB RAM)          │
│  ├─ Storage: 100 GB (auto-scales to 500 GB)            │
│  ├─ Encrypted: AES-256 with KMS                        │
│  ├─ Endpoint: myapp-prod.abc123.rds.amazonaws.com      │
│  └─ Database: production                                │
│                                                          │
│  STANDBY DATABASE (us-east-1b) - Synchronous Replica   │
│  ├─ Automatic failover if primary fails                │
│  └─ No manual intervention needed                       │
│                                                          │
│  READ REPLICA 1 (us-east-1c) - Asynchronous            │
│  ├─ Endpoint: myapp-prod-read1.abc123.rds.aws.com      │
│  └─ Handles 50% of read traffic                        │
│                                                          │
│  READ REPLICA 2 (us-east-1d) - Asynchronous            │
│  ├─ Endpoint: myapp-prod-read2.abc123.rds.aws.com      │
│  └─ Handles 50% of read traffic                        │
│                                                          │
│  AUTOMATED BACKUPS                                       │
│  ├─ Daily snapshot: 3:00 AM UTC                         │
│  ├─ Retention: 30 days                                  │
│  ├─ Point-in-time recovery: Restore to any second      │
│  └─ Backup storage: 100 GB included free               │
│                                                          │
│  MONITORING                                              │
│  ├─ CloudWatch Logs: Query logs, errors, slow queries  │
│  ├─ Performance Insights: Top SQL queries analyzed      │
│  └─ Enhanced Monitoring: OS-level metrics (CPU, RAM)   │
└─────────────────────────────────────────────────────────┘
```

**Cost Estimate:**
- Primary: db.r5.large = $0.29/hour = ~$210/month
- Standby (Multi-AZ): +100% = $210/month
- 2 Read Replicas: 2 × $210 = $420/month
- Storage: 100 GB × $0.115/GB = $11.50/month
- Backup storage (extra 100 GB): $0.095/GB = $9.50/month
- **Total: ~$861/month**

**For small apps (dev/staging):**
- Single db.t3.micro: $0.017/hour = ~$12/month
- 20 GB storage: $2.30/month
- **Total: ~$15/month**

---

## 🔑 Key Concepts

### 1. Database Engines

**Which database should I use?**

```
PostgreSQL (RECOMMENDED for new projects)
├─ Use for: Modern web apps, complex queries, JSON data
├─ Strengths: Advanced features, excellent JSON support, open source
├─ Cost: FREE engine (only pay for instance)
├─ Versions: 11, 12, 13, 14, 15 (use latest)
└─ Example: SaaS app, analytics platform, CRM

MySQL
├─ Use for: WordPress, legacy apps, simple queries
├─ Strengths: Simple, widely used, fast for basic queries
├─ Cost: FREE engine
├─ Versions: 5.7, 8.0 (use 8.0)
└─ Example: WordPress site, simple web app

MariaDB
├─ Use for: MySQL alternative, same SQL syntax
├─ Strengths: MySQL-compatible, more features than MySQL
├─ Cost: FREE engine
├─ Versions: 10.5, 10.6
└─ Example: Migrating from MySQL, need MySQL compatibility

SQL Server
├─ Use for: .NET apps, Windows environments
├─ Strengths: Best for Microsoft stack, enterprise features
├─ Cost: EXPENSIVE (SQL Server license fees)
├─ Versions: 2017, 2019 (Standard, Enterprise)
└─ Example: .NET enterprise app, legacy Microsoft app

Oracle
├─ Use for: Legacy enterprise apps
├─ Strengths: Enterprise features, legacy compatibility
├─ Cost: VERY EXPENSIVE (Oracle license fees)
├─ Versions: 19c, 21c
└─ Example: Large enterprise with existing Oracle apps
```

**Recommendation for new projects:** **PostgreSQL 15** (modern, powerful, free)

---

### 2. Instance Classes (How powerful is the database?)

```
T3 Instances (Burstable - For dev/test/small apps)
├─ db.t3.micro:  1 vCPU, 1 GB RAM    → $12/month  → Dev/test
├─ db.t3.small:  2 vCPU, 2 GB RAM    → $25/month  → Small apps
├─ db.t3.medium: 2 vCPU, 4 GB RAM    → $50/month  → Small production
├─ db.t3.large:  2 vCPU, 8 GB RAM    → $100/month → Medium apps
└─ Good for: Variable workloads, testing, small apps

M5 Instances (General Purpose - For production)
├─ db.m5.large:   2 vCPU, 8 GB RAM   → $131/month → Medium apps
├─ db.m5.xlarge:  4 vCPU, 16 GB RAM  → $262/month → Large apps
├─ db.m5.2xlarge: 8 vCPU, 32 GB RAM  → $524/month → Very large apps
└─ Good for: Steady workloads, production apps

R5 Instances (Memory Optimized - For heavy workloads)
├─ db.r5.large:   2 vCPU, 16 GB RAM  → $210/month → Memory-intensive
├─ db.r5.xlarge:  4 vCPU, 32 GB RAM  → $420/month → Large datasets
├─ db.r5.2xlarge: 8 vCPU, 64 GB RAM  → $840/month → Very large datasets
└─ Good for: Large datasets, complex queries, analytics
```

**Decision Tree:**
```
How many users?
│
├─ < 100 users           → db.t3.micro ($12/month)
├─ 100-1,000 users       → db.t3.small ($25/month)
├─ 1,000-10,000 users    → db.m5.large ($131/month)
├─ 10,000-100,000 users  → db.m5.xlarge ($262/month)
└─ > 100,000 users       → db.r5.xlarge+ ($420+/month)
```

---

### 3. Storage Types

```
gp3 (General Purpose SSD - RECOMMENDED)
├─ Speed: 3,000 IOPS baseline, up to 16,000 IOPS
├─ Cost: $0.115/GB/month
├─ Use for: 99% of use cases
└─ Example: Web apps, SaaS, general production

gp2 (General Purpose SSD - Legacy)
├─ Speed: 3 IOPS per GB (min 100, max 16,000)
├─ Cost: $0.115/GB/month
├─ Use for: Legacy systems (use gp3 for new projects)
└─ Example: Older RDS instances

io1 (Provisioned IOPS SSD - High Performance)
├─ Speed: Up to 64,000 IOPS (you choose exact IOPS)
├─ Cost: $0.125/GB + $0.10 per IOPS
├─ Use for: Mission-critical, low-latency workloads
└─ Example: Financial transactions, high-performance apps
```

**Recommendation:** **gp3** for all new projects (cheaper, faster than gp2)

---

### 4. Multi-AZ vs Single-AZ

#### **Single-AZ (Cheaper, Less Reliable)**

```
┌─────────────────────────┐
│    Availability Zone A  │
│                         │
│  ┌───────────────────┐ │
│  │  PRIMARY DATABASE │ │
│  └───────────────────┘ │
│                         │
└─────────────────────────┘

If AZ fails → Database down until AWS fixes it (hours)

Cost: $210/month (db.r5.large)
Use for: Dev, staging, non-critical apps
```

#### **Multi-AZ (Expensive, High Availability - RECOMMENDED for production)**

```
┌─────────────────────────┐      ┌─────────────────────────┐
│    Availability Zone A  │      │    Availability Zone B  │
│                         │      │                         │
│  ┌───────────────────┐ │      │  ┌───────────────────┐ │
│  │  PRIMARY DATABASE │ │──────┼─→│ STANDBY DATABASE  │ │
│  │  (Active)         │ │      │  │ (Passive)         │ │
│  └───────────────────┘ │      │  └───────────────────┘ │
│                         │      │                         │
└─────────────────────────┘      └─────────────────────────┘

If primary fails → Automatic failover to standby (60-120 seconds)

Synchronous replication (standby is always up-to-date)
Cost: $420/month (db.r5.large × 2)
Use for: Production apps, critical data
```

**Decision:**
- **Dev/Staging:** Single-AZ (save money)
- **Production:** Multi-AZ (high availability)

---

### 5. Read Replicas

**What:** Read-only copies of your database for scaling read traffic

**Why:** Your app reads data 90% of the time, writes 10%. Offload reads to replicas.

```
┌──────────────────────┐
│  PRIMARY DATABASE    │  ← Handles all WRITES
│  (Read/Write)        │  ← Handles some reads
└──────────┬───────────┘
           │ Asynchronous
           │ replication
           ├──────────────────┬──────────────────┐
           ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  READ REPLICA 1  │ │  READ REPLICA 2  │ │  READ REPLICA 3  │
│  (Read-only)     │ │  (Read-only)     │ │  (Read-only)     │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

**Use Cases:**
- **Reporting/Analytics:** Run heavy queries on replica, don't slow down production
- **Scale reads:** Distribute read traffic across multiple replicas
- **Cross-region:** Create replica in different region for low latency

**Important:** Replicas are asynchronous (slight delay, typically < 1 second)

**Cost:** Each replica costs same as primary instance

---

### 6. Backups

#### **Automated Backups (FREE)**

```
What: AWS automatically snapshots your database daily
Retention: 1-35 days (you choose)
Cost: FREE for storage = database size (extra storage charged)

Example:
- Database size: 100 GB
- Backup retention: 7 days
- Backup storage: 100 GB FREE, extra charged at $0.095/GB

Point-in-time recovery:
- Restore to ANY second in retention period
- Example: "Restore to yesterday 2:47 PM" → AWS restores to that exact time
```

#### **Manual Snapshots (Keep Forever)**

```
What: You manually create snapshot (like taking a photo)
Retention: Forever (until you delete)
Cost: $0.095/GB/month

Use cases:
- Before major migration
- Before risky operation
- Quarterly compliance backup
```

---

## 🛠️ Common RDS Patterns

### Pattern 1: Simple Web App (Dev/Staging)

**Use Case:** Small web app, non-critical, low budget

```hcl
resource "aws_db_instance" "dev" {
  identifier     = "myapp-dev-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"  # $12/month

  allocated_storage     = 20
  max_allocated_storage = 100  # Auto-scale to 100 GB
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "myapp"
  username = "dbadmin"
  password = var.db_password  # Store in Secrets Manager!

  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 7  # 7 days backup
  skip_final_snapshot     = true  # OK for dev/staging
  multi_az                = false  # Single-AZ (cheaper)
  deletion_protection     = false  # Can delete easily

  tags = {
    Environment = "dev"
  }
}
```

**Cost:** ~$15/month

---

### Pattern 2: Production App (High Availability)

**Use Case:** Production web app, critical data, high availability

```hcl
resource "aws_db_instance" "prod" {
  identifier     = "myapp-prod-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.m5.large"  # $131/month

  allocated_storage     = 100
  max_allocated_storage = 500  # Auto-scale to 500 GB
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn  # Customer-managed KMS

  db_name  = "myapp"
  username = "dbadmin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string

  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # High Availability
  multi_az            = true  # Auto-failover
  deletion_protection = true  # Prevent accidental deletion

  # Backups
  backup_retention_period = 30  # 30 days
  backup_window           = "03:00-04:00"  # 3 AM UTC
  skip_final_snapshot     = false
  final_snapshot_identifier = "myapp-prod-final-snapshot"

  # Maintenance
  maintenance_window         = "sun:04:00-sun:05:00"  # Sunday 4 AM
  auto_minor_version_upgrade = true

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60  # Enhanced monitoring
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = {
    Environment = "production"
    Backup      = "critical"
  }
}
```

**Cost:** ~$280/month (Multi-AZ)

---

### Pattern 3: Read-Heavy App (With Read Replicas)

**Use Case:** App with 90% reads, 10% writes (analytics, reporting)

```hcl
# Primary database (handles writes + some reads)
resource "aws_db_instance" "primary" {
  identifier     = "myapp-primary"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.m5.large"

  allocated_storage = 100
  storage_encrypted = true
  multi_az          = true

  backup_retention_period = 30  # Required for read replicas

  db_name  = "myapp"
  username = "dbadmin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string

  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.db.id]
}

# Read replica 1 (handle 50% of read traffic)
resource "aws_db_instance" "read_replica_1" {
  identifier          = "myapp-read-replica-1"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = "db.m5.large"

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "Read Replica 1"
  }
}

# Read replica 2 (handle 50% of read traffic)
resource "aws_db_instance" "read_replica_2" {
  identifier          = "myapp-read-replica-2"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = "db.m5.large"

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "Read Replica 2"
  }
}

# Application code connects:
# - Writes → Primary endpoint
# - Reads → Load balance between replica endpoints
```

**Cost:** ~$655/month (1 primary Multi-AZ + 2 read replicas)

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Publicly Accessible Database

```hcl
# WRONG - Database exposed to internet!
resource "aws_db_instance" "bad" {
  publicly_accessible = true  # Anyone can try to connect!
}

# Hackers scan for open databases and brute-force passwords
# If they get in → All data stolen
```

**Fix:**
```hcl
# CORRECT - Database only accessible from VPC
resource "aws_db_instance" "good" {
  publicly_accessible    = false  # Only VPC can access
  db_subnet_group_name   = aws_db_subnet_group.private.name  # Private subnets
  vpc_security_group_ids = [aws_security_group.db_only_from_app.id]
}

# Security group only allows connections from app servers
resource "aws_security_group" "db_only_from_app" {
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_servers.id]  # Only app servers
  }
}
```

---

### ❌ Mistake 2: Hardcoded Passwords

```hcl
# WRONG - Password visible in Terraform code!
resource "aws_db_instance" "bad" {
  password = "SuperSecret123!"  # Shows up in:
  # - Terraform state (stored in S3)
  # - Git history
  # - CI/CD logs
  # - Terraform plan output
}
```

**Fix:**
```hcl
# CORRECT - Password stored in AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "myapp-prod-db-password"
}

resource "aws_db_instance" "good" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# Create secret in Secrets Manager:
# aws secretsmanager create-secret --name myapp-prod-db-password --secret-string "YourSecurePassword"
```

---

### ❌ Mistake 3: No Backups

```hcl
# WRONG - No backups!
resource "aws_db_instance" "bad" {
  backup_retention_period = 0  # No backups
  # If database corrupted → Lost forever
}
```

**Fix:**
```hcl
# CORRECT - 30 days of backups
resource "aws_db_instance" "good" {
  backup_retention_period = 30  # 30 days
  backup_window           = "03:00-04:00"  # Daily at 3 AM

  # Can restore to any point in last 30 days!
}
```

---

### ❌ Mistake 4: Skip Final Snapshot in Production

```hcl
# WRONG - Deleting production database without final backup!
resource "aws_db_instance" "bad" {
  skip_final_snapshot = true  # No final backup before deletion

  # terraform destroy → Database deleted forever
}
```

**Fix:**
```hcl
# CORRECT - Create final snapshot on deletion
resource "aws_db_instance" "good" {
  skip_final_snapshot       = false
  final_snapshot_identifier = "myapp-prod-final-snapshot-${timestamp()}"

  # terraform destroy → Creates final snapshot → Can restore later
}

# Dev/staging can skip (OK to lose data)
resource "aws_db_instance" "dev" {
  skip_final_snapshot = true  # OK for dev
}
```

---

### ❌ Mistake 5: Wrong Instance Class

```hcl
# WRONG - Massive instance for tiny app
resource "aws_db_instance" "overkill" {
  instance_class = "db.r5.8xlarge"  # $2,880/month
  # App has 10 users → Wasting $2,865/month
}

# WRONG - Tiny instance for large app
resource "aws_db_instance" "too_small" {
  instance_class = "db.t3.micro"  # $12/month
  # App has 100,000 users → Database overloaded, app slow
}
```

**Fix:**
```hcl
# Start small, monitor, upgrade if needed
resource "aws_db_instance" "right_size" {
  instance_class = "db.t3.small"  # $25/month

  # Monitor CloudWatch metrics:
  # - CPU > 80% → Upgrade instance
  # - Connections maxed out → Upgrade instance
  # - Slow queries → Upgrade or add read replicas
}
```

---

## 🎯 Best Practices

### 1. Always Use Private Subnets

```hcl
# Create private subnet group
resource "aws_db_subnet_group" "private" {
  name       = "myapp-private-db-subnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "secure" {
  db_subnet_group_name = aws_db_subnet_group.private.name
  publicly_accessible  = false
}
```

---

### 2. Enable Encryption

```hcl
resource "aws_db_instance" "encrypted" {
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn  # Customer-managed KMS

  # Also enable Performance Insights encryption
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
}
```

---

### 3. Use Secrets Manager for Passwords

```hcl
# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "myapp-${var.environment}-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.master_password  # Set via terraform.tfvars (not hardcoded)
}

# Use in RDS
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

resource "aws_db_instance" "secure" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

---

### 4. Enable Multi-AZ for Production

```hcl
# Production: Multi-AZ
resource "aws_db_instance" "prod" {
  multi_az            = true  # High availability
  deletion_protection = true  # Prevent accidental deletion
}

# Dev/Staging: Single-AZ
resource "aws_db_instance" "dev" {
  multi_az = false  # Save money
}
```

---

### 5. Set Appropriate Backup Retention

```hcl
resource "aws_db_instance" "production" {
  backup_retention_period = 30  # 30 days (max 35)
  backup_window           = "03:00-04:00"  # Low-traffic time

  # Point-in-time recovery enabled automatically
}
```

---

### 6. Monitor with CloudWatch and Performance Insights

```hcl
resource "aws_db_instance" "monitored" {
  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Enhanced Monitoring (OS metrics)
  monitoring_interval = 60  # Every 60 seconds
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights (SQL query analysis)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7  # 7 days free, 731 days paid
}

# Create monitoring role
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
```

---

## 💰 RDS Pricing

**Instance Costs (On-Demand, us-east-1):**

```
T3 (Burstable):
- db.t3.micro:  $0.017/hour = $12/month
- db.t3.small:  $0.034/hour = $25/month
- db.t3.medium: $0.068/hour = $50/month

M5 (General Purpose):
- db.m5.large:   $0.180/hour = $131/month
- db.m5.xlarge:  $0.360/hour = $262/month
- db.m5.2xlarge: $0.720/hour = $524/month

R5 (Memory Optimized):
- db.r5.large:   $0.290/hour = $210/month
- db.r5.xlarge:  $0.580/hour = $420/month
- db.r5.2xlarge: $1.160/hour = $840/month
```

**Storage:**
- gp3: $0.115/GB/month
- gp2: $0.115/GB/month
- io1: $0.125/GB/month + $0.10/IOPS

**Backup Storage:**
- First 100% of database size: FREE
- Extra backup storage: $0.095/GB/month

**Multi-AZ:**
- Doubles instance cost (2× instances)

**Read Replicas:**
- Each replica = full instance cost

**Examples:**

```
Small Dev App:
- db.t3.micro (Single-AZ)
- 20 GB storage
- 7 days backup
Cost: $12 + $2.30 = $14.30/month

Medium Production App:
- db.m5.large (Multi-AZ)
- 100 GB storage
- 30 days backup
Cost: ($131 × 2) + $11.50 = $273.50/month

Large Production App (with read replicas):
- db.r5.large primary (Multi-AZ)
- 2 read replicas (db.r5.large each)
- 200 GB storage
Cost: ($210 × 2) + ($210 × 2) + $23 = $863/month
```

---

**Next**: See complete implementations in [rds_create.tf](./rds_create.tf)
