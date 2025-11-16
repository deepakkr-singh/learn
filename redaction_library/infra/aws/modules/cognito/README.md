# Cognito - User Authentication and Authorization

## 🎯 What is Cognito?

**Simple Explanation:**
Cognito is like having a professional bouncer + ID system for your app. Instead of building login/signup yourself (hard and risky), AWS handles user registration, login, password resets, MFA, and social logins.

Think of it as:
- **Without Cognito** = Building your own login system (passwords, tokens, security - months of work)
- **With Cognito** = Ready-made authentication (signup, login, forgot password - works in minutes)

**Real-World Analogy:**
- **DIY authentication** = Building your own bank vault and security system
- **Cognito** = Renting a professional bank vault with guards, already secure

**Technical Definition:**
Amazon Cognito provides user identity and data synchronization services. It enables you to add user sign-up, sign-in, and access control to your web and mobile apps quickly and easily.

---

## 🤔 Why Do I Need Cognito?

### Without Cognito (DIY Authentication):

```
PROBLEMS with building authentication yourself:

1. Security vulnerabilities (password storage, SQL injection, XSS)
2. Forgot password flow (send emails, reset tokens, expiration)
3. Email verification (send verification emails, track status)
4. Multi-factor authentication (SMS codes, authenticator apps)
5. Social logins (Google, Facebook OAuth integration)
6. Session management (JWT tokens, refresh tokens, expiration)
7. Password policies (complexity, expiration, history)
8. User profile storage
9. GDPR/compliance requirements
10. Constant security updates

Time to build: 3-6 months
Ongoing maintenance: Forever
Risk: High (one mistake = security breach)
```

---

### With Cognito:

```
BENEFITS:

✅ Pre-built signup/login UI (or use your own)
✅ Secure password storage (bcrypt, salted hashing)
✅ Email/phone verification built-in
✅ Forgot password flow automatic
✅ Multi-factor authentication (SMS, TOTP)
✅ Social logins (Google, Facebook, Apple, Amazon)
✅ OAuth 2.0 and OpenID Connect support
✅ JWT tokens automatically generated
✅ User attributes and custom fields
✅ Compliance (SOC, PCI DSS, HIPAA eligible)
✅ Scalable to millions of users

Time to implement: 1 day
Ongoing maintenance: None (AWS handles it)
Risk: Low (AWS security team manages it)
```

---

## 📊 Real-World Example

### Scenario: SaaS Application Login

```
┌─────────────────────────────────────────────────────────────┐
│                      USER SIGNUP FLOW                        │
│                                                              │
│  1. User visits app                                          │
│     └─> https://myapp.com/signup                            │
│                                                              │
│  2. User enters:                                             │
│     ├─ Email: user@example.com                              │
│     ├─ Password: SecurePass123!                             │
│     └─ Name: John Doe                                        │
│                                                              │
│  3. App calls Cognito API                                    │
│     POST /signup                                             │
│                                                              │
│  4. Cognito validates:                                       │
│     ├─ ✅ Email format valid                                │
│     ├─ ✅ Password meets policy (8+ chars, uppercase, etc.) │
│     └─ ✅ Email not already registered                      │
│                                                              │
│  5. Cognito creates user and sends verification email        │
│     └─> Email with verification code sent                    │
│                                                              │
│  6. User clicks link or enters code                          │
│     └─> Account verified ✅                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      USER LOGIN FLOW                         │
│                                                              │
│  1. User visits login page                                   │
│     └─> https://myapp.com/login                             │
│                                                              │
│  2. User enters credentials                                  │
│     ├─ Email: user@example.com                              │
│     └─ Password: SecurePass123!                             │
│                                                              │
│  3. App calls Cognito                                        │
│     POST /login                                              │
│                                                              │
│  4. Cognito validates credentials                            │
│     ├─ ✅ Password matches                                  │
│     └─ ✅ Account verified                                  │
│                                                              │
│  5. (Optional) MFA Challenge                                 │
│     ├─ Cognito sends SMS code                               │
│     └─ User enters code                                      │
│                                                              │
│  6. Cognito returns JWT tokens                               │
│     ├─ ID Token: User identity info                         │
│     ├─ Access Token: API access                             │
│     └─ Refresh Token: Get new tokens                        │
│                                                              │
│  7. App stores tokens and user logged in ✅                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

COGNITO USER POOL
├─ Users: 10,000 registered users
├─ Monthly Active Users: 2,000
├─ Authentication: Email + Password + MFA
├─ Social Logins: Google, Facebook enabled
└─ Custom Attributes: company, role, subscription_tier
```

