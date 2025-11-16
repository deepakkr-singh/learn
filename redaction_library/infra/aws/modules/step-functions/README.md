# Step Functions - Workflow Orchestration

## What is Step Functions?

Step Functions is like a **flowchart for your code**. It coordinates multiple AWS services (Lambda, ECS, SNS, etc.) into a workflow with built-in error handling, retries, and parallel execution.

**Real-World Analogy:**
```
Restaurant Order Workflow (Step Functions)
├─ Step 1: Take order → Lambda (validate order)
├─ Step 2: Check inventory → DynamoDB (check stock)
├─ Step 3: Process payment → Lambda (charge card)
├─ Step 4: Prepare food → ECS Task (cook food)
├─ Step 5: Deliver → SNS (notify delivery driver)
└─ Step 6: Send receipt → SES (email customer)

If payment fails → Retry 3 times → Send error notification
If inventory low → Parallel check multiple warehouses
```

## When to Use Step Functions?

Use Step Functions when you need:
1. **Multi-step workflows** (order processing, data pipelines)
2. **Orchestrate multiple services** (Lambda + DynamoDB + SNS)
3. **Built-in error handling** (automatic retries, catch errors)
4. **Long-running processes** (up to 1 year)
5. **Human approval steps** (wait for manual approval)
6. **Parallel processing** (process multiple items simultaneously)

Don't use Step Functions when:
- You just need to run a single Lambda function
- Your workflow is simple (A → B, no branching)
- You need real-time (sub-second) processing
- Cost is critical (Step Functions has per-state-transition cost)

## Step Functions vs Other Options

| Feature | Step Functions | Lambda | SQS | EventBridge |
|---------|----------------|--------|-----|-------------|
| **Orchestration** | Built-in | Manual | None | Rules-based |
| **Max Duration** | 1 year | 15 minutes | Unlimited | N/A |
| **Error Handling** | Automatic retries | Manual | Manual | Manual |
| **Visual Workflow** | Yes | No | No | Limited |
| **Cost** | Per transition | Per invocation | Per request | Per event |
| **Use Case** | Complex workflows | Single tasks | Message queues | Event routing |

## Should I Create One State Machine or Multiple?

**One State Machine:**
- Single workflow (order processing)
- Related steps
- Shared error handling
- Cost-effective (fewer state machines to manage)

**Multiple State Machines:**
- Different workflows (orders vs invoices vs shipping)
- Different SLAs (critical vs non-critical)
- Different teams/services
- Independent scaling

**Real-World Example:**
```
E-commerce Application
├─ order-processing (1 state machine)
│  ├─ Validate order
│  ├─ Check inventory
│  ├─ Process payment
│  └─ Create shipment
│
├─ invoice-generation (separate state machine)
│  ├─ Calculate totals
│  ├─ Generate PDF
│  └─ Email customer
│
└─ inventory-sync (separate state machine)
   ├─ Check warehouse stock
   ├─ Update database
   └─ Send low-stock alerts
```

## Key Concepts

### 1. State Types

**Task State** - Do work (call Lambda, run ECS task, etc.)
```json
{
  "ValidateOrder": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:us-east-1:123456789012:function:validate-order",
    "Next": "CheckInventory"
  }
}
```

**Choice State** - Branch based on conditions (if/else)
```json
{
  "CheckPaymentStatus": {
    "Type": "Choice",
    "Choices": [
      {
        "Variable": "$.paymentStatus",
        "StringEquals": "SUCCESS",
        "Next": "ProcessOrder"
      },
      {
        "Variable": "$.paymentStatus",
        "StringEquals": "FAILED",
        "Next": "SendPaymentFailedEmail"
      }
    ],
    "Default": "RetryPayment"
  }
}
```

