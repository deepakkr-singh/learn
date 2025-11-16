# S3 (Simple Storage Service) - Cloud File Storage

## 🎯 What is S3?

**Simple Explanation:**
S3 is like Google Drive or Dropbox for your applications. It's unlimited cloud storage where you can store any type of file.

Think of it as:
- **Your computer's hard drive** = Limited space (500 GB, 1 TB)
- **S3** = Unlimited space, pay only for what you use

**Real-World Analogy:**
- **Traditional storage** = Buying external hard drives and storing them in your office
- **S3** = Renting infinite warehouse space, pay only for space used, AWS handles security/backup

**Technical Definition:**
Amazon S3 is an object storage service offering industry-leading scalability, data availability, security, and performance. You can store and retrieve any amount of data at any time from anywhere.

---

## 🤔 Why Do I Need S3?

### Without S3 (Local File Storage):
```
PROBLEMS with storing files on EC2 or Lambda:

1. Limited space (need to buy more disks)
2. Files lost if server crashes
3. Can't share files between servers
4. Manual backups needed
5. No redundancy (single point of failure)
6. Expensive scaling

Example: E-commerce site
- Store product images on EC2 server
- Server crashes → All images gone!
- Need CDN? Manual setup
- Traffic spike? Server can't handle downloads
```

---

### With S3:
```
BENEFITS:

✅ Unlimited storage (store petabytes)
✅ 99.999999999% durability (11 nines - virtually never loses data)
✅ Automatic backup across multiple data centers
✅ Share files between any AWS service
✅ Built-in CDN (CloudFront) integration
✅ Automatic scaling (handles 1 or 1 billion requests)
✅ Cheap ($0.023/GB/month)
✅ Versioning (keep old versions of files)
✅ Encryption built-in

Example: E-commerce site
- Upload product images to S3
- Images never lost (99.999999999% durability)
- CloudFront CDN delivers images fast worldwide
- Scales automatically for Black Friday traffic
```

---

## 📊 Real-World Example

### Scenario: Photo Sharing App

```
┌─────────────────────────────────────────────────────────────┐
│                        USER                                  │
│  Uploads photo.jpg (2 MB)                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   LAMBDA FUNCTION                            │
│  1. Receives upload request                                 │
│  2. Generates presigned URL for S3                          │
│  3. Returns URL to user                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    S3 BUCKET                                 │
│  Bucket: my-photos-app                                      │
│                                                              │
│  Folders:                                                    │
│  ├─ uploads/original/                                       │
│  │   └─ photo.jpg (original 2 MB)                           │
│  │                                                           │
│  ├─ uploads/thumbnails/                                     │
│  │   └─ photo.jpg (thumbnail 100 KB)                        │
│  │                                                           │
│  └─ uploads/optimized/                                      │
│      └─ photo.jpg (optimized 500 KB)                        │
│                                                              │
│  Features enabled:                                           │
│  - Versioning: Keep old versions                            │
│  - Encryption: AES-256 with KMS                             │
│  - Lifecycle: Delete after 90 days                          │
│  - Public access: BLOCKED                                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   CLOUDFRONT CDN                             │
│  Delivers images fast to users worldwide                    │
└─────────────────────────────────────────────────────────────┘
```

**Cost:**
- Store 10,000 photos (2 MB each) = 20 GB
- S3 storage: $0.46/month
- 100,000 downloads/month: $0.40/month
- **Total: ~$1/month**

---

## 🔑 Key Concepts

### 1. Buckets and Objects

**Bucket = Folder/Container**
```
Bucket name: my-app-uploads
- Must be globally unique (across all AWS accounts!)
- Can't rename (delete and recreate only)
- Can have unlimited objects

Examples of good bucket names:
✅ mycompany-production-uploads
✅ ecommerce-user-photos-prod
✅ acme-corp-backups-2025

Examples of bad bucket names:
❌ uploads (too generic, likely taken)
❌ my bucket (no spaces allowed)
❌ MyBucket (no uppercase allowed)
```

**Object = File**
```
Object key: uploads/2025/01/15/photo.jpg
- "Key" = file path (can have slashes for organization)
- Size: 0 bytes to 5 TB per object
- Metadata: Content-Type, custom tags

Example structure:
my-app-uploads/
├─ uploads/
│   ├─ 2025/01/15/photo1.jpg
│   ├─ 2025/01/15/photo2.jpg
│   └─ 2025/01/16/video.mp4
├─ thumbnails/
│   └─ photo1_thumb.jpg
└─ documents/
    └─ report.pdf
```

---

### 2. Public vs Private Buckets

#### **Private Bucket (Default, RECOMMENDED)**

```
Access: Only you and authorized AWS services

Use cases:
✅ User uploads (documents, private photos)
✅ Application backups
✅ Database exports
✅ Internal files
✅ 99% of use cases

Security:
- Block all public access (default)
- Access only via IAM roles
- Presigned URLs for temporary access
```

**Example:**
```hcl
resource "aws_s3_bucket" "private" {
  bucket = "my-private-uploads"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

#### **Public Bucket (Rare, Use with Caution)**

```
Access: Anyone on the internet