**Cost:**
- MAU (Monthly Active Users): FREE for first 50,000
- Advanced security features: $0.05/MAU
- SMS MFA: $0.00581 per SMS
- **Total for 2,000 MAU: ~$0-10/month**

---

## 🔑 Key Concepts

### 1. User Pools vs Identity Pools

```
USER POOLS (Most Common)
├─ What: User directory (like database of users)
├─ Features: Signup, login, forgot password, MFA
├─ Returns: JWT tokens
├─ Use for: 99% of apps
└─ Example: User logs in with email/password

IDENTITY POOLS (Advanced)
├─ What: Temporary AWS credentials for users
├─ Features: Access AWS services directly from frontend
├─ Returns: AWS IAM credentials
├─ Use for: Advanced use cases (upload to S3 from browser)
└─ Example: User uploads photo directly to S3 without backend
```

**Recommendation:** Start with **User Pools** (simpler, covers most needs)

---

### 2. Authentication Flows

```
Standard Flow (Most Common):
1. User enters email/password
2. Cognito validates
3. Returns JWT tokens
4. App uses tokens for API calls

Social Login Flow:
1. User clicks "Login with Google"
2. Redirected to Google
3. Google authenticates
4. Redirected back to app
5. Cognito creates/links user
6. Returns JWT tokens

MFA Flow:
1. User enters email/password
2. Cognito validates
3. Sends SMS code
4. User enters code
5. Returns JWT tokens
```

---

### 3. JWT Tokens

**What Cognito Returns After Login:**

```
ID Token (User Info):
{
  "sub": "abc-123-def-456",  // User ID
  "email": "user@example.com",
  "email_verified": true,
  "name": "John Doe",
  "exp": 1642349235  // Expiration
}

Access Token (API Access):
{
  "sub": "abc-123-def-456",
  "scope": "openid email profile",
  "exp": 1642349235
}

Refresh Token:
- Used to get new ID/Access tokens when they expire
- Valid for 30 days (configurable)
```

**How to Use Tokens:**

```javascript
// Frontend stores tokens after login
localStorage.setItem('idToken', response.idToken);
localStorage.setItem('accessToken', response.accessToken);

// Send access token with API requests
fetch('https://api.myapp.com/data', {
  headers: {
    'Authorization': `Bearer ${accessToken}`
  }
});

// Backend verifies token
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ABC123/.well-known/jwks.json'
});

// Verify token signature
const verified = jwt.verify(token, getKey, options);
// If valid → Allow API request
// If invalid/expired → Return 401 Unauthorized
```

---

### 4. Password Policies

```hcl
resource "aws_cognito_user_pool" "secure" {
  name = "myapp-users"

  password_policy {
    minimum_length    = 12  # At least 12 characters
    require_lowercase = true  # Must have lowercase
    require_uppercase = true  # Must have uppercase
    require_numbers   = true  # Must have numbers
    require_symbols   = true  # Must have symbols (!@#$%)
    
    temporary_password_validity_days = 7  # Reset link expires in 7 days
  }
}
```

**Password Policy Recommendations:**

