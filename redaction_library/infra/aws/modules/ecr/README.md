# ECR (Elastic Container Registry) - Docker Image Storage

## What is ECR?

ECR is like **Docker Hub but private and inside AWS**. It's where you store your Docker images that Fargate, ECS, or Lambda will use.

**Real-World Analogy:**
```
Photo Album Storage (ECR)
├─ You take photos (build Docker images)
├─ Upload to cloud storage (push to ECR)
├─ Access from any device (pull from Fargate/ECS)
├─ Organize in albums (repositories)
└─ Share with family only (private, secure)

WITHOUT ECR:
Build image → Store on laptop → Can't deploy to AWS

WITH ECR:
Build image → Push to ECR → Fargate pulls and runs
```

## When to Use ECR?

Use ECR when you need:
1. **Store Docker images for Fargate/ECS** (most common)
2. **Private container registry** (not public like Docker Hub)
3. **AWS integration** (works seamlessly with AWS services)
4. **Image scanning** (detect vulnerabilities automatically)
5. **Lifecycle policies** (auto-delete old images)

Don't use ECR when:
- You're using public Docker images (just reference Docker Hub)
- You don't use containers (use S3 for code, not ECR)

## Should I Create One ECR Repository or Multiple?

**One Repository Per Application/Service:**
```
Best Practice: One repository per microservice

E-commerce App:
├─ ecr/user-service        (user management)
├─ ecr/product-service     (product catalog)
├─ ecr/order-service       (order processing)
└─ ecr/payment-service     (payment gateway)

Why?
├─ Clear separation of concerns
├─ Independent versioning (user-service:v1, v2, v3)
├─ Easy to manage permissions
└─ Better organization
```

**One Repository with Tags (NOT Recommended):**
```
❌ Anti-pattern: Single repository for everything

ecr/all-services
├─ all-services:user-v1
├─ all-services:product-v1
├─ all-services:order-v1
└─ all-services:payment-v1

Problems:
├─ Hard to find specific images
├─ Confusing versioning
└─ Difficult to manage permissions
```

## Key Concepts

### 1. Repository Structure

```
ECR Repository = Storage for one application
├─ Repository Name: myapp
├─ Images (versions):
│  ├─ myapp:latest (most recent)
│  ├─ myapp:v1.0.0 (stable release)
│  ├─ myapp:v1.0.1 (bug fix)
│  ├─ myapp:dev (development)
│  └─ myapp:abc123 (commit SHA)
│
└─ Each image contains:
   ├─ Docker layers
   ├─ Metadata
   └─ Image digest (SHA256)
```

### 2. Image Tags

```
Tagging Strategies:

1. Semantic Versioning (Recommended):
   ├─ myapp:1.0.0 (major.minor.patch)
   ├─ myapp:1.0.1
   └─ myapp:2.0.0

2. Environment-based:
   ├─ myapp:dev
   ├─ myapp:staging
   └─ myapp:prod

3. Git-based:
   ├─ myapp:main (branch)
   ├─ myapp:feature-xyz (branch)
   └─ myapp:abc123 (commit SHA)

4. Date-based:
   ├─ myapp:2024-11-16
   └─ myapp:20241116-1430

5. Latest (Use with caution):
   └─ myapp:latest (points to newest image)
```

**Best Practice:**
```
Use multiple tags for same image:

docker tag myapp:build-123 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0.0
docker tag myapp:build-123 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker tag myapp:build-123 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:prod

Same image, multiple tags!
```

### 3. ECR URI Format

```
ECR Image URI:
<account-id>.dkr.ecr.<region>.amazonaws.com/<repository-name>:<tag>

Example:
123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

Breaking it down:
├─ 123456789012 = AWS Account ID
├─ dkr.ecr = ECR service
├─ us-east-1 = Region
├─ myapp = Repository name
└─ v1.0.0 = Image tag
```

### 4. Image Scanning

