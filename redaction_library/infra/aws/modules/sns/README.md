# SNS (Simple Notification Service) - Pub/Sub Messaging

## 🎯 What is SNS?

**Simple Explanation:**
SNS is like a WhatsApp broadcast group. You send one message to a topic, and everyone subscribed to that topic receives it instantly. It's a publish-subscribe (pub/sub) messaging service.

Think of it as:
- **Direct email** = Sending email to one person at a time
- **SNS** = Broadcasting to multiple subscribers simultaneously

**Real-World Analogy:**
- **School announcement system** = Principal speaks once, all classrooms hear it
- **YouTube channel** = Creator publishes video, all subscribers get notified
- **News alert** = Breaking news sent to all subscribers (email, SMS, app push)

**Technical Definition:**
Amazon SNS is a fully managed pub/sub messaging service that enables you to decouple microservices, distributed systems, and event-driven serverless applications. Send messages to multiple subscribers simultaneously.

---

## 🤔 Why Do I Need SNS?

### Without SNS (Direct Notification):

```
PROBLEMS with sending notifications directly:

1. Must know all recipients in advance
2. Send same message multiple times (one per recipient)
3. If one recipient fails, all fail
4. Tight coupling (sender knows all receivers)
5. Hard to add new recipients

Example: Order placed notification
Code must send to:
- Email service (for customer)
- SMS service (for customer)
- Slack (for team)
- Database (for logging)
- Analytics (for tracking)

If any service fails, notification code breaks!
```

---

### With SNS (Pub/Sub):

```
BENEFITS:

✅ Decoupling: Publisher doesn't know subscribers
✅ Fan-out: One message to many recipients
✅ Multiple protocols: Email, SMS, HTTP, Lambda, SQS
✅ Reliability: Retry failed deliveries
✅ Easy to add/remove subscribers
✅ Cheap: $0.50 per 1M notifications

Example: Order placed notification
Publish once to "order-placed" topic
    ↓
SNS automatically sends to ALL subscribers:
- Lambda function (process order)
- SQS queue (background processing)
- Email (customer notification)
- SMS (delivery notification)
- HTTP endpoint (webhook to external system)
```

---

## 📊 Real-World Example

### Scenario: E-commerce Order Placement

**Without SNS (Bad):**
```python
def place_order(order_id):
    # Direct calls to multiple services
    email_service.send(customer_email, "Order placed")  # Fails?
    sms_service.send(customer_phone, "Order confirmed")  # Fails?
    inventory_service.update(order_id)  # Fails?
    analytics.track("order_placed", order_id)  # Fails?

    # If any service is down, entire function fails!
    # Code is tightly coupled to all services!
```

**With SNS (Good):**
```python
def place_order(order_id):
    # Publish once to SNS topic
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:order-placed',
        Message=json.dumps({'order_id': order_id})
    )
    # Done! SNS handles the rest

# SNS automatically notifies ALL subscribers:
# - Lambda 1: Send email
# - Lambda 2: Send SMS
# - Lambda 3: Update inventory
# - SQS Queue: Analytics processing
# - HTTP: Webhook to shipping partner
```

**Benefits:**
- Order placement succeeds immediately
- Each subscriber processes independently
- If email fails, SMS still sent
- Easy to add new subscribers (no code change!)

**Cost:**
- 1,000 orders/day = 30,000 notifications/month
- SNS cost: $0.015/month (30K × $0.50 per 1M)
- **Essentially FREE!**

---

## 🔑 Key Concepts

### 1. Topics and Subscriptions

#### **Topic = Broadcast Channel**

```
Think of a topic as a YouTube channel or WhatsApp group

Topic: "order-placed"
  ├─ Subscriber 1: Lambda function (send email)
  ├─ Subscriber 2: SQS queue (process order)
  ├─ Subscriber 3: Email address (notify admin)
  └─ Subscriber 4: HTTP endpoint (webhook)

When you publish to topic, ALL subscribers receive message!
```

**Topic Naming:**
```hcl
# Good names
order-placed
user-signup-completed
payment-failed
system-alert-critical

# Bad names
topic1
notifications
events
```

---

#### **Subscriptions = Who Receives Messages**

**Supported Protocols:**
```
1. Email - Send to email address
   Example: admin@company.com receives alerts

2. Email-JSON - Send JSON to email
   Example: For programmatic processing

3. SMS - Send text messages
   Example: Critical alerts to phone

4. HTTP/HTTPS - Send to web endpoint
   Example: Webhook to external service

5. Lambda - Trigger Lambda function
   Example: Process event asynchronously

6. SQS - Send to SQS queue
   Example: Fan-out pattern (SNS → SQS → Lambda)

7. Application - Mobile push notifications
   Example: iOS/Android app notifications

8. Firehose - Stream to data lakes
   Example: Analytics and archival
```

