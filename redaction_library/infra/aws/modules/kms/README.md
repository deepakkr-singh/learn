# KMS (Key Management Service) - Your Encryption Key Vault

## 🎯 What is KMS?

**Simple Explanation:**
KMS is like a secure vault that stores encryption keys. Think of it as a safe where you keep the master key that locks/unlocks all your other safes.

Imagine you have important documents (data in S3, database, secrets). You lock them in a safe (encrypt them). KMS is where you keep the key to that safe.

**Technical Definition:**
AWS KMS (Key Management Service) is a managed service that makes it easy to create and control encryption keys used to encrypt your data across AWS services and applications.

---

## 🤔 Why Do I Need KMS?

### Without KMS (Encryption Keys in Code):
```python
# DANGEROUS - Don't do this!
encryption_key = "my-secret-key-12345"  # Hard-coded key
encrypted_data = encrypt(data, encryption_key)
```

**Problems:**
- ❌ Key visible in code (anyone with code access sees key)
- ❌ Key in git history (permanent exposure)
- ❌ Can't rotate key easily
- ❌ No audit trail (who used the key?)
- ❌ Compliance failure (PCI-DSS, HIPAA won't allow this)

---

### With KMS:
```python
# SECURE - Key stored in KMS
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/abc-123"
encrypted_data = kms.encrypt(data, kms_key_id)
```

**Benefits:**
- ✅ **Secure Storage**: Keys never leave AWS hardware
- ✅ **Automatic Rotation**: Keys rotate automatically every year
- ✅ **Access Control**: IAM controls who can use keys
- ✅ **Audit Trail**: CloudTrail logs every key usage
- ✅ **Compliance**: Meets FIPS 140-2, PCI-DSS, HIPAA
- ✅ **Easy Integration**: Works with S3, RDS, Secrets Manager, etc.

---

## 📊 Real-World Example

### Scenario: E-commerce Platform

```
┌─────────────────────────────────────────────────────────────┐
│                        YOUR APPLICATION                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Lambda Function (Processes Orders)                     │ │
│  │                                                         │ │
│  │ 1. Receives credit card number                        │ │
│  │ 2. Encrypts with KMS key                              │ │
│  │ 3. Stores encrypted data in DynamoDB                  │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS KMS (Key Vault)                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ KMS Key: payment-encryption-key                        │ │
│  │ ID: abc-123-def-456                                    │ │
│  │                                                         │ │
│  │ Permissions (IAM Policy):                              │ │
│  │  ✓ Lambda can encrypt/decrypt                         │ │
│  │  ✓ Admin can manage key                               │ │
│  │  ✗ No one else can access                             │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    ENCRYPTED DATA STORAGE                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ DynamoDB Table                                         │ │
│  │  Order ID: 12345                                       │ │
│  │  Card Number: [ENCRYPTED BLOB - Unreadable!]          │ │
│  │                                                         │ │
│  │ S3 Bucket                                              │ │
│  │  customer-data.csv: [ENCRYPTED - Unreadable!]         │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**How It Works:**
1. Lambda needs to encrypt credit card number
2. Lambda calls KMS: "Please encrypt this data with key abc-123"
3. KMS checks: "Does Lambda have permission? Yes!"
4. KMS encrypts data and returns encrypted blob
5. Lambda stores encrypted blob in DynamoDB
6. Even if attacker steals DynamoDB data, it's unreadable without KMS key

---

## 🔑 Key Concepts

### 1. What is Encryption?

**Simple Analogy:**
```
Original Message:  "Hello World"
Encryption Key:    "my-secret-key"
Encrypted:         "8j2k#lm@9x$q"  (unreadable gibberish)

To decrypt: You need the SAME key
```

**Why Encrypt?**
- Protect data at rest (stored in S3, database)
- Protect data in transit (over network)
- Meet compliance requirements
- Prevent data breaches

---

### 2. Symmetric vs Asymmetric Encryption

**KMS Uses Symmetric Encryption (One Key for Both)**

```
Symmetric (KMS Default):
┌──────────────┐
│  Same Key    │
│  "abc-123"   │
└──────┬───────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
Encrypt  Decrypt
```

**Why Symmetric?**
- Faster encryption/decryption
- Simpler key management
- Good for most use cases (S3, RDS, Secrets Manager)

---

**Asymmetric (Advanced - Not Covered Here):**
```
Two Keys:
- Public Key: Encrypts
- Private Key: Decrypts
```

**When to use:**
- Digital signatures
- SSL/TLS certificates
- Client-side encryption

---

### 3. KMS Key Types

#### **Customer Managed Keys (CMK) - YOU CONTROL**

```hcl
resource "aws_kms_key" "my_key" {
  description             = "My encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true  # Rotate every year
}
```

**Characteristics:**
- ✅ You control permissions (who can use it)
- ✅ You control key rotation
- ✅ You can disable/delete
- ✅ Full audit trail
- 💰 **Cost**: $1/month per key

**Use for:**
- Your application data
- Secrets Manager
- Custom encryption needs

---

#### **AWS Managed Keys - AWS CONTROLS**

```
Created automatically when you enable encryption on AWS services

Examples:
- aws/s3      (for S3 buckets)
- aws/rds     (for RDS databases)
- aws/lambda  (for Lambda env variables)
```

**Characteristics:**
- ✅ Free (no monthly cost)
- ✅ Automatic rotation (every 3 years)
- ❌ Can't control permissions (AWS manages)
- ❌ Can't disable/delete
- ❌ Limited visibility

**Use for:**
- Quick setup
- Development environments
- When you don't need custom permissions

---

### 4. Encryption at Rest vs In Transit

**Encryption at Rest (Stored Data):**
```
Data sitting in storage (S3, RDS, DynamoDB)
KMS encrypts it so if someone steals the disk, data is unreadable

Example:
S3 Bucket → Data encrypted with KMS key → Stored on AWS disk
```

**Encryption in Transit (Moving Data):**
```
Data moving over network
Uses SSL/TLS (HTTPS), not KMS

Example:
Your Browser → HTTPS → API Gateway → Lambda
```

**Important:**
- KMS = Encryption at rest (stored data)
- SSL/TLS = Encryption in transit (moving data)
- **You need BOTH for full security!**

---

## 🛠️ Common KMS Patterns

### Pattern 1: One KMS Key for Secrets Manager

**Use Case:** Encrypt all application secrets

```hcl
# Create KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "Encryption key for Secrets Manager secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "secrets-encryption-key"
    Environment = "production"
    Purpose     = "Secrets Manager"
  }
}

