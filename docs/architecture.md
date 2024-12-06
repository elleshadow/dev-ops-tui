# DevOps TUI Architecture

## Philosophy: Flow State First

The architecture is designed around one core principle: **Get developers into flow state as quickly as possible**.

```mermaid
graph TD
    subgraph "Developer Journey"
        A[Zero State] --> B[Environment Ready]
        B --> C[Browser Handoff]
        C --> D[Flow State]
        D --> E[Productivity Loop]
        E --> D
    end
    
    subgraph "TUI Magic"
        F[Runtime Setup]
        G[Service Orchestration]
        H[Security Config]
        I[Network Setup]
    end
    
    subgraph "Background Processes"
        J[Health Monitoring]
        K[Auto Updates]
        L[Error Recovery]
    end
    
    A --> F
    A --> G
    A --> H
    A --> I
    
    G --> J
    G --> K
    G --> L
    
    style D fill:#9f9,stroke:#333
    style E fill:#9f9,stroke:#333
```

## Service Architecture

```mermaid
graph TD
    subgraph "Frontend Layer"
        A[TUI Interface]
        B[Browser Tools]
    end
    
    subgraph "Orchestration Layer"
        C[Docker Compose]
        D[Service Discovery]
        E[Health Checks]
    end
    
    subgraph "Development Services"
        F[PostgreSQL]
        G[pgAdmin]
        H[Grafana]
        I[Prometheus]
        J[Loki]
        K[Traefik]
    end
    
    subgraph "System Services"
        L[SQLite DB]
        M[Docker Engine]
        N[Network Manager]
    end
    
    A --> C
    C --> D
    D --> E
    
    C --> F
    C --> G
    C --> H
    C --> I
    C --> J
    C --> K
    
    A --> L
    A --> M
    A --> N
    
    B --> G
    B --> H
    B --> I
    B --> J
    B --> K
    
    style A fill:#f96,stroke:#333
    style B fill:#9f9,stroke:#333
    style L fill:#666,stroke:#333,color:#fff
```

## Data Flow

```mermaid
graph LR
    subgraph "System Layer"
        A[SQLite DB]
        B[Config Files]
        C[State Files]
    end
    
    subgraph "Project Layer"
        D[PostgreSQL]
        E[Metrics DB]
        F[Log Storage]
    end
    
    subgraph "Access Layer"
        G[TUI]
        H[pgAdmin]
        I[Grafana]
        J[Kibana]
    end
    
    G --> A
    G --> B
    G --> C
    
    H --> D
    I --> E
    J --> F
    
    style A fill:#666,stroke:#333,color:#fff
    style B fill:#666,stroke:#333,color:#fff
    style C fill:#666,stroke:#333,color:#fff
```

## Development Workflow

```mermaid
stateDiagram-v2
    [*] --> FirstRun: Clone & Start
    FirstRun --> Setup: Auto Detection
    Setup --> Services: Deploy Stack
    Services --> Browser: Handoff
    
    state Browser {
        [*] --> Development
        Development --> Database: pgAdmin
        Development --> Metrics: Grafana
        Development --> Logs: Loki
        Database --> Development
        Metrics --> Development
        Logs --> Development
    }
    
    Browser --> Services: Only for Management
    Services --> Browser: Back to Flow
```

## Component Interaction

```mermaid
sequenceDiagram
    participant User
    participant TUI
    participant Docker
    participant Services
    participant Browser
    
    User->>TUI: Start Development
    
    rect rgb(200, 200, 200)
        Note over TUI,Docker: Setup Phase
        TUI->>Docker: Check Environment
        Docker-->>TUI: Status Report
        TUI->>Docker: Deploy Services
        Docker->>Services: Start Containers
        Services-->>Docker: Ready Status
    end
    
    rect rgb(150, 250, 150)
        Note over TUI,Browser: Handoff Phase
        TUI->>User: Display Service URLs
        User->>Browser: Access Services
        Note over Browser: Development Flow
    end
    
    rect rgb(200, 200, 250)
        Note over TUI,Services: Background Operations
        loop Health Checks
            TUI->>Services: Monitor Health
            Services-->>TUI: Status Updates
        end
    end
```

## Error Recovery

```mermaid
stateDiagram-v2
    [*] --> Normal
    
    Normal --> Warning: Health Check
    Warning --> Critical: No Recovery
    Warning --> Normal: Auto Recovery
    
    Critical --> Warning: Manual Action
    Critical --> Normal: Full Recovery
    
    state Warning {
        [*] --> Detection
        Detection --> AutoFix
        AutoFix --> [*]
    }
    
    state Critical {
        [*] --> Alert
        Alert --> UserAction
        UserAction --> ServiceRestart
        ServiceRestart --> [*]
    }
```

## Security Model

```mermaid
graph TD
    subgraph "Access Control"
        A[SSH Keys]
        B[GPG Keys]
        C[Service Credentials]
    end
    
    subgraph "Storage"
        D[System DB]
        E[Config Files]
        F[Secrets]
    end
    
    subgraph "Network"
        G[Traefik]
        H[Docker Network]
        I[Service Mesh]
    end
    
    A --> D
    B --> D
    C --> D
    
    D --> E
    D --> F
    
    G --> H
    H --> I
    
    style D fill:#666,stroke:#333,color:#fff
    style F fill:#666,stroke:#333,color:#fff
```

## Service Health Management

```mermaid
graph TD
    subgraph "Monitoring"
        A[Health Checks]
        B[Metrics Collection]
        C[Log Aggregation]
    end
    
    subgraph "Analysis"
        D[Status Evaluation]
        E[Threshold Checks]
        F[Pattern Detection]
    end
    
    subgraph "Response"
        G[Auto Recovery]
        H[Alert System]
        I[User Notification]
    end
    
    A --> D
    B --> E
    C --> F
    
    D --> G
    E --> H
    F --> I
```

Remember: Every component and interaction is designed to maintain flow state. The system should handle complexity invisibly and only surface what's needed for development.