---

### 2. Message Filtering

**What is it?**
Subscribers only receive messages matching their filter criteria.

**Why?**
Not all subscribers need all messages!

```
Topic: "order-events"

Message 1: {"event": "order-placed", "total": 50}
Message 2: {"event": "order-cancelled", "total": 100}
Message 3: {"event": "order-placed", "total": 500}

Subscriber 1 (Email): Filter = "event = order-cancelled"
  → Receives only Message 2

Subscriber 2 (Lambda): Filter = "total > 100"
  → Receives Messages 2 and 3

Subscriber 3 (SQS): No filter
  → Receives ALL messages
```

**Example Filter Policy:**
```json
{
  "event": ["order-placed"],
  "total": [{"numeric": [">", 100]}]
}
```

---

### 3. Message Attributes

**What are they?**
Metadata attached to messages (used for filtering).

**Example:**
```python
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123/orders',
    Message='Order placed',
    MessageAttributes={
        'event': {'DataType': 'String', 'StringValue': 'order-placed'},
        'total': {'DataType': 'Number', 'StringValue': '150'},
        'priority': {'DataType': 'String', 'StringValue': 'high'}
    }
)
```

Subscribers can filter based on these attributes!

---

### 4. Fan-Out Pattern (SNS + SQS)

**Why combine SNS and SQS?**
- SNS: Broadcast to multiple targets
- SQS: Reliable message queuing with retries

**Architecture:**
```
Publisher → SNS Topic → SQS Queue 1 → Lambda 1 (Email)
                     → SQS Queue 2 → Lambda 2 (SMS)
                     → SQS Queue 3 → Lambda 3 (Analytics)

Benefits:
✅ If Lambda 1 fails, queues 2 and 3 still work
✅ Each Lambda can retry independently
✅ Throttling protection (SQS buffers messages)
✅ Separate DLQ for each subscriber
```

**Example:**
```hcl
# SNS Topic
resource "aws_sns_topic" "orders" {
  name = "order-events"
}

# SQS Queue 1 (Email processing)
resource "aws_sqs_queue" "email_queue" {
  name = "order-email-queue"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_queue.arn
}

# SQS Queue 2 (SMS processing)
resource "aws_sqs_queue" "sms_queue" {
  name = "order-sms-queue"
}

resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sms_queue.arn
}
```

---

### 5. Delivery Retry Policy

**What is it?**
SNS automatically retries failed deliveries.

**Default Retry:**
```
HTTP/HTTPS endpoints:
- Immediate retry
- Retry after 20 seconds
- Retry with backoff (40s, 80s, 160s...)
- Up to 100,015 seconds (27+ hours)

Lambda:
- Retries 3 times immediately
- If all fail, message lost (use DLQ!)

SQS:
- Retries indefinitely (SQS handles retries)
```

**Custom Retry Policy:**
```hcl
resource "aws_sns_topic" "custom_retry" {
  name = "critical-events"

  # Custom retry policy (JSON)
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 600
        numRetries         = 5
        numNoDelayRetries  = 0
        numMinDelayRetries = 2
        numMaxDelayRetries = 3
        backoffFunction    = "exponential"
      }
    }
  })
}
```

---

### 6. Message Encryption

**In Transit:**
- Always encrypted with HTTPS (automatic)

**At Rest:**
- Optional KMS encryption for topics

```hcl
resource "aws_sns_topic" "encrypted" {
  name              = "secure-topic"
  kms_master_key_id = var.kms_key_id  # From KMS module

  # All messages encrypted with KMS
}
```

---

## 🛠️ Common SNS Patterns

### Pattern 1: Simple Email Notifications

**Use Case:** Send alerts to admin

```hcl
# Create topic
resource "aws_sns_topic" "system_alerts" {
  name = "${var.project_name}-system-alerts-${var.environment}"

  tags = {
    Name = "System Alerts"
  }
}

# Subscribe admin email
resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.system_alerts.arn
  protocol  = "email"
  endpoint  = "admin@company.com"

  # Admin must confirm subscription via email!
}
```

**Publish Alert:**
```python
import boto3

sns = boto3.client('sns')

sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123456789012:system-alerts',
    Subject='CRITICAL: Database Down',
    Message='Database connection failed at 10:30 AM'
)
```

---

### Pattern 2: Lambda Trigger (Event-Driven)

**Use Case:** Process events asynchronously