**Parallel State** - Execute multiple branches simultaneously
```json
{
  "ProcessOrderAndNotify": {
    "Type": "Parallel",
    "Branches": [
      {
        "StartAt": "CreateShipment",
        "States": { ... }
      },
      {
        "StartAt": "SendConfirmationEmail",
        "States": { ... }
      }
    ],
    "Next": "OrderComplete"
  }
}
```

**Wait State** - Pause workflow
```json
{
  "WaitForApproval": {
    "Type": "Wait",
    "Seconds": 3600,
    "Next": "CheckApprovalStatus"
  }
}
```

**Succeed State** - Workflow completed successfully
```json
{
  "OrderComplete": {
    "Type": "Succeed"
  }
}
```

**Fail State** - Workflow failed
```json
{
  "OrderFailed": {
    "Type": "Fail",
    "Error": "OrderValidationFailed",
    "Cause": "Invalid order data"
  }
}
```

**Map State** - Process array items (loop)
```json
{
  "ProcessItems": {
    "Type": "Map",
    "ItemsPath": "$.orderItems",
    "Iterator": {
      "StartAt": "ValidateItem",
      "States": { ... }
    },
    "Next": "AllItemsProcessed"
  }
}
```

**Pass State** - Pass input to output (data transformation)
```json
{
  "TransformData": {
    "Type": "Pass",
    "Result": {
      "status": "processing"
    },
    "ResultPath": "$.orderStatus",
    "Next": "ProcessOrder"
  }
}
```

### 2. Error Handling

**Retry** - Automatically retry on errors
```json
{
  "ProcessPayment": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:...",
    "Retry": [
      {
        "ErrorEquals": ["States.Timeout", "ServiceException"],
        "IntervalSeconds": 2,
        "MaxAttempts": 3,
        "BackoffRate": 2.0
      }
    ],
    "Next": "PaymentComplete"
  }
}
```

**Retry Behavior:**
```
Attempt 1: Immediate
Attempt 2: Wait 2 seconds (IntervalSeconds)
Attempt 3: Wait 4 seconds (2 × BackoffRate)
Attempt 4: Wait 8 seconds (4 × BackoffRate)
```

**Catch** - Handle errors
```json
{
  "ProcessPayment": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:...",
    "Catch": [
      {
        "ErrorEquals": ["PaymentDeclined"],
        "Next": "SendPaymentDeclinedEmail"
      },
      {
        "ErrorEquals": ["States.ALL"],
        "Next": "SendGenericErrorEmail"
      }
    ],
    "Next": "PaymentComplete"
  }
}
```

### 3. Input/Output Processing

**InputPath** - Select portion of input
```json
{
  "ProcessOrder": {
    "Type": "Task",
    "InputPath": "$.order",
    "Resource": "arn:aws:lambda:..."
  }
}
```

**OutputPath** - Select portion of output
```json
{
  "ProcessOrder": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:...",
    "OutputPath": "$.result"
  }
}
```

**ResultPath** - Where to put task result
```json
{
  "ProcessOrder": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:...",
    "ResultPath": "$.orderResult"
  }
}
```

**Example Flow:**
```
Input:
{
  "orderId": "123",
  "customerId": "456",
  "total": 100
}

Task Result:
{
  "status": "success",
  "confirmationNumber": "ABC-123"
}

With ResultPath = "$.orderResult":
{
  "orderId": "123",
  "customerId": "456",
  "total": 100,
  "orderResult": {
    "status": "success",
    "confirmationNumber": "ABC-123"
  }
}
```

### 4. State Machine Types

**Standard Workflows**
- Max duration: 1 year
- Exactly-once execution
- Pricing: $0.025 per 1,000 state transitions
- Use for: Long-running, reliable workflows

**Express Workflows**
- Max duration: 5 minutes
- At-least-once execution
- Pricing: Based on executions and duration
- Use for: High-volume, short-duration workflows (IoT, streaming)

### 5. Integrations

**AWS Lambda** - Run serverless functions
```json
{
  "Resource": "arn:aws:lambda:us-east-1:123456789012:function:my-function"
}
```

