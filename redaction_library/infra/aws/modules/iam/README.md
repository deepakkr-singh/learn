# IAM (Identity and Access Management) - Who Can Do What

## 🎯 What is IAM?

**Simple Explanation:**
IAM is like a security system that controls who can access what in your AWS account. Think of it as:
- **ID badges** for your applications (who you are)
- **Security clearance levels** for what you can do (what you're allowed to access)

**Real-World Analogy:**
Imagine an office building:
- **IAM User** = Person with ID badge (you, your team member)
- **IAM Role** = Job position with specific access (security guard, accountant, manager)
- **IAM Policy** = List of permissions (can enter server room, can view financial records)

**Technical Definition:**
AWS IAM is a web service that helps you securely control access to AWS resources. You use IAM to control who is authenticated (signed in) and authorized (has permissions) to use resources.

---

## 🤔 Why Do I Need IAM?

### Without IAM (Everyone is Admin):
```
DANGEROUS - Everyone has full access!

Developer → Can delete production database ❌
Lambda function → Can delete all S3 buckets ❌
Contractor → Can view all customer data ❌
```

**Problems:**
- ❌ Anyone can do anything (security nightmare)
- ❌ Can't track who did what
- ❌ One mistake = entire infrastructure deleted
- ❌ Compliance failure
- ❌ No accountability

---

### With IAM (Least Privilege):
```
SECURE - Each person/service has only needed permissions

Developer → Can deploy code, view logs ✅
Lambda function → Can read DynamoDB, write S3 ✅
Contractor → Can view docs only ✅
```

**Benefits:**
- ✅ **Security**: Limit blast radius of mistakes/attacks
- ✅ **Compliance**: Meet SOC2, ISO, HIPAA requirements
- ✅ **Audit Trail**: CloudTrail shows who did what
- ✅ **Least Privilege**: Grant minimum needed access
- ✅ **Easy Revocation**: Remove access instantly
- ✅ **No Shared Passwords**: Each person/service has own credentials

---

## 📊 Real-World Example

### Scenario: E-commerce Application

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR AWS ACCOUNT                        │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ IAM USERS (Humans)                                     │ │
│  │                                                         │ │
│  │  👤 Alice (Developer)                                  │ │
│  │     Policy: DeployCode, ViewLogs                      │ │
│  │     Can: Deploy Lambda, Read CloudWatch               │ │
│  │     Cannot: Delete databases, View secrets            │ │
│  │                                                         │ │
│  │  👤 Bob (DevOps)                                       │ │
│  │     Policy: FullInfraAccess                           │ │
│  │     Can: Manage VPC, Databases, Everything            │ │
│  │                                                         │ │
│  │  👤 Carol (Contractor)                                 │ │
│  │     Policy: ReadOnlyAccess                            │ │
│  │     Can: View documentation, Read logs                │ │
│  │     Cannot: Modify anything                           │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ IAM ROLES (Services)                                   │ │
│  │                                                         │ │
│  │  🤖 Lambda Execution Role                             │ │
│  │     Policy: DynamoDB read/write, Secrets Manager read │ │
│  │     Can: Query database, Get API keys                 │ │
│  │     Cannot: Delete tables, Access S3                  │ │
│  │                                                         │ │
│  │  🤖 EC2 Instance Role                                 │ │
│  │     Policy: S3 read/write, CloudWatch Logs write      │ │
│  │     Can: Upload files to S3, Send logs                │ │
│  │     Cannot: Access DynamoDB, Delete S3 buckets        │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**How it Works:**
1. Lambda function tries to read secret from Secrets Manager
2. AWS checks: "Does Lambda role have secretsmanager:GetSecretValue permission?" → Yes!
3. Lambda gets the secret
4. Lambda tries to delete S3 bucket
5. AWS checks: "Does Lambda role have s3:DeleteBucket permission?" → No!
6. Request denied → Protection from accidents

---

## 🔑 Key Concepts

### 1. IAM Users vs IAM Roles

#### **IAM Users (For Humans)**

```
What: Person who logs into AWS Console or uses AWS CLI
Who: Developers, DevOps, admins
Authentication: Username + password + MFA
Use Case: You, your team members

Example:
- alice@company.com (Developer)
- bob@company.com (DevOps)
- carol@company.com (Contractor)
```

**When to create:**
- New team member joins
- Need console access
- Need AWS CLI access

---

#### **IAM Roles (For Services/Applications)**

```
What: Job position that services assume
Who: Lambda, EC2, Fargate, other AWS services
Authentication: Automatic (no password needed)
Use Case: Applications, automation

Example:
- lambda-execution-role (for Lambda functions)
- ec2-instance-role (for EC2 servers)
- ecs-task-role (for containers)
```

**When to create:**
- Lambda function needs database access
- EC2 instance needs S3 access
- ECS task needs Secrets Manager access

---

**Key Difference:**
```
IAM User = Person (has credentials)
IAM Role = Job (services assume it, no credentials)
```

---

### 2. IAM Policies (The Permission List)

**What is a Policy?**
A JSON document that says "what actions are allowed on which resources"

**Policy Structure:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",           // Allow or Deny
      "Action": [                  // What can you do?
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"  // On what?
    }
  ]
}
```

**Translation:**
"Allow reading and writing objects in my-bucket"

---

### 3. Principle of Least Privilege

**What:**
Give only minimum permissions needed to do the job. Nothing more.

**Bad Example (Too Permissive):**
```json
{
  "Effect": "Allow",
  "Action": "*",              // Everything!
  "Resource": "*"             // On everything!
}
```
Problem: Can delete entire AWS account!

---

**Good Example (Least Privilege):**
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",           // Only read
    "s3:PutObject"            // Only write
  ],
  "Resource": "arn:aws:s3:::my-specific-bucket/*"  // Only this bucket
}
```
Benefit: Can only read/write this one bucket. Can't delete, can't access other buckets.

