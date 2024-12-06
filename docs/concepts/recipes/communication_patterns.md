# Microservice Communication Recipes

## Common Communication Patterns

### 1. Request-Response Pattern

```mermaid
sequenceDiagram
    participant Client
    participant API Gateway
    participant Service A
    participant Service B
    participant Cache
    
    Client->>API Gateway: Request
    API Gateway->>Service A: Forward
    
    alt Cache Hit
        Service A->>Cache: Check Cache
        Cache-->>Service A: Data
    else Cache Miss
        Service A->>Service B: Get Data
        Service B-->>Service A: Response
        Service A->>Cache: Store
    end
    
    Service A-->>API Gateway: Response
    API Gateway-->>Client: Result
```

**When to Use:**
- Direct service-to-service communication
- Synchronous operations
- CRUD operations

**Recipe Ingredients:**
```yaml
# Traefik Configuration
services:
  service-a:
    labels:
      - "traefik.http.middlewares.retry.retry.attempts=3"
      - "traefik.http.middlewares.retry.retry.initialInterval=100ms"
```

### 2. Event-Driven Pattern

```mermaid
graph LR
    subgraph "Publishers"
        A[Order Service]
        B[Payment Service]
        C[Inventory Service]
    end
    
    subgraph "Event Bus"
        D[Message Queue]
    end
    
    subgraph "Subscribers"
        E[Notification Service]
        F[Analytics Service]
        G[Shipping Service]
    end
    
    A --> D
    B --> D
    C --> D
    D --> E
    D --> F
    D --> G
```

**When to Use:**
- Decoupled services
- Asynchronous operations
- Event logging
- Analytics

**Recipe Ingredients:**
```yaml
# RabbitMQ Configuration
services:
  rabbitmq:
    image: rabbitmq:3-management
    environment:
      - RABBITMQ_DEFAULT_USER=user
      - RABBITMQ_DEFAULT_PASS=password
```

### 3. Saga Pattern

```mermaid
stateDiagram-v2
    [*] --> OrderCreated
    OrderCreated --> PaymentProcessed
    PaymentProcessed --> InventoryReserved
    InventoryReserved --> ShippingScheduled
    ShippingScheduled --> [*]
    
    PaymentProcessed --> OrderFailed: Failure
    InventoryReserved --> PaymentRefunded: Failure
    ShippingScheduled --> InventoryReleased: Failure
    
    state Compensation {
        PaymentRefunded --> OrderFailed
        InventoryReleased --> PaymentRefunded
    }
```

**When to Use:**
- Distributed transactions
- Multi-step processes
- Compensation logic needed

**Recipe Ingredients:**
```yaml
# State Management Service
services:
  state-manager:
    environment:
      - SAGA_TIMEOUT=30s
      - RETRY_ATTEMPTS=3
      - COMPENSATION_ENABLED=true
```

### 4. Circuit Breaker Pattern

```mermaid
stateDiagram-v2
    [*] --> Closed
    Closed --> Open: Error Threshold
    Open --> HalfOpen: Timeout
    HalfOpen --> Closed: Success
    HalfOpen --> Open: Failure
```

**When to Use:**
- Prevent cascading failures
- Handle service outages
- Graceful degradation

**Recipe Ingredients:**
```yaml
# Circuit Breaker Configuration
services:
  api:
    environment:
      - CIRCUIT_THRESHOLD=5
      - CIRCUIT_TIMEOUT=10s
      - CIRCUIT_RESET=30s
```

### 5. API Gateway Pattern

```mermaid
graph TD
    subgraph "Client Layer"
        A[Web App]
        B[Mobile App]
        C[Third Party]
    end
    
    subgraph "Gateway Layer"
        D[Rate Limiting]
        E[Authentication]
        F[Routing]
        G[Transformation]
    end
    
    subgraph "Service Layer"
        H[Service A]
        I[Service B]
        J[Service C]
    end
    
    A --> D
    B --> E
    C --> F
    D --> H
    E --> I
    F --> J
    G --> H
```

**When to Use:**
- Single entry point needed
- Cross-cutting concerns
- API versioning
- Request transformation

**Recipe Ingredients:**
```yaml
# Traefik Gateway Configuration
services:
  traefik:
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
```

### 6. CQRS Pattern

```mermaid
graph TD
    subgraph "Write Side"
        A[Commands] --> B[Command Handler]
        B --> C[Write Model]
        C --> D[Event Store]
    end
    
    subgraph "Read Side"
        E[Queries] --> F[Query Handler]
        F --> G[Read Model]
        D --> H[Projections]
        H --> G
    end
```

**When to Use:**
- Complex domains
- Different read/write patterns
- Event sourcing
- Performance optimization

**Recipe Ingredients:**
```yaml
# Event Store Configuration
services:
  eventstore:
    image: eventstore/eventstore
    environment:
      - EVENTSTORE_CLUSTER_SIZE=1
      - EVENTSTORE_RUN_PROJECTIONS=All
```

## Common Gotchas

### 1. Network Timeouts

```mermaid
sequenceDiagram
    participant A as Service A
    participant B as Service B
    
    A->>B: Request (Timeout: 5s)
    Note over B: Processing...
    alt Success
        B-->>A: Response (3s)
    else Timeout
        Note over A: Timeout!
        A->>A: Fallback Logic
    end
```

**Solution Recipe:**
```yaml
services:
  service-a:
    environment:
      - HTTP_TIMEOUT=5s
      - FALLBACK_ENABLED=true
```

### 2. Data Consistency

```mermaid
graph TD
    subgraph "Eventually Consistent"
        A[Write] --> B[Event]
        B --> C[Process]
        C --> D[Read]
        
        E[Time Window]
        F[Retry Logic]
        G[Version Tracking]
    end
```

**Solution Recipe:**
```yaml
services:
  database:
    environment:
      - CONSISTENCY_LEVEL=eventual
      - SYNC_INTERVAL=1s
```

### 3. Service Discovery

```mermaid
graph LR
    subgraph "Registration"
        A[Service] --> B[Registry]
    end
    
    subgraph "Discovery"
        C[Client] --> B
        B --> D[Load Balancer]
        D --> A
    end
```

**Solution Recipe:**
```yaml
services:
  consul:
    image: consul
    environment:
      - CONSUL_BIND_INTERFACE=eth0
```

Remember:
1. Start with simple patterns
2. Add complexity when needed
3. Monitor everything
4. Plan for failure
5. Keep services independent
6. Document your choices 