# API Gateway - REST API Management

## What is API Gateway?

API Gateway is like a **front desk at a hotel**. It receives all requests from outside, validates them, routes them to the right service, and sends back responses.

**Real-World Analogy:**
```
Hotel Front Desk (API Gateway)
├─ Guest arrives → Verify ID (authentication)
├─ Check reservation → Validate request
├─ Direct to room service → Route to Lambda function
├─ Handle special requests → Transform request
└─ Ensure quality service → Rate limiting, caching

WITHOUT API Gateway:
Guest → Directly to kitchen (chaos, security risk)

WITH API Gateway:
Guest → Front Desk → Kitchen (organized, secure)
```

## API Gateway vs ALB - Critical Differences

| Feature | API Gateway | ALB (Application Load Balancer) |
|---------|-------------|--------------------------------|
| **Location** | OUTSIDE VPC (AWS-managed) | INSIDE VPC |
| **Best For** | Serverless APIs (Lambda) | Multiple servers (EC2, Fargate) |
| **Pricing** | Per request ($3.50/1M) | Per hour ($16/month base) |
| **API Features** | Versioning, API keys, caching, validation | None (just load balancing) |
| **Rate Limiting** | Built-in per API key | Need WAF |
| **Request Transformation** | Built-in | Manual |
| **WebSocket Support** | Yes | No |
| **Target** | Lambda, HTTP endpoints, AWS services | EC2, Fargate, Lambda, IPs |

## When to Use API Gateway?

Use API Gateway when you need:
1. **Serverless REST APIs** (Lambda backend)
2. **API versioning** (v1, v2, v3)
3. **API key management** (different keys for different customers)
4. **Request/response transformation** (modify data before/after Lambda)
5. **Built-in rate limiting** (per API key)
6. **WebSocket APIs** (real-time bidirectional communication)
7. **Low to medium traffic** (< 10M requests/month is cost-effective)

Don't use API Gateway when:
- High traffic (> 10M requests/month) → Use ALB (cheaper at scale)
- Just need load balancing → Use ALB
- Running containers (not Lambda) → Use ALB
- Need sticky sessions → Use ALB

## Should I Create One API Gateway or Multiple?

**One API Gateway:**
- Single application with multiple endpoints
- All endpoints share same authentication
- Same rate limiting for all APIs
- Cost-effective (one API Gateway)

**Multiple API Gateways:**
- Different applications (user-api, admin-api)
- Different authentication methods
- Different rate limits per API
- Different teams managing different APIs
- Different environments (dev, staging, prod)

**Real-World Example:**
```
E-commerce Company
├─ public-api (API Gateway 1)
│  ├─ GET /products
│  ├─ POST /orders
│  └─ GET /cart
│
├─ admin-api (API Gateway 2)
│  ├─ POST /products (create products)
│  ├─ DELETE /users (admin only)
│  └─ GET /analytics
│
└─ partner-api (API Gateway 3)
   ├─ GET /inventory (for partners)
   └─ POST /webhooks
```

## Key Concepts

### 1. API Gateway Types

**REST API** - Traditional HTTP APIs
```
Use for:
├─ Standard REST endpoints (GET, POST, PUT, DELETE)
├─ Need API keys and usage plans
├─ Need request validation
├─ Need caching
└─ Most common choice

Cost: $3.50 per 1M requests
```

**HTTP API** - Simpler, cheaper REST APIs
```
Use for:
├─ Simple Lambda proxy
├─ No need for API keys
├─ No need for request validation
├─ Cost-sensitive (70% cheaper than REST API)
└─ Modern choice for serverless

Cost: $1.00 per 1M requests (70% cheaper!)
```

**WebSocket API** - Real-time bidirectional communication
```
Use for:
├─ Chat applications
├─ Live dashboards
├─ Real-time notifications
├─ Gaming
└─ IoT device communication

Cost: $1.00 per 1M messages + $0.25 per 1M connection minutes
```

### 2. Integration Types