# Alias for easy reference
resource "aws_kms_alias" "secrets" {
  name          = "alias/secrets-manager-key"
  target_key_id = aws_kms_key.secrets.key_id
}

# Use in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name       = "production/db/password"
  kms_key_id = aws_kms_key.secrets.id  # Encrypted with this key!
}
```

**Why separate key for secrets?**
- If key is compromised, only secrets are affected (not S3, not DynamoDB)
- Different teams can manage different keys
- Easier to audit who accesses secrets

---

### Pattern 2: One KMS Key for S3 Buckets

**Use Case:** Encrypt all files uploaded to S3

```hcl
# Create KMS key for S3
resource "aws_kms_key" "s3" {
  description             = "Encryption key for S3 buckets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "s3-encryption-key"
    Environment = "production"
    Purpose     = "S3 Buckets"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3.key_id
}

# S3 bucket with KMS encryption
resource "aws_s3_bucket" "uploads" {
  bucket = "my-app-uploads"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id  # Use our KMS key!
    }
  }
}
```

**What happens:**
- User uploads file to S3
- S3 automatically encrypts with KMS key
- File stored encrypted on disk
- When user downloads, S3 decrypts automatically (if they have permission)

---

### Pattern 3: One KMS Key for DynamoDB

**Use Case:** Encrypt database at rest

```hcl
# Create KMS key for DynamoDB
resource "aws_kms_key" "dynamodb" {
  description             = "Encryption key for DynamoDB tables"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "dynamodb-encryption-key"
    Environment = "production"
    Purpose     = "DynamoDB Tables"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-encryption-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# DynamoDB table with KMS encryption
resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn  # Encrypted!
  }
}
```

---

### Pattern 4: Shared KMS Key (Not Recommended for Production)

**Use Case:** Development environment, want to save money

```hcl
# One key for everything (ONLY for dev/test!)
resource "aws_kms_key" "shared" {
  description             = "Shared encryption key for all services (DEV ONLY)"
  deletion_window_in_days = 7  # Shorter window for dev
  enable_key_rotation     = false  # Don't rotate in dev

  tags = {
    Name        = "dev-shared-key"
    Environment = "dev"
    Warning     = "DO NOT USE IN PRODUCTION"
  }
}

# Use for Secrets Manager
resource "aws_secretsmanager_secret" "api_key" {
  kms_key_id = aws_kms_key.shared.id
}