Use cases:
⚠️ Public website hosting (HTML, CSS, JS)
⚠️ Public CDN assets (logos, public images)
⚠️ Public downloads

Security risks:
❌ Anyone can download files
❌ Can expose sensitive data if misconfigured
❌ Famous S3 data breaches from public buckets

Better alternative: Use CloudFront CDN with private bucket
```

---

### 3. S3 Storage Classes

**Which storage class should I use?**

```
Standard (Default)
├─ Use for: Frequently accessed files
├─ Cost: $0.023/GB/month
├─ Retrieval: Instant
└─ Example: Active user uploads, website assets

Standard-IA (Infrequent Access)
├─ Use for: Files accessed < once/month
├─ Cost: $0.0125/GB/month (cheaper storage)
├─ Retrieval: Instant, but costs $0.01/GB to retrieve
└─ Example: Old photos, archived documents

Glacier Instant Retrieval
├─ Use for: Archive, accessed once/quarter
├─ Cost: $0.004/GB/month
├─ Retrieval: Instant, costs $0.03/GB
└─ Example: Compliance archives

Glacier Flexible Retrieval
├─ Use for: Long-term backup
├─ Cost: $0.0036/GB/month
├─ Retrieval: Minutes to hours, costs $0.02/GB
└─ Example: Old backups, rarely needed data

Glacier Deep Archive
├─ Use for: Cold storage (7-10 years)
├─ Cost: $0.00099/GB/month (cheapest!)
├─ Retrieval: 12 hours, costs $0.02/GB
└─ Example: Regulatory compliance (must keep 7 years)
```

**Lifecycle Rules (Automatic Transitions):**
```hcl
# Automatically move files to cheaper storage
resource "aws_s3_bucket_lifecycle_rule" "auto_archive" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "archive-old-files"
    status = "Enabled"

    transition {
      days          = 30  # After 30 days
      storage_class = "STANDARD_IA"  # Move to Infrequent Access
    }

    transition {
      days          = 90  # After 90 days
      storage_class = "GLACIER"  # Move to Glacier
    }

    expiration {
      days = 365  # Delete after 1 year
    }
  }
}
```

---

### 4. S3 Versioning

**What is Versioning?**
Keep multiple versions of same file (like Google Docs version history)

**Why Enable?**
- Protect from accidental deletion
- Rollback to previous version
- Compliance (audit trail)

**How it Works:**
```
Upload photo.jpg (version 1)
├─ Version ID: abc123

Upload photo.jpg again (version 2)
├─ Version ID: def456
└─ Version 1 (abc123) still exists!

Delete photo.jpg
├─ Creates "delete marker"
└─ All versions still exist (can undelete!)
```

**Cost Impact:**
```
Without versioning:
- photo.jpg (2 MB) = $0.046/month

With versioning (3 versions):
- photo.jpg v1 (2 MB) = $0.046/month
- photo.jpg v2 (2 MB) = $0.046/month
- photo.jpg v3 (2 MB) = $0.046/month
Total: $0.138/month

Recommendation: Use lifecycle rules to delete old versions
```

---

### 5. S3 Encryption

**Encryption at Rest (Stored Files):**

```
SSE-S3 (S3-Managed Keys)
├─ AWS manages encryption keys
├─ Cost: FREE
├─ Security: Good
└─ Use for: Most use cases

SSE-KMS (KMS-Managed Keys)
├─ You control encryption keys (via KMS)
├─ Cost: KMS charges ($1/month + API calls)
├─ Security: Better (audit trail, key rotation)
└─ Use for: Sensitive data, compliance

SSE-C (Customer-Provided Keys)
├─ You manage keys yourself
├─ Cost: FREE (but you handle key storage)
├─ Security: Full control
└─ Use for: Very specific compliance needs
```

**Recommendation:**
- **Default**: SSE-S3 (free, automatic)
- **Sensitive data**: SSE-KMS (audit trail, key control)

---

## 🛠️ Common S3 Patterns

### Pattern 1: User Uploads (Private Bucket)

**Use Case:** Users upload profile pictures

```hcl
# Create bucket
resource "aws_s3_bucket" "user_uploads" {
  bucket = "${var.project_name}-user-uploads-${var.environment}"

  tags = {
    Name        = "User Uploads"
    Environment = var.environment
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

# Lifecycle rule (delete old versions)
resource "aws_s3_bucket_lifecycle_configuration" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30  # Delete old versions after 30 days
    }
  }
}
```

**Access from Lambda (Presigned URL):**
```python
import boto3

s3 = boto3.client('s3')

def generate_upload_url(filename):
    # Generate presigned URL (valid for 15 minutes)
    url = s3.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': 'my-user-uploads',
            'Key': f'uploads/{filename}'
        },
        ExpiresIn=900  # 15 minutes
    )
    return url

