# Secrets Manager - Your Password Vault

## 🎯 What is Secrets Manager?

**Simple Explanation:**
Secrets Manager is like a secure password manager (like 1Password or LastPass) for your applications. It stores passwords, API keys, and other sensitive data encrypted and safe.

Think of it as a vault where you lock away all your application's secrets instead of writing them directly in your code.

**Technical Definition:**
AWS Secrets Manager is a managed service that helps you protect access to your applications, services, and IT resources without the upfront cost and complexity of managing your own hardware security module (HSM) infrastructure.

---

## 🤔 Why Do I Need Secrets Manager?

### Without Secrets Manager (Secrets in Code):
```python
# DANGEROUS - Don't do this!
DATABASE_PASSWORD = "mySecretPassword123"
API_KEY = "sk_live_abc123def456"
STRIPE_SECRET = "stripe_secret_key_xyz"

# Connect to database
db.connect(password=DATABASE_PASSWORD)
```

**Problems:**
- ❌ Secrets visible in code (anyone with code access sees them)
- ❌ Secrets in git history (permanent exposure, even if you delete)
- ❌ Can't rotate passwords without redeploying code
- ❌ No audit trail (who accessed which secret?)
- ❌ Compliance failure (PCI-DSS, HIPAA won't allow this)
- ❌ If repo is leaked, ALL secrets are compromised

---

### With Secrets Manager:
```python
# SECURE - Secrets stored in Secrets Manager
import boto3

secrets = boto3.client('secretsmanager')
response = secrets.get_secret_value(SecretId='production/database/password')
db_password = response['SecretString']

# Connect to database
db.connect(password=db_password)
```

**Benefits:**
- ✅ **Secure Storage**: Secrets encrypted with KMS
- ✅ **Never in Code**: No secrets in git history
- ✅ **Easy Rotation**: Change passwords without code changes
- ✅ **Access Control**: IAM controls who can read secrets
- ✅ **Audit Trail**: CloudTrail logs every secret access
- ✅ **Automatic Rotation**: Can auto-rotate database passwords
- ✅ **Compliance**: Meets PCI-DSS, HIPAA, SOC2 requirements

---

## 📊 Real-World Example

### Scenario: E-commerce Application

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR APPLICATION                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Lambda Function (API Handler)                          │ │
│  │                                                         │ │
│  │ 1. Starts up                                           │ │
│  │ 2. Calls Secrets Manager: "Get database password"     │ │
│  │ 3. Receives encrypted secret                          │ │
│  │ 4. Connects to database with password                 │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  AWS SECRETS MANAGER                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Secret: production/database/password                   │ │
│  │ Value: [ENCRYPTED]                                     │ │
│  │ Encryption: KMS key abc-123                            │ │
│  │                                                         │ │
│  │ Secret: production/stripe/api-key                      │ │
│  │ Value: [ENCRYPTED]                                     │ │
│  │                                                         │ │
│  │ Secret: production/sendgrid/api-key                    │ │
│  │ Value: [ENCRYPTED]                                     │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      KMS (Encryption)                        │
│  All secrets encrypted with KMS key                          │
│  Even if someone steals Secrets Manager data, can't decrypt │
└─────────────────────────────────────────────────────────────┘
```

**What Happens:**
1. Lambda starts and needs database password
2. Lambda calls Secrets Manager API
3. Secrets Manager checks: "Does Lambda have IAM permission?" → Yes!
4. Secrets Manager decrypts secret with KMS key
5. Returns plaintext password to Lambda
6. Lambda connects to database
7. CloudTrail logs: "Lambda read database password at 2:30 PM"

---

## 🔑 Key Concepts

### 1. What is a "Secret"?

**Simple Answer:**
Any sensitive data your application needs but shouldn't be in code.

**Examples:**
```
✅ Store in Secrets Manager:
- Database passwords
- API keys (Stripe, SendGrid, Twilio)
- OAuth tokens
- Private encryption keys
- SSH private keys
- Third-party service credentials

❌ Don't store in Secrets Manager:
- Configuration values (not sensitive) → Use environment variables
- Public API endpoints → Use environment variables
- Feature flags → Use config service
- Non-sensitive settings → Use environment variables
```

---

### 2. Secret Format: String vs JSON

#### **String Format (Simple)**
```
Secret Name: production/database/password
Secret Value: "mySecretPassword123"
```

**Use when:**
- Single value (just a password or API key)
- Simple to retrieve

**Example:**
```python
response = secrets.get_secret_value(SecretId='production/database/password')
password = response['SecretString']  # "mySecretPassword123"
```

---

#### **JSON Format (Multiple Values)**
```
Secret Name: production/database/credentials
Secret Value: {
  "username": "admin",
  "password": "mySecretPassword123",
  "host": "db.example.com",
  "port": 5432
}
```

**Use when:**
- Multiple related values
- Database connection details
- API credentials with multiple fields

**Example:**
```python
import json

response = secrets.get_secret_value(SecretId='production/database/credentials')
credentials = json.loads(response['SecretString'])

username = credentials['username']  # "admin"
password = credentials['password']  # "mySecretPassword123"
host = credentials['host']           # "db.example.com"
```

---

### 3. Secret Naming Convention

**Best Practice: Use Path-like Names**

```
Format: environment/service/secret-type

Examples:
production/database/password
production/stripe/api-key
production/sendgrid/api-key
production/jwt/signing-key

staging/database/password
staging/stripe/api-key

dev/database/password
```

**Why this structure?**
- Easy to understand what secret is for
- Easy to grant access by environment (all production/*)
- Easy to search and manage
- Follows enterprise conventions

---

### 4. Secret Rotation

**What is Rotation?**
Changing the password/key periodically for security.

**Why Rotate?**
- Reduce risk if secret is compromised
- Compliance requirement (PCI-DSS, HIPAA)
- Best practice (change passwords regularly)

**How it Works:**

```
Manual Rotation:
1. You create new password
2. Update secret in Secrets Manager
3. Application automatically gets new password (no code change!)

Automatic Rotation (Advanced):
1. Secrets Manager triggers Lambda function every 30 days
2. Lambda creates new database password
3. Lambda updates RDS database with new password
4. Lambda updates secret with new password
5. Applications automatically use new password
```

**Supported Automatic Rotation:**
- ✅ RDS databases (PostgreSQL, MySQL, etc.)
- ✅ Amazon DocumentDB
- ✅ Amazon Redshift
- ❌ Third-party APIs (manual rotation)
- ❌ Custom secrets (write your own Lambda)

---

## 🛠️ Common Secrets Manager Patterns

### Pattern 1: Database Password (Simple String)

**Use Case:** Store PostgreSQL password

```hcl
# Create KMS key for encryption
resource "aws_kms_key" "secrets" {
  description = "KMS key for Secrets Manager"
  enable_key_rotation = true
}

# Create secret
resource "aws_secretsmanager_secret" "db_password" {
  name        = "production/database/password"
  description = "PostgreSQL database password"
  kms_key_id  = aws_kms_key.secrets.id

  tags = {
    Name        = "production-db-password"
    Environment = "production"
  }
}

# Store the secret value
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.database_password  # From terraform.tfvars (not in code!)
}
```

**How to Use in Lambda:**
```python
import boto3
import json