**DynamoDB** - Read/write database
```json
{
  "Resource": "arn:aws:states:::dynamodb:putItem",
  "Parameters": {
    "TableName": "orders",
    "Item": {
      "orderId": { "S.$": "$.orderId" }
    }
  }
}
```

**SNS** - Send notifications
```json
{
  "Resource": "arn:aws:states:::sns:publish",
  "Parameters": {
    "TopicArn": "arn:aws:sns:us-east-1:123456789012:orders",
    "Message.$": "$.message"
  }
}
```

**SQS** - Send messages
```json
{
  "Resource": "arn:aws:states:::sqs:sendMessage",
  "Parameters": {
    "QueueUrl": "https://sqs.us-east-1.amazonaws.com/123456789012/orders",
    "MessageBody.$": "$"
  }
}
```

**ECS** - Run containers
```json
{
  "Resource": "arn:aws:states:::ecs:runTask.sync",
  "Parameters": {
    "Cluster": "my-cluster",
    "TaskDefinition": "my-task"
  }
}
```

**Glue** - Run ETL jobs
```json
{
  "Resource": "arn:aws:states:::glue:startJobRun.sync",
  "Parameters": {
    "JobName": "my-etl-job"
  }
}
```

## Common Patterns

### Pattern 1: Simple Sequential Workflow

```
Use Case: Order processing
├─ Validate order
├─ Check inventory
├─ Process payment
├─ Create shipment
└─ Send confirmation
```

```json
{
  "StartAt": "ValidateOrder",
  "States": {
    "ValidateOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:validate-order",
      "Next": "CheckInventory"
    },
    "CheckInventory": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:check-inventory",
      "Next": "ProcessPayment"
    },
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:process-payment",
      "Next": "CreateShipment"
    },
    "CreateShipment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:create-shipment",
      "Next": "SendConfirmation"
    },
    "SendConfirmation": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:send-email",
      "End": true
    }
  }
}
```

### Pattern 2: Branching (Choice)

```
Use Case: Different handling based on order value
├─ If order > $1000 → Require approval
└─ If order <= $1000 → Auto-approve
```

```json
{
  "StartAt": "ValidateOrder",
  "States": {
    "ValidateOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:validate-order",
      "Next": "CheckOrderValue"
    },
    "CheckOrderValue": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.total",
          "NumericGreaterThan": 1000,
          "Next": "RequireApproval"
        }
      ],
      "Default": "ProcessOrder"
    },
    "RequireApproval": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:request-approval",
      "Next": "WaitForApproval"
    },
    "WaitForApproval": {
      "Type": "Wait",
      "Seconds": 3600,
      "Next": "CheckApprovalStatus"
    },
    "CheckApprovalStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.approved",
          "BooleanEquals": true,
          "Next": "ProcessOrder"
        }
      ],
      "Default": "OrderRejected"
    },
    "ProcessOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:process-order",
      "End": true
    },
    "OrderRejected": {
      "Type": "Fail",
      "Error": "OrderRejected",
      "Cause": "Order was not approved"
    }
  }
}
```

### Pattern 3: Parallel Processing

```
Use Case: Process order and send notifications simultaneously
├─ Branch 1: Create shipment + Update inventory
└─ Branch 2: Send email + Send SMS
```

```json
{
  "StartAt": "ProcessPayment",
  "States": {
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:process-payment",
      "Next": "ParallelTasks"
    },
    "ParallelTasks": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "CreateShipment",
          "States": {
            "CreateShipment": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:...:function:create-shipment",
              "Next": "UpdateInventory"
            },
            "UpdateInventory": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:...:function:update-inventory",
              "End": true
            }
          }
        },
        {
          "StartAt": "SendEmail",
          "States": {
            "SendEmail": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:...:function:send-email",
              "Next": "SendSMS"
            },
            "SendSMS": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:...:function:send-sms",
              "End": true
            }
          }
        }
      ],
      "Next": "OrderComplete"
    },
    "OrderComplete": {
      "Type": "Succeed"
    }
  }
}
```