```
Scan Types:

1. On Push (Automatic):
   ├─ Scan every image when pushed
   ├─ Detect vulnerabilities (CVE database)
   ├─ Report severity (Critical, High, Medium, Low)
   └─ Cost: Free (basic scan)

2. Enhanced Scanning (Inspector):
   ├─ Continuous monitoring
   ├─ OS and programming language packages
   ├─ More detailed findings
   └─ Cost: $0.09 per image/month

Scan Results:
├─ CRITICAL: 2 vulnerabilities
├─ HIGH: 5 vulnerabilities
├─ MEDIUM: 10 vulnerabilities
└─ LOW: 15 vulnerabilities

Action: Fix critical before deploying to production!
```

### 5. Lifecycle Policies

```
Auto-cleanup old images to save storage costs

Example Policy 1: Keep last 10 images
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep last 10 images",
    "selection": {
      "tagStatus": "any",
      "countType": "imageCountMoreThan",
      "countNumber": 10
    },
    "action": {
      "type": "expire"
    }
  }]
}

Example Policy 2: Delete untagged images after 7 days
{
  "rules": [{
    "rulePriority": 1,
    "description": "Delete untagged after 7 days",
    "selection": {
      "tagStatus": "untagged",
      "countType": "sinceImagePushed",
      "countUnit": "days",
      "countNumber": 7
    },
    "action": {
      "type": "expire"
    }
  }]
}

Why?
├─ Old images = Wasted storage
├─ 100 old images × 500 MB = 50 GB
└─ Cost: $5/month (could be $0 with lifecycle policy)
```

## Common Workflow - Build & Push

### Step-by-Step: Build and Push Docker Image

```bash
# Step 1: Build Docker image locally
docker build -t myapp:latest .

# Step 2: Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Step 3: Tag image for ECR
docker tag myapp:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

docker tag myapp:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# Step 4: Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# Step 5: Verify image in ECR
aws ecr describe-images \
  --repository-name myapp \
  --region us-east-1
```

### CI/CD Pipeline Integration

```yaml
# GitHub Actions example
name: Build and Push to ECR

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: myapp
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
                     $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

## Fargate Integration

### Pull Image from ECR in Fargate

```hcl
# Fargate task definition using ECR image
resource "aws_ecs_task_definition" "app" {
  family = "myapp"

  container_definitions = jsonencode([{
    name  = "app"
    # Pull from ECR
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0"

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
  }])

  # IAM role needs ECR permissions
  execution_role_arn = aws_iam_role.ecs_execution.arn
}

# IAM role for ECS to pull from ECR
resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach policy for ECR access
resource "aws_iam_role_policy_attachment" "ecs_ecr" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

## Performance and Storage

### Image Pull Time

```
Factors affecting pull time:
├─ Image size: 100 MB vs 2 GB
├─ Network speed: AWS internal (fast)
├─ Layers cached: Reuse layers
└─ Region: Same region as Fargate (faster)

Example Pull Times:
├─ Small image (100 MB): 5-10 seconds
├─ Medium image (500 MB): 15-30 seconds
├─ Large image (2 GB): 60-120 seconds
└─ Cached layers: 1-5 seconds (very fast!)

Optimization:
1. Use multi-stage builds (smaller images)
2. Minimize layers
3. Use .dockerignore
4. Use same base image (layer caching)
```

### Storage Costs

```
ECR Storage Pricing:
├─ $0.10 per GB/month
└─ No charge for data transfer within AWS

Examples:

Small App (5 images × 200 MB = 1 GB):
└─ Cost: $0.10/month

Medium App (20 images × 500 MB = 10 GB):
└─ Cost: $1.00/month

Large App (100 images × 1 GB = 100 GB):
└─ Cost: $10.00/month

With Lifecycle Policy (keep last 10 images):
├─ 10 images × 500 MB = 5 GB
└─ Cost: $0.50/month (90% savings!)
```

## Security Best Practices

```
1. Enable Image Scanning
   ✓ Scan on push
   ✓ Review vulnerabilities before production
   ❌ Deploy without scanning

2. Use Private Repositories
   ✓ ECR repos are private by default
   ❌ Don't make public unless necessary

3. IAM Permissions (Least Privilege)
   ✓ Read-only for ECS/Fargate
   ✓ Read-write for CI/CD only
   ❌ Full access for everyone

4. Encrypt Images
   ✓ Encryption at rest (default: AES-256)
   ✓ Use KMS for custom encryption
   ❌ No encryption

5. Immutable Tags
   ✓ Prevent tag overwriting (v1.0.0 stays v1.0.0)
   ❌ Allow tag overwriting (risky)

6. Repository Policy
   ✓ Restrict access to specific AWS accounts
   ✓ Allow cross-account access when needed
   ❌ Open to all AWS accounts
```