**Lambda Proxy Integration** (Most Common)
```
API Gateway → Lambda
├─ API Gateway passes entire request to Lambda
├─ Lambda returns entire response
├─ No transformation in API Gateway
└─ Simplest setup

Request to Lambda:
{
  "httpMethod": "POST",
  "path": "/users",
  "headers": {...},
  "body": "{"name": "John"}"
}
```

**Lambda Non-Proxy Integration**
```
API Gateway → Transform → Lambda → Transform → Response
├─ API Gateway transforms request before sending to Lambda
├─ Lambda receives only specific data
├─ API Gateway transforms Lambda response
└─ More complex, more control

Use when: Need custom request/response formats
```

**HTTP Integration**
```
API Gateway → External HTTP Endpoint
├─ Call any HTTP/HTTPS endpoint
├─ No Lambda needed
└─ Use for: Calling external APIs, on-premises systems

Example: API Gateway → https://api.thirdparty.com
```

**AWS Service Integration**
```
API Gateway → DynamoDB/SQS/SNS/S3 (directly)
├─ No Lambda in between
├─ Direct integration with AWS services
└─ Cost-effective (no Lambda invocation cost)

Example: POST /messages → SQS (without Lambda)
```

**Mock Integration**
```
API Gateway → Returns mock response
├─ No backend service
├─ Returns predefined response
└─ Use for: Testing, API documentation

Example: GET /health → Returns {"status": "OK"}
```

### 3. API Gateway Components

**Resources** - URL paths
```
/                    (root)
├─ /users            (resource)
│  ├─ /users/{id}    (resource with path parameter)
│  └─ /users/active  (sub-resource)
│
└─ /products         (resource)
   ├─ /products/{id}
   └─ /products/search
```

**Methods** - HTTP verbs
```
GET /users          → List users
POST /users         → Create user
GET /users/{id}     → Get specific user
PUT /users/{id}     → Update user
DELETE /users/{id}  → Delete user
```

**Stages** - Deployment environments
```
dev    → https://api.example.com/dev
staging → https://api.example.com/staging
prod   → https://api.example.com/prod
v1     → https://api.example.com/v1
v2     → https://api.example.com/v2
```

**Authorizers** - Authentication/Authorization
```
Lambda Authorizer:
├─ Custom authentication logic
├─ Validate JWT tokens
├─ Check database for permissions
└─ Return IAM policy

Cognito Authorizer:
├─ AWS Cognito User Pools
├─ Built-in user management
└─ OAuth2/OIDC support

IAM Authorizer:
├─ AWS IAM credentials (access key/secret)
└─ For service-to-service communication
```

**Usage Plans & API Keys** - Rate limiting
```
Usage Plan = Rate limit policy
├─ Rate: 1000 requests per second
├─ Burst: 2000 requests
├─ Quota: 1,000,000 requests per month
└─ Associated with API Keys

API Key = Unique identifier for clients
├─ API Key 1 → Free Tier Usage Plan
├─ API Key 2 → Pro Tier Usage Plan
└─ API Key 3 → Enterprise Tier Usage Plan
```

## Common Patterns

### Pattern 1: Simple Lambda REST API

```
Use Case: Basic CRUD API
├─ GET /users → List users
├─ POST /users → Create user
├─ GET /users/{id} → Get user
└─ DELETE /users/{id} → Delete user
```

**Architecture:**
```
Internet → API Gateway → Lambda → DynamoDB

Request: GET https://api.example.com/users
API Gateway → Lambda (get-users) → DynamoDB (scan)
Response: [{"id": 1, "name": "John"}, {...}]
```

### Pattern 2: Multi-Function API

```
Use Case: Microservices architecture
├─ /users → Lambda (users-service)
├─ /products → Lambda (products-service)
├─ /orders → Lambda (orders-service)
└─ Each Lambda handles its own resource
```

**Architecture:**
```
                    ┌→ Lambda (users) → DynamoDB
Internet → API Gateway ├→ Lambda (products) → DynamoDB
                    └→ Lambda (orders) → DynamoDB + SQS
```

### Pattern 3: API with Authentication