```
Weak (Only for dev/testing):
├─ Length: 8 characters
├─ Complexity: Lowercase only
└─ Example: "password"

Medium (Basic production):
├─ Length: 8 characters
├─ Complexity: Lowercase + uppercase + numbers
└─ Example: "Password123"

Strong (Recommended for production):
├─ Length: 12 characters
├─ Complexity: Lowercase + uppercase + numbers + symbols
└─ Example: "SecurePass123!"

Very Strong (Financial/Healthcare):
├─ Length: 16+ characters
├─ Complexity: All character types
├─ Expiration: 90 days
└─ Example: "V3ry$ecur3P@ssw0rd!"
```

---

### 5. Multi-Factor Authentication (MFA)

```
OFF
├─ Only password required
├─ Use for: Low-security apps, dev/testing
└─ Risk: If password leaked, account compromised

OPTIONAL (Recommended)
├─ Users can enable MFA if they want
├─ Use for: Most production apps
└─ Balance: Security + user convenience

ON (Required)
├─ All users must use MFA
├─ Use for: High-security apps (banking, healthcare)
└─ Most secure but less convenient

MFA Methods:
├─ SMS: Send code via text message ($0.00581/SMS)
├─ TOTP: Authenticator app (Google Authenticator, Authy) - FREE
└─ Recommendation: TOTP (cheaper, more secure)
```

---

## 🛠️ Common Cognito Patterns

### Pattern 1: Basic Email/Password Authentication

```hcl
resource "aws_cognito_user_pool" "users" {
  name = "${var.project_name}-${var.environment}-users"

  # Password policy
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  # Auto-verify email
  auto_verified_attributes = ["email"]

  # MFA optional
  mfa_configuration = "OPTIONAL"

  # Account recovery via email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Custom attributes
  schema {
    name                = "company"
    attribute_data_type = "String"
    mutable             = true
  }

  schema {
    name                = "subscription_tier"
    attribute_data_type = "String"
    mutable             = true
  }
}

# App client (frontend)
resource "aws_cognito_user_pool_client" "web_client" {
  name         = "web-client"
  user_pool_id = aws_cognito_user_pool.users.id

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Callback URLs (after login)
  callback_urls = ["https://myapp.com/callback", "http://localhost:3000/callback"]
  
  # Logout URLs
  logout_urls = ["https://myapp.com/logout", "http://localhost:3000/logout"]

  # Token validity
  id_token_validity      = 60  # 60 minutes
  access_token_validity  = 60  # 60 minutes
  refresh_token_validity = 30  # 30 days
}
```

---

### Pattern 2: Social Logins (Google + Facebook)

```hcl
# User pool with social identity providers
resource "aws_cognito_user_pool" "social" {
  name = "myapp-users"

  # Auto-verify email from social providers
  auto_verified_attributes = ["email"]
}

# Google identity provider
resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.social.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    client_secret    = "YOUR_GOOGLE_CLIENT_SECRET"
    authorize_scopes = "email profile openid"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    name     = "name"
  }
}

# Facebook identity provider
resource "aws_cognito_identity_provider" "facebook" {
  user_pool_id  = aws_cognito_user_pool.social.id
  provider_name = "Facebook"
  provider_type = "Facebook"

  provider_details = {
    client_id        = "YOUR_FACEBOOK_APP_ID"
    client_secret    = "YOUR_FACEBOOK_APP_SECRET"
    authorize_scopes = "email public_profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "id"
    name     = "name"
  }
}

# App client supporting social logins
resource "aws_cognito_user_pool_client" "social_client" {
  name         = "social-client"
  user_pool_id = aws_cognito_user_pool.social.id

  supported_identity_providers = ["COGNITO", "Google", "Facebook"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  callback_urls = ["https://myapp.com/callback"]
  logout_urls   = ["https://myapp.com/logout"]
}

# Cognito domain for hosted UI
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "myapp-auth"  # Creates: https://myapp-auth.auth.us-east-1.amazoncognito.com
  user_pool_id = aws_cognito_user_pool.social.id
}
```

---

### Pattern 3: API Gateway Authorization