## Common Mistakes

```
❌ MISTAKE 1: Using :latest in production
Example: image: myapp:latest
Problem: :latest changes, production breaks unexpectedly
Solution: Use specific version tags (myapp:v1.0.0)

❌ MISTAKE 2: No lifecycle policy
Example: 500 old images stored
Impact: $50/month wasted storage
Solution: Keep last 10-20 images, delete rest

❌ MISTAKE 3: Large Docker images
Example: 5 GB image (includes everything)
Impact: Slow deployments (2 min pull time)
Solution: Multi-stage builds, minimal base image

❌ MISTAKE 4: No image scanning
Example: Deploy image with critical vulnerabilities
Impact: Security breach
Solution: Enable scan on push, fix criticals

❌ MISTAKE 5: Wrong IAM permissions
Example: ECS can't pull image
Error: "CannotPullContainerError"
Solution: ECS execution role needs ECR read permissions

❌ MISTAKE 6: Forgetting to login
Example: docker push without login
Error: "no basic auth credentials"
Solution: aws ecr get-login-password before push

❌ MISTAKE 7: Cross-region pulls
Example: ECR in us-east-1, Fargate in eu-west-1
Impact: Slower pulls, data transfer costs
Solution: ECR in same region as Fargate

❌ MISTAKE 8: Not using .dockerignore
Example: node_modules, .git in Docker image
Impact: Huge image size (2 GB instead of 200 MB)
Solution: Add .dockerignore file

❌ MISTAKE 9: Building on Mac M1, deploying to x86
Example: Build ARM image, run on x86 Fargate
Error: "exec format error"
Solution: docker build --platform linux/amd64

❌ MISTAKE 10: No image tags
Example: Push without tags
Impact: Untagged images (hard to identify)
Solution: Always tag images with version
```

## ECR vs Alternatives

```
Use ECR when:
✓ Using AWS Fargate/ECS/Lambda containers
✓ Need private registry
✓ Want AWS integration
✓ Need image scanning

Use Docker Hub when:
✓ Public open-source images
✓ Free tier sufficient (unlimited pulls)
✓ Not using AWS

Use GitHub Container Registry when:
✓ GitHub Actions CI/CD
✓ Free for public repos
✓ Not AWS-centric

Use Harbor/GitLab Registry when:
✓ Self-hosted solution
✓ On-premises deployment
✓ Multi-cloud strategy
```

## Cost Optimization

```
1. Lifecycle Policies
   ❌ 100 images × 500 MB = $5/month
   ✓ 10 images × 500 MB = $0.50/month
   Savings: 90%

2. Smaller Images
   ❌ 2 GB image = $0.20/image/month
   ✓ 200 MB image = $0.02/image/month
   Savings: 90%

3. Multi-stage Builds
   ❌ Include build tools in final image (1.5 GB)
   ✓ Build stage + runtime stage (300 MB)
   Savings: 80%

4. Same Region as Compute
   ❌ Cross-region data transfer: $0.02/GB
   ✓ Same region: Free
   Savings: 100% on data transfer

5. Delete Unused Repositories
   ❌ 20 repos with old images = $20/month
   ✓ 5 active repos = $5/month
   Savings: 75%
```

## Summary

**ECR in Simple Terms:**
- Private Docker image storage in AWS
- Integrated with Fargate/ECS/Lambda
- Auto-scanning for vulnerabilities
- Lifecycle policies for cost savings
- Pay $0.10/GB/month

**Key Decisions:**
1. One repository per service (microservices)
2. Enable image scanning (security)
3. Lifecycle policy (keep last 10-20 images)
4. Use specific version tags (not :latest in prod)
5. Same region as Fargate/ECS (performance)

**Quick Start:**
1. Create ECR repository
2. Build Docker image locally
3. Authenticate to ECR
4. Tag and push image
5. Reference in Fargate task definition
6. Enable scanning and lifecycle policy
