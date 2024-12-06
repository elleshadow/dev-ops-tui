# Microservice Security Cookbook

## Core Security Patterns

### 1. Authentication & Authorization

```mermaid
sequenceDiagram
    participant User
    participant Gateway
    participant Auth Service
    participant Service A
    participant Service B
    
    User->>Gateway: Request + Credentials
    Gateway->>Auth Service: Validate
    Auth Service-->>Gateway: JWT Token
    
    Note over Gateway,Service B: JWT propagation
    
    Gateway->>Service A: Request + JWT
    Service A->>Service B: Request + JWT
    Service B-->>Service A: Response
    Service A-->>Gateway: Response
    Gateway-->>User: Response
```

**Recipe:**
```yaml
# Auth Service Configuration
security:
  jwt:
    secret: ${JWT_SECRET}
    expiration: 3600
    refresh-token-expiration: 86400
  cors:
    allowed-origins: "*"
    allowed-methods: ["GET", "POST", "PUT", "DELETE"]
```

### 2. Secret Management

```mermaid
graph TD
    subgraph "Secret Sources"
        A[Environment Variables]
        B[Vault]
        C[Cloud KMS]
    end
    
    subgraph "Application"
        D[Secret Manager]
        E[Service Config]
    end
    
    A --> D
    B --> D
    C --> D
    D --> E
```

**Recipe:**
```yaml
# Vault Configuration
vault:
  addr: "http://vault:8200"
  token: ${VAULT_TOKEN}
  paths:
    - secret/database
    - secret/api-keys
    - secret/certificates
```

### 3. Network Security

```mermaid
graph TD
    subgraph "External"
        A[Internet]
    end
    
    subgraph "DMZ"
        B[WAF]
        C[API Gateway]
    end
    
    subgraph "Internal Network"
        D[Service Mesh]
        E[Services]
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
```

**Recipe:**
```yaml
# Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway
spec:
  podSelector:
    matchLabels:
      app: gateway
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: backend
```

### 4. Data Protection

```mermaid
graph LR
    subgraph "Data States"
        A[In Transit]
        B[At Rest]
        C[In Use]
    end
    
    subgraph "Protection Methods"
        D[TLS]
        E[Encryption]
        F[Access Control]
    end
    
    A --> D
    B --> E
    C --> F
```

**Recipe:**
```yaml
# Encryption Configuration
encryption:
  algorithm: AES256
  key-rotation: 90d
  backup-retention: 30d
  
tls:
  version: "1.3"
  ciphers:
    - TLS_AES_128_GCM_SHA256
    - TLS_AES_256_GCM_SHA384
```

### 5. Access Control

```mermaid
graph TD
    subgraph "Identity"
        A[Authentication]
        B[Authorization]
    end
    
    subgraph "Policies"
        C[RBAC]
        D[ABAC]
    end
    
    subgraph "Resources"
        E[APIs]
        F[Data]
        G[Functions]
    end
    
    A --> C
    B --> C
    A --> D
    B --> D
    C --> E
    C --> F
    C --> G
    D --> E
    D --> F
    D --> G
```

**Recipe:**
```yaml
# RBAC Configuration
roles:
  admin:
    permissions:
      - "*"
  reader:
    permissions:
      - "read:*"
      - "list:*"
  writer:
    permissions:
      - "read:*"
      - "write:*"
      - "delete:own"
```

## Security Best Practices

### 1. Input Validation

```json
{
  "validation": {
    "input": {
      "sanitize": true,
      "escape": true,
      "max_length": 1000,
      "allowed_chars": "[a-zA-Z0-9-_.]"
    },
    "output": {
      "encode": true,
      "content_type": "application/json",
      "headers": {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY"
      }
    }
  }
}
```

### 2. Audit Logging

```mermaid
graph TD
    A[Security Event] --> B[Audit Logger]
    B --> C[Secure Storage]
    C --> D[Monitoring]
    C --> E[Compliance]
```

**Recipe:**
```yaml
# Audit Log Configuration
audit:
  enabled: true
  events:
    - authentication
    - authorization
    - data_access
    - configuration_change
  retention: 365d
  encryption: true
```

### 3. Security Headers

```yaml
# Security Headers Configuration
security_headers:
  Strict-Transport-Security: "max-age=31536000; includeSubDomains"
  Content-Security-Policy: "default-src 'self'"
  X-Content-Type-Options: "nosniff"
  X-Frame-Options: "DENY"
  X-XSS-Protection: "1; mode=block"
```

## Common Attack Vectors & Mitigations

### 1. API Security

```mermaid
graph TD
    subgraph "Threats"
        A[OWASP Top 10]
        B[Rate Limiting]
        C[Input Validation]
    end
    
    subgraph "Mitigations"
        D[WAF Rules]
        E[API Gateway]
        F[Input Sanitization]
    end
    
    A --> D
    B --> E
    C --> F
```

**Recipe:**
```yaml
# API Security Configuration
api_security:
  rate_limit:
    window: 60s
    max_requests: 100
  throttling:
    enabled: true
    burst: 50
  validation:
    schema: true
    sanitize: true
```

### 2. Container Security

```mermaid
graph TD
    subgraph "Container Security"
        A[Image Scanning]
        B[Runtime Security]
        C[Network Policies]
    end
    
    A --> D[Vulnerability DB]
    B --> E[Security Policies]
    C --> F[Network Rules]
```

**Recipe:**
```yaml
# Container Security Policy
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
```

Remember:
1. Defense in depth
2. Least privilege principle
3. Regular security audits
4. Automated security testing
5. Incident response plan
6. Security monitoring
7. Regular updates and patches