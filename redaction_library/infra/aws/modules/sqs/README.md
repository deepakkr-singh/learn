# SQS (Simple Queue Service) - Message Queue

## 🎯 What is SQS?

**Simple Explanation:**
SQS is like a post office mailbox for your applications. One application puts messages in the queue, another application picks them up later. Messages wait in line until they're processed.

Think of it as:
- **Direct function call** = Calling someone on the phone (must answer immediately)
- **SQS** = Leaving a voicemail (they check it when they're free)

**Real-World Analogy:**
- **Restaurant kitchen** = Customer orders (messages) go into a queue, chefs process them one by one
- **Post office** = You drop mail in mailbox, postal worker collects and delivers later
- **Coffee shop** = Orders are called out in sequence, customers pick up when ready

**Technical Definition:**
Amazon SQS is a fully managed message queuing service that enables decoupling and scaling of microservices, distributed systems, and serverless applications. Messages are stored reliably until consumed.

---

## 🤔 Why Do I Need SQS?

### Without SQS (Direct/Synchronous Processing):

```
PROBLEMS with direct function calls:

1. Caller must wait for response (slow!)
2. If receiver is down, request fails
3. Traffic spikes overwhelm receiver
4. No retry mechanism
5. Tight coupling (caller needs to know receiver)

Example: E-commerce order processing
User places order → Calls payment API → Calls inventory API → Calls shipping API
If any API is slow/down, user waits or sees error!
```

---

### With SQS (Asynchronous Processing):

```
BENEFITS:

✅ Decoupling: Services don't need to know about each other
✅ Asynchronous: Caller doesn't wait for processing
✅ Buffering: Queue absorbs traffic spikes
✅ Reliability: Messages not lost if receiver is down
✅ Scalability: Multiple consumers can process in parallel
✅ Retry: Automatic retry on failure
✅ Cheap: $0.40 per 1M requests (first 1M free)

Example: E-commerce order processing
User places order → Message to SQS → User sees "Order received!"
                         ↓
           Lambda processes when ready (payment, inventory, shipping)
```

---

## 📊 Real-World Example

### Scenario: Photo Processing App

**Problem**: User uploads photo, needs thumbnail + optimization

**Without SQS (Bad):**
```
User uploads photo.jpg
    ↓
Lambda receives upload
    ↓ (user waits 30 seconds...)
Lambda creates thumbnail (10 sec)
Lambda optimizes image (10 sec)
Lambda uploads to S3 (10 sec)
    ↓
User finally sees "Upload complete!"

Problem: User waits 30 seconds! Terrible UX!
```

**With SQS (Good):**
```
User uploads photo.jpg
    ↓
Lambda receives upload
    ↓
Put message in SQS queue
    ↓
User sees "Upload received!" (1 second!)

Meanwhile (asynchronously):
SQS Queue → Lambda Worker 1 (creates thumbnail)
         → Lambda Worker 2 (optimizes image)
         → Lambda Worker 3 (generates variants)

All processed in background, user can continue browsing!
```

**Cost:**
- 1,000 photo uploads/day = 30,000 messages/month
- SQS cost: $0.012/month (30K messages × $0.40 per 1M)
- **Essentially FREE!**

---

## 🔑 Key Concepts

### 1. Standard Queue vs FIFO Queue

#### **Standard Queue (Default)**

```
Order: Best-effort ordering (NOT guaranteed order)
Throughput: Unlimited (millions of messages/sec)
Duplicates: At-least-once delivery (may receive same message twice)
Cost: Cheaper

Use cases:
✅ Log processing (order doesn't matter)
✅ Image processing (order doesn't matter)
✅ Email sending (order doesn't matter)
✅ Background jobs
✅ Event processing
```

**Example:**
```
Messages sent:     [1, 2, 3, 4, 5]
Messages received: [1, 3, 2, 5, 4, 3]  ← Out of order, duplicate 3!
```

---

#### **FIFO Queue (First In, First Out)**

```
Order: Strict ordering (GUARANTEED order)
Throughput: Limited (300-3000 messages/sec)
Duplicates: Exactly-once delivery (no duplicates)
Cost: Slightly more expensive

Use cases:
✅ Financial transactions (order matters!)
✅ Stock trading (order matters!)
✅ Chat messages (need correct order)
✅ Command queue (execute in sequence)
```

**Example:**
```
Messages sent:     [1, 2, 3, 4, 5]
Messages received: [1, 2, 3, 4, 5]  ← Exactly as sent!
```

**FIFO Queue Name Requirement:**
- Must end with `.fifo`
- Example: `orders.fifo`, `transactions.fifo`

---

### 2. Message Visibility Timeout

**What is it?**
When a consumer picks up a message, it becomes "invisible" to other consumers for X seconds.

**Why?**
Prevents multiple consumers from processing the same message simultaneously.

```
Timeline:

00:00 - Message in queue (visible)
00:01 - Consumer A picks message (message becomes invisible for 30 sec)
00:05 - Consumer B tries to get message (gets nothing, message still invisible)
00:31 - If Consumer A didn't delete message, it becomes visible again
        (Consumer A probably failed, retry!)
```

**Default:** 30 seconds
**Range:** 0 seconds to 12 hours
**Recommendation:** Set to 6x your processing time

**Example:**
- If processing takes 5 seconds, set visibility timeout to 30 seconds
- If processing takes 2 minutes, set visibility timeout to 12 minutes

---

### 3. Dead Letter Queue (DLQ)

**What is it?**
A separate queue for messages that fail processing multiple times.

**Why?**
Prevents poison messages (bad messages) from blocking the queue forever.

```
Normal Flow:
User sends message → Main Queue → Lambda processes → Success! → Delete message

Failure Flow:
User sends message → Main Queue → Lambda fails (retry 1)
                                 → Lambda fails (retry 2)
                                 → Lambda fails (retry 3)
                                 → Move to Dead Letter Queue

Now you can:
- Inspect failed messages
- Debug the issue
- Manually reprocess or discard
```

**Configuration:**
- **Max Receive Count**: How many retries before moving to DLQ?
  - Common: 3-5 retries
  - Financial: 1-2 retries (fail fast)
  - Background jobs: 5-10 retries

**Best Practice:**
- Always create a DLQ for production queues
- Set up CloudWatch alerts when messages arrive in DLQ
- Periodically review and fix issues

---

### 4. Message Retention Period

**What is it?**
How long SQS keeps messages before deleting them.

**Default:** 4 days
**Range:** 1 minute to 14 days

**Example:**
```
Day 1: Message arrives in queue
Day 2: No consumer picks it up
Day 3: Still waiting...
Day 4: Still waiting...
Day 5: Message automatically deleted (retention expired)
```

**Recommendations:**
- **Real-time processing**: 1-2 days (messages should be processed quickly)
- **Background jobs**: 4-7 days (default is fine)
- **Batch processing**: 7-14 days (process weekly)

---

### 5. Long Polling vs Short Polling

#### **Short Polling (Default, NOT recommended)**
```
Consumer asks: "Any messages?"
SQS responds: "Let me check 1 server... no messages" (might miss messages on other servers!)
Consumer waits 1 second
Consumer asks again: "Any messages?"
...repeat forever...

Problems:
❌ Wastes API calls (costs money)
❌ May not find messages immediately
❌ Empty responses cost $$$
```

#### **Long Polling (RECOMMENDED)**
```
Consumer asks: "Any messages?"
SQS responds: "Let me check ALL servers and wait up to 20 seconds..."
  → If message arrives within 20 sec, return immediately
  → If no message after 20 sec, return empty response

Benefits:
✅ Reduces API calls (saves money)
✅ Finds messages faster
✅ More efficient
```

**Configuration:**
```hcl
receive_wait_time_seconds = 20  # Enable long polling (0 = short polling)
```

**Cost Savings:**
- Short polling: 10 requests/sec = 864,000 requests/day = $0.35/day
- Long polling: 1 request/20 sec = 4,320 requests/day = $0.002/day
- **Savings: 99.4%!**

---

## 🛠️ Common SQS Patterns

### Pattern 1: Asynchronous Task Processing

**Use Case:** User uploads file, process in background

```hcl
# Main queue for file processing
resource "aws_sqs_queue" "file_processing" {
  name                       = "${var.project_name}-file-processing-${var.environment}"
  visibility_timeout_seconds = 300  # 5 minutes to process
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds  = 20  # Long polling

  # Dead letter queue after 3 failures
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.file_processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "File Processing Queue"
  }
}

# Dead letter queue
resource "aws_sqs_queue" "file_processing_dlq" {
  name                       = "${var.project_name}-file-processing-dlq-${var.environment}"
  message_retention_seconds  = 1209600  # 14 days (keep failed messages longer)

  tags = {
    Name = "File Processing DLQ"
  }
}
```

**Lambda Consumer:**
```python
import boto3
import json

sqs = boto3.client('sqs')
queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/file-processing-dev'

def lambda_handler(event, context):
    # Lambda automatically polls SQS
    for record in event['Records']:
        message = json.loads(record['body'])
        file_key = message['file_key']

        try:
            # Process file
            process_file(file_key)

            # Success! Message auto-deleted by Lambda
            print(f"Processed {file_key}")

        except Exception as e:
            # Failure! Lambda will retry (up to 3 times)
            print(f"Failed to process {file_key}: {e}")
            raise  # Re-raise to trigger retry
```

---

### Pattern 2: Load Leveling (Buffer Traffic Spikes)

**Use Case:** Black Friday sale, millions of orders

```
Normal traffic:     100 orders/hour
Black Friday:       100,000 orders/hour (1000x spike!)

Without SQS:
Database overwhelmed → Crashes → All orders lost!

With SQS:
Orders → SQS Queue → Processed at steady rate
       (absorbs spike)   (100/hour, no crash)

Queue size: 99,900 pending (processed over next few hours)
Result: All orders saved, database happy!
```

**Configuration:**
```hcl
resource "aws_sqs_queue" "orders" {
  name                       = "orders-queue"
  message_retention_seconds  = 1209600  # 14 days (handle long backlog)
  visibility_timeout_seconds = 300

  tags = {
    Purpose = "Buffer order spikes"
  }
}

# Lambda with reserved concurrency (limit processing rate)
resource "aws_lambda_function" "order_processor" {
  function_name    = "order-processor"
  reserved_concurrent_executions = 10  # Max 10 concurrent (protect DB)

  # ... other config
}
```

---

### Pattern 3: Fan-Out (One Message, Multiple Consumers)

**Use Case:** User places order → Notify payment, inventory, shipping

**Better with SNS + SQS:**
```
User places order
    ↓
SNS Topic
    ├─ SQS Queue 1 → Lambda (Payment)
    ├─ SQS Queue 2 → Lambda (Inventory)
    └─ SQS Queue 3 → Lambda (Shipping)

Each Lambda processes independently!
```

**Why SNS + SQS instead of just SQS?**
- SNS sends to multiple queues simultaneously
- Each service has its own queue (decoupled)
- If one service is down, others still work

---

### Pattern 4: FIFO Queue for Ordered Processing

**Use Case:** Chat application (messages must be in order)

```hcl
resource "aws_sqs_queue" "chat_messages" {
  name                        = "chat-messages.fifo"  # Must end with .fifo
  fifo_queue                  = true
  content_based_deduplication = true  # Auto-deduplicate based on content

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400  # 1 day (chat messages)

  tags = {
    Purpose = "Chat message ordering"
  }
}
```

**Send Message:**
```python
import boto3

sqs = boto3.client('sqs')

sqs.send_message(
    QueueUrl='https://sqs.us-east-1.amazonaws.com/123/chat-messages.fifo',
    MessageBody='Hello world!',
    MessageGroupId='chat-room-123',  # Required for FIFO
    MessageDeduplicationId='unique-msg-id'  # Or use content_based_deduplication
)
```

---

## 🤔 Should I Create One SQS Queue or Multiple Queues?

### The Question

Your app needs to:
- Process file uploads
- Send email notifications
- Generate reports
- Process payments

Do you create:
- **Option A**: One queue for everything
- **Option B**: Separate queue for each task

**Short Answer**: **Option B** (separate queues) is better

---

### Option A: One Queue for Everything

```
my-app-queue
├─ Message type: file-upload
├─ Message type: email
├─ Message type: report
└─ Message type: payment
```

**Pros:**
- ✅ Simpler (one queue to manage)

**Cons:**
- ❌ Can't set different retry policies per task type
- ❌ Can't scale consumers independently
- ❌ Payment failures affect file uploads
- ❌ Hard to monitor (all mixed together)
- ❌ Can't prioritize (payments more important than reports)

---

### Option B: Separate Queues (RECOMMENDED)

```
my-app-file-uploads-queue     (retry 3x, 5 min timeout)
my-app-email-queue            (retry 5x, 30 sec timeout)
my-app-reports-queue          (retry 10x, 30 min timeout)
my-app-payments-queue         (retry 1x, 1 min timeout, FIFO)
```

**Pros:**
- ✅ **Different retry policies**: Payments retry 1x, reports retry 10x
- ✅ **Independent scaling**: 10 workers for payments, 2 for reports
- ✅ **Isolation**: Email failures don't affect payments
- ✅ **Monitoring**: Track metrics per queue
- ✅ **Prioritization**: Critical queues get more resources
- ✅ **Security**: Different IAM permissions per queue

**Cons:**
- ⚠️ More queues to manage (but worth it!)

---

### Decision Tree

```
Are these tasks similar in nature?
│
├─ YES (all file processing, all emails, etc)
│  └─ ONE queue is OK
│     Example: All file uploads go to one queue
│
└─ NO (different types: files, emails, payments, etc)
   └─ SEPARATE queues
      Example: Files, emails, payments each get own queue
```

**Golden Rule:**
> Separate queues if tasks have different retry policies, timeouts, or scaling needs.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: No Dead Letter Queue

```hcl
# WRONG - No DLQ!
resource "aws_sqs_queue" "bad" {
  name = "my-queue"
  # Poison messages will retry forever, blocking queue!
}
```

**Fix:**
```hcl
# CORRECT - Always use DLQ
resource "aws_sqs_queue" "good" {
  name = "my-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "my-queue-dlq"
}
```

---

### ❌ Mistake 2: Short Polling (Wastes Money)

```hcl
# WRONG - Short polling (default)
resource "aws_sqs_queue" "bad" {
  name = "my-queue"
  receive_wait_time_seconds = 0  # Short polling!
}
```

**Fix:**
```hcl
# CORRECT - Long polling
resource "aws_sqs_queue" "good" {
  name = "my-queue"
  receive_wait_time_seconds = 20  # Long polling (save 99% on API costs!)
}
```

---

### ❌ Mistake 3: Visibility Timeout Too Short

```hcl
# WRONG - 10 second timeout, but processing takes 60 seconds!
resource "aws_sqs_queue" "bad" {
  name = "my-queue"
  visibility_timeout_seconds = 10

  # Result: Message becomes visible again after 10 sec
  # Another consumer picks it up → Duplicate processing!
}
```

**Fix:**
```hcl
# CORRECT - Timeout = 6x processing time
resource "aws_sqs_queue" "good" {
  name = "my-queue"
  visibility_timeout_seconds = 360  # 6 minutes (6x 60 sec processing)
}
```

---

### ❌ Mistake 4: Not Deleting Messages After Processing

```python
# WRONG - Process but don't delete
for record in event['Records']:
    process_message(record['body'])
    # Forgot to delete! Message will reappear after visibility timeout!
```

**Fix:**
```python
# CORRECT - Lambda auto-deletes on success
def lambda_handler(event, context):
    for record in event['Records']:
        process_message(record['body'])
        # Lambda automatically deletes if function succeeds
        # Only re-raises exception if you want retry
```

---

## 🎯 Best Practices

### 1. Always Use Dead Letter Queue

```hcl
resource "aws_sqs_queue" "main" {
  name = "orders-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  name                      = "orders-queue-dlq"
  message_retention_seconds = 1209600  # 14 days
}

# CloudWatch alarm when messages arrive in DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "orders-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}
```

---

### 2. Enable Long Polling

```hcl
resource "aws_sqs_queue" "efficient" {
  name                      = "my-queue"
  receive_wait_time_seconds = 20  # Maximum for long polling
}
```

---

### 3. Encrypt Messages with KMS

```hcl
resource "aws_sqs_queue" "secure" {
  name                      = "secure-queue"
  kms_master_key_id        = var.kms_key_id  # From KMS module
  kms_data_key_reuse_period_seconds = 300
}
```

---

### 4. Use Descriptive Names

```hcl
# Good
queue_name = "${var.project_name}-${var.environment}-${var.purpose}"
# Result: "ecommerce-prod-order-processing"

# Bad
queue_name = "queue1"
```

---

### 5. Set Appropriate Retention

```hcl
resource "aws_sqs_queue" "appropriate_retention" {
  name = "my-queue"

  # Real-time: 1-2 days
  message_retention_seconds = 172800  # 2 days

  # Batch processing: 7-14 days
  # message_retention_seconds = 1209600  # 14 days
}
```

---

## 💰 SQS Pricing

**Requests:**
- First 1 million requests/month: **FREE**
- After: $0.40 per 1 million requests

**Data Transfer:**
- Within same region: **FREE**
- Cross-region: $0.01/GB

**Examples:**
```
Small App (100K messages/month):
- Requests: FREE (under 1M)
- Total: $0/month

Medium App (10M messages/month):
- Requests: $3.60/month (9M × $0.40)
- Total: $3.60/month

Large App (100M messages/month):
- Requests: $39.60/month (99M × $0.40)
- Total: $39.60/month

Essentially FREE for most applications!
```

---

**Next**: See complete implementations in [sqs_queues_create.tf](./sqs_queues_create.tf)