---

### 4. Managed Policies vs Inline Policies

#### **AWS Managed Policies (Pre-made by AWS)**

```
What: Ready-to-use policies created by AWS
Examples:
- ReadOnlyAccess (read everything, change nothing)
- PowerUserAccess (everything except IAM)
- AmazonS3FullAccess (all S3 operations)
- AWSLambdaBasicExecutionRole (Lambda CloudWatch Logs)

Pros:
✅ Easy to use (just attach)
✅ AWS maintains them
✅ Best practices built-in

Cons:
⚠️ Often too permissive (not least privilege)
⚠️ Can't customize
```

---

#### **Customer Managed Policies (You Create)**

```
What: Custom policies you write
Examples:
- MyAppLambdaPolicy (exactly what your Lambda needs)
- DeveloperPolicy (what developers can do)

Pros:
✅ Least privilege (exact permissions needed)
✅ Reusable across roles/users
✅ You control updates

Cons:
⚠️ More work to create
⚠️ You maintain them
```

---

#### **Inline Policies (Embedded in Role)**

```
What: Policy directly attached to one role/user
Can't be reused

Pros:
✅ Keeps policy with role (clear relationship)

Cons:
⚠️ Not reusable
⚠️ Harder to manage at scale

Recommendation: Use Customer Managed Policies instead
```

---

## 🛠️ Common IAM Patterns

### Pattern 1: Lambda Execution Role (DynamoDB + Secrets Manager)

**Use Case:** Lambda function that reads/writes DynamoDB and gets secrets

```hcl
# 1. Create IAM role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution-${var.environment}"

  # Trust policy: Who can assume this role?
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"  # Only Lambda can assume
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 2. Attach AWS managed policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. Create custom policy for DynamoDB
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.project_name}-lambda-dynamodb-${var.environment}"
  description = "Allow Lambda to read/write DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn  # Specific table only
      }
    ]
  })
}

# 4. Attach custom policy to role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

# 5. Create custom policy for Secrets Manager
resource "aws_iam_policy" "lambda_secrets" {
  name        = "${var.project_name}-lambda-secrets-${var.environment}"
  description = "Allow Lambda to read specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_secret_arn,  # Only these secrets
          var.api_key_secret_arn
        ]
      }
    ]
  })
}

# 6. Attach secrets policy to role
resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_secrets.arn
}

# 7. Use in Lambda
resource "aws_lambda_function" "api" {
  function_name = "api-handler"
  role          = aws_iam_role.lambda_execution.arn  # Use the role!

  # ... other Lambda config
}
```

**What this allows:**
- ✅ Lambda can write logs to CloudWatch
- ✅ Lambda can read/write specific DynamoDB table
- ✅ Lambda can read specific secrets
- ❌ Lambda CANNOT delete DynamoDB table
- ❌ Lambda CANNOT access S3
- ❌ Lambda CANNOT create new resources

---

### Pattern 2: EC2 Instance Role (S3 Read/Write)

**Use Case:** EC2 instance that uploads files to S3

```hcl
# 1. Create IAM role
resource "aws_iam_role" "ec2_instance" {
  name = "${var.project_name}-ec2-instance-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  # Only EC2 can assume
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 2. Create S3 access policy
resource "aws_iam_policy" "ec2_s3_access" {
  name = "${var.project_name}-ec2-s3-access-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",      # Bucket itself
          "arn:aws:s3:::${var.bucket_name}/*"     # Objects in bucket
        ]
      }
    ]
  })
}

# 3. Attach policy
resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

# 4. Create instance profile (EC2 requires this)
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_instance.name
}

# 5. Use in EC2
resource "aws_instance" "web" {
  ami                  = "ami-12345678"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2.name  # Attach profile!

  # ... other EC2 config
}
```