### Pattern 4: Loop (Map State)

```
Use Case: Process multiple items in an order
├─ For each item in order:
│  ├─ Check stock
│  ├─ Reserve item
│  └─ Update inventory
```

```json
{
  "StartAt": "ProcessItems",
  "States": {
    "ProcessItems": {
      "Type": "Map",
      "ItemsPath": "$.orderItems",
      "MaxConcurrency": 10,
      "Iterator": {
        "StartAt": "CheckStock",
        "States": {
          "CheckStock": {
            "Type": "Task",
            "Resource": "arn:aws:lambda:...:function:check-stock",
            "Next": "ReserveItem"
          },
          "ReserveItem": {
            "Type": "Task",
            "Resource": "arn:aws:lambda:...:function:reserve-item",
            "Next": "UpdateInventory"
          },
          "UpdateInventory": {
            "Type": "Task",
            "Resource": "arn:aws:lambda:...:function:update-inventory",
            "End": true
          }
        }
      },
      "Next": "AllItemsProcessed"
    },
    "AllItemsProcessed": {
      "Type": "Succeed"
    }
  }
}
```

### Pattern 5: Error Handling with Retry and Catch

```
Use Case: Payment processing with retries
├─ Try payment 3 times with exponential backoff
├─ If still fails → Send failure notification
└─ If succeeds → Continue workflow
```

```json
{
  "StartAt": "ProcessPayment",
  "States": {
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:process-payment",
      "Retry": [
        {
          "ErrorEquals": ["ServiceException", "States.Timeout"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["PaymentDeclined"],
          "ResultPath": "$.error",
          "Next": "PaymentDeclined"
        },
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "PaymentError"
        }
      ],
      "Next": "PaymentSuccess"
    },
    "PaymentSuccess": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:send-success-email",
      "End": true
    },
    "PaymentDeclined": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:send-declined-email",
      "End": true
    },
    "PaymentError": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:...:function:send-error-email",
      "End": true
    }
  }
}
```

## Execution Time and Performance

### Execution Duration

```
Standard Workflow:
├─ Min duration: < 1 second
├─ Max duration: 1 year (365 days)
├─ Use for: Long-running workflows (batch jobs, approval workflows)

Express Workflow:
├─ Min duration: < 1 second
├─ Max duration: 5 minutes
├─ Use for: High-volume, short workflows (API responses, streaming)
```

### State Transition Time

```
Sequential States:
├─ State A → State B: 50-100ms overhead
├─ Total workflow time = Sum of task times + transition overhead

Example:
├─ 5 Lambda functions (500ms each) = 2.5 seconds
├─ 5 state transitions (100ms each) = 0.5 seconds
└─ Total: 3 seconds
```

### Parallel Execution

```
Without Parallel:
├─ Task A: 2 seconds
├─ Task B: 3 seconds
├─ Task C: 2 seconds
└─ Total: 7 seconds (sequential)

With Parallel:
├─ Task A, B, C run simultaneously
└─ Total: 3 seconds (longest task)

Savings: 57% faster!
```

### Scalability

```
Standard Workflow:
├─ Max concurrent executions: 1,000,000 (soft limit)
├─ Can be increased by AWS support

Express Workflow:
├─ Max concurrent executions: Unlimited
├─ Throttle: Account-level limits (can be increased)

Map State Concurrency:
├─ Default: Process items sequentially
├─ MaxConcurrency: 10 → Process 10 items at once
├─ MaxConcurrency: 100 → Process 100 items at once
```

## Cost Optimization

### Pricing Models