# User gets this URL and uploads directly to S3
```

---

### Pattern 2: Static Website Hosting

**Use Case:** Host static website (HTML, CSS, JS)

```hcl
resource "aws_s3_bucket" "website" {
  bucket = "my-company-website"
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Make bucket public (for website hosting)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy (allow public read)
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}
```

**Better Alternative: Use CloudFront CDN**
- Private S3 bucket
- CloudFront distributes content
- Faster, more secure

---

### Pattern 3: Application Backups

**Use Case:** Daily database backups

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-backups-${var.environment}"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rules (move to cheaper storage)
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "archive-old-backups"
    status = "Enabled"

    # Move to Glacier after 30 days
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # Delete after 365 days
    expiration {
      days = 365
    }
  }
}

# Enable versioning (protect from accidental deletion)
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

## 🤔 Should I Create One S3 Bucket or Multiple Buckets?

### The Question

Your app needs to store:
- User profile pictures
- Document uploads
- Application backups
- Temporary files

Do you create:
- **Option A**: One bucket for everything
- **Option B**: Separate bucket for each type

**Short Answer**: **Option B** (separate buckets) is better for production

---

### Option A: One Bucket for Everything

```
my-app-bucket/
├─ profile-pictures/
├─ documents/
├─ backups/
└─ temp/
```

**Pros:**
- ✅ Simpler (one bucket to manage)
- ✅ Easier IAM policies

**Cons:**
- ❌ Can't set different lifecycle rules per type
- ❌ Can't set different encryption per type
- ❌ Harder to grant specific access (can't give access to just backups)
- ❌ Risk of accidental deletion affects everything
- ❌ Mixed costs (can't track per purpose)

---

### Option B: Separate Buckets (RECOMMENDED)

```
my-app-profile-pictures/
my-app-documents/
my-app-backups/
my-app-temp/
```

**Pros:**
- ✅ **Different lifecycle rules**: Backups → Glacier, temp → delete after 7 days
- ✅ **Different encryption**: Sensitive docs use KMS, temp files use S3
- ✅ **Granular access**: Backup Lambda only accesses backup bucket
- ✅ **Cost tracking**: See costs per bucket/purpose
- ✅ **Security isolation**: Compromise of one doesn't affect others

**Cons:**
- ⚠️ More buckets to manage
- ⚠️ Slightly more Terraform code

---

### Decision Tree

```
Do these files need different treatment?
│
├─ YES (different lifecycle, encryption, access)
│  └─ SEPARATE buckets
│     Example: User uploads (keep forever) vs temp files (delete after 1 day)
│
└─ NO (same lifecycle, encryption, access)
   └─ ONE bucket OK
      Example: All user uploads (profile pics, cover photos)
```

**Golden Rule:**
> Separate buckets if files have different lifecycles, security needs, or access patterns.

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting to Block Public Access

```hcl
# WRONG - No public access block!
resource "aws_s3_bucket" "bad" {
  bucket = "my-bucket"
}

# Someone could accidentally make files public → Data leak!
```

**Fix:**
```hcl
# CORRECT - Always block public access
resource "aws_s3_bucket_public_access_block" "good" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### ❌ Mistake 2: No Encryption

```hcl
# WRONG - Files stored unencrypted!
resource "aws_s3_bucket" "bad" {
  bucket = "my-bucket"
  # No encryption configuration
}
```

**Fix:**
```hcl
# CORRECT - Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "good" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # or "aws:kms"
    }
  }
}
```

---

### ❌ Mistake 3: No Lifecycle Rules (Wasting Money)

```hcl
# WRONG - Keep all files forever, even old versions!
# Cost grows infinitely
```

**Fix:**
```hcl
# CORRECT - Delete old versions, move to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "good" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    # Delete old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Move to Glacier after 180 days
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}
```

---

## 🎯 Best Practices

### 1. Always Block Public Access (Unless Website Hosting)

```hcl
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### 2. Enable Encryption by Default

```hcl
# Use KMS for sensitive data
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}
```

---

### 3. Use Versioning for Important Data

```hcl
resource "aws_s3_bucket_versioning" "important_data" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

### 4. Set Lifecycle Rules to Save Money

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimization" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "auto-archive"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
```

---

### 5. Use Descriptive Bucket Names

```hcl
# Good
bucket = "${var.company}-${var.environment}-${var.purpose}"
# Result: "acme-production-user-uploads"

# Bad
bucket = "bucket1"
```

---

## 💰 S3 Pricing

**Storage:**
- Standard: $0.023/GB/month
- Infrequent Access: $0.0125/GB/month
- Glacier: $0.004/GB/month
- Deep Archive: $0.00099/GB/month

**Requests:**
- PUT/POST: $0.005 per 1,000
- GET: $0.0004 per 1,000

**Data Transfer:**
- Upload (PUT): FREE
- Download (first 100 GB/month): FREE
- Download (after 100 GB): $0.09/GB

**Examples:**
```
Small App (100 GB, 10K requests/month):
- Storage: $2.30
- Requests: $0.05
Total: $2.35/month

Medium App (1 TB, 100K requests/month):
- Storage: $23
- Requests: $0.50
Total: $23.50/month

With Lifecycle (move to Glacier after 90 days):
- First 90 days: Standard ($23)
- After: Glacier ($4)
Average: ~$10/month (60% savings!)
```

---

**Next**: See complete implementations in [s3_buckets_create.tf](./s3_buckets_create.tf)
