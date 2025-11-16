# DynamoDB - NoSQL Database

## 🎯 What is DynamoDB?

**Simple Explanation:**
DynamoDB is like a super-fast Excel spreadsheet in the cloud. Instead of traditional databases with rigid tables and complex queries, DynamoDB stores data as flexible JSON documents. It's AWS's fully managed NoSQL database.

Think of it as:
- **Traditional SQL database (PostgreSQL/MySQL)** = Structured filing cabinet with strict folders and labels
- **DynamoDB** = Flexible notepad where you can store any information, find it instantly

**Real-World Analogy:**
- **SQL Database** = Library with Dewey Decimal System (rigid, structured, complex queries)
- **DynamoDB** = Google search (flexible, fast lookups, scale infinitely)

**Technical Definition:**
Amazon DynamoDB is a fully managed NoSQL database service that provides fast and predictable performance with seamless scalability. Single-digit millisecond latency at any scale.

---

## 🤔 Why Do I Need DynamoDB?

### Without DynamoDB (Traditional SQL):

```
PROBLEMS with traditional databases:

1. Scaling is hard (add servers, sharding, replication)
2. Slow for simple lookups (complex joins, indexes)
3. Schema changes require migrations
4. Manual backups and maintenance
5. Expensive for high traffic
6. Fixed capacity (must provision upfront)

Example: User profile lookup
SELECT * FROM users WHERE user_id = '12345'
JOIN preferences ON users.id = preferences.user_id
→ Slow query with multiple tables!
```

---

### With DynamoDB:

```
BENEFITS:

✅ Serverless (no servers to manage)
✅ Fast (single-digit millisecond latency)
✅ Auto-scaling (handles 0 to millions of requests)
✅ Flexible schema (JSON documents)
✅ Built-in backups and replication
✅ Pay per request (no idle costs)
✅ Encryption built-in

Example: User profile lookup
GetItem(user_id='12345')
→ <1ms response, no joins needed!
```

**Cost:**
- Pay only for what you use
- First 25 GB storage: **FREE**
- On-demand: $1.25 per million reads, $6.25 per million writes
- Provisioned: ~$0.47/month per read unit

---

## 📊 Real-World Example

### Scenario: Social Media App (User Profiles)

**SQL Database (Old Way):**
```sql
users table:
- id, name, email, created_at

preferences table:
- user_id, theme, notifications

posts table:
- id, user_id, content, likes

Query to get user with preferences:
SELECT * FROM users u
LEFT JOIN preferences p ON u.id = p.user_id
WHERE u.id = '12345'

→ 50-100ms response time
→ Complex migrations when adding fields
```

**DynamoDB (Better Way):**
```json
{
  "user_id": "12345",
  "name": "John Doe",
  "email": "john@example.com",
  "preferences": {
    "theme": "dark",
    "notifications": true
  },
  "created_at": "2025-01-15T10:30:00Z"
}

GetItem query → <1ms response time!
Add new field? Just include it, no migration!
```

**Cost Example:**
- 1 million user profile lookups/month
- DynamoDB: $1.25/month
- RDS (t3.micro): $15/month minimum
- **Savings: 92%!**

---

## 🔑 Key Concepts

### 1. Tables, Items, and Attributes

```
Table = Excel sheet
Item = Row
Attribute = Column (but flexible!)

Example "Users" table:
Item 1: {"user_id": "123", "name": "John", "age": 30}
Item 2: {"user_id": "456", "name": "Jane", "email": "jane@x.com"}
        ↑ Notice: Different attributes! (flexible schema)
```

---

### 2. Primary Keys

**Partition Key (Required):**
```
Like a unique ID for each item

Example:
user_id = "12345" (partition key)

DynamoDB uses this to distribute data across servers
Must be unique for each item
```

**Partition Key + Sort Key (Optional):**
```
Use when you have related items

Example: Order History
partition_key = user_id, sort_key = order_date

user_id="123", order_date="2025-01-15"  → Order 1
user_id="123", order_date="2025-01-14"  → Order 2
user_id="456", order_date="2025-01-15"  → Order 3

Query: "Get all orders for user_id=123"
→ Returns Order 1 and 2 (fast!)
```

---

### 3. Read/Write Capacity Modes

#### **On-Demand (Recommended for Most)**
```
Pay per request (no capacity planning)

Pros:
✅ No planning needed
✅ Automatic scaling
✅ Pay only for what you use
✅ Perfect for variable traffic

Cons:
⚠️ Slightly more expensive than provisioned (if traffic is constant)

Cost:
- $1.25 per million reads
- $6.25 per million writes

Use when: Traffic is unpredictable or low
```

#### **Provisioned Capacity**
```
Pre-pay for specific capacity

Pros:
✅ Cheaper if traffic is predictable
✅ Can use auto-scaling

Cons:
❌ Must plan capacity
❌ Pay for idle capacity
❌ Throttling if exceeded

Cost:
- $0.47/month per read unit (10 reads/sec)
- $2.35/month per write unit (10 writes/sec)

Use when: Steady, predictable traffic
```

---

### 4. Global Secondary Index (GSI)

**What is it?**
Alternate way to query your table (like creating a new Excel view).

**Example:**
```
Main table: Partition key = user_id
Data: {"user_id": "123", "email": "john@x.com", "name": "John"}

Problem: Can't query by email!

Solution: Create GSI
GSI partition key = email

Now you can query:
GetItem(email="john@x.com") → Returns user!
```