```
Standard Workflow:
├─ $0.025 per 1,000 state transitions
├─ First 4,000 transitions/month free
└─ No charge for duration

Express Workflow (Synchronous):
├─ $1.00 per 1 million requests
├─ $0.00001667 per GB-second
└─ Use for: API workflows

Express Workflow (Asynchronous):
├─ $0.25 per 1 million requests
├─ $0.00001667 per GB-second
└─ Use for: Event-driven workflows
```

### Cost Examples

```
Example 1: Order Processing (Standard)
├─ 10,000 orders/month
├─ 8 states per order = 80,000 transitions
├─ Free tier: 4,000 transitions
├─ Billable: 76,000 transitions
└─ Cost: $1.90/month

Example 2: Data Pipeline (Standard)
├─ 1,000 jobs/month
├─ 20 states per job = 20,000 transitions
├─ Free tier: 4,000 transitions
├─ Billable: 16,000 transitions
└─ Cost: $0.40/month

Example 3: API Workflow (Express Sync)
├─ 1 million requests/month
├─ Average duration: 2 seconds
├─ Request cost: $1.00
├─ Duration cost: $0.03
└─ Total: $1.03/month

Example 4: IoT Processing (Express Async)
├─ 10 million events/month
├─ Average duration: 1 second
├─ Request cost: $2.50
├─ Duration cost: $0.17
└─ Total: $2.67/month
```

### Cost-Saving Tips

```
1. Minimize State Transitions
   ❌ Separate state for each operation (10 states)
   ✓ Combine related operations in Lambda (5 states)
   Savings: 50% fewer transitions

2. Use Express for High Volume
   ❌ Standard workflow: 1M orders × 10 states = $250/month
   ✓ Express async: 1M orders = $2.50/month
   Savings: 99%!

3. Batch Processing with Map State
   ❌ Start 1,000 separate executions (1,000 × 10 = 10,000 transitions)
   ✓ Single execution with Map (1 execution × 10 = 10 transitions)
   Savings: 99.9%!

4. Optimize Parallel Branches
   ❌ 5 parallel branches with 10 states each = 50 transitions
   ✓ Combine into 2 branches with 5 states each = 10 transitions
   Savings: 80%

5. Use Wait State for Polling
   ❌ Lambda polling every minute for 1 hour = 60 invocations
   ✓ Wait state for 1 hour = 1 transition
   Savings: Significant Lambda cost reduction
```

## Best Practices

### Production Readiness

```
1. Error Handling
   ✓ Add Retry to all Task states (handle transient errors)
   ✓ Add Catch for known errors (graceful degradation)
   ✓ Add fallback Fail state with descriptive errors
   ❌ No error handling (workflow fails on first error)

2. Timeouts
   ✓ Set TimeoutSeconds on Task states (prevent hanging)
   ✓ Set HeartbeatSeconds for long-running tasks
   ❌ No timeouts (workflow waits forever)

3. Logging
   ✓ Enable CloudWatch Logs for all executions
   ✓ Log execution history (debug failures)
   ✓ Set appropriate log level (ERROR, ALL)
   ❌ No logging

4. Monitoring
   ✓ CloudWatch alarms for failed executions
   ✓ Dashboard for execution metrics
   ✓ SNS notifications for failures
   ❌ No monitoring

5. IAM Permissions
   ✓ Least privilege (only permissions needed)
   ✓ Separate roles for dev/staging/prod
   ❌ Over-permissive role (can do anything)
```

### Development Best Practices

```
1. Version Control
   ✓ Store state machine definitions in Git
   ✓ Use variables for ARNs (don't hardcode)
   ✓ Tag releases
   ❌ Manual updates in console

2. Testing
   ✓ Unit test Lambda functions separately
   ✓ Integration test full workflow
   ✓ Test error paths (what happens when payment fails?)
   ❌ No testing

3. Naming Conventions
   ✓ Descriptive state names (ProcessPayment, not Step1)
   ✓ Consistent resource naming
   ❌ Generic names (Task1, Task2)

4. Documentation
   ✓ Comment complex logic in state machine
   ✓ Document error handling strategy
   ✓ Create workflow diagrams
   ❌ No documentation
```