```
Use Case: Secured API with user authentication

Architecture:
┌────────────┐
│   Client   │
└─────┬──────┘
      │ 1. POST /login (username, password)
      ▼
┌────────────────────┐
│   API Gateway      │
└─────┬──────────────┘
      │ 2. Invoke Lambda
      ▼
┌────────────────────┐
│ Lambda (login)     │ 3. Validate credentials
└─────┬──────────────┘    Return JWT token
      ▼
┌────────────────────┐
│   DynamoDB         │
└────────────────────┘

Then for protected routes:
┌────────────┐
│   Client   │ 4. GET /users
└─────┬──────┘    Authorization: Bearer <JWT>
      ▼
┌────────────────────┐
│   API Gateway      │ 5. Lambda Authorizer
│   ┌──────────────┐ │    validates JWT
│   │ Authorizer   │ │
│   └──────────────┘ │
└─────┬──────────────┘
      │ 6. If valid, invoke Lambda
      ▼
┌────────────────────┐
│ Lambda (get-users) │
└────────────────────┘
```

### Pattern 4: Request/Response Transformation

```
Use Case: API returns XML but client wants JSON

Request Flow:
Client (JSON) → API Gateway → Transform to XML → External API (XML)
                                                         ↓
Client (JSON) ← API Gateway ← Transform to JSON ← Response (XML)
```

### Pattern 5: API Versioning

```
Use Case: Maintain multiple API versions

/v1/users → Lambda (v1-users) → Old logic
/v2/users → Lambda (v2-users) → New logic

Clients can migrate at their own pace:
├─ Old clients → https://api.example.com/v1
└─ New clients → https://api.example.com/v2
```

### Pattern 6: WebSocket API (Real-time Chat)

```
Use Case: Real-time chat application

Architecture:
┌────────────┐
│   Client   │ 1. Connect to WebSocket
└─────┬──────┘    wss://chat.example.com
      │
      ▼
┌────────────────────────────────────┐
│   API Gateway (WebSocket)          │
│                                    │
│   $connect    → Lambda (connect)   │ 2. Store connection ID
│   $disconnect → Lambda (disconnect)│ 3. Remove connection ID
│   sendMessage → Lambda (send)      │ 4. Send to other clients
└────────────────┬───────────────────┘
                 │
                 ▼
┌────────────────────────┐
│   DynamoDB             │ Store connection IDs
│   { connectionId,      │
│     userId }           │
└────────────────────────┘
```

## Request Flow - Detailed Timeline

### Simple GET Request

```
Step-by-Step: GET https://api.example.com/users

T+0ms:   Client sends HTTPS request
         GET /users HTTP/1.1
         Host: api.example.com
         Authorization: Bearer eyJhbGc...

T+5ms:   Request hits API Gateway
         ├─ TLS termination (decrypt HTTPS)
         ├─ Check rate limiting (within limits?)
         ├─ Check authorization (valid token?)
         └─ Log request to CloudWatch

T+10ms:  API Gateway invokes Lambda
         Event payload:
         {
           "httpMethod": "GET",
           "path": "/users",
           "headers": {...},
           "requestContext": {...}
         }

T+15ms:  Lambda cold start (if needed)
         ├─ Download code
         ├─ Initialize runtime
         └─ Run init code

T+20ms:  Lambda execution begins
         ├─ Query DynamoDB
         ├─ Format response
         └─ Return to API Gateway

T+100ms: Lambda completes
         Returns:
         {
           "statusCode": 200,
           "body": "[{\"id\":1,\"name\":\"John\"}]"
         }

T+105ms: API Gateway processes response
         ├─ Apply response transformations
         ├─ Add CORS headers
         ├─ Cache response (if caching enabled)
         └─ Log response

T+110ms: Client receives response
         HTTP/1.1 200 OK
         Content-Type: application/json
         [{"id":1,"name":"John"}]

Total Time: ~110ms
├─ API Gateway overhead: ~10ms
├─ Lambda cold start: ~5ms (warm: 0ms)
├─ Lambda execution: ~80ms
└─ Network latency: ~15ms
```

### POST Request with Validation