def lambda_handler(event, context):
    # Get secret
    secrets = boto3.client('secretsmanager')
    response = secrets.get_secret_value(SecretId='production/database/password')
    password = response['SecretString']

    # Use password
    db.connect(password=password)
```

---

### Pattern 2: Database Credentials (JSON Format)

**Use Case:** Store all database connection details

```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "production/database/credentials"
  description = "Complete database connection details"
  kms_key_id  = aws_kms_key.secrets.id
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = 5432
    database = "production"
  })
}
```

**How to Use:**
```python
import boto3
import json

def lambda_handler(event, context):
    secrets = boto3.client('secretsmanager')
    response = secrets.get_secret_value(SecretId='production/database/credentials')

    # Parse JSON
    creds = json.loads(response['SecretString'])

    # Connect to database
    db.connect(
        host=creds['host'],
        port=creds['port'],
        user=creds['username'],
        password=creds['password'],
        database=creds['database']
    )
```

---

### Pattern 3: API Keys (Multiple Secrets)

**Use Case:** Store third-party API keys

```hcl
# Stripe API Key
resource "aws_secretsmanager_secret" "stripe_key" {
  name        = "production/stripe/api-key"
  description = "Stripe API secret key"
  kms_key_id  = aws_kms_key.secrets.id
}

resource "aws_secretsmanager_secret_version" "stripe_key" {
  secret_id     = aws_secretsmanager_secret.stripe_key.id
  secret_string = var.stripe_api_key
}

# SendGrid API Key
resource "aws_secretsmanager_secret" "sendgrid_key" {
  name        = "production/sendgrid/api-key"
  description = "SendGrid API key for sending emails"
  kms_key_id  = aws_kms_key.secrets.id
}

