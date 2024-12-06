# Microservice Observability Cookbook

## Core Ingredients

### 1. Distributed Tracing

```mermaid
sequenceDiagram
    participant User
    participant Gateway
    participant ServiceA
    participant ServiceB
    participant Database
    
    Note over User,Database: Trace ID: abc-123
    
    User->>Gateway: Request
    Gateway->>ServiceA: Span 1
    ServiceA->>ServiceB: Span 2
    ServiceB->>Database: Span 3
    Database-->>ServiceB: Response
    ServiceB-->>ServiceA: Response
    ServiceA-->>Gateway: Response
    Gateway-->>User: Response
```

**Recipe:**
```yaml
# Jaeger Configuration
services:
  jaeger:
    image: jaegertracing/all-in-one
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
      - COLLECTOR_OTLP_ENABLED=true
```

### 2. Metrics Collection

```mermaid
graph TD
    subgraph "Application Metrics"
        A[Request Count]
        B[Response Time]
        C[Error Rate]
        D[Resource Usage]
    end
    
    subgraph "Collection"
        E[Prometheus]
    end
    
    subgraph "Visualization"
        F[Grafana]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    E --> F
```

**Recipe:**
```yaml
# Prometheus Configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'microservices'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['service-a:8080', 'service-b:8080']
```

### 3. Log Aggregation

```mermaid
graph LR
    subgraph "Log Sources"
        A[App Logs]
        B[System Logs]
        C[Access Logs]
    end
    
    subgraph "Collection"
        D[Fluentd]
    end
    
    subgraph "Storage"
        E[Elasticsearch]
    end
    
    subgraph "Analysis"
        F[Kibana]
    end
    
    A --> D
    B --> D
    C --> D
    D --> E
    E --> F
```

**Recipe:**
```yaml
# Fluentd Configuration
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match **>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
</match>
```

### 4. Health Checks

```mermaid
graph TD
    subgraph "Health Endpoints"
        A[Liveness]
        B[Readiness]
        C[Startup]
    end
    
    subgraph "Monitoring"
        D[Kubernetes]
        E[Custom Monitor]
    end
    
    A --> D
    B --> D
    C --> D
    A --> E
    B --> E
    C --> E
```

**Recipe:**
```yaml
# Health Check Configuration
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 5. Alerting

```mermaid
graph TD
    subgraph "Alert Sources"
        A[High Error Rate]
        B[Slow Response]
        C[Resource Usage]
        D[Custom Metrics]
    end
    
    subgraph "Alert Manager"
        E[Rules Engine]
        F[Notification System]
    end
    
    subgraph "Channels"
        G[Email]
        H[Slack]
        I[PagerDuty]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    E --> F
    F --> G
    F --> H
    F --> I
```

**Recipe:**
```yaml
# Alert Manager Rules
groups:
- name: example
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: High error rate detected
```

## Best Practices

### 1. Structured Logging

```json
{
  "timestamp": "2024-02-20T10:00:00Z",
  "level": "ERROR",
  "service": "order-service",
  "trace_id": "abc-123",
  "message": "Payment processing failed",
  "error": {
    "code": "PAYMENT_001",
    "details": "Insufficient funds"
  },
  "context": {
    "user_id": "user-123",
    "order_id": "order-456"
  }
}
```

### 2. Metric Naming

```yaml
# Metric Naming Convention
http_requests_total{method="GET", path="/api/v1/users", status="200"}
http_request_duration_seconds{method="POST", path="/api/v1/orders"}
app_queue_depth{queue="orders"}
```

### 3. Dashboard Organization

```mermaid
graph TD
    subgraph "Dashboard Hierarchy"
        A[Overview]
        B[Service Details]
        C[Resource Usage]
        D[Business Metrics]
        
        A --> B
        A --> C
        A --> D
    end
```

## Troubleshooting Recipes

### 1. Performance Investigation

```mermaid
graph TD
    A[High Latency Alert] --> B{Check Traces}
    B --> C[Database Slow]
    B --> D[Network Issues]
    B --> E[CPU Bound]
    
    C --> F[Query Optimization]
    D --> G[Network Diagnosis]
    E --> H[Profile CPU Usage]
```

### 2. Error Investigation

```mermaid
graph TD
    A[Error Alert] --> B{Check Logs}
    B --> C[Application Error]
    B --> D[Infrastructure Error]
    
    C --> E[Code Fix]
    D --> F[Scale Resources]
```

Remember:
1. Start with basic metrics
2. Add tracing for complex flows
3. Use structured logging
4. Set meaningful alerts
5. Keep dashboards simple
6. Document alert responses 