```
Step-by-Step: POST https://api.example.com/users

T+0ms:   Client sends request
         POST /users HTTP/1.1
         Body: {"name": "John", "email": "john@example.com"}

T+5ms:   API Gateway receives request
         ├─ Check Content-Type (application/json?)
         ├─ Validate request body against schema
         │  {
         │    "type": "object",
         │    "required": ["name", "email"],
         │    "properties": {
         │      "name": {"type": "string"},
         │      "email": {"type": "string", "format": "email"}
         │    }
         │  }
         └─ If invalid → Return 400 Bad Request (no Lambda invocation)

T+10ms:  Validation passed, invoke Lambda
T+20ms:  Lambda creates user in DynamoDB
T+100ms: Lambda returns success

Total Time: ~100ms (faster because validation caught errors early)
```

## Performance and Latency

### API Gateway Overhead

```
REST API:
├─ Authorization: 1-5ms
├─ Request validation: 1-3ms
├─ Request transformation: 1-5ms
├─ Lambda invocation: 1-3ms
├─ Response transformation: 1-5ms
├─ Logging: 1-2ms
└─ Total overhead: ~10-25ms

HTTP API (simpler):
├─ Lambda invocation: 1-3ms
├─ Logging: 1-2ms
└─ Total overhead: ~2-5ms (faster!)
```

### Caching Performance

```
WITHOUT Caching:
Every request → Lambda invocation
Response time: 100-200ms
Cost: $0.20 per 1M requests (Lambda) + $3.50 per 1M (API Gateway)

WITH Caching (1 hour TTL):
1st request → Lambda invocation (100ms)
Next 3600 requests → Served from cache (10ms!)
Response time: 10ms (10x faster)
Cost: Cache cost + reduced Lambda invocations
```

### Concurrent Request Handling

```
Question: If 1000 requests come at once, what happens?

Answer: API Gateway handles concurrency automatically!

Scenario: 1000 simultaneous requests

T+0s:    1000 requests arrive at API Gateway
         API Gateway → Spawns 1000 Lambda invocations (in parallel)

T+0.1s:  Lambdas start executing
         ├─ 1000 concurrent Lambda instances
         ├─ Each handles 1 request
         └─ No queueing (instant scale)

T+0.2s:  Lambdas complete
         API Gateway returns 1000 responses

Result: ALL requests handled simultaneously!
No waiting, no queue (Lambda auto-scales)

Limits:
├─ API Gateway: 10,000 requests/second (soft limit, can increase)
├─ Lambda concurrent executions: 1,000 (soft limit, can increase)
└─ If you exceed limits → throttling (429 Too Many Requests)
```

## Rate Limiting and Throttling

### Built-in Rate Limiting

```
Usage Plan Configuration:
├─ Rate: 1000 requests per second
├─ Burst: 2000 requests (temporary spike)
└─ Quota: 1,000,000 requests per month

What Happens:

Normal Traffic (500 req/sec):
├─ All requests pass through
└─ No throttling

Burst Traffic (1500 req/sec for 5 seconds):
├─ First 2000 requests → Pass (burst allowance)
├─ Remaining requests → Throttled
└─ Returns: 429 Too Many Requests

Sustained High Traffic (2000 req/sec):
├─ 1000 requests/sec → Pass (rate limit)
├─ 1000 requests/sec → Throttled (429)
└─ Client must implement retry with backoff
```

### Per-API-Key Rate Limiting

```
Free Tier:
├─ Rate: 100 req/sec
├─ Quota: 100,000 req/month
└─ API Key: abc123

Pro Tier:
├─ Rate: 1000 req/sec
├─ Quota: 10,000,000 req/month
└─ API Key: xyz789

Request with Free Tier Key:
GET /users
x-api-key: abc123
→ Subject to 100 req/sec limit

Request with Pro Tier Key:
GET /users
x-api-key: xyz789
→ Subject to 1000 req/sec limit
```

## Cost Optimization

### Pricing Models