# Use for S3
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.shared.id  # Same key
    }
  }
}

# Use for DynamoDB
resource "aws_dynamodb_table" "users" {
  server_side_encryption {
    kms_key_arn = aws_kms_key.shared.arn  # Same key again
  }
}
```

**Why NOT recommended for production:**
- If key is compromised, EVERYTHING is exposed
- Can't have different teams manage different keys
- Can't revoke access to just one service

---

## 🔐 KMS Key Permissions (IAM Policies)

### Who Can Use KMS Keys?

KMS uses IAM policies to control access. Two types:

#### 1. Key Policy (Attached to KMS Key)

```hcl
resource "aws_kms_key" "example" {
  description = "Example KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"  # AWS account root
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to use key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/lambda-execution-role"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

#### 2. IAM Policy (Attached to User/Role)

```hcl
# Lambda execution role
resource "aws_iam_role" "lambda" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy allowing Lambda to use KMS key
resource "aws_iam_role_policy" "lambda_kms" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.secrets.arn  # Specific key ARN
      }
    ]
  })
}
```

---

## 🤔 Should I Create One KMS Key or Multiple?

### The Question

You have:
- Secrets Manager (API keys, DB passwords)
- S3 buckets (user uploads)
- DynamoDB tables (user data)

Do you create:
- **Option A**: One KMS key for everything
- **Option B**: Separate KMS key for each service

**Short Answer**: Usually **Option B** (separate keys) is better for production

---

### Option A: One Shared KMS Key

```hcl
# Single key for all services
resource "aws_kms_key" "shared" {
  description = "Shared encryption key"
}

# Used everywhere
resource "aws_secretsmanager_secret" "db_pass" {
  kms_key_id = aws_kms_key.shared.id  # Same key
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.shared.id  # Same key
    }
  }
}

resource "aws_dynamodb_table" "users" {
  server_side_encryption {
    kms_key_arn = aws_kms_key.shared.arn  # Same key
  }
}
```

**Pros:**
- ✅ Simpler (only one key to manage)
- ✅ Cheaper ($1/month instead of $3/month)
- ✅ Easier IAM policies

**Cons:**
- ❌ If key compromised, EVERYTHING is exposed
- ❌ Can't grant access to just one service
- ❌ All-or-nothing access control
- ❌ Harder to audit (who accessed what?)

---

### Option B: Separate KMS Keys (RECOMMENDED)

```hcl
# Separate key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description = "Secrets Manager encryption"
}

# Separate key for S3
resource "aws_kms_key" "s3" {
  description = "S3 bucket encryption"
}

# Separate key for DynamoDB
resource "aws_kms_key" "dynamodb" {
  description = "DynamoDB table encryption"
}

# Each service uses its own key
resource "aws_secretsmanager_secret" "db_pass" {
  kms_key_id = aws_kms_key.secrets.id  # Secrets key
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.id  # S3 key
    }
  }
}

resource "aws_dynamodb_table" "users" {
  server_side_encryption {
    kms_key_arn = aws_kms_key.dynamodb.arn  # DynamoDB key
  }
}
```

**Pros:**
- ✅ **Security Isolation**: Compromise of one key doesn't affect others
- ✅ **Granular Access**: Give Lambda access to secrets key only, not S3 key
- ✅ **Better Audit**: CloudTrail shows which key was used
- ✅ **Compliance**: Some standards require separate keys (PCI-DSS)

**Cons:**
- ⚠️ More keys to manage
- ⚠️ Higher cost ($1/month per key)
- ⚠️ More complex IAM policies

---

### Decision Tree

```
How sensitive is your data?
│
├─ VERY SENSITIVE (payment data, health records, SSN)
│  └─ Use SEPARATE keys per service
│     └─ Even separate keys per environment (prod, staging, dev)
│
├─ MODERATELY SENSITIVE (user profiles, app data)
│  └─ Use separate keys per service type
│     └─ One for secrets, one for databases, one for files
│
└─ LOW SENSITIVITY (dev environment, logs, cache)
   └─ One shared key is OK
      └─ Cost savings, simpler management
```

---

### Real-World Recommendations

#### **Startup / Small Team**
```
Cost-conscious, need to move fast

Strategy:
- Dev environment: 1 shared key (save money)
- Production: 2-3 keys (secrets, databases, files)
```

#### **Medium Company**
```
Security matters, but not regulated industry

Strategy:
- 1 key per service type (secrets, S3, DynamoDB, RDS)
- Separate keys per environment (prod, staging, dev)
- Total: ~12 keys ($12/month)
```

#### **Large Enterprise / Regulated Industry**
```
Compliance required (HIPAA, PCI-DSS, SOC2)

Strategy:
- 1 key per resource (each S3 bucket, each DynamoDB table)
- Separate keys per team
- Separate keys per environment
- Total: 50-100+ keys
```

---

### Summary Table

| Scenario | Number of Keys | Example |
|----------|----------------|---------|
| **Dev environment** | 1 shared key | All services use same key |
| **Production (small app)** | 2-3 keys | Secrets, databases, files |
| **Production (medium app)** | 5-10 keys | One per service type + environment |
| **Regulated industry** | Many keys | One per resource or team |

**Golden Rule:**
> Start with separate keys for secrets, databases, and files. Only share keys if you have a good reason (cost, simplicity in dev).

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Deleting KMS Key Immediately

```hcl
# WRONG
resource "aws_kms_key" "bad" {
  deletion_window_in_days = 7  # Too short!
}
```

**Why wrong?**
- Can't recover key if deleted by mistake
- Encrypted data becomes UNREADABLE if key is gone

**Fix:**
```hcl
# CORRECT
resource "aws_kms_key" "good" {
  deletion_window_in_days = 30  # 30 days to recover
}
```

---

### ❌ Mistake 2: Not Enabling Key Rotation

```hcl
# WRONG
resource "aws_kms_key" "bad" {
  enable_key_rotation = false  # Never rotates!
}
```

**Why wrong?**
- Same key used forever
- If key is compromised, all historical data is at risk

**Fix:**
```hcl
# CORRECT
resource "aws_kms_key" "good" {
  enable_key_rotation = true  # Rotates every year
}
```

---

### ❌ Mistake 3: Overly Permissive Key Policy

```hcl
# WRONG - Anyone can use this key!
policy = jsonencode({
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        AWS = "*"  # ANYONE!
      }
      Action   = "kms:*"
      Resource = "*"
    }
  ]
})
```

**Why wrong?**
- Anyone in AWS account can decrypt your data
- Defeats purpose of encryption

**Fix:**
```hcl
# CORRECT - Only specific roles
policy = jsonencode({
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:role/lambda-role"  # Specific role
      }
      Action = [
        "kms:Decrypt",
        "kms:Encrypt"
      ]
      Resource = "*"
    }
  ]
})
```

---

### ❌ Mistake 4: No Description or Tags

```hcl
# WRONG
resource "aws_kms_key" "bad" {
  # No description, no tags
}
```

**Why wrong?**
- 6 months later: "What is this key for?"
- Can't track costs
- Can't find the right key

**Fix:**
```hcl
# CORRECT
resource "aws_kms_key" "good" {
  description = "Encryption key for production Secrets Manager"

  tags = {
    Name        = "production-secrets-key"
    Environment = "production"
    Purpose     = "Secrets Manager"
    Team        = "Platform"
  }
}
```

---

## 🔄 CREATE vs USE EXISTING

### Decision Tree

```
Do you need to create new KMS keys?
│
├─ YES → I have permission and want control
│         └─ Use: kms_create.tf
│            ✓ Create custom KMS keys
│            ✓ Define key policies
│            ✓ Best for: App Team, custom encryption
│
└─ NO → Security Team manages KMS keys
          └─ Use: kms_use_existing.tf
             ✓ Reference existing keys
             ✓ No new keys created
             ✓ Best for: Enterprise, strict security
```

---

## 📋 QUESTIONNAIRE: Using Existing KMS Keys

### Before You Start

If your Security Team has already created KMS keys, gather this information:

### ✅ Required Information

#### 1. Which Services Need Encryption?

```
□ Secrets Manager (API keys, passwords)
□ S3 buckets (file uploads)
□ DynamoDB tables (database)
□ RDS databases (relational DB)
□ Lambda environment variables
□ SNS topics (notifications)
□ SQS queues (messages)
```

#### 2. KMS Key ARNs

```
Secrets Manager KMS Key:
  ARN: arn:aws:kms:us-east-1:123456789012:key/_______________
  Alias: alias/_______________
  Purpose: _______________

S3 KMS Key:
  ARN: arn:aws:kms:us-east-1:123456789012:key/_______________
  Alias: alias/_______________
  Purpose: _______________

DynamoDB KMS Key:
  ARN: arn:aws:kms:us-east-1:123456789012:key/_______________
  Alias: alias/_______________
  Purpose: _______________
```

#### 3. Confirm Permissions

```
Question: Does my Lambda execution role have permission to use the Secrets Manager KMS key?
Answer: _______________

Question: Can I use the S3 KMS key for my application's file uploads?
Answer: _______________

Question: Is the key rotation enabled?
Answer: _______________
```

---

### 🤔 Common Questions

#### Q1: How do I find KMS key ARN if Security Team only gave me the alias?

**Answer**: Use AWS CLI

```bash
# Find key by alias
aws kms describe-key --key-id alias/secrets-manager-key

# Output shows:
{
  "KeyMetadata": {
    "KeyId": "abc-123-def-456",
    "Arn": "arn:aws:kms:us-east-1:123456789012:key/abc-123-def-456"
  }
}
```

---

#### Q2: Can I use the same KMS key across regions?

**Answer**: NO! KMS keys are region-specific

```
If you have:
- Lambda in us-east-1
- S3 bucket in us-west-2

You need:
- KMS key in us-east-1 (for Lambda)
- KMS key in us-west-2 (for S3)
```

**Solution**: Create keys in each region or replicate keys

---

#### Q3: What if I don't have permission to use the KMS key?

**Answer**: Request access from Security Team

```
Error you'll see:
"AccessDeniedException: User is not authorized to perform kms:Decrypt"

Steps:
1. Find your Lambda execution role ARN
2. Email Security Team requesting access
3. They add your role to key policy
```

**Email template below**

---

#### Q4: How do I test if I have access to the KMS key?

**Answer**: Try to encrypt/decrypt

```bash
# Test encryption
aws kms encrypt \
  --key-id arn:aws:kms:us-east-1:123456789012:key/abc-123 \
  --plaintext "test data" \
  --query CiphertextBlob \
  --output text

# If successful: You have access!
# If error: Request permission
```

---

## 📝 Email Template: Request KMS Key Access

```
Subject: KMS Key Access Request for [Project Name]

Hi [Security Team],

I need access to KMS keys for [project name].

RESOURCES THAT NEED ENCRYPTION:
--------------------------------
□ Secrets Manager (store API keys and DB passwords)
□ S3 bucket "my-app-uploads" (store user files)
□ DynamoDB table "users" (store user data)

INFORMATION NEEDED:
-------------------
1. KMS Key ARNs or Aliases for each service
2. Confirmation that my execution role has decrypt/encrypt permissions

MY EXECUTION ROLE:
------------------
Lambda Role ARN: arn:aws:iam::123456789012:role/my-lambda-role

PERMISSIONS NEEDED:
-------------------
- kms:Decrypt (to read encrypted data)
- kms:Encrypt (to encrypt new data)
- kms:GenerateDataKey (for S3/DynamoDB encryption)

REGION:
-------
us-east-1

Please let me know the KMS key details and confirm permissions.

Thanks!
[Your Name]
```

---

## 💰 KMS Pricing

| Item | Cost |
|------|------|
| **Customer Managed Key** | $1/month per key |
| **AWS Managed Key** | FREE |
| **API Requests** | $0.03 per 10,000 requests |
| **Key Storage** | Included in $1/month |
| **Key Rotation** | FREE (automatic) |

**Example Cost Calculation:**

```
Small App:
- 3 KMS keys (secrets, S3, DynamoDB) = $3/month
- 1M encrypt/decrypt operations = $3/month
Total: ~$6/month

Medium App:
- 10 KMS keys = $10/month
- 10M operations = $30/month
Total: ~$40/month

Large App:
- 50 KMS keys = $50/month
- 100M operations = $300/month
Total: ~$350/month
```

---

## 🎯 Best Practices

### 1. Enable Automatic Key Rotation

```hcl
resource "aws_kms_key" "example" {
  enable_key_rotation = true  # Rotate every year
}
```

**Why?**
- Reduces risk if key is compromised
- Compliance requirement (PCI-DSS)
- No downtime (AWS handles rotation)

---

### 2. Use Separate Keys per Service

```hcl
# Good
resource "aws_kms_key" "secrets" { }
resource "aws_kms_key" "s3" { }
resource "aws_kms_key" "dynamodb" { }

# Bad (for production)
resource "aws_kms_key" "shared" { }  # Used by everything
```

---

### 3. Always Add Descriptions and Tags

```hcl
resource "aws_kms_key" "example" {
  description = "Encryption key for production Secrets Manager"

  tags = {
    Name        = "production-secrets-key"
    Environment = "production"
    Purpose     = "Secrets Manager"
  }
}
```

---

### 4. Set Deletion Window to 30 Days

```hcl
resource "aws_kms_key" "example" {
  deletion_window_in_days = 30  # Time to recover if mistake
}
```

---

### 5. Use Least Privilege for Key Policies

```hcl
# Only grant specific actions to specific roles
policy = jsonencode({
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:role/lambda-role"
      }
      Action = [
        "kms:Decrypt",    # Only what's needed
        "kms:Encrypt"     # Not kms:*
      ]
      Resource = "*"
    }
  ]
})
```

---

## 🛠️ Step-by-Step: Create KMS Keys

### Step 1: Decide How Many Keys

```
Ask yourself:
- What services need encryption? (Secrets, S3, DynamoDB, RDS)
- Is this dev or production? (Dev = fewer keys OK)
- Any compliance requirements? (HIPAA, PCI-DSS = more keys)
```

### Step 2: Create Terraform Configuration

```bash
cd modules/kms
cp kms_create.tf main.tf
```

### Step 3: Configure Variables

```hcl
# In terraform.tfvars
create_secrets_manager_key = true   # Create key for Secrets Manager
create_s3_key               = true   # Create key for S3
create_dynamodb_key         = true   # Create key for DynamoDB
create_rds_key              = false  # Not using RDS

project_name = "my-app"
environment  = "production"
```

### Step 4: Run Terraform

```bash
terraform init
terraform plan    # Review what will be created
terraform apply   # Create KMS keys
```

### Step 5: Use in Other Resources

```hcl
# In your Secrets Manager module
resource "aws_secretsmanager_secret" "db_password" {
  kms_key_id = module.kms.secrets_manager_key_id  # Use the key!
}

# In your S3 module
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms.s3_key_id  # Use the key!
    }
  }
}
```

---

## 🛠️ Step-by-Step: Use Existing KMS Keys

### Step 1: Get Key ARNs from Security Team

Use email template above.

### Step 2: Copy File

```bash
cd modules/kms
cp kms_use_existing.tf main.tf
```

### Step 3: Fill in Key ARNs

```hcl
# In terraform.tfvars
existing_secrets_manager_key_arn = "arn:aws:kms:us-east-1:123:key/abc-123"
existing_s3_key_arn              = "arn:aws:kms:us-east-1:123:key/def-456"
existing_dynamodb_key_arn        = "arn:aws:kms:us-east-1:123:key/ghi-789"
```

### Step 4: Verify Access

```bash
terraform plan
terraform output kms_key_summary  # Verify keys are accessible
```

### Step 5: Use Same as Created Keys

```hcl
# Same code works for both created and existing!
resource "aws_secretsmanager_secret" "db_password" {
  kms_key_id = module.kms.secrets_manager_key_id
}
```

---

## 🔒 Security Checklist

Before deploying to production:

- [ ] Automatic key rotation enabled
- [ ] Separate keys per service (or good reason for shared key)
- [ ] Deletion window = 30 days
- [ ] Key policies follow least privilege
- [ ] All keys have descriptions and tags
- [ ] CloudTrail logging enabled (audit key usage)
- [ ] Tested that application can encrypt/decrypt
- [ ] Documented which key is for what purpose

---

## 📊 Comparison: Create vs Use Existing

| Feature | kms_create.tf | kms_use_existing.tf |
|---------|--------------|---------------------|
| **Creates new keys** | ✅ Yes | ❌ No |
| **Uses existing keys** | ❌ No | ✅ Yes |
| **Control over rotation** | Full control | No control |
| **Key policies** | You define | Security Team defines |
| **terraform destroy** | Schedules deletion | Does nothing |
| **Best for** | App Team, small/medium companies | Enterprise, strict security |
| **Cost** | $1/month per key | No additional cost |
| **Flexibility** | High | Low |

---

## 💡 When to Use Which?

### Use `kms_create.tf` if:
- ✅ Starting new project
- ✅ Dev/test environment
- ✅ Have permission to create keys
- ✅ Want full control over key policies
- ✅ Small/medium company

### Use `kms_use_existing.tf` if:
- ✅ Enterprise company
- ✅ Production environment
- ✅ Security Team manages all keys
- ✅ Need to follow strict compliance
- ✅ Keys already exist

---

**Next**: See complete implementations in [kms_create.tf](./kms_create.tf) or [kms_use_existing.tf](./kms_use_existing.tf)