resource "aws_secretsmanager_secret_version" "sendgrid_key" {
  secret_id     = aws_secretsmanager_secret.sendgrid_key.id
  secret_string = var.sendgrid_api_key
}

# Twilio Credentials (JSON format)
resource "aws_secretsmanager_secret" "twilio" {
  name        = "production/twilio/credentials"
  description = "Twilio Account SID and Auth Token"
  kms_key_id  = aws_kms_key.secrets.id
}

resource "aws_secretsmanager_secret_version" "twilio" {
  secret_id = aws_secretsmanager_secret.twilio.id

  secret_string = jsonencode({
    account_sid = var.twilio_account_sid
    auth_token  = var.twilio_auth_token
  })
}
```

---

### Pattern 4: JWT Signing Key

**Use Case:** Secret key for signing JWT tokens

```hcl
resource "aws_secretsmanager_secret" "jwt_signing_key" {
  name        = "production/jwt/signing-key"
  description = "Secret key for signing JWT tokens"
  kms_key_id  = aws_kms_key.secrets.id
}

# Generate random key
resource "random_password" "jwt_key" {
  length  = 64
  special = true
}

resource "aws_secretsmanager_secret_version" "jwt_signing_key" {
  secret_id     = aws_secretsmanager_secret.jwt_signing_key.id
  secret_string = random_password.jwt_key.result
}
```

**How to Use:**
```python
import jwt
import boto3

def create_token(user_id):
    # Get signing key
    secrets = boto3.client('secretsmanager')
    response = secrets.get_secret_value(SecretId='production/jwt/signing-key')
    signing_key = response['SecretString']

    # Create JWT token
    token = jwt.encode(
        {'user_id': user_id},
        signing_key,
        algorithm='HS256'
    )
    return token
```

---

## 🤔 Should I Create One Secret or Multiple Secrets?

### The Question

You have:
- Database password
- Stripe API key
- SendGrid API key
- JWT signing key

Do you create:
- **Option A**: One secret with all values (JSON)
- **Option B**: Separate secret for each value

**Short Answer**: Usually **Option B** (separate secrets) is better

---

### Option A: One Secret with All Values

```hcl
resource "aws_secretsmanager_secret" "all_secrets" {
  name = "production/all-secrets"
}

resource "aws_secretsmanager_secret_version" "all_secrets" {
  secret_id = aws_secretsmanager_secret.all_secrets.id

  secret_string = jsonencode({
    db_password    = "password123"
    stripe_key     = "sk_live_abc123"
    sendgrid_key   = "SG.xyz789"
    jwt_key        = "secret_key_456"
  })
}
```

**Pros:**
- ✅ Simple (only one secret to manage)
- ✅ One API call to get all secrets
- ✅ Cheaper ($0.40/month for one secret vs $1.60 for four)

**Cons:**
- ❌ All-or-nothing access (can't grant access to just Stripe key)
- ❌ If one key needs rotation, must update entire secret
- ❌ Harder to audit (who accessed which key?)
- ❌ Higher risk (compromise of secret = all keys exposed)

---

### Option B: Separate Secrets (RECOMMENDED)

```hcl
# Database password
resource "aws_secretsmanager_secret" "db_password" {
  name = "production/database/password"
}

# Stripe API key
resource "aws_secretsmanager_secret" "stripe_key" {
  name = "production/stripe/api-key"
}

# SendGrid API key
resource "aws_secretsmanager_secret" "sendgrid_key" {
  name = "production/sendgrid/api-key"
}

# JWT signing key
resource "aws_secretsmanager_secret" "jwt_key" {
  name = "production/jwt/signing-key"
}
```

**Pros:**
- ✅ **Granular Access**: Give payment Lambda only Stripe key access
- ✅ **Security Isolation**: Compromise of one doesn't expose others
- ✅ **Easy Rotation**: Rotate Stripe key without touching database password
- ✅ **Better Audit**: CloudTrail shows which specific secret was accessed
- ✅ **Compliance**: Some standards require separate secrets

**Cons:**
- ⚠️ More secrets to manage
- ⚠️ Higher cost ($0.40/month per secret)
- ⚠️ Multiple API calls if need multiple secrets

---

### Decision Tree

```
How are secrets used?
│
├─ DIFFERENT SERVICES use different secrets
│  └─ Use SEPARATE secrets
│     Example: Payment Lambda needs Stripe, Email Lambda needs SendGrid
│     Why: Grant each Lambda only what it needs
│
├─ RELATED VALUES (same service)
│  └─ Use ONE secret with JSON
│     Example: Database username + password + host
│     Why: Always used together, no reason to separate
│
└─ ALL SECRETS used by same application
   │
   ├─ High security requirements?
   │  └─ Use SEPARATE secrets (better isolation)
   │
   └─ Cost-conscious, low security needs?
      └─ Use ONE secret (save money)
