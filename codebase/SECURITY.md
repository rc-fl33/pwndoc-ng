# PwnDoc-NG Security Analysis and Requirements

## Current Security Posture

### Authentication & Authorization

#### Strengths
- **httpOnly cookies**: JWT tokens stored as httpOnly, secure, sameSite=strict cookies - immune to XSS token theft
- **bcrypt password hashing**: 10 rounds of bcrypt for password storage
- **TOTP 2FA support**: Optional OTP-based two-factor authentication with QR code enrollment
- **Refresh token rotation**: Session-based refresh tokens with expiry tracking and session management
- **Timing attack mitigation**: Random bcrypt comparison on failed login to prevent username enumeration (`user.js:420`)
- **Role-based ACL**: Granular permission system with role inheritance
- **Password policy**: Requires uppercase, lowercase, digit, minimum 8 characters

#### Concerns

| ID | Severity | Location | Issue | Recommendation |
|---|---|---|---|---|
| SEC-01 | **HIGH** | `backend/src/lib/auth.js:6-15` | JWT secrets auto-generated and written to `config.json` on disk. If config file is readable, all tokens can be forged. | Use environment variables for secrets. Never persist to filesystem. |
| SEC-02 | **HIGH** | `backend/src/app.js:3-6` | Self-signed SSL certificates in `ssl/` directories committed to repo. No certificate rotation mechanism. | Use proper CA-signed certificates. In AWS, use ACM (free) + ALB for SSL termination. |
| SEC-03 | **HIGH** | `backend/src/config/config.json` | Config file contains JWT secrets, DB connection strings. Mounted as a Docker volume and writable by the application. | Separate secrets from config. Use AWS Secrets Manager or SSM Parameter Store. |
| SEC-04 | **MEDIUM** | `backend/src/app.js:91-98` | CORS headers commented out (`Access-Control-Allow-Origin`), but `Access-Control-Allow-Methods` and `Access-Control-Allow-Headers` are set broadly. | Configure strict CORS policy with explicit allowed origins. |
| SEC-05 | **MEDIUM** | `backend/src/app.js:7-10` | Socket.IO CORS set to `origin: "*"` - allows any origin to establish WebSocket connections. | Restrict to specific frontend origin. |
| SEC-06 | **MEDIUM** | `backend/src/app.js:100` | Body parser limit set to 100MB for JSON. Potential DoS vector via large payloads. | Reduce to 10MB or add request-level rate limiting. |
| SEC-07 | **MEDIUM** | `backend/src/app.js:128-159` | Hocuspocus WebSocket auth parses cookies from raw headers manually. Complex parsing logic could have bypass vulnerabilities. | Use proper cookie parsing library. Add structured authentication middleware. |
| SEC-08 | **MEDIUM** | `backend/src/models/user.js:71-75` | Password hash detection uses string length/prefix check. Could be bypassed with crafted pre-hashed passwords during import. | Use a dedicated flag for import mode rather than pattern matching on password strings. |
| SEC-09 | **LOW** | `backend/src/lib/passwordpolicy.js` | Password policy is minimal (8 chars, upper+lower+digit). No special character requirement, no breach database checking. | Strengthen policy. Consider haveibeenpwned API integration. |
| SEC-10 | **LOW** | `backend/src/routes/user.js:101-107` | `/api/users/init` endpoint reveals whether users exist (returns true/false). Information disclosure. | Return consistent response regardless of user existence. |
| SEC-11 | **LOW** | `frontend/.docker/nginx.conf:6` | TLS 1.0 and 1.1 enabled (`ssl_protocols TLSv1 TLSv1.1 TLSv1.2`). These are deprecated and insecure. | Only allow TLSv1.2 and TLSv1.3. |
| SEC-12 | **LOW** | `backend/src/routes/user.js:290` | Password validation bug: `req.body.newPassword.length==0` should likely be `!== 0` (empty password passes policy check). | Fix the condition to `req.body.newPassword.length > 0`. |

### Data Security

| ID | Severity | Issue | Recommendation |
|---|---|---|---|
| SEC-13 | **HIGH** | MongoDB has no authentication configured. Connection string has no credentials. | Enable MongoDB authentication. Use SCRAM-SHA-256. |
| SEC-14 | **HIGH** | MongoDB port 27017 bound to 127.0.0.1 on host but accessible from all containers on the Docker bridge network without auth. | Add MongoDB user credentials. Use network policies in AWS. |
| SEC-15 | **MEDIUM** | Images stored directly in MongoDB as base64. No file type validation or size limits at the model level. | Validate file types, enforce size limits, consider S3 for image storage. |
| SEC-16 | **MEDIUM** | Report templates (DOCX) stored on filesystem and mounted as Docker volume. No integrity checking. | Consider S3 with versioning for template storage. |
| SEC-17 | **MEDIUM** | User export endpoint (`/api/users/export`) returns password hashes. Even hashed, this is unnecessary exposure. | Exclude password hashes from export or add additional authorization. |
| SEC-18 | **LOW** | No audit logging for security events (login attempts, permission denials, data access). | Implement structured security audit logging. |

### Infrastructure Security

| ID | Severity | Issue | Recommendation |
|---|---|---|---|
| SEC-19 | **MEDIUM** | No rate limiting on any endpoint including login. Brute force attacks possible. | Add rate limiting middleware (express-rate-limit). Especially on `/api/users/token`. |
| SEC-20 | **MEDIUM** | No Content Security Policy (CSP) headers configured. | Add CSP headers via Nginx. |
| SEC-21 | **MEDIUM** | Missing security headers: X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security. | Add security headers in Nginx config. |
| SEC-22 | **LOW** | Winston logger (v2) is outdated. No structured logging to external service. | Upgrade to winston v3. Send logs to CloudWatch in AWS. |
| SEC-23 | **LOW** | No health check endpoints for container orchestration. | Add `/health` and `/ready` endpoints. |

### Dependency Concerns

| ID | Severity | Issue | Recommendation |
|---|---|---|---|
| SEC-24 | **MEDIUM** | Several dependencies are outdated (winston v2, js-yaml v3). Run `npm audit` regularly. | Set up automated dependency scanning (Dependabot is already configured). |
| SEC-25 | **LOW** | Frontend uses electron dependencies in package.json but doesn't appear to use Electron. Unnecessary attack surface. | Remove unused electron-related dependencies. |

## Security Requirements for AWS Deployment

### Must Have (P0)
1. Enable MongoDB authentication with strong credentials stored in AWS Secrets Manager
2. Use ACM certificates + ALB for SSL termination (eliminate self-signed certs)
3. Move JWT secrets to environment variables or AWS Secrets Manager
4. Restrict MongoDB access via Security Groups (backend only)
5. Enable TLS 1.2+ only
6. Add rate limiting on authentication endpoints
7. Configure strict CORS policy

### Should Have (P1)
1. Add WAF rules on ALB for common attack patterns (OWASP rule set)
2. Enable CloudWatch logging for all containers
3. Add VPC with private subnets for MongoDB and backend
4. Implement security headers (CSP, HSTS, X-Frame-Options)
5. Set up automated vulnerability scanning for container images (ECR scanning)
6. Enable MongoDB encryption at rest (EBS encryption)
7. Add health check endpoints

### Nice to Have (P2)
1. Integrate with AWS Cognito for SSO/external auth
2. Use AWS KMS for JWT signing keys
3. Implement audit trail logging to CloudTrail/CloudWatch
4. Add GuardDuty for threat detection
5. Use S3 for image and template storage instead of MongoDB/filesystem
6. Implement backup automation for MongoDB with point-in-time recovery
