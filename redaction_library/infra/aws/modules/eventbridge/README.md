# EventBridge - Event-Driven Architecture

## 🎯 What is EventBridge?

**Simple Explanation:**
EventBridge is like a smart notification system that listens for events in your AWS account and triggers actions automatically. When something happens (file uploaded, user signs up, order placed), EventBridge can automatically trigger Lambda functions, send messages, or start workflows.

Think of it as:
- **Without EventBridge** = Manually checking if things happened, polling databases
- **With EventBridge** = Automatic notifications when events occur, instant reactions

**Real-World Analogy:**
- **Traditional approach** = Checking your mailbox every 5 minutes to see if mail arrived
- **EventBridge** = Doorbell that rings when mail arrives, automatically notifies you

**Technical Definition:**
Amazon EventBridge is a serverless event bus service that makes it easy to connect applications using data from your own apps, AWS services, and SaaS applications.

---

## 🤔 Why Do I Need EventBridge?

### Without EventBridge (Polling/Manual):

```
PROBLEMS:

1. Constant polling (check database every minute for new orders)
2. Wasted resources (checking even when nothing changed)
3. Delays (5-minute polling interval = 5-minute delay)
4. Tight coupling (services directly call each other)
5. Hard to scale (adding new reactions requires code changes)

Example: E-commerce Order Processing
- Check database every minute for new orders
- If order found → Trigger fulfillment
- Wastes 1,440 database queries/day even with 0 orders
- 1-minute delay before processing
```

---

### With EventBridge:

```
BENEFITS:

✅ Event-driven (instant reaction to events, no polling)
✅ Loose coupling (services don't know about each other)
✅ Easy to add new reactions (just add new rules)
✅ Built-in retries and error handling
✅ Supports 100+ AWS services automatically
✅ Archive and replay events
✅ Schema registry (validate event structure)

Example: E-commerce with EventBridge
- Order placed → Event published
- EventBridge triggers:
  - Lambda: Send confirmation email
  - SNS: Notify fulfillment team
  - SQS: Add to processing queue
  - Step Functions: Start workflow
All happen instantly and in parallel!
```

---

## 📊 Real-World Example

### Scenario: Image Processing Pipeline

```
USER UPLOADS IMAGE → S3 BUCKET
    │
    ▼
┌─────────────────────────────────────────────┐
│       S3 SENDS EVENT TO EVENTBRIDGE         │
│  {                                          │
│    "source": "aws.s3",                      │
│    "detail-type": "Object Created",         │
│    "detail": {                              │
│      "bucket": "user-uploads",              │
│      "key": "photo.jpg"                     │
│    }                                        │
│  }                                          │
└────────────────┬────────────────────────────┘
                 │
                 ▼
       ┌─────────────────┐
       │   EVENTBRIDGE   │
       │   RULE ENGINE   │
       └─────────┬───────┘
                 │
     ┌───────────┼───────────┬───────────┐
     │           │           │           │
     ▼           ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│Lambda 1 │ │Lambda 2 │ │  SNS    │ │   SQS   │
│Thumbnail│ │Rekognit │ │ Notify  │ │  Queue  │
│Generate │ │Detect   │ │ Team    │ │Process  │
└─────────┘ └─────────┘ └─────────┘ └─────────┘

All triggered automatically in parallel!
```

**Cost:**
- Events: $1 per million events
- Upload 10,000 images/month: $0.01
- **Almost FREE!**

---

## 🔑 Key Concepts

### 1. Event Buses

```
Default Event Bus (Automatic)
├─ All AWS service events go here automatically
├─ Examples: S3 uploads, EC2 state changes, RDS snapshots
└─ No setup needed

Custom Event Bus (Your App Events)
├─ Your application publishes custom events
├─ Examples: "OrderPlaced", "UserSignedUp", "PaymentProcessed"
└─ You control the schema
```

---

### 2. Event Structure

```json
{
  "version": "0",
  "id": "abc-123-def-456",
  "source": "myapp.orders",
  "detail-type": "Order Placed",
  "time": "2025-01-15T10:30:00Z",
  "region": "us-east-1",
  "detail": {
    "orderId": "12345",
    "customerId": "user-789",
    "amount": 99.99,
    "items": [
      {"productId": "prod-1", "quantity": 2}
    ]
  }
}
```

---

### 3. Event Rules (Pattern Matching)

```hcl
# Match S3 upload events
resource "aws_cloudwatch_event_rule" "s3_upload" {
  name = "s3-upload-rule"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = ["user-uploads"]
      }
    }
  })
}

# Match custom app events
resource "aws_cloudwatch_event_rule" "order_placed" {
  name = "order-placed-rule"

  event_pattern = jsonencode({
    source      = ["myapp.orders"]
    detail-type = ["Order Placed"]
    detail = {
      amount = [
        { numeric = [">", 100] }  # Only orders > $100
      ]
    }
  })
}
```