```hcl
# SNS Topic
resource "aws_sns_topic" "user_events" {
  name = "user-events"
}

# Lambda subscription
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.user_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process_user_event.arn
}

# Allow SNS to invoke Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_user_event.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_events.arn
}
```

**Lambda Handler:**
```python
def lambda_handler(event, context):
    for record in event['Records']:
        message = record['Sns']['Message']
        print(f"Processing: {message}")

        # Process event
        process_user_event(message)
```

---

### Pattern 3: Fan-Out (SNS + Multiple SQS)

**Use Case:** One event triggers multiple workflows

```hcl
# SNS Topic
resource "aws_sns_topic" "order_placed" {
  name = "order-placed"
}

# SQS Queue 1: Email notifications
resource "aws_sqs_queue" "email" {
  name = "order-email-queue"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.order_placed.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email.arn
}

# SQS Queue 2: Inventory updates
resource "aws_sqs_queue" "inventory" {
  name = "order-inventory-queue"
}

resource "aws_sns_topic_subscription" "inventory_sub" {
  topic_arn = aws_sns_topic.order_placed.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.inventory.arn
}

# SQS Queue 3: Analytics
resource "aws_sqs_queue" "analytics" {
  name = "order-analytics-queue"
}

resource "aws_sns_topic_subscription" "analytics_sub" {
  topic_arn = aws_sns_topic.order_placed.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.analytics.arn
}

# Allow SNS to send to SQS queues
resource "aws_sqs_queue_policy" "email_policy" {
  queue_url = aws_sqs_queue.email.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action = "sqs:SendMessage"
      Resource = aws_sqs_queue.email.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.order_placed.arn
        }
      }
    }]
  })
}

# Repeat policy for other queues...
```

---

### Pattern 4: Message Filtering

**Use Case:** Subscribers only get relevant messages

```hcl
# Topic
resource "aws_sns_topic" "orders" {
  name = "order-events"
}

# Subscription 1: High-value orders only
resource "aws_sns_topic_subscription" "high_value" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.high_value_alert.arn

  filter_policy = jsonencode({
    total = [{ numeric = [">", 1000] }]
  })
}

# Subscription 2: Cancelled orders only
resource "aws_sns_topic_subscription" "cancelled" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.refund_queue.arn

  filter_policy = jsonencode({
    status = ["cancelled"]
  })
}
```

**Publish with Attributes:**
```python
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123/order-events',
    Message=json.dumps({'order_id': '12345'}),
    MessageAttributes={
        'total': {'DataType': 'Number', 'StringValue': '1500'},
        'status': {'DataType': 'String', 'StringValue': 'placed'}
    }
)
# Only high_value subscription receives this (total > 1000)
```

---

### Pattern 5: HTTP/HTTPS Webhook

**Use Case:** Send events to external system

```hcl
resource "aws_sns_topic" "webhooks" {
  name = "external-webhooks"
}

resource "aws_sns_topic_subscription" "external_api" {
  topic_arn = aws_sns_topic.webhooks.arn
  protocol  = "https"
  endpoint  = "https://external-api.com/webhook"

  # SNS sends confirmation request to this URL
  # Endpoint must confirm subscription
}
```

---

## 🤔 Should I Create One SNS Topic or Multiple Topics?

### The Question

Your app needs to send notifications for:
- User signup
- Order placed
- Payment failed
- System alerts

Do you create:
- **Option A**: One topic for all events
- **Option B**: Separate topic for each event type

**Short Answer**: **Option B** (separate topics) is better

---

### Option A: One Topic for Everything

```
app-events-topic
├─ Message: {"type": "user-signup", ...}
├─ Message: {"type": "order-placed", ...}
├─ Message: {"type": "payment-failed", ...}
└─ Message: {"type": "system-alert", ...}
```

**Pros:**
- ✅ Simpler (one topic to manage)

**Cons:**
- ❌ All subscribers get all message types (noise!)
- ❌ Must use message filtering (complex)
- ❌ Hard to manage permissions (everyone sees everything)
- ❌ Can't set different retry policies per event type
- ❌ Monitoring is difficult (all mixed together)

---

### Option B: Separate Topics (RECOMMENDED)

```
user-signup-topic      → Email welcome, create profile
order-placed-topic     → Email receipt, update inventory
payment-failed-topic   → Alert admin, retry payment
system-alert-topic     → Email ops team, create ticket
```

**Pros:**
- ✅ **Clear purpose**: Each topic has one responsibility
- ✅ **Targeted subscribers**: Only relevant subscriptions
- ✅ **Easy permissions**: Grant access per topic
- ✅ **Better monitoring**: Track metrics per topic
- ✅ **Flexible retry**: Different policies per topic
- ✅ **No filtering needed**: Subscribers get exactly what they need