```

---

### Real-World Recommendations

#### **Small App / Startup**
```
Cost-conscious, simple setup

Strategy:
- Group related secrets together
- 2-3 secrets total

Examples:
- production/database/credentials (username + password)
- production/api-keys (Stripe + SendGrid + Twilio)
- production/jwt/signing-key

Cost: ~$1.20/month
```

#### **Medium App**
```
Balance security and cost

Strategy:
- Separate secrets per service type
- 5-10 secrets

Examples:
- production/database/password
- production/stripe/api-key
- production/sendgrid/api-key
- production/twilio/credentials
- production/jwt/signing-key

Cost: ~$2-4/month
```

#### **Large Enterprise / Regulated**
```
Security first, compliance required

Strategy:
- One secret per credential
- Separate by team/service
- 20+ secrets

Examples:
- production/payment-service/stripe/api-key
- production/email-service/sendgrid/api-key
- production/database/master/password
- production/database/readonly/password

Cost: ~$8+/month
```

---

### Summary Table

| Scenario | Number of Secrets | Example |
|----------|-------------------|---------|
| **Dev environment** | 1-2 secrets | All in one JSON or grouped by type |
| **Small production app** | 2-4 secrets | Grouped by service (DB, APIs, signing keys) |
| **Medium app** | 5-10 secrets | One per external service |
| **Enterprise / Regulated** | Many secrets | One per credential, separated by team |

**Golden Rule:**
> Group secrets that are always used together (like database username + password). Separate secrets used by different services or teams.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Storing Secrets in Code

```python
# WRONG - Secret in code!
API_KEY = "sk_live_abc123def456"
```

**Fix:**
```python
# CORRECT - Get from Secrets Manager
import boto3
secrets = boto3.client('secretsmanager')
response = secrets.get_secret_value(SecretId='production/stripe/api-key')
API_KEY = response['SecretString']
```

---

### ❌ Mistake 2: Not Using KMS Encryption

```hcl
# WRONG - No KMS key specified
resource "aws_secretsmanager_secret" "bad" {
  name = "my-secret"
  # kms_key_id not specified!
}
```

**Why wrong?**
- Uses default AWS managed key (less control)
- Can't track who encrypted/decrypted
- Can't control key rotation

**Fix:**
```hcl
# CORRECT - Use your own KMS key
resource "aws_secretsmanager_secret" "good" {
  name       = "my-secret"
  kms_key_id = aws_kms_key.secrets.id  # Your KMS key
}
```

---

### ❌ Mistake 3: Hardcoding Secret Values in Terraform

```hcl
# WRONG - Secret value hardcoded!
resource "aws_secretsmanager_secret_version" "bad" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = "myPassword123"  # Hardcoded in Terraform file!
}
```

**Why wrong?**
- Secret visible in Terraform files
- Secret in git history
- Defeats purpose of Secrets Manager

**Fix:**
```hcl
# CORRECT - Use variable
resource "aws_secretsmanager_secret_version" "good" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = var.database_password  # From terraform.tfvars (in .gitignore)
}
```

---

### ❌ Mistake 4: Not Granting IAM Permissions

```python
# Code tries to get secret
response = secrets.get_secret_value(SecretId='production/database/password')

# Error: AccessDeniedException!
```

**Why?**
- Lambda execution role doesn't have permission to read secret

**Fix:**
```hcl
# Grant Lambda permission to read secret
resource "aws_iam_role_policy" "lambda_secrets" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}
```

---

### ❌ Mistake 5: Not Caching Secrets

```python
# WRONG - Get secret on every request!
def lambda_handler(event, context):
    secrets = boto3.client('secretsmanager')
    response = secrets.get_secret_value(SecretId='production/database/password')
    password = response['SecretString']
    # ... use password
```

**Why wrong?**
- Slow (API call every time)
- Expensive (charged per API call)
- Unnecessary

**Fix:**
```python
# CORRECT - Cache secret
import boto3

# Cache secret outside handler (reused across invocations)
secrets_client = boto3.client('secretsmanager')
cached_password = None

def get_password():
    global cached_password
    if cached_password is None:
        response = secrets_client.get_secret_value(
            SecretId='production/database/password'
        )
        cached_password = response['SecretString']
    return cached_password

