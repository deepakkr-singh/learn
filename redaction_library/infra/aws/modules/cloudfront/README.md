# CloudFront - Content Delivery Network (CDN)

## 🎯 What is CloudFront?

**Simple Explanation:**
CloudFront is like having copies of your website stored in warehouses around the world. When someone visits your site from Tokyo, they get content from the Tokyo warehouse (fast) instead of from your server in Virginia (slow).

Think of it as:
- **Without CloudFront** = Pizza delivery from one store to entire country (slow for far customers)
- **With CloudFront** = Pizza chains in every city (fast delivery everywhere)

**Real-World Analogy:**
- **Direct server** = Everyone downloads files from one location → Slow for distant users
- **CloudFront** = Files cached in 400+ locations worldwide → Fast for everyone

---

## 🤔 Why Do I Need CloudFront?

### Without CloudFront:

```
PROBLEMS:
1. Slow for users far from server (Tokyo user waits 3 seconds)
2. Server overwhelmed by traffic spikes
3. No DDoS protection
4. Expensive bandwidth costs
5. No HTTPS for custom domains (without certificate setup)

Example: Website hosted in US East
- User in Sydney: 250ms latency
- User in London: 80ms latency  
- Black Friday traffic: Server crashes
```

---

### With CloudFront:

```
BENEFITS:
✅ Fast globally (average 20-50ms latency worldwide)
✅ Automatic scaling (handles traffic spikes)
✅ DDoS protection included
✅ Free HTTPS certificates (with ACM)
✅ Cheaper bandwidth (CloudFront is cheaper than S3 direct)
✅ Cache static files (reduce server load 90%)

Example: Website with CloudFront
- User in Sydney: 20ms latency (from Sydney edge)
- User in London: 15ms latency (from London edge)
- Black Friday: CloudFront auto-scales, no crashes
```

---

## 📊 Real-World Example

```
USER IN TOKYO
    │
    ▼
┌─────────────────────────────┐
│  CLOUDFRONT EDGE (Tokyo)     │  ← User connects here (20ms)
│  - Cached: CSS, JS, images   │
│  - Not cached: API calls     │
└────────────┬────────────────┘
             │
  ┌──────────┴────────────┐
  │                       │
  ▼ (Cached)              ▼ (Not cached)
Return                  Forward to
immediately             Origin Server
                            │
                            ▼
                ┌──────────────────────┐
                │  ORIGIN SERVER       │
                │  (S3 or EC2)         │
                │  Virginia, USA       │
                └──────────────────────┘
```

**Performance:**
- Without CloudFront: 250ms (Tokyo → Virginia → Tokyo)
- With CloudFront: 20ms (Tokyo edge cache hit)
- **12× faster!**

---

## 🔑 Key Concepts

### 1. Origins (Where Files Come From)

```
S3 Origin (Most Common)
├─ Static website: HTML, CSS, JS, images
├─ Cost: Cheapest
└─ Use for: Static sites, SPAs (React, Vue, Angular)

Custom Origin (EC2, ALB, API Gateway)
├─ Dynamic content: APIs, server-rendered pages
├─ Cost: Medium
└─ Use for: Dynamic websites, APIs
```

---

### 2. Cache Behaviors

```hcl
# Cache static files for 1 day
cache_behavior {
  path_pattern     = "*.jpg"
  allowed_methods  = ["GET", "HEAD"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "S3-my-bucket"

  forwarded_values {
    query_string = false
    cookies {
      forward = "none"
    }
  }

  min_ttl     = 0
  default_ttl = 86400   # 1 day
  max_ttl     = 31536000  # 1 year
}

# Don't cache API calls
cache_behavior {
  path_pattern     = "/api/*"
  allowed_methods  = ["GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
  cached_methods   = ["GET", "HEAD"]
  target_origin_id = "API-Gateway"

  min_ttl     = 0
  default_ttl = 0  # No caching
  max_ttl     = 0
}
```

---

## 🛠️ Common CloudFront Patterns

### Pattern 1: Static Website (S3 + CloudFront)

```hcl
# S3 bucket (origin)
resource "aws_s3_bucket" "website" {
  bucket = "my-website-files"
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for my website"
}

# S3 bucket policy (allow CloudFront only)
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["www.mysite.com"]

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-my-website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-my-website"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400   # 1 day
    max_ttl     = 31536000  # 1 year
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
```

---

## 🎯 Best Practices

### 1. Use HTTPS Only

```hcl
viewer_protocol_policy = "redirect-to-https"
```

---

### 2. Enable Compression

```hcl
default_cache_behavior {
  compress = true  # Gzip compression
}
```

---

### 3. Set Appropriate TTLs

```
Static assets (CSS, JS, images): 1 year
HTML files: 5 minutes - 1 hour
API responses: 0 (no cache)
```

---

## 💰 CloudFront Pricing

**Data Transfer Out:**
- First 10 TB: $0.085/GB
- Next 40 TB: $0.080/GB
- Over 150 TB: $0.060/GB

**Requests:**
- HTTPS: $0.010 per 10,000 requests
- HTTP: $0.0075 per 10,000 requests

**Examples:**

```
Small Site (1 TB/month, 1M requests):
- Data transfer: 1,000 GB × $0.085 = $85
- Requests: 100 × $0.010 = $1
Total: ~$86/month

VS S3 Direct:
- Data transfer: 1,000 GB × $0.09 = $90
CloudFront is CHEAPER!
```

---

**Next**: See complete implementations in [cloudfront_create.tf](./cloudfront_create.tf)
