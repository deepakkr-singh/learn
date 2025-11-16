# CloudWatch - AWS Monitoring and Logging Service

## 🎯 What is CloudWatch?

**Simple Explanation:**
CloudWatch is like a security camera system + fitness tracker for your AWS infrastructure. It watches everything happening in your AWS account, records logs, tracks metrics, and alerts you when something goes wrong.

Think of it as:
- **Without CloudWatch** = Flying blind, no idea if your app is healthy
- **With CloudWatch** = Dashboard showing CPU, memory, errors, logs - know everything

**Real-World Analogy:**
- **Traditional monitoring** = Checking your car manually every hour (is it overheating? low on gas?)
- **CloudWatch** = Dashboard with gauges showing everything in real-time + alerts when issues occur

**Technical Definition:**
Amazon CloudWatch is a monitoring and observability service that provides data and actionable insights for AWS resources and applications. It collects metrics, logs, events, and alarms to help you monitor and troubleshoot issues.

---

## 🤔 Why Do I Need CloudWatch?

### Without CloudWatch:

```
PROBLEMS with no monitoring:

1. No visibility into application health
2. Don't know when errors occur
3. Can't debug production issues
4. App crashes and you find out from angry users
5. No historical data to analyze trends
6. Can't set up automated alerts

Example: Production API
- Lambda function running
- Starts failing 50% of requests
- You don't know until customers complain
- No logs to debug the issue
- No idea when it started failing
```

---

### With CloudWatch:

```
BENEFITS:

✅ Real-time monitoring of all AWS resources
✅ Store and search application logs
✅ Set alarms for automatic notifications
✅ Create dashboards to visualize metrics
✅ Track custom application metrics
✅ Analyze trends and patterns
✅ Automated responses to issues
✅ Historical data for troubleshooting

Example: Production API with CloudWatch
- Lambda function monitored
- Error rate jumps to 50%
- CloudWatch alarm triggers immediately
- SNS notification sent to team
- Logs show exact error message
- Fix deployed in 5 minutes
- Historical graphs show when issue started
```

---

## 📊 Real-World Example

### Scenario: Web Application Monitoring

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR APPLICATION                        │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │   Lambda   │  │    EC2     │  │    RDS     │           │
│  │  Function  │  │  Instance  │  │  Database  │           │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘           │
│         │                │                │                  │
│         └────────────────┼────────────────┘                 │
│                          │                                   │
│                          ▼                                   │
│                ┌──────────────────┐                         │
│                │   CLOUDWATCH     │                         │
│                └──────────────────┘                         │
└─────────────────────────────────────────────────────────────┘

CloudWatch Collects:

1. LOGS
   ├─ /aws/lambda/my-function
   │  ├─ "2025-01-15 10:30:00 ERROR: Database connection failed"
   │  ├─ "2025-01-15 10:30:01 ERROR: Timeout after 30s"
   │  └─ "2025-01-15 10:30:02 INFO: Retry successful"
   │
   ├─ /aws/ec2/web-server
   │  ├─ "2025-01-15 10:25:00 INFO: User login successful"
   │  └─ "2025-01-15 10:26:00 WARN: High memory usage 85%"
   │
   └─ /aws/rds/postgres
      └─ "2025-01-15 10:20:00 ERROR: Slow query 15 seconds"

2. METRICS (Automatic)
   ├─ Lambda: Invocations, Errors, Duration, Throttles
   ├─ EC2: CPUUtilization, NetworkIn, DiskReadOps
   ├─ RDS: DatabaseConnections, ReadLatency, WriteIOPS
   └─ API Gateway: Count, Latency, 4XXError, 5XXError

3. CUSTOM METRICS (You Define)
   ├─ OrdersPlaced: 1,247 orders/hour
   ├─ ActiveUsers: 342 concurrent users
   ├─ PaymentSuccess: 98.5% success rate
   └─ CartAbandonment: 23% abandonment rate

4. ALARMS
   ├─ CPU > 80% for 5 minutes → Alert team
   ├─ Error rate > 5% → Page on-call engineer
   ├─ Database connections > 90 → Auto-scale RDS
   └─ Disk space < 10% → Send SNS notification