def lambda_handler(event, context):
    password = get_password()  # Uses cached value
    # ... use password
```

---

## 🔄 CREATE vs USE EXISTING

### Decision Tree

```
Do you need to create new secrets?
│
├─ YES → I manage my application secrets
│         └─ Use: secrets_create.tf
│            ✓ Create secrets for your app
│            ✓ Control secret values
│            ✓ Best for: App Team, developers
│
└─ NO → Security Team manages secrets
          └─ Use: secrets_use_existing.tf
             ✓ Reference existing secrets
             ✓ No new secrets created
             ✓ Best for: Enterprise, strict governance
```

---

## 💰 Secrets Manager Pricing

| Item | Cost |
|------|------|
| **Secret Storage** | $0.40/month per secret |
| **API Calls** | $0.05 per 10,000 calls |
| **Free Tier** | 30-day trial for new secrets |
| **Rotation** | FREE (no extra charge) |

**Example Cost Calculation:**

```
Small App:
- 3 secrets = $1.20/month
- 100K API calls = $0.50/month
Total: ~$1.70/month

Medium App:
- 10 secrets = $4/month
- 1M API calls = $5/month
Total: ~$9/month

Large App:
- 50 secrets = $20/month
- 10M API calls = $50/month
Total: ~$70/month
```

**Cost Saving Tips:**
- Cache secrets in Lambda (reduce API calls)
- Use fewer secrets where appropriate
- Rotate manually instead of automatic (if acceptable)

---

## 🎯 Best Practices

### 1. Use Path-like Naming

```hcl
# Good
name = "production/database/password"
name = "production/stripe/api-key"

# Bad
name = "db-pass"
name = "stripekey"
```

---

### 2. Always Use KMS Encryption

```hcl
resource "aws_secretsmanager_secret" "example" {
  name       = "production/database/password"
  kms_key_id = aws_kms_key.secrets.id  # Always specify!
}
```

---

### 3. Separate Secrets by Environment

```hcl
# Production secrets
resource "aws_secretsmanager_secret" "prod_db" {
  name = "production/database/password"
}

# Staging secrets
resource "aws_secretsmanager_secret" "staging_db" {
  name = "staging/database/password"
}

# Dev secrets
resource "aws_secretsmanager_secret" "dev_db" {
  name = "dev/database/password"
}
```

---

### 4. Grant Least Privilege

```hcl
# Only grant access to specific secret
resource "aws_iam_role_policy" "lambda_secrets" {
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn  # Specific secret!
      }
    ]
  })
}
```

---

### 5. Never Commit Secrets to Git

```bash
# Add to .gitignore
terraform.tfvars
*.tfvars
secrets.txt
.env
```

---

### 6. Enable Secret Rotation

```hcl
resource "aws_secretsmanager_secret_rotation" "db" {
  secret_id           = aws_secretsmanager_secret.db.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn

  rotation_rules {
    automatically_after_days = 30  # Rotate every 30 days
  }
}
```

---

### 7. Add Tags for Organization

```hcl
resource "aws_secretsmanager_secret" "example" {
  name = "production/database/password"

  tags = {
    Name        = "production-db-password"
    Environment = "production"
    Service     = "database"
    Team        = "platform"
    Compliance  = "PCI-DSS"
  }
}
```

---

## 🛠️ How to Use Secrets in Different Languages

### Python (Lambda)

```python
import boto3
import json

def get_secret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return response['SecretString']

# Simple string secret
db_password = get_secret('production/database/password')

# JSON secret
creds = json.loads(get_secret('production/database/credentials'))
username = creds['username']
password = creds['password']
```

---

### Node.js (Lambda)

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecret(secretName) {
  const data = await secretsManager.getSecretValue({
    SecretId: secretName
  }).promise();

  return data.SecretString;
}

// Usage
const dbPassword = await getSecret('production/database/password');

// JSON secret
const credsJson = await getSecret('production/database/credentials');
const creds = JSON.parse(credsJson);
```

---

### Go (Lambda)

```go
import (
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/secretsmanager"
)

func getSecret(secretName string) (string, error) {
    sess := session.Must(session.NewSession())
    svc := secretsmanager.New(sess)

    input := &secretsmanager.GetSecretValueInput{
        SecretId: aws.String(secretName),
    }

    result, err := svc.GetSecretValue(input)
    if err != nil {
        return "", err
    }

    return *result.SecretString, nil
}
```

---

**Next**: See complete implementations in [secrets_create.tf](./secrets_create.tf) or [secrets_use_existing.tf](./secrets_use_existing.tf)