**Cons:**
- ⚠️ More topics to manage (but worth it!)

---

### Decision Tree

```
Are these events related and consumed by same subscribers?
│
├─ YES (all subscribers need all events)
│  └─ ONE topic might be OK
│     Example: All "order updates" (placed, shipped, delivered)
│
└─ NO (different events, different subscribers)
   └─ SEPARATE topics
      Example: User events, order events, payment events
```

**Golden Rule:**
> One topic = one event type. Separate topics for separate concerns.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: No Confirmation for Email/SMS Subscriptions

```hcl
# WRONG - User won't receive notifications until they confirm!
resource "aws_sns_topic_subscription" "bad" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "user@example.com"
  # User must click confirmation link in email!
  # Until then, subscription is "PendingConfirmation"
}
```

**Solution:**
- For automation, use Lambda or SQS (no confirmation needed)
- For email/SMS, manually confirm or use AWS Console/CLI

---

### ❌ Mistake 2: Missing SQS Queue Policy

```hcl
# WRONG - SNS can't send to SQS!
resource "aws_sns_topic_subscription" "bad" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.my_queue.arn
  # Missing: SQS queue policy to allow SNS!
}
```

**Fix:**
```hcl
# CORRECT - Allow SNS to send to SQS
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.my_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action = "sqs:SendMessage"
      Resource = aws_sqs_queue.my_queue.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.events.arn }
      }
    }]
  })
}
```

---

### ❌ Mistake 3: Missing Lambda Permission

```hcl
# WRONG - SNS can't invoke Lambda!
resource "aws_sns_topic_subscription" "bad" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.processor.arn
  # Missing: Lambda permission!
}
```

**Fix:**
```hcl
# CORRECT - Allow SNS to invoke Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.events.arn
}
```

---

### ❌ Mistake 4: Large Messages (> 256 KB)

```python
# WRONG - SNS has 256 KB limit!
large_message = "x" * 300000  # 300 KB
sns.publish(TopicArn=topic_arn, Message=large_message)
# Error: Message too large!
```

**Fix:**
```python
# CORRECT - Store large data in S3, send S3 key
s3.put_object(Bucket='my-bucket', Key='data.json', Body=large_data)

sns.publish(
    TopicArn=topic_arn,
    Message=json.dumps({'s3_key': 'data.json'})
)
```

---

## 🎯 Best Practices

### 1. Always Use KMS Encryption for Sensitive Data

```hcl
resource "aws_sns_topic" "secure" {
  name              = "secure-notifications"
  kms_master_key_id = var.kms_key_id

  tags = {
    Sensitive = "true"
  }
}
```

---

### 2. Use Fan-Out Pattern (SNS + SQS)

```hcl
# Better reliability and retry control
SNS Topic → SQS Queue 1 → Lambda 1
         → SQS Queue 2 → Lambda 2
         → SQS Queue 3 → Lambda 3

# Each Lambda has independent retries and DLQ
```

---

### 3. Use Descriptive Topic Names

```hcl
# Good
topic_name = "${var.project_name}-${var.environment}-${var.event_type}"
# Result: "ecommerce-prod-order-placed"

# Bad
topic_name = "topic1"
```

---

### 4. Set Up CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "failed_notifications" {
  alarm_name          = "sns-delivery-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    TopicName = aws_sns_topic.important.name
  }
}
```

---

### 5. Use Message Filtering to Reduce Noise

```hcl
resource "aws_sns_topic_subscription" "filtered" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.handler.arn

  # Only receive critical events
  filter_policy = jsonencode({
    priority = ["critical", "high"]
  })
}
```

---

## 💰 SNS Pricing

**Publishing:**
- HTTP/HTTPS: $0.60 per 1M notifications
- Email/Email-JSON: $2.00 per 100K notifications
- SMS: Varies by country ($0.00645 per SMS in US)
- Mobile Push: $0.50 per 1M notifications
- Lambda/SQS: $0.50 per 1M notifications

**Data Transfer:**
- Within same region: **FREE**
- Cross-region: $0.01/GB

**Examples:**
```
Small App (10K notifications/month to Lambda):
- Notifications: FREE (under 1M)
- Total: $0/month

Medium App (1M notifications/month):
- Lambda/SQS: $0.50
- Email (10K): $0.20
- Total: $0.70/month

Large App (100M notifications/month):
- Lambda/SQS: $50
- Email (1M): $20
- SMS (100K): $645
- Total: $715/month

Essentially FREE for most pub/sub use cases!
```

---

**Next**: See complete implementations in [sns_topics_create.tf](./sns_topics_create.tf)