**Cost:** GSIs consume additional read/write capacity.

---

### 5. Local Secondary Index (LSI)

**What is it?**
Alternate sort key for the same partition key.

**When to use:** Rare. Only if you need to query same partition key with different sort order.

---

### 6. Streams

**What is it?**
Capture all changes to table (insert, update, delete).

**Use case:**
- Trigger Lambda when data changes
- Replicate data to another table
- Audit logs

**Example:**
```
User signs up → Item added to DynamoDB
              → DynamoDB Stream captures change
              → Lambda triggered (send welcome email)
```

---

## 🛠️ Common DynamoDB Patterns

### Pattern 1: Simple Key-Value Store

**Use Case:** User sessions, caching

```hcl
resource "aws_dynamodb_table" "sessions" {
  name           = "user-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"

  attribute {
    name = "session_id"
    type = "S"  # String
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "User Sessions"
  }
}
```

**Query:**
```python
# Get session
dynamodb.get_item(
    TableName='user-sessions',
    Key={'session_id': 'abc123'}
)
```

---

### Pattern 2: One-to-Many (User Orders)

```hcl
resource "aws_dynamodb_table" "orders" {
  name           = "user-orders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "order_date"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "order_date"
    type = "S"
  }

  tags = {
    Name = "User Orders"
  }
}
```

**Query:**
```python
# Get all orders for user
dynamodb.query(
    TableName='user-orders',
    KeyConditionExpression='user_id = :uid',
    ExpressionAttributeValues={':uid': '12345'}
)
```

---

### Pattern 3: GSI for Alternate Queries

```hcl
resource "aws_dynamodb_table" "users" {
  name           = "users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # GSI to query by email
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  tags = {
    Name = "Users Table"
  }
}
```

---

## 🤔 Should I Create One DynamoDB Table or Multiple Tables?

### The Question

Your app needs to store:
- Users
- Orders
- Products
- Reviews

Do you create:
- **Option A**: One table for everything
- **Option B**: Separate table for each entity

**Short Answer**: **It depends** (but usually separate tables for beginners)

---

### Option A: Single Table Design (Advanced)

```
One table with composite keys

PK="USER#123", SK="PROFILE"
PK="USER#123", SK="ORDER#2025-01-15"
PK="PRODUCT#456", SK="DETAILS"
PK="PRODUCT#456", SK="REVIEW#789"
```

**Pros:**
- ✅ Fewer tables to manage
- ✅ Can fetch related data in one query

**Cons:**
- ❌ Complex design (requires expertise)
- ❌ Hard to understand
- ❌ Difficult to migrate

**Recommendation:** Only for experienced DynamoDB developers

---

### Option B: Multiple Tables (RECOMMENDED for Beginners)

```
users-table
orders-table
products-table
reviews-table
```

**Pros:**
- ✅ Simple and clear
- ✅ Easy to understand
- ✅ Easy to manage permissions
- ✅ Independent scaling

**Cons:**
- ⚠️ More tables to manage
- ⚠️ Can't fetch related data in single query

**Recommendation:** Start here, optimize later if needed

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Not Enabling Encryption

```hcl
# WRONG
resource "aws_dynamodb_table" "bad" {
  name = "users"
  # No encryption!
}
```

**Fix:**
```hcl
resource "aws_dynamodb_table" "good" {
  name = "users"

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }
}
```

---

### ❌ Mistake 2: Using Provisioned Mode Without Auto-Scaling

```hcl
# WRONG - Fixed capacity
resource "aws_dynamodb_table" "bad" {
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  # Traffic spike → throttling!
}
```

**Fix:** Use on-demand mode
```hcl
resource "aws_dynamodb_table" "good" {
  billing_mode = "PAY_PER_REQUEST"  # Automatic scaling!
}
```

---

### ❌ Mistake 3: Not Enabling Point-in-Time Recovery

```hcl
# WRONG - No backups
resource "aws_dynamodb_table" "bad" {
  name = "critical-data"
  # Accidental delete → data lost forever!
}
```

**Fix:**
```hcl
resource "aws_dynamodb_table" "good" {
  name = "critical-data"

  point_in_time_recovery {
    enabled = true  # Can restore to any point in last 35 days
  }
}
```

---

## 🎯 Best Practices

1. **Use On-Demand Mode** (unless traffic is very predictable)
2. **Enable Encryption** (always)
3. **Enable Point-in-Time Recovery** (for production)
4. **Use TTL** (auto-delete old items)
5. **Start with Multiple Tables** (single-table design is advanced)
6. **Monitor with CloudWatch** (watch for throttling)

---

## 💰 DynamoDB Pricing

**Storage:**
- First 25 GB: **FREE**
- After: $0.25/GB/month

**On-Demand Requests:**
- Reads: $0.25 per million
- Writes: $1.25 per million

**Examples:**
```
Small App (100K reads, 10K writes/month):
- Reads: $0.025
- Writes: $0.0125
Total: $0.04/month (essentially FREE!)

Medium App (10M reads, 1M writes/month):
- Reads: $2.50
- Writes: $1.25
Total: $3.75/month

Large App (100M reads, 10M writes/month):
- Reads: $25
- Writes: $12.50
Total: $37.50/month
```

---

**Next**: See complete implementations in [dynamodb_tables_create.tf](./dynamodb_tables_create.tf)