5. DASHBOARDS
   ┌──────────────────────────────────────────┐
   │  Production Application Dashboard         │
   ├──────────────────────────────────────────┤
   │  ┌─────────────┐  ┌─────────────┐       │
   │  │ API Latency │  │  Error Rate │       │
   │  │   125 ms    │  │    0.3%     │       │
   │  └─────────────┘  └─────────────┘       │
   │  ┌─────────────┐  ┌─────────────┐       │
   │  │  CPU Usage  │  │ Active Users│       │
   │  │    45%      │  │    1,247    │       │
   │  └─────────────┘  └─────────────┘       │
   └──────────────────────────────────────────┘
```

**Cost Example:**
- Store 50 GB logs/month: $2.50/month
- 100 custom metrics: $30/month
- 10 alarms: $1/month
- **Total: ~$34/month**

---

## 🔑 Key Concepts

### 1. CloudWatch Logs

**What:** Store and search application logs

**Log Groups:**
```
Log Group = Container for logs from same source

Examples:
/aws/lambda/my-function        → Lambda function logs
/aws/ec2/web-server           → EC2 application logs
/aws/rds/postgres/error       → RDS error logs
/ecs/my-service               → ECS container logs
/custom/payment-service       → Your custom app logs
```

**Log Streams:**
```
Log Stream = Individual instance of log source

Example: /aws/lambda/my-function
├─ 2025/01/15/[$LATEST]abc123  → Individual Lambda execution
├─ 2025/01/15/[$LATEST]def456  → Another execution
└─ 2025/01/15/[$LATEST]ghi789  → Another execution
```

**Retention:**
```
How long to keep logs?

Options:
├─ 1, 3, 5, 7, 14, 30 days  → Short-term (dev/staging)
├─ 60, 90, 120, 150, 180 days → Medium-term
├─ 1 year (365 days)  → Compliance
├─ 10 years (3653 days) → Regulatory
└─ Never expire → Keep forever (expensive!)

Cost: $0.50/GB stored/month

Recommendation:
- Dev: 7 days
- Staging: 30 days
- Production: 90-365 days (depending on compliance)
```

---

### 2. CloudWatch Metrics

**Standard Metrics (FREE):**

```
Every AWS service automatically sends metrics:

Lambda:
├─ Invocations: Number of times function called
├─ Errors: Number of failed invocations
├─ Duration: How long function runs
├─ Throttles: Number of throttled invocations
└─ Concurrent Executions: Functions running simultaneously

EC2:
├─ CPUUtilization: CPU usage percentage
├─ NetworkIn/NetworkOut: Network traffic
├─ DiskReadOps/DiskWriteOps: Disk operations
└─ StatusCheckFailed: Instance health

RDS:
├─ DatabaseConnections: Active connections
├─ ReadLatency/WriteLatency: Query speed
├─ ReadIOPS/WriteIOPS: Database operations per second
└─ FreeStorageSpace: Available disk space

API Gateway:
├─ Count: Number of API requests
├─ Latency: Request duration
├─ 4XXError: Client errors (400, 404, etc.)
└─ 5XXError: Server errors (500, 502, etc.)
```

**Custom Metrics (PAID):**

```
Send your own application metrics:

Example: E-commerce app
├─ OrdersPlaced: Count of orders
├─ Revenue: Total sales amount
├─ CartAbandonmentRate: % of abandoned carts
├─ InventoryLevel: Stock quantities
└─ PaymentSuccessRate: % of successful payments

Cost: $0.30 per custom metric/month

How to send:
aws cloudwatch put-metric-data \
  --namespace "MyApp/Orders" \
  --metric-name "OrdersPlaced" \
  --value 42 \
  --unit Count
```

---

### 3. CloudWatch Alarms

**What:** Automatically alert when metrics cross thresholds

**Alarm States:**
```
OK → Metric within threshold
ALARM → Metric exceeded threshold
INSUFFICIENT_DATA → Not enough data to evaluate
```

**Example Alarms:**

```hcl
# High CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2  # Must exceed for 2 periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 80  # 80% CPU

  alarm_description = "Alert when CPU > 80% for 10 minutes"
  alarm_actions     = [aws_sns_topic.alerts.arn]  # Send SNS

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