```
REST API:
├─ Requests: $3.50 per 1M requests
├─ Caching: $0.02/hour per GB
└─ Data transfer: $0.09/GB out

HTTP API (70% cheaper):
├─ Requests: $1.00 per 1M requests
└─ No caching available

WebSocket API:
├─ Messages: $1.00 per 1M messages
├─ Connection minutes: $0.25 per 1M minutes
└─ Data transfer: $0.09/GB out
```

### Cost Examples

```
Example 1: Low Traffic REST API (100,000 requests/month)
├─ API Gateway: 0.1M × $3.50 = $0.35
├─ Lambda: 0.1M × $0.20 = $0.02
└─ Total: $0.37/month

Example 2: Medium Traffic HTTP API (10M requests/month)
├─ API Gateway: 10M × $1.00 = $10.00
├─ Lambda: 10M × $0.20 = $2.00
└─ Total: $12.00/month

Example 3: High Traffic with Caching (10M requests/month, 80% cache hit)
├─ API Gateway: 10M × $3.50 = $35.00
├─ Cache (0.5 GB, 24/7): 720 hours × $0.02 = $14.40
├─ Lambda (2M cache misses): 2M × $0.20 = $0.40
└─ Total: $49.80/month (vs $37 without caching, but faster!)

Example 4: WebSocket Chat (1000 concurrent users, 24/7, 100 messages/user/day)
├─ Connections: 1000 users × 43,200 min/month = 43.2M min
├─ Connection cost: 43.2M × $0.25 / 1M = $10.80
├─ Messages: 1000 × 100 × 30 = 3M messages
├─ Message cost: 3M × $1.00 / 1M = $3.00
└─ Total: $13.80/month
```

### Cost-Saving Tips

```
1. Use HTTP API instead of REST API
   ❌ REST API: $3.50 per 1M
   ✓ HTTP API: $1.00 per 1M
   Savings: 70%!

2. Enable Caching (if read-heavy workload)
   ❌ No cache: Every request invokes Lambda
   ✓ Cache (1 hour TTL): 80% cache hit → 80% fewer Lambda invocations
   Savings: Significant Lambda cost reduction

3. Optimize Lambda memory/timeout
   ❌ Lambda: 1024 MB, always runs 10 seconds
   ✓ Lambda: 512 MB, optimized to run 2 seconds
   Savings: 80% Lambda cost reduction

4. Use API Gateway directly to DynamoDB/SQS (no Lambda)
   ❌ API Gateway → Lambda → DynamoDB
   ✓ API Gateway → DynamoDB (direct integration)
   Savings: Eliminate Lambda costs

5. Implement request throttling
   ❌ Unlimited requests (DDoS attack = huge bill)
   ✓ Rate limiting: 1000 req/sec max
   Savings: Prevent unexpected costs
```

## Best Practices

### Production Readiness

```
1. Enable Logging
   ✓ CloudWatch Logs for all requests
   ✓ Access logs (who accessed what, when)
   ✓ Execution logs (Lambda invocation details)
   ❌ No logging (can't troubleshoot)

2. Enable Monitoring
   ✓ CloudWatch metrics (4xx errors, 5xx errors, latency)
   ✓ Alarms for error rates
   ✓ X-Ray tracing (distributed tracing)
   ❌ No monitoring

3. Use Custom Domain
   ✓ https://api.example.com (professional)
   ❌ https://abc123.execute-api.us-east-1.amazonaws.com (ugly)

4. Enable CORS
   ✓ Allow specific origins
   ❌ Allow all origins (security risk)

5. Implement Authentication
   ✓ Lambda authorizer or Cognito
   ❌ No authentication (public API)

6. Rate Limiting
   ✓ Usage plans with reasonable limits
   ❌ No rate limiting (vulnerable to DDoS)

7. Request Validation
   ✓ Validate request body before Lambda invocation
   ❌ No validation (Lambda handles invalid requests)

8. Enable Caching (for read-heavy APIs)
   ✓ Cache GET requests
   ❌ No caching (higher latency, more Lambda invocations)

9. Multiple Stages
   ✓ dev, staging, prod stages
   ❌ Single stage for everything

10. API Versioning
    ✓ /v1, /v2 for breaking changes
    ❌ Breaking changes in same API
```

