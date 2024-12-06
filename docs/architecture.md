# DevOps TUI Architecture

This document provides a comprehensive overview of the DevOps TUI system architecture.

## System Overview

The system is built with a modular architecture focusing on clean state management and robust process handling.

```mermaid
flowchart TD
    subgraph Core ["Core Components"]
        TS[Terminal State]
        PM[Process Manager]
        MS[Menu State]
    end

    subgraph UI ["UI Components"]
        TH[Theme]
        MM[Menu System]
        DG[Dialog System]
    end

    subgraph Services ["Service Components"]
        DO[Docker Operations]
        RM[Resource Monitor]
        LG[Logging System]
        CF[Config Manager]
    end

    MM --> MS
    MM --> TS
    DG --> TH
    DG --> TS
    DO --> PM
    RM --> PM
    LG --> TS
    CF --> MS
    MS --> TS
```

## State Management

The system uses a hierarchical state management system to maintain clean state transitions and proper cleanup.

```mermaid
stateDiagram-v2
    [*] --> Init
    Init --> MainMenu: Authentication Success
    MainMenu --> DockerMenu: Select Docker
    MainMenu --> ConfigMenu: Select Config
    MainMenu --> LogsMenu: Select Logs
    MainMenu --> MonitorMenu: Select Monitor
    
    DockerMenu --> ServiceOp
    ServiceOp --> DockerMenu
    
    ConfigMenu --> ConfigEdit
    ConfigEdit --> ConfigMenu
    
    LogsMenu --> LogView
    LogView --> LogsMenu
    
    MonitorMenu --> ResourceView
    ResourceView --> MonitorMenu
    
    state ServiceOp {
        [*] --> Running
        Running --> Success
        Running --> Failed
        Success --> [*]
        Failed --> [*]
    }
```

## Process Management

The system handles long-running processes with proper monitoring and cleanup.

```mermaid
sequenceDiagram
    participant User
    participant Menu
    participant PM as Process Manager
    participant Docker
    participant Logs
    
    User->>Menu: Select Operation
    Menu->>PM: start_managed_process()
    PM->>Docker: Execute Command
    PM->>Logs: Redirect Output
    
    loop Monitor
        PM->>Docker: Check Status
        alt Process Running
            Docker->>PM: Status OK
        else Process Failed
            Docker->>PM: Error Status
            PM->>Logs: Collect Error Logs
            PM->>Menu: Show Error Dialog
        end
    end
    
    PM->>Menu: Operation Complete
    Menu->>User: Show Result
```

## Resource Monitoring

The resource monitoring system collects and visualizes system metrics.

```mermaid
flowchart TD
    subgraph Collection ["Data Collection"]
        CPU[CPU Metrics]
        MEM[Memory Metrics]
        DISK[Disk Metrics]
    end
    
    subgraph Processing ["Data Processing"]
        TH[Thresholds]
        AL[Alerts]
        LOG[Logging]
    end
    
    subgraph Display ["Visualization"]
        BAR[Usage Bars]
        HIST[History View]
        ALERT[Alert Display]
    end
    
    CPU --> TH
    MEM --> TH
    DISK --> TH
    
    TH --> AL
    AL --> LOG
    AL --> ALERT
    
    CPU --> BAR
    MEM --> BAR
    DISK --> BAR
    
    CPU --> HIST
    MEM --> HIST
    DISK --> HIST
```

## Configuration Management

The configuration system provides validated settings management.

```mermaid
flowchart TD
    subgraph Files ["Config Files"]
        SYS[System Config]
        DOC[Docker Config]
        NET[Network Config]
    end
    
    subgraph Management ["Config Management"]
        VAL[Validators]
        CACHE[Config Cache]
        LOAD[Config Loader]
    end
    
    subgraph Access ["Access Layer"]
        GET[Get Config]
        SET[Set Config]
        EDIT[Edit Config]
    end
    
    SYS --> LOAD
    DOC --> LOAD
    NET --> LOAD
    
    LOAD --> CACHE
    CACHE --> GET
    SET --> VAL
    VAL --> CACHE
    EDIT --> SET
```

## Component Details

### Terminal State Management
- Handles terminal cleanup and restoration
- Manages screen state stack
- Ensures proper cleanup on exit

### Process Management
- Tracks running processes
- Handles output redirection
- Manages process lifecycle
- Provides cleanup on exit

### Menu System
- Implements hierarchical menus
- Maintains menu state stack
- Handles user input
- Manages screen transitions

### Docker Operations
- Manages Docker services
- Handles service health checks
- Provides service logs
- Manages cleanup

### Resource Monitor
- Collects system metrics
- Processes threshold alerts
- Maintains metric history
- Visualizes resource usage

### Configuration Manager
- Validates configuration
- Manages config persistence
- Provides atomic updates
- Handles defaults

### Logging System
- Manages log rotation
- Provides contextual logging
- Handles log viewing
- Maintains log history 