# High error rate alarm
resource "aws_cloudwatch_metric_alarm" "high_errors" {
  alarm_name          = "high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60  # 1 minute
  statistic           = "Sum"
  threshold           = 10  # More than 10 errors

  alarm_description = "Alert when errors > 10 in 1 minute"
  alarm_actions     = [aws_sns_topic.pager.arn]  # Page on-call

  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
  }
}

# Low disk space alarm
resource "aws_cloudwatch_metric_alarm" "low_disk" {
  alarm_name          = "low-disk-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240  # 10 GB in bytes

  alarm_description = "Alert when disk < 10 GB"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}
```

**Cost:** $0.10 per alarm/month (first 10 alarms FREE)

---

### 4. CloudWatch Dashboards

**What:** Visual graphs and charts of your metrics

```
┌──────────────────────────────────────────────────────────┐
│  Production Dashboard                    Last 3 hours ▼  │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────┐  ┌────────────────────┐         │
│  │  API Requests      │  │  Error Rate        │         │
│  │  12,543 req/min    │  │  0.2%              │         │
│  │  [Graph showing    │  │  [Graph showing    │         │
│  │   trend line]      │  │   error spikes]    │         │
│  └────────────────────┘  └────────────────────┘         │
│  ┌────────────────────┐  ┌────────────────────┐         │
│  │  Response Time     │  │  Database Conns    │         │
│  │  85ms avg          │  │  45/100 active     │         │
│  │  [Graph]           │  │  [Graph]           │         │
│  └────────────────────┘  └────────────────────┘         │
│  ┌──────────────────────────────────────────┐           │
│  │  Lambda Invocations by Function          │           │
│  │  [Bar chart comparing functions]         │           │
│  └──────────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────┘
```

**Cost:** $3/dashboard/month (first 3 dashboards FREE)

---

## 🛠️ Common CloudWatch Patterns

### Pattern 1: Lambda Function Monitoring

```hcl
# Log group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 30  # Keep logs 30 days

  tags = {
    Function = var.function_name
  }
}

# Alarm for high error rate
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.function_name}-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  alarm_description = "Lambda function error rate too high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.function_name
  }
}

# Alarm for high duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.function_name}-slow-execution"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 5000  # 5 seconds

  alarm_description = "Lambda taking too long to execute"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.function_name
  }
}
```

---

### Pattern 2: EC2 Instance Monitoring

```hcl
# High CPU alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "EC2 CPU usage too high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

# Status check alarm
resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "ec2-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  alarm_description = "EC2 instance failing status checks"
  alarm_actions     = [
    aws_sns_topic.alerts.arn,
    "arn:aws:automate:${data.aws_region.current.name}:ec2:recover"  # Auto-recover
  ]

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}
```

---

### Pattern 3: Application Logs with Encryption

```hcl
# KMS key for log encryption
resource "aws_kms_key" "logs" {
  description = "KMS key for CloudWatch Logs encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

# Encrypted log group
resource "aws_cloudwatch_log_group" "encrypted" {
  name              = "/aws/application/sensitive-data"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Encryption = "KMS"
    Compliance = "Required"
  }
}
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: No Log Retention (Paying Forever)

```hcl
# WRONG - Logs kept forever, costs grow infinitely
resource "aws_cloudwatch_log_group" "bad" {
  name = "/aws/lambda/my-function"
  # No retention_in_days = logs kept forever
  # Cost grows every month!
}

# Month 1: 10 GB × $0.50 = $5
# Month 2: 20 GB × $0.50 = $10
# Month 3: 30 GB × $0.50 = $15
# Month 12: 120 GB × $0.50 = $60/month
```

**Fix:**
```hcl
# CORRECT - Auto-delete old logs
resource "aws_cloudwatch_log_group" "good" {
  name              = "/aws/lambda/my-function"
  retention_in_days = 30  # Delete after 30 days

  # Cost stays constant at ~$5/month
}
```

---

### ❌ Mistake 2: Too Sensitive Alarms (Alert Fatigue)