---

## 🛠️ Common EventBridge Patterns

### Pattern 1: S3 Upload → Lambda Processing

```hcl
# EventBridge rule for S3 uploads
resource "aws_cloudwatch_event_rule" "s3_upload" {
  name = "process-s3-uploads"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.uploads.id]
      }
    }
  })
}

# Target Lambda function
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.s3_upload.name
  target_id = "ProcessUpload"
  arn       = aws_lambda_function.process.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_upload.arn
}
```

---

### Pattern 2: Scheduled Events (Cron Jobs)

```hcl
# Run Lambda every hour
resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "run-hourly"
  schedule_expression = "rate(1 hour)"
}

# Run Lambda every day at 2 AM
resource "aws_cloudwatch_event_rule" "daily" {
  name                = "run-daily-2am"
  schedule_expression = "cron(0 2 * * ? *)"
}

# Run Lambda every Monday at 9 AM
resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "run-weekly-monday-9am"
  schedule_expression = "cron(0 9 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "lambda_hourly" {
  rule      = aws_cloudwatch_event_rule.hourly.name
  target_id = "HourlyTask"
  arn       = aws_lambda_function.task.arn
}
```

---

### Pattern 3: Custom Application Events

```hcl
# Custom event bus for application events
resource "aws_cloudwatch_event_bus" "app" {
  name = "myapp-events"
}

# Rule: When order placed
resource "aws_cloudwatch_event_rule" "order_placed" {
  name           = "order-placed"
  event_bus_name = aws_cloudwatch_event_bus.app.name

  event_pattern = jsonencode({
    source      = ["myapp.orders"]
    detail-type = ["Order Placed"]
  })
}

# Target 1: Send email via Lambda
resource "aws_cloudwatch_event_target" "send_email" {
  rule           = aws_cloudwatch_event_rule.order_placed.name
  event_bus_name = aws_cloudwatch_event_bus.app.name
  target_id      = "SendEmail"
  arn            = aws_lambda_function.send_email.arn
}

# Target 2: Update analytics via SQS
resource "aws_cloudwatch_event_target" "analytics" {
  rule           = aws_cloudwatch_event_rule.order_placed.name
  event_bus_name = aws_cloudwatch_event_bus.app.name
  target_id      = "UpdateAnalytics"
  arn            = aws_sqs_queue.analytics.arn
}

# Application publishes event (Python example)
import boto3
import json

client = boto3.client('events')

response = client.put_events(
    Entries=[
        {
            'Source': 'myapp.orders',
            'DetailType': 'Order Placed',
            'Detail': json.dumps({
                'orderId': '12345',
                'customerId': 'user-789',
                'amount': 99.99
            }),
            'EventBusName': 'myapp-events'
        }
    ]
)
```

---

## 🎯 Best Practices

### 1. Use Descriptive Event Names

```
# Good
source: "myapp.orders"
detail-type: "Order Placed"

# Bad
source: "app"
detail-type: "event1"
```

---

### 2. Include Enough Context in Events

```json
{
  "source": "myapp.orders",
  "detail-type": "Order Placed",
  "detail": {
    "orderId": "12345",
    "customerId": "user-789",
    "amount": 99.99,
    "timestamp": "2025-01-15T10:30:00Z",
    "items": [...]
  }
}
```

---

### 3. Enable Dead Letter Queues

```hcl
resource "aws_cloudwatch_event_target" "lambda_with_dlq" {
  rule      = aws_cloudwatch_event_rule.my_rule.name
  target_id = "MyLambda"
  arn       = aws_lambda_function.process.arn

  dead_letter_config {
    arn = aws_sqs_queue.failed_events.arn
  }

  retry_policy {
    maximum_event_age       = 3600  # 1 hour
    maximum_retry_attempts  = 2
  }
}
```

---

## 💰 EventBridge Pricing

**Events:**
- $1.00 per million events
- First 1 million events: FREE (per month)

**Schema Discovery:**
- $0.10 per million events

**Archive/Replay:**
- $0.10/GB storage
- $0.023/GB replay

**Examples:**

```
Small App (10,000 events/month):
- Events: FREE (under 1 million)
Total: $0/month

Medium App (10 million events/month):
- Events: 9 million × $1 = $9
Total: $9/month

Large App (100 million events/month):
- Events: 99 million × $1 = $99
Total: $99/month
```

---

**Next**: See complete implementations in [eventbridge_create.tf](./eventbridge_create.tf)
