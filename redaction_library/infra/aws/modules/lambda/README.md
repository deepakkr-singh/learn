# Lambda - Serverless Functions (Run Code Without Servers)

## 🎯 What is Lambda?

**Simple Explanation:**
Lambda is like hiring someone to do a specific job for you - they show up, do the work, and leave. You don't need to hire them full-time or provide them an office.

Think of it as:
- **Traditional server** = Hiring a full-time employee who sits at a desk 24/7 (even when there's no work)
- **Lambda** = Hiring a contractor who only works when you need them (pay only for work done)

**Real-World Analogy:**
Imagine a restaurant:
- **EC2 (Traditional)** = Full-time chef who works 24/7, paid by the hour even when restaurant is closed
- **Lambda (Serverless)** = On-call chef who only comes when you have customers, paid only for cooking time

**Technical Definition:**
AWS Lambda is a serverless compute service that runs your code in response to events without requiring you to provision or manage servers. You pay only for the compute time you consume.

---

## 🤔 Why Do I Need Lambda?

### Without Lambda (Traditional EC2):
```
EXPENSIVE and COMPLEX

1. Rent EC2 server ($50/month)
2. Install operating system
3. Install dependencies (Python, Node.js, etc.)
4. Configure auto-scaling
5. Monitor server health
6. Patch security updates
7. Pay 24/7 even when idle

Cost: $50-200/month
Complexity: High
Maintenance: Constant
```

---

### With Lambda (Serverless):
```
CHEAP and SIMPLE

1. Write function code
2. Upload to Lambda
3. Lambda handles:
   - Scaling (automatic)
   - Servers (invisible to you)
   - Operating system (managed by AWS)
   - Security patches (automatic)
   - High availability (built-in)

Cost: $0-5/month for most apps
Complexity: Low
Maintenance: None
```

**Benefits:**
- ✅ **No Servers**: AWS manages everything
- ✅ **Auto-Scaling**: Handles 1 or 10,000 requests automatically
- ✅ **Pay Per Use**: Only pay for execution time (not idle time)
- ✅ **High Availability**: Runs in multiple data centers automatically
- ✅ **Fast Deployment**: Upload code and run immediately
- ✅ **Multiple Languages**: Python, Node.js, Java, Go, .NET, Ruby

---

## 📊 Real-World Example

### Scenario: Image Resizing Service

**Without Lambda (EC2):**
```
┌─────────────────────────────────────────────────────────────┐
│ EC2 Server ($50/month, runs 24/7)                           │
│                                                              │
│  - Operating System: Ubuntu                                 │
│  - Runtime: Python 3.11                                     │
│  - App: Image resizer                                       │
│  - Running cost: $50/month (even at night when no traffic) │
│                                                              │
│  Problem: What if 1000 images uploaded at once?             │
│  → Server crashes (need more servers)                       │
│  → Need auto-scaling (complex setup)                        │
│  → Need load balancer ($16/month)                           │
│                                                              │
│  Total: $66+/month minimum                                  │
└─────────────────────────────────────────────────────────────┘
```

---

**With Lambda:**
```
┌─────────────────────────────────────────────────────────────┐
│                     USER UPLOADS IMAGE                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      S3 BUCKET                               │
│  - Image uploaded to: my-uploads/original/photo.jpg         │
│  - Triggers event: "New file uploaded!"                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   LAMBDA FUNCTION                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ def resize_image(event, context):                      │ │
│  │     # Get uploaded image                               │ │
│  │     bucket = event['bucket']                           │ │
│  │     key = event['key']                                 │ │
│  │                                                         │ │
│  │     # Download image                                   │ │
│  │     image = s3.get_object(Bucket=bucket, Key=key)      │ │
│  │                                                         │ │
│  │     # Resize to thumbnail                              │ │
│  │     thumbnail = resize(image, width=200)               │ │
│  │                                                         │ │
│  │     # Upload thumbnail                                 │ │
│  │     s3.put_object(                                      │ │
│  │         Bucket=bucket,                                  │ │
│  │         Key='thumbnails/photo.jpg',                    │ │
│  │         Body=thumbnail                                  │ │
│  │     )                                                   │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  - Execution time: 200ms per image                          │
│  - Cost: $0.0000002 per image (nearly free!)               │
│  - Auto-scales: 1 image or 1000 images, no problem         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      S3 BUCKET                               │
│  - Thumbnail saved to: my-uploads/thumbnails/photo.jpg      │
└─────────────────────────────────────────────────────────────┘
```

**Cost Comparison:**
```
EC2: $66/month (minimum, even with 0 uploads)

Lambda:
- 1,000 images/month = $0.20/month
- 10,000 images/month = $2.00/month
- 100,000 images/month = $20/month
```

---

## 🔑 Key Concepts

### 1. How Lambda Works (Event-Driven)

**Lambda doesn't run continuously. It runs when triggered by an event.**

**Common Triggers:**
```
1. API Gateway (HTTP request)
   → User visits https://api.example.com/users
   → Lambda processes request
   → Returns response

2. S3 (File uploaded)
   → User uploads file to S3
   → Lambda processes file
   → Saves result

3. DynamoDB (Database change)
   → New item added to table
   → Lambda sends notification
   → Email sent

4. EventBridge (Scheduled)
   → Every day at 2 AM
   → Lambda runs cleanup job
   → Old data deleted

5. SQS (Message in queue)
   → Message arrives in queue
   → Lambda processes message
   → Updates database
```

---

### 2. Lambda Execution Flow

```
1. EVENT OCCURS
   ↓
2. AWS STARTS LAMBDA
   - Finds available server
   - Loads your code
   - Sets up environment
   ↓
3. YOUR CODE RUNS
   - Processes event
   - Accesses database/S3/etc
   - Returns result
   ↓
4. AWS STOPS LAMBDA
   - Cleans up
   - Server returned to pool
   ↓
5. YOU PAY
   - Only for execution time
   - Billed per 100ms
```

**Example:**
```
Event: API request
Lambda runs for: 150ms
Cost: $0.0000000025 (basically free)
```

---

### 3. Lambda Limitations (Important!)

**Execution Time Limit:**
```
Maximum: 15 minutes per execution

Good for:
✅ API requests (milliseconds)
✅ Image processing (seconds)
✅ Data transformation (minutes)

NOT good for:
❌ Video encoding (hours)
❌ Machine learning training (hours/days)
❌ Long-running background jobs (> 15 min)

Solution for long jobs: Use Fargate or EC2
```

---

**Memory Limit:**
```
Minimum: 128 MB
Maximum: 10,240 MB (10 GB)

Good for:
✅ API processing
✅ File processing
✅ Database queries

NOT good for:
❌ In-memory big data processing
❌ Loading huge datasets into RAM

Solution: Use Fargate or EMR
```

---

**Package Size:**
```
Deployment package: 50 MB zipped, 250 MB unzipped

Good for:
✅ Application code
✅ Small dependencies

NOT good for:
❌ Huge ML models (hundreds of MB)
❌ Massive libraries

Solution: Use Lambda Layers or container images
```

---

### 4. Lambda Pricing

**Free Tier (Per Month):**
- 1 million requests
- 400,000 GB-seconds of compute

**After Free Tier:**
- $0.20 per 1 million requests
- $0.0000166667 per GB-second

**What's a GB-second?**
```
GB-second = Memory allocated × Execution time

Examples:
1. Lambda with 128 MB, runs for 1 second
   = 0.128 GB × 1 second = 0.128 GB-seconds
   Cost: $0.000002

2. Lambda with 1024 MB (1 GB), runs for 2 seconds
   = 1 GB × 2 seconds = 2 GB-seconds
   Cost: $0.000033

3. 100,000 requests, each 512 MB for 200ms
   = 100,000 × 0.512 GB × 0.2 sec = 10,240 GB-seconds
   Cost: $0.17 (requests) + $0.17 (compute) = $0.34
```

---

### 5. Lambda Runtimes (Languages)

**Supported Languages:**
- Python 3.8, 3.9, 3.10, 3.11, 3.12
- Node.js 16.x, 18.x, 20.x
- Java 8, 11, 17, 21
- .NET 6, 7, 8
- Go 1.x
- Ruby 3.2, 3.3
- Custom runtime (any language using containers)

**Most Popular:**
1. Python (simple, great for APIs, data processing)
2. Node.js (fast, great for real-time APIs)
3. Go (extremely fast, lowest memory usage)

---

## 🛠️ Common Lambda Patterns

### Pattern 1: API Handler (With API Gateway)

**Use Case:** REST API endpoint that queries database

```python
# lambda_function.py
import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

def lambda_handler(event, context):
    # Get user ID from API request
    user_id = event['pathParameters']['id']

    # Query DynamoDB
    response = table.get_item(Key={'user_id': user_id})
    user = response.get('Item')

    if not user:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'User not found'})
        }

    return {
        'statusCode': 200,
        'body': json.dumps(user)
    }
```

**Terraform:**
```hcl
resource "aws_lambda_function" "user_api" {
  filename      = "lambda.zip"
  function_name = "user-api"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"

  environment {
    variables = {
      TABLE_NAME = "users"
    }
  }
}

# API Gateway integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.user_api.invoke_arn
  integration_method = "POST"
}
```

---

### Pattern 2: S3 Event Processor

**Use Case:** Process files uploaded to S3

```python
# lambda_function.py
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get bucket and file from S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    print(f"Processing file: {bucket}/{key}")

    # Download file
    obj = s3.get_object(Bucket=bucket, Key=key)
    content = obj['Body'].read()

    # Process content (example: convert to uppercase)
    processed = content.decode('utf-8').upper()

    # Save processed file
    output_key = key.replace('input/', 'output/')
    s3.put_object(
        Bucket=bucket,
        Key=output_key,
        Body=processed.encode('utf-8')
    )

    return {'statusCode': 200, 'body': 'Success'}
```

**Terraform:**
```hcl
resource "aws_lambda_function" "s3_processor" {
  filename      = "lambda.zip"
  function_name = "s3-file-processor"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
}

# S3 trigger
resource "aws_s3_bucket_notification" "upload_trigger" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}
```

---

### Pattern 3: Scheduled Job (Cron)

**Use Case:** Daily cleanup job that runs at 2 AM

```python
# lambda_function.py
import boto3
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('sessions')

def lambda_handler(event, context):
    # Delete sessions older than 30 days
    cutoff_date = datetime.now() - timedelta(days=30)

    # Scan for old sessions
    response = table.scan(
        FilterExpression='created_at < :cutoff',
        ExpressionAttributeValues={':cutoff': cutoff_date.isoformat()}
    )

    # Delete old items
    with table.batch_writer() as batch:
        for item in response['Items']:
            batch.delete_item(Key={'session_id': item['session_id']})

    print(f"Deleted {len(response['Items'])} old sessions")
    return {'deleted': len(response['Items'])}
```

**Terraform:**
```hcl
resource "aws_lambda_function" "daily_cleanup" {
  filename      = "lambda.zip"
  function_name = "daily-cleanup"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300  # 5 minutes
}

# EventBridge rule (cron schedule)
resource "aws_cloudwatch_event_rule" "daily_cleanup" {
  name                = "daily-cleanup-schedule"
  description         = "Run cleanup every day at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily_cleanup.name
  target_id = "lambda"
  arn       = aws_lambda_function.daily_cleanup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cleanup.arn
}
```

---

### Pattern 4: SQS Queue Processor

**Use Case:** Process messages from queue (async job processing)

```python
# lambda_function.py
import json
import boto3

ses = boto3.client('ses')

def lambda_handler(event, context):
    # Process each message from SQS
    for record in event['Records']:
        message = json.loads(record['body'])

        # Send email
        ses.send_email(
            Source='noreply@example.com',
            Destination={'ToAddresses': [message['email']]},
            Message={
                'Subject': {'Data': message['subject']},
                'Body': {'Text': {'Data': message['body']}}
            }
        )

        print(f"Email sent to {message['email']}")

    return {'statusCode': 200}
```

**Terraform:**
```hcl
resource "aws_lambda_function" "email_sender" {
  filename      = "lambda.zip"
  function_name = "email-sender"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
}

# SQS trigger
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.emails.arn
  function_name    = aws_lambda_function.email_sender.arn
  batch_size       = 10
}
```

---

## 🤔 Should I Use One Lambda or Multiple Lambdas?

### The Question

You have an API with 5 endpoints:
- GET /users
- POST /users
- GET /orders
- POST /orders
- GET /analytics

Do you create:
- **Option A**: One Lambda for all 5 endpoints
- **Option B**: Separate Lambda per endpoint (5 Lambdas)

**Short Answer**: **Option B** (separate Lambdas) is usually better

---

### Option A: Monolithic Lambda

```python
# One Lambda handles all routes
def lambda_handler(event, context):
    path = event['path']
    method = event['httpMethod']

    if path == '/users' and method == 'GET':
        return get_users()
    elif path == '/users' and method == 'POST':
        return create_user()
    elif path == '/orders' and method == 'GET':
        return get_orders()
    elif path == '/orders' and method == 'POST':
        return create_order()
    elif path == '/analytics' and method == 'GET':
        return get_analytics()
```

**Pros:**
- ✅ Simpler deployment (one function)
- ✅ Shared code easier

**Cons:**
- ❌ All endpoints affected if one breaks
- ❌ Harder to scale (analytics heavy, users light)
- ❌ Harder to grant permissions (needs access to everything)
- ❌ Larger package size
- ❌ Longer cold starts
- ❌ Difficult to debug

---

### Option B: Microservices (RECOMMENDED)

```python
# users_get.py
def lambda_handler(event, context):
    return get_users()

# users_post.py
def lambda_handler(event, context):
    return create_user()

# orders_get.py
def lambda_handler(event, context):
    return get_orders()

# (etc...)
```

**Pros:**
- ✅ **Isolation**: One function breaks, others still work
- ✅ **Scalability**: Each function scales independently
- ✅ **Permissions**: Each gets only what it needs
- ✅ **Smaller packages**: Faster deployments
- ✅ **Faster cold starts**: Less code to load
- ✅ **Easier debugging**: Clear which function failed

**Cons:**
- ⚠️ More functions to manage
- ⚠️ Code duplication (use Lambda Layers to share)

---

### Decision Tree

```
How complex is your application?
│
├─ VERY SIMPLE (1-2 endpoints, prototype)
│  └─ ONE Lambda OK
│     └─ Fast to build, good for testing
│
├─ MODERATE (3-10 endpoints, production)
│  └─ SEPARATE Lambdas per endpoint
│     └─ Better isolation and scaling
│
└─ COMPLEX (10+ endpoints, microservices)
   └─ SEPARATE Lambdas per business function
      └─ Users service, Orders service, Analytics service
```

**Golden Rule:**
> One Lambda per route/function. Use Lambda Layers for shared code.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Not Setting Timeout

```hcl
# WRONG - Default timeout is 3 seconds!
resource "aws_lambda_function" "bad" {
  # No timeout specified
}

# Your function takes 5 seconds → Timeout error!
```

**Fix:**
```hcl
# CORRECT - Set appropriate timeout
resource "aws_lambda_function" "good" {
  timeout = 30  # 30 seconds (adjust based on your needs)

  # Maximum: 900 seconds (15 minutes)
}
```

---

### ❌ Mistake 2: Putting Secrets in Environment Variables (Plaintext)

```hcl
# WRONG - API key visible in console!
resource "aws_lambda_function" "bad" {
  environment {
    variables = {
      API_KEY = "sk_live_abc123def456"  # Visible to anyone with console access!
    }
  }
}
```

**Fix:**
```hcl
# CORRECT - Use Secrets Manager
resource "aws_lambda_function" "good" {
  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.api_key.arn
    }
  }
}

# In Lambda code:
# secret = secretsmanager.get_secret_value(SecretId=os.environ['SECRET_ARN'])
```

---

### ❌ Mistake 3: Not Configuring Memory (Too Low)

```hcl
# WRONG - Default 128 MB (very slow!)
resource "aws_lambda_function" "bad" {
  # No memory specified
}
```

**Why wrong?**
- Lambda CPU scales with memory
- 128 MB = Very slow CPU
- Your function runs 10x slower, costs more!

**Fix:**
```hcl
# CORRECT - Set appropriate memory
resource "aws_lambda_function" "good" {
  memory_size = 512  # or 1024 for faster processing

  # Sweet spot: 512-1024 MB for most apps
  # More memory = faster CPU = faster execution = lower cost!
}
```

---

### ❌ Mistake 4: Forgetting Lambda Permission for Triggers

```hcl
# Created S3 notification
resource "aws_s3_bucket_notification" "upload" {
  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# FORGOT permission!
# S3 can't invoke Lambda → Silent failure
```

**Fix:**
```hcl
# CORRECT - Grant S3 permission to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}
```

---

## 🎯 Best Practices

### 1. Keep Functions Small and Focused

```python
# Good - One responsibility
def lambda_handler(event, context):
    return create_user(event)

# Bad - Too many responsibilities
def lambda_handler(event, context):
    if event['action'] == 'create_user':
        return create_user()
    elif event['action'] == 'send_email':
        return send_email()
    # ... 10 more actions
```

---

### 2. Use Environment Variables for Configuration

```hcl
resource "aws_lambda_function" "api" {
  environment {
    variables = {
      TABLE_NAME        = "users"
      ENVIRONMENT       = "production"
      LOG_LEVEL         = "INFO"
      SECRET_ARN        = aws_secretsmanager_secret.api_key.arn
    }
  }
}
```

---

### 3. Enable CloudWatch Logs

```hcl
# Lambda logs automatically go to CloudWatch
# Just ensure IAM role has permissions (AWSLambdaBasicExecutionRole)

# In your code, use print() or logging
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"Processing event: {event}")
```

---

### 4. Set Appropriate Timeout and Memory

```hcl
resource "aws_lambda_function" "api" {
  timeout     = 30      # 30 seconds (default: 3)
  memory_size = 512     # 512 MB (default: 128)

  # API calls: 128-512 MB, 3-30 sec
  # File processing: 512-1024 MB, 30-300 sec
  # Data processing: 1024-3008 MB, 60-900 sec
}
```

---

### 5. Use Lambda Layers for Shared Code

```hcl
# Shared dependencies layer
resource "aws_lambda_layer_version" "dependencies" {
  filename   = "dependencies.zip"
  layer_name = "shared-dependencies"

  compatible_runtimes = ["python3.11"]
}

# Use in multiple Lambdas
resource "aws_lambda_function" "api1" {
  layers = [aws_lambda_layer_version.dependencies.arn]
}

resource "aws_lambda_function" "api2" {
  layers = [aws_lambda_layer_version.dependencies.arn]  # Reuse!
}
```

---

## 💰 Lambda Pricing Examples

```
Free Tier (per month):
- 1 million requests
- 400,000 GB-seconds

Example 1: Small API (10,000 requests/month)
- Memory: 128 MB
- Duration: 100ms each
- Cost: FREE (under free tier)

Example 2: Medium API (500,000 requests/month)
- Memory: 512 MB
- Duration: 200ms each
- GB-seconds: 500,000 × 0.512 GB × 0.2 sec = 51,200
- Cost: $0.00 (requests) + $0.85 (compute) = $0.85/month

Example 3: Large API (5 million requests/month)
- Memory: 1024 MB (1 GB)
- Duration: 300ms each
- GB-seconds: 5,000,000 × 1 GB × 0.3 sec = 1,500,000
- Cost: $0.80 (requests) + $25 (compute) = $25.80/month
```

---

**Next**: See complete implementations in [lambda_functions.tf](./lambda_functions.tf)