## Common Mistakes

```
❌ MISTAKE 1: Not handling errors
Example: Payment processing with no retry or catch
Impact: Workflow fails on first transient error
Solution: Add Retry and Catch blocks

❌ MISTAKE 2: No timeouts
Example: Calling external API with no timeout
Impact: Workflow hangs indefinitely
Solution: Set TimeoutSeconds on all Task states

❌ MISTAKE 3: Too many state transitions
Example: Separate state for each small operation
Impact: High costs (charged per transition)
Solution: Combine related operations in single Lambda

❌ MISTAKE 4: Synchronous Express for long tasks
Example: Express workflow with 10-minute task
Error: Express max duration is 5 minutes
Solution: Use Standard workflow for long-running tasks

❌ MISTAKE 5: Not using Parallel for independent tasks
Example: Send email, then send SMS (sequential)
Impact: 2x slower (email 2s + SMS 2s = 4s total)
Solution: Use Parallel state (both complete in 2s)

❌ MISTAKE 6: Hardcoded ARNs in state machine
Example: Lambda ARN hardcoded in JSON
Impact: Can't reuse across environments
Solution: Use variables/parameters in Terraform

❌ MISTAKE 7: Not setting MaxConcurrency in Map
Example: Processing 10,000 items without limit
Impact: Throttling errors, Lambda limits exceeded
Solution: Set MaxConcurrency (e.g., 10 or 100)

❌ MISTAKE 8: Using Step Functions for simple tasks
Example: Single Lambda invocation via Step Functions
Impact: Unnecessary cost and complexity
Solution: Just call Lambda directly

❌ MISTAKE 9: No CloudWatch Logs
Example: Execution fails, no logs to debug
Impact: Can't troubleshoot failures
Solution: Enable CloudWatch Logs for all executions

❌ MISTAKE 10: Over-privileged IAM role
Example: Step Functions role with AdministratorAccess
Security Risk: Can access/modify any AWS resource
Solution: Least privilege (only invoke specific Lambdas)
```

## When to Use Step Functions vs Alternatives

```
Use Step Functions when:
✓ Multi-step workflow with branching
✓ Need error handling and retries
✓ Orchestrating multiple AWS services
✓ Long-running workflows (hours, days)
✓ Visual workflow editor helpful
✓ Human approval steps needed

Use Lambda alone when:
✓ Single task, no orchestration
✓ Simple event processing
✓ Cost-sensitive (avoid per-transition fees)

Use SQS when:
✓ Simple message queue (producer/consumer)
✓ Decouple services
✓ No complex orchestration needed

Use EventBridge when:
✓ Event routing (A → B, B → C)
✓ Scheduled tasks (cron jobs)
✓ Simple rules, no complex workflows

Use Airflow/Temporal when:
✓ Complex data pipelines
✓ Need self-hosted solution
✓ Language-agnostic (not just AWS)
```

## Summary

**Step Functions in Simple Terms:**
- Visual workflow orchestrator
- Coordinates multiple AWS services
- Built-in error handling and retries
- Pay per state transition
- Best for: Complex, multi-step workflows

**Key Decisions:**
1. Standard vs Express → Standard for most use cases
2. State types → Task (do work), Choice (if/else), Parallel (concurrent), Map (loop)
3. Error handling → Always add Retry and Catch
4. Integrations → Lambda, DynamoDB, SNS, SQS, ECS, etc.
5. Cost → Minimize state transitions, use Express for high volume

**Quick Start:**
1. Define workflow (draw flowchart first!)
2. Create state machine in ASL (Amazon States Language)
3. Add error handling (Retry + Catch)
4. Test with sample input
5. Monitor executions (CloudWatch Logs + Alarms)