```hcl
# Cognito User Pool
resource "aws_cognito_user_pool" "api_users" {
  name = "api-users"
}

resource "aws_cognito_user_pool_client" "api_client" {
  name         = "api-client"
  user_pool_id = aws_cognito_user_pool.api_users.id
}

# API Gateway with Cognito authorizer
resource "aws_api_gateway_rest_api" "api" {
  name = "protected-api"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.api_users.arn]
}

# Protected API endpoint
resource "aws_api_gateway_resource" "protected" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "protected"
}

resource "aws_api_gateway_method" "protected_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.protected.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  # Only authenticated users can access this endpoint!
}
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Mistake 1: Weak Password Policy

```hcl
# WRONG - Weak passwords allowed
resource "aws_cognito_user_pool" "bad" {
  password_policy {
    minimum_length    = 6  # Too short!
    require_lowercase = false
    require_uppercase = false
    require_numbers   = false
    require_symbols   = false
  }
  
  # Users can use "123456" as password → Easy to hack
}
```

**Fix:**
```hcl
# CORRECT - Strong password policy
resource "aws_cognito_user_pool" "good" {
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}
```

---

### ❌ Mistake 2: Not Verifying Email

```hcl
# WRONG - No email verification
resource "aws_cognito_user_pool" "bad" {
  auto_verified_attributes = []  # No verification
  
  # Users can sign up with fake emails
  # Can't send password reset emails
}
```

**Fix:**
```hcl
# CORRECT - Verify email
resource "aws_cognito_user_pool" "good" {
  auto_verified_attributes = ["email"]
  
  # Users must verify email to activate account
}
```

---

### ❌ Mistake 3: Production Callback URL in Code

```hcl
# WRONG - Production URL hardcoded
resource "aws_cognito_user_pool_client" "bad" {
  callback_urls = ["https://myapp.com/callback"]
  
  # Can't test locally!
  # Must update Terraform for dev/staging
}
```

**Fix:**
```hcl
# CORRECT - Use variables for different environments
resource "aws_cognito_user_pool_client" "good" {
  callback_urls = var.callback_urls
}

# terraform.tfvars (dev)
# callback_urls = ["http://localhost:3000/callback"]

# terraform.tfvars (prod)
# callback_urls = ["https://myapp.com/callback"]
```

---

## 🎯 Best Practices

### 1. Enable MFA for Production

```hcl
resource "aws_cognito_user_pool" "secure" {
  mfa_configuration = "OPTIONAL"  # Users can enable MFA
  
  # For high-security apps
  # mfa_configuration = "ON"  # MFA required for all
}
```

---

### 2. Use Strong Password Policies

```hcl
resource "aws_cognito_user_pool" "secure" {
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}
```

---

### 3. Configure Account Recovery

```hcl
resource "aws_cognito_user_pool" "secure" {
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}
```

---

### 4. Set Appropriate Token Expiration

```hcl
resource "aws_cognito_user_pool_client" "client" {
  id_token_validity      = 60   # 1 hour (short for security)
  access_token_validity  = 60   # 1 hour
  refresh_token_validity = 30   # 30 days (long for convenience)
}
```

---

## 💰 Cognito Pricing

**Free Tier:**
- 50,000 Monthly Active Users (MAU): FREE forever

**Paid:**
- MAU 50,001+: $0.00550 per MAU

**Advanced Security Features:**
- $0.05 per MAU (adaptive authentication, compromised credentials check)

**SMS MFA:**
- $0.00581 per SMS message

**SAML/OIDC Federation:**
- $0.015 per MAU

**Examples:**

```
Small App (1,000 MAU):
- Authentication: FREE (under 50,000)
- SMS MFA (50 users, 2 logins/month): $0.58
Total: ~$1/month

Medium App (100,000 MAU):
- First 50,000: FREE
- Next 50,000: 50,000 × $0.00550 = $275
- SMS MFA (5,000 users, 2 logins/month): $58
Total: ~$333/month

Large App (1,000,000 MAU):
- First 50,000: FREE
- Next 950,000: 950,000 × $0.00550 = $5,225
Total: ~$5,225/month
```

---

**Next**: See complete implementations in [cognito_create.tf](./cognito_create.tf)