---

### Pattern 3: Cross-Account Access Role

**Use Case:** Allow another AWS account to access your resources

```hcl
# Role that another account can assume
resource "aws_iam_role" "cross_account" {
  name = "cross-account-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::999999999999:root"  # Other account ID
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-123"  # Security measure
          }
        }
      }
    ]
  })
}

# Grant read-only access to S3
resource "aws_iam_policy" "cross_account_s3_read" {
  name = "cross-account-s3-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::shared-bucket/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cross_account_s3" {
  role       = aws_iam_role.cross_account.name
  policy_arn = aws_iam_policy.cross_account_s3_read.arn
}
```

---

## 🤔 Should I Create One IAM Role or Multiple Roles?

### The Question

You have 5 Lambda functions. Do you create:
- **Option A**: One shared IAM role for all Lambdas
- **Option B**: Separate IAM role per Lambda

**Short Answer**: Usually **Option B** (separate roles) is better for production

---

### Option A: One Shared Role

```hcl
# Single role for all Lambda functions
resource "aws_iam_role" "all_lambdas" {
  name = "all-lambdas-role"
}

# Grant ALL permissions any Lambda might need
resource "aws_iam_policy" "all_permissions" {
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*",       # All DynamoDB
          "s3:*",             # All S3
          "secretsmanager:*"  # All Secrets Manager
        ]
        Resource = "*"        # On everything!
      }
    ]
  })
}

# All Lambdas use same role
resource "aws_lambda_function" "user_api" {
  role = aws_iam_role.all_lambdas.arn
}

resource "aws_lambda_function" "payment_api" {
  role = aws_iam_role.all_lambdas.arn  # Same role
}
```

**Pros:**
- ✅ Simple (one role to manage)
- ✅ Easy to add new Lambda (just use existing role)