```hcl
# WRONG - Alarm triggers on every tiny spike
resource "aws_cloudwatch_metric_alarm" "bad" {
  alarm_name         = "cpu-alarm"
  evaluation_periods = 1  # Trigger immediately
  period             = 60  # 1 minute
  threshold          = 50  # 50% CPU

  # Triggers 100 times/day → Team ignores all alerts
}
```

**Fix:**
```hcl
# CORRECT - Only alert on sustained high CPU
resource "aws_cloudwatch_metric_alarm" "good" {
  alarm_name         = "cpu-alarm"
  evaluation_periods = 3  # Must exceed for 15 minutes
  period             = 300  # 5 minutes
  threshold          = 80  # 80% CPU

  # Only triggers on real problems
}
```

---

### ❌ Mistake 3: No Alarm Actions

```hcl
# WRONG - Alarm triggers but nobody notified
resource "aws_cloudwatch_metric_alarm" "bad" {
  alarm_name     = "high-errors"
  # ... alarm configuration ...
  alarm_actions  = []  # No actions!

  # Alarm triggers, nobody knows, app stays broken
}
```

**Fix:**
```hcl
# CORRECT - Send SNS notification
resource "aws_cloudwatch_metric_alarm" "good" {
  alarm_name    = "high-errors"
  # ... alarm configuration ...
  alarm_actions = [aws_sns_topic.alerts.arn]  # Notify team

  # Also consider: PagerDuty, Slack, email
}
```

---

## 🎯 Best Practices

### 1. Set Appropriate Log Retention

```hcl
# Dev/Staging: 7 days
resource "aws_cloudwatch_log_group" "dev" {
  name              = "/aws/lambda/dev-function"
  retention_in_days = 7
}

# Production: 30-90 days
resource "aws_cloudwatch_log_group" "prod" {
  name              = "/aws/lambda/prod-function"
  retention_in_days = 90
}

# Compliance: 1-10 years
resource "aws_cloudwatch_log_group" "compliance" {
  name              = "/aws/application/audit-logs"
  retention_in_days = 3653  # 10 years
}
```

---

### 2. Encrypt Sensitive Logs

```hcl
resource "aws_cloudwatch_log_group" "sensitive" {
  name       = "/aws/application/payment-service"
  kms_key_id = aws_kms_key.logs.arn  # Encrypt with KMS
}
```

---

### 3. Use Composite Alarms for Complex Conditions

```hcl
# Multiple conditions must be true
resource "aws_cloudwatch_composite_alarm" "critical" {
  alarm_name = "critical-system-failure"

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.high_cpu.alarm_name}) AND ALARM(${aws_cloudwatch_metric_alarm.high_errors.alarm_name})"

  alarm_actions = [aws_sns_topic.pager.arn]  # Page on-call
}
```

---

### 4. Create Dashboards for Key Metrics

```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "production-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            [".", "Errors", { stat = "Sum" }]
          ]
          period = 300
          region = "us-east-1"
          title  = "Lambda Metrics"
        }
      }
    ]
  })
}
```

---

## 💰 CloudWatch Pricing

**Logs:**
- Ingestion: $0.50/GB
- Storage: $0.03/GB/month
- Data scanned (Insights): $0.005/GB

**Metrics:**
- Standard metrics: FREE
- Custom metrics: $0.30/metric/month
- High-resolution metrics: $0.30/metric/month

**Alarms:**
- Standard metrics: $0.10/alarm/month
- High-resolution metrics: $0.30/alarm/month

**Dashboards:**
- $3/dashboard/month

**Examples:**

```
Small App:
- 10 GB logs/month: $5.30
- 10 custom metrics: $3
- 5 alarms: $0.50
- 1 dashboard: $3
Total: ~$12/month

Medium App:
- 50 GB logs/month: $26.50
- 100 custom metrics: $30
- 20 alarms: $2
- 3 dashboards: $9
Total: ~$68/month

Large App:
- 500 GB logs/month: $265
- 500 custom metrics: $150
- 100 alarms: $10
- 10 dashboards: $30
Total: ~$455/month
```

---

**Next**: See complete implementations in [cloudwatch_create.tf](./cloudwatch_create.tf)