## Common Mistakes

```
❌ MISTAKE 1: Not enabling CORS
Example: Frontend (React) calling API from different domain
Error: "CORS policy: No 'Access-Control-Allow-Origin' header"
Solution: Enable CORS in API Gateway

❌ MISTAKE 2: Lambda timeout too short
Example: API Gateway timeout: 29 seconds, Lambda timeout: 30 seconds
Error: API Gateway times out before Lambda completes
Solution: Lambda timeout must be < 29 seconds (API Gateway max)

❌ MISTAKE 3: Not using API keys for public APIs
Example: Public API with no rate limiting
Impact: DDoS attack, huge bill
Solution: API keys + usage plans

❌ MISTAKE 4: Not implementing retry logic in Lambda authorizer
Example: Authorizer calls external service, service is down
Impact: All API requests fail
Solution: Implement retry with exponential backoff

❌ MISTAKE 5: Returning entire DynamoDB item from Lambda
Example: Lambda returns 500 KB response (includes sensitive data)
Error: Response size too large (6 MB limit for synchronous)
Solution: Return only needed fields, use pagination

❌ MISTAKE 6: Not caching frequently accessed data
Example: GET /products called 1M times/month (same data)
Impact: 1M Lambda invocations, high latency
Solution: Enable caching (1 hour TTL)

❌ MISTAKE 7: Using REST API when HTTP API is sufficient
Example: Simple Lambda proxy, no need for API keys/caching
Impact: Paying 3.5x more than necessary
Solution: Use HTTP API ($1/M vs $3.50/M)

❌ MISTAKE 8: Not setting proper Lambda memory
Example: Lambda with 128 MB memory, runs out of memory
Error: "Runtime exited with error: signal: killed"
Solution: Right-size Lambda memory based on workload

❌ MISTAKE 9: Not handling Lambda cold starts
Example: First request takes 3 seconds, subsequent requests take 100ms
Impact: Poor user experience
Solution: Provisioned concurrency or accept cold starts

❌ MISTAKE 10: Not implementing idempotency for POST/PUT
Example: POST /orders called twice → creates 2 orders
Impact: Duplicate data
Solution: Implement idempotency keys
```

## When to Use API Gateway vs Alternatives

```
Use API Gateway when:
✓ Serverless REST APIs (Lambda backend)
✓ Need API versioning (v1, v2)
✓ Need API key management
✓ Need request/response transformation
✓ Need built-in rate limiting
✓ WebSocket support needed
✓ Low to medium traffic (< 10M req/month)

Use ALB when:
✓ High traffic (> 10M req/month)
✓ Running containers (Fargate/ECS)
✓ Need sticky sessions
✓ Path-based routing to multiple targets
✓ Cost-effective at scale

Use CloudFront + Lambda@Edge when:
✓ Global users (low latency worldwide)
✓ Static content + dynamic content
✓ CDN caching needed

Use Direct Lambda URL when:
✓ Simple use case, no API management needed
✓ Internal APIs (not public)
✓ Cost-sensitive (no API Gateway cost)
```

## Summary

**API Gateway in Simple Terms:**
- Front desk for your APIs
- Routes requests to Lambda or other services
- Handles authentication, rate limiting, caching
- Pay per request ($1-3.50 per 1M requests)
- Best for: Serverless REST/WebSocket APIs

**Key Decisions:**
1. REST API vs HTTP API → HTTP API for most cases (70% cheaper)
2. Lambda Proxy vs Direct Integration → Lambda Proxy for most cases (simpler)
3. Enable Caching → Yes for read-heavy APIs
4. Authentication → Lambda authorizer or Cognito
5. Rate Limiting → Always enable (prevent DDoS)

**Quick Start:**
1. Create API Gateway (REST or HTTP)
2. Add resource (/users) and method (GET)
3. Integrate with Lambda function
4. Deploy to stage (dev/prod)
5. Test with curl or Postman
6. Add authentication and rate limiting