**Cons:**
- ❌ **MAJOR SECURITY RISK**: All Lambdas have all permissions
- ❌ Payment Lambda can access user data table (shouldn't!)
- ❌ User Lambda can access payment secrets (shouldn't!)
- ❌ If one Lambda is compromised, attacker has access to everything
- ❌ Violates least privilege principle
- ❌ Compliance failure

---

### Option B: Separate Roles (RECOMMENDED)

```hcl
# User API Lambda role (only what it needs)
resource "aws_iam_role" "user_api" {
  name = "user-api-lambda-role"
}

resource "aws_iam_policy" "user_api" {
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:*:*:table/users"  # Only users table
      }
    ]
  })
}

# Payment API Lambda role (different permissions)
resource "aws_iam_role" "payment_api" {
  name = "payment-api-lambda-role"
}

resource "aws_iam_policy" "payment_api" {
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = "arn:aws:dynamodb:*:*:table/payments"  # Only payments table
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:*:secret:stripe-key"  # Only Stripe key
      }
    ]
  })
}

# Each Lambda uses its own role
resource "aws_lambda_function" "user_api" {
  role = aws_iam_role.user_api.arn  # User-specific role
}

resource "aws_lambda_function" "payment_api" {
  role = aws_iam_role.payment_api.arn  # Payment-specific role
}
```

**Pros:**
- ✅ **Security**: Each Lambda has only what it needs
- ✅ **Isolation**: User Lambda can't access payment data
- ✅ **Compliance**: Meets least privilege requirement
- ✅ **Audit**: Clear what each Lambda can access
- ✅ **Containment**: Compromised Lambda has limited damage

**Cons:**
- ⚠️ More roles to manage
- ⚠️ More Terraform code

---

### Decision Tree

```
How sensitive is your data?
│
├─ VERY SENSITIVE (payments, health, PII)
│  └─ SEPARATE roles per Lambda
│     └─ Each Lambda gets minimum needed permissions
│
├─ MODERATELY SENSITIVE (user data)
│  └─ SEPARATE roles per service type
│     └─ User service role, Payment service role, etc.
│
└─ LOW SENSITIVITY (dev environment, logs)
   └─ SHARED role OK
      └─ But still limit permissions (not *)
```

---

### Summary Table

| Scenario | Number of Roles | Example |
|----------|-----------------|---------|
| **Production (sensitive data)** | One per Lambda | user-api-role, payment-api-role, email-api-role |
| **Production (moderate)** | One per service | api-lambdas-role, worker-lambdas-role |
| **Dev environment** | Shared OK | dev-lambda-role (but still limit permissions) |
| **Enterprise / Regulated** | One per Lambda + per environment | prod-user-api-role, staging-user-api-role |

**Golden Rule:**
> Start with separate roles. Never grant `*` permissions or `Resource: "*"` in production.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Using `*` for Actions or Resources

```hcl
# WRONG - Too permissive!
policy = jsonencode({
  Statement = [
    {
      Effect   = "Allow"
      Action   = "*"              # Everything!
      Resource = "*"              # On everything!
    }
  ]
})
```

**Why wrong?**
- Can delete entire AWS account
- Violates least privilege
- Compliance failure

**Fix:**
```hcl
# CORRECT - Specific permissions
policy = jsonencode({
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",     # Only what's needed
        "dynamodb:PutItem"
      ]
      Resource = "arn:aws:dynamodb:*:*:table/specific-table"  # Specific resource
    }
  ]
})
```

---

### ❌ Mistake 2: Forgetting to Attach Policy to Role

```hcl
# Created role
resource "aws_iam_role" "lambda" {
  name = "lambda-role"
}

# Created policy
resource "aws_iam_policy" "dynamodb_access" {
  name = "dynamodb-access"
  # ... policy definition
}

# FORGOT TO ATTACH!
# Missing: aws_iam_role_policy_attachment
```

**Result:** Role has no permissions! Lambda will get "Access Denied"

**Fix:**
```hcl
# CORRECT - Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}
```

---

### ❌ Mistake 3: Wrong Trust Policy (Assume Role Policy)

```hcl
# WRONG - Lambda can't assume this role!
resource "aws_iam_role" "lambda" {
  assume_role_policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  # Wrong service!
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

**Result:** Lambda can't use this role (403 error)

**Fix:**
```hcl
# CORRECT - Lambda service can assume
resource "aws_iam_role" "lambda" {
  assume_role_policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"  # Correct!
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

---

### ❌ Mistake 4: Not Using Instance Profile for EC2

```hcl
# WRONG - EC2 needs instance profile, not just role
resource "aws_instance" "web" {
  iam_instance_profile = aws_iam_role.ec2.name  # Wrong!
}
```

**Result:** Error - role is not an instance profile

**Fix:**
```hcl
# CORRECT - Create instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "web" {
  iam_instance_profile = aws_iam_instance_profile.ec2.name  # Correct!
}
```

---

## 🎯 Best Practices

### 1. Always Use Least Privilege

```hcl
# Good
Action = ["s3:GetObject", "s3:PutObject"]  # Only read/write
Resource = "arn:aws:s3:::specific-bucket/*"  # Only this bucket

# Bad
Action = "s3:*"        # All S3 operations
Resource = "*"         # All buckets
```

---

### 2. Separate Roles per Service/Environment

```hcl
# Good
aws_iam_role.prod_user_api_lambda
aws_iam_role.prod_payment_api_lambda
aws_iam_role.staging_user_api_lambda

# Bad
aws_iam_role.all_lambdas  # Used by everything
```

---

### 3. Use Descriptive Names

```hcl
# Good
name = "${var.project_name}-lambda-${var.function_name}-${var.environment}"
# Result: "ecommerce-lambda-user-api-production"

# Bad
name = "role1"  # What is this?
```

---

### 4. Add Tags for Organization

```hcl
tags = {
  Name        = "production-lambda-user-api-role"
  Environment = "production"
  Service     = "user-api"
  ManagedBy   = "Terraform"
  Team        = "platform"
}
```

---

### 5. Document Permissions

```hcl
# Add description to policies
resource "aws_iam_policy" "lambda_db" {
  name        = "lambda-dynamodb-access"
  description = "Allows Lambda to read/write users table only"  # Clear purpose!

  policy = jsonencode({
    Statement = [
      {
        Sid    = "AllowUsersTableAccess"  # Named statement
        Effect = "Allow"
        # ...
      }
    ]
  })
}
```

---

## 💰 IAM Pricing

**Good News: IAM is FREE!**

| Item | Cost |
|------|------|
| **IAM Users** | FREE |
| **IAM Roles** | FREE |
| **IAM Policies** | FREE |
| **IAM Groups** | FREE |

**No limit on:**
- Number of users
- Number of roles
- Number of policies
- Policy updates

---

## 🔄 CREATE vs USE EXISTING

### Decision Tree

```
Do you need to create IAM roles for your application?
│
├─ YES → You manage your application's IAM
│         └─ Use: iam_roles_create.tf
│            ✓ Create Lambda execution roles
│            ✓ Create EC2 instance roles
│            ✓ Best for: App Team, developers
│
└─ NO → Security Team pre-creates all roles
          └─ Use: iam_roles_use_existing.tf
             ✓ Reference existing role ARNs
             ✓ No new roles created
             ✓ Best for: Enterprise, strict governance
```

---

**Next**: See complete implementations in [iam_roles_create.tf](./iam_roles_create.tf) or [iam_roles_use_existing.tf](./iam_roles_use_existing.tf)
