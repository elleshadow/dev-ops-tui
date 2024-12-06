# Logging System

The logging system provides comprehensive logging capabilities with proper log management, rotation, and viewing.

## Logging Architecture

```mermaid
flowchart TD
    subgraph Input ["Log Sources"]
        APP[Application]
        SYS[System]
        PROC[Processes]
        USER[User Actions]
    end
    
    subgraph Processing ["Log Processing"]
        FMT[Formatter]
        LEVEL[Log Level]
        CTX[Context]
        TIME[Timestamp]
    end
    
    subgraph Output ["Log Output"]
        FILE[Log Files]
        TERM[Terminal]
        ALERT[Alerts]
    end
    
    subgraph Management ["Log Management"]
        ROT[Rotation]
        ARCH[Archive]
        CLEAN[Cleanup]
    end
    
    APP --> FMT
    SYS --> FMT
    PROC --> FMT
    USER --> FMT
    
    FMT --> LEVEL
    LEVEL --> CTX
    CTX --> TIME
    
    TIME --> FILE
    TIME --> TERM
    TIME --> ALERT
    
    FILE --> ROT
    ROT --> ARCH
    ARCH --> CLEAN
```

## Logging Flow

```mermaid
sequenceDiagram
    participant App
    participant Logger
    participant Format
    participant File
    participant Term
    
    App->>Logger: log_message()
    Logger->>Format: Format Message
    
    Format->>Logger: Formatted Log
    
    par File Output
        Logger->>File: Write Log
        File-->>Logger: Success
    and Terminal Output
        Logger->>Term: Show Log
        Term-->>Logger: Success
    end
    
    alt Error Level
        Logger->>Term: Show Alert
    end
    
    Logger-->>App: Complete
```

## Log Level Management

```mermaid
stateDiagram-v2
    [*] --> Debug
    Debug --> Info: Higher Priority
    Info --> Warning: Higher Priority
    Warning --> Error: Higher Priority
    Error --> Critical: Higher Priority
    
    Critical --> Error: Lower Priority
    Error --> Warning: Lower Priority
    Warning --> Info: Lower Priority
    Info --> Debug: Lower Priority
    
    state Debug {
        [*] --> Verbose
        Verbose --> Trace
    }
    
    state Error {
        [*] --> Standard
        Standard --> Extended
    }
```

## Log File Management

```mermaid
flowchart LR
    subgraph Files ["Log Files"]
        CURR[Current Log]
        OLD[Old Logs]
        ARCH[Archives]
    end
    
    subgraph Rotation ["Log Rotation"]
        SIZE[Size Check]
        TIME[Time Check]
        ROT[Rotate]
    end
    
    subgraph Cleanup ["Cleanup"]
        COMP[Compress]
        MOVE[Move]
        DEL[Delete]
    end
    
    CURR --> SIZE
    CURR --> TIME
    
    SIZE --> ROT
    TIME --> ROT
    
    ROT --> OLD
    OLD --> COMP
    COMP --> MOVE
    MOVE --> ARCH
    ARCH --> DEL
```

## Log Viewing System

```mermaid
flowchart TD
    subgraph Input ["View Input"]
        FILE[Log File]
        FILTER[Filters]
        SEARCH[Search]
    end
    
    subgraph Display ["View Display"]
        PARSE[Parser]
        COLOR[Color]
        PAGER[Pager]
    end
    
    subgraph Navigation ["Navigation"]
        SCROLL[Scroll]
        JUMP[Jump]
        FIND[Find]
    end
    
    FILE --> PARSE
    FILTER --> PARSE
    SEARCH --> FIND
    
    PARSE --> COLOR
    COLOR --> PAGER
    
    PAGER --> SCROLL
    PAGER --> JUMP
    PAGER --> FIND
```

## Key Features

- Multi-level logging
- Contextual logging
- Log rotation
- Color output
- Log viewing
- Search capability
- Log archival
- Error tracking

## Usage Example

```bash
# Initialize logging system
init_logging_system

# Log messages at different levels
log_error "Error message"
log_warning "Warning message"
log_info "Info message"
log_debug "Debug message"

# View logs
show_log_viewer "system"

# Clean up old logs
cleanup_old_logs
```

## Error Handling

```mermaid
flowchart TD
    subgraph Errors ["Error Types"]
        WRITE[Write Error]
        PERM[Permission Error]
        SPACE[Space Error]
        ROT[Rotation Error]
    end
    
    subgraph Handling ["Error Handling"]
        FALLBACK[Fallback Logger]
        STDERR[Standard Error]
        CONSOLE[Console Output]
    end
    
    subgraph Recovery ["Recovery Actions"]
        CLEAN[Clean Space]
        FIX[Fix Permissions]
        RETRY[Retry Write]
    end
    
    WRITE --> FALLBACK
    PERM --> STDERR
    SPACE --> CONSOLE
    ROT --> STDERR
    
    FALLBACK --> RETRY
    STDERR --> FIX
    CONSOLE --> CLEAN
```

## Best Practices

1. Use appropriate log levels
2. Include context in logs
3. Configure log rotation
4. Monitor log size
5. Archive old logs
6. Handle write errors
7. Format logs consistently
8. Set retention policies
9. Secure log files 