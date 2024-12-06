# Error Scenarios

This document details various error scenarios and their handling flows.

## Docker Service Failure

```mermaid
sequenceDiagram
    participant User
    participant Menu
    participant Docker
    participant PM as Process Manager
    participant Log
    participant Recovery
    
    User->>Menu: Start Service
    Menu->>Docker: start_docker_services()
    
    activate Docker
    Docker->>PM: Start Container
    
    alt Container Start Failed
        PM-->>Docker: Start Error
        Docker->>Log: Log Error Details
        Docker->>Recovery: Attempt Recovery
        
        par Recovery Actions
            Recovery->>Docker: Cleanup Old Container
            Recovery->>Docker: Reset Network
            Recovery->>Docker: Retry Start
        end
        
        alt Recovery Success
            Recovery-->>Menu: Service Restored
            Menu-->>User: Show Success
        else Recovery Failed
            Recovery->>Log: Log Recovery Failure
            Recovery-->>Menu: Recovery Failed
            Menu-->>User: Show Error Dialog
        end
    else Container Unhealthy
        PM-->>Docker: Health Check Failed
        Docker->>Log: Log Health Status
        Docker->>Recovery: Health Recovery
        
        Recovery->>Docker: Restart Container
        
        alt Health Restored
            Docker-->>Menu: Service Healthy
            Menu-->>User: Show Status
        else Still Unhealthy
            Docker->>Log: Log Health Failure
            Docker-->>Menu: Health Check Failed
            Menu-->>User: Show Health Error
        end
    end
    deactivate Docker
```

## Configuration Error Recovery

```mermaid
sequenceDiagram
    participant User
    participant Menu
    participant Config
    participant File
    participant Backup
    participant Log
    
    User->>Menu: Edit Config
    Menu->>Config: set_config()
    
    activate Config
    Config->>File: Write Config
    
    alt Write Failed
        File-->>Config: IO Error
        Config->>Log: Log Error
        Config->>Backup: Load Backup
        
        alt Backup Available
            Backup-->>Config: Restore Config
            Config->>File: Write Backup
            Config-->>Menu: Config Restored
        else No Backup
            Config->>File: Write Defaults
            Config-->>Menu: Using Defaults
        end
        
        Menu-->>User: Show Recovery Status
    else Validation Failed
        Config->>Log: Log Validation Error
        Config->>File: Keep Old Config
        Config-->>Menu: Validation Failed
        Menu-->>User: Show Invalid Input
    else Permission Error
        Config->>Log: Log Permission Error
        Config->>File: Attempt Safe Write
        
        alt Safe Write Success
            Config-->>Menu: Config Saved
            Menu-->>User: Show Success
        else Safe Write Failed
            Config-->>Menu: Permission Denied
            Menu-->>User: Show Permission Error
        end
    end
    deactivate Config
```

## Process Management Failure

```mermaid
sequenceDiagram
    participant Menu
    participant PM as Process Manager
    participant Proc as Process
    participant Resource
    participant Log
    participant Recovery
    
    Menu->>PM: start_managed_process()
    
    activate PM
    PM->>Proc: Start Process
    PM->>Resource: Monitor Resources
    
    alt Process Crash
        Proc-->>PM: Process Died
        PM->>Log: Log Crash Details
        PM->>Recovery: Crash Recovery
        
        Recovery->>Resource: Free Resources
        Recovery->>PM: Reset State
        Recovery->>Proc: Restart Process
        
        alt Restart Success
            Proc-->>PM: Process Running
            PM-->>Menu: Process Restored
        else Restart Failed
            Recovery->>Log: Log Recovery Failed
            PM-->>Menu: Process Failed
        end
        
    else Resource Exhaustion
        Resource-->>PM: Resource Limit Hit
        PM->>Log: Log Resource Error
        PM->>Recovery: Resource Recovery
        
        par Recovery Actions
            Recovery->>Resource: Free Memory
            Recovery->>Resource: Clear Temp Files
            Recovery->>Resource: Kill Zombie Processes
        end
        
        alt Resources Freed
            Resource-->>PM: Resources Available
            PM->>Proc: Continue Process
            PM-->>Menu: Process Running
        else Still Exhausted
            Recovery->>Log: Log Resource Failure
            PM->>Proc: Terminate Process
            PM-->>Menu: Resource Error
        end
    end
    deactivate PM
```

## Terminal State Recovery

```mermaid
sequenceDiagram
    participant Menu
    participant Term as Terminal State
    participant Screen
    participant Log
    participant Recovery
    
    Menu->>Term: push_terminal_state()
    
    activate Term
    Term->>Screen: Save State
    
    alt Save Failed
        Screen-->>Term: Save Error
        Term->>Log: Log State Error
        Term->>Recovery: State Recovery
        
        Recovery->>Screen: Reset Terminal
        Recovery->>Screen: Restore Default
        
        alt Reset Success
            Screen-->>Term: Terminal Reset
            Term-->>Menu: Using Default State
        else Reset Failed
            Recovery->>Log: Log Terminal Error
            Term-->>Menu: Terminal Error
        end
        
    else State Corruption
        Term->>Log: Log Corruption
        Term->>Recovery: Corruption Recovery
        
        Recovery->>Screen: Clear Screen
        Recovery->>Term: Pop All States
        Recovery->>Screen: Reinitialize
        
        alt Recovery Success
            Screen-->>Term: Terminal Ready
            Term-->>Menu: State Restored
        else Recovery Failed
            Recovery->>Log: Log Fatal Error
            Term-->>Menu: Fatal Error
        end
    end
    deactivate Term
```

## Logging System Failure

```mermaid
sequenceDiagram
    participant Component
    participant Log
    participant File
    participant Fallback
    participant Alert
    
    Component->>Log: log_message()
    
    activate Log
    Log->>File: Write Log
    
    alt Write Failed
        File-->>Log: IO Error
        Log->>Fallback: Use Fallback
        
        par Fallback Actions
            Fallback->>File: Write to Temp
            Fallback->>Alert: Show Warning
        end
        
        alt Fallback Success
            Fallback-->>Log: Message Saved
            Log-->>Component: Log Written
        else Fallback Failed
            Fallback->>Alert: Show Error
            Log-->>Component: Log Failed
        end
        
    else Rotation Failed
        File-->>Log: Rotation Error
        Log->>Fallback: Emergency Rotation
        
        par Emergency Actions
            Fallback->>File: Archive Current
            Fallback->>File: Clear Log
            Fallback->>Alert: Show Warning
        end
        
        alt Emergency Success
            File-->>Log: Rotation Complete
            Log-->>Component: Log Continued
        else Emergency Failed
            Fallback->>Alert: Show Error
            Log-->>Component: Using Stdout
        end
    end
    deactivate Log
```

## Resource Monitor Recovery

```mermaid
sequenceDiagram
    participant Monitor
    participant Metric
    participant Store
    participant Alert
    participant Recovery
    
    Monitor->>Metric: collect_metrics()
    
    activate Monitor
    Metric->>Store: Store Metrics
    
    alt Collection Failed
        Metric-->>Monitor: Collection Error
        Monitor->>Recovery: Collection Recovery
        
        par Recovery Actions
            Recovery->>Metric: Reset Collectors
            Recovery->>Store: Use Cache
            Recovery->>Alert: Show Warning
        end
        
        alt Recovery Success
            Metric-->>Monitor: Collection Restored
            Monitor->>Store: Resume Storage
        else Recovery Failed
            Recovery->>Alert: Show Error
            Monitor->>Store: Use Estimates
        end
        
    else Storage Failed
        Store-->>Monitor: Storage Error
        Monitor->>Recovery: Storage Recovery
        
        par Recovery Actions
            Recovery->>Store: Clear Old Data
            Recovery->>Store: Compact Storage
            Recovery->>Alert: Show Warning
        end
        
        alt Recovery Success
            Store-->>Monitor: Storage Available
            Monitor->>Metric: Resume Collection
        else Recovery Failed
            Recovery->>Alert: Show Error
            Monitor->>Store: Use Memory Only
        end
    end
    deactivate Monitor
```

## Recovery Strategies

### Graceful Degradation
- Fall back to simpler UI if terminal state corrupts
- Use memory-only storage if disk fails
- Switch to stdout logging if log files are inaccessible
- Operate in reduced functionality mode when resources are constrained

### State Recovery
- Keep state checkpoints for critical operations
- Use transaction-like approaches for multi-step operations
- Maintain backup copies of configuration files
- Implement undo/redo capability for user actions

### Resource Management
- Implement garbage collection for orphaned processes
- Clear temporary files periodically
- Release unused terminal states
- Compact logs and metrics storage

### Service Recovery
- Implement exponential backoff for retries
- Use circuit breakers for failing services
- Maintain service health checks
- Implement automatic container cleanup

## Error Prevention Patterns

### Input Validation
```bash
validate_input() {
    local input=$1
    local type=$2
    
    case $type in
        "number")
            [[ $input =~ ^[0-9]+$ ]] || return 1
            ;;
        "path")
            [[ -e $input ]] || return 1
            ;;
        "container")
            docker inspect "$input" >/dev/null 2>&1 || return 1
            ;;
    esac
    return 0
}
```

### Resource Guards
```bash
with_resource_guard() {
    local resource=$1
    local operation=$2
    
    # Acquire
    lock_resource "$resource"
    
    # Execute with trap
    trap 'unlock_resource "$resource"' EXIT
    eval "$operation"
    
    # Release
    unlock_resource "$resource"
}
```

### State Invariants
```bash
check_state_invariants() {
    local component=$1
    
    # Check required files
    [[ -f "$CONFIG_FILE" ]] || return 1
    [[ -d "$LOG_DIR" ]] || return 1
    
    # Check permissions
    [[ -w "$LOG_DIR" ]] || return 1
    [[ -r "$CONFIG_FILE" ]] || return 1
    
    # Check running services
    pgrep -f "$component" >/dev/null || return 1
    
    return 0
}
```

## Error Handling Guidelines

### Core Principles
1. **Fail Fast** - Detect and handle errors early
2. **Fail Safe** - Always leave system in consistent state
3. **Recover Gracefully** - Provide degraded service over no service
4. **Inform Clearly** - Give users actionable error messages

### Implementation Rules
1. **Always check return values**
```bash
if ! some_operation; then
    log_error "Operation failed"
    handle_error
fi
```

2. **Use error codes consistently**
```bash
ERROR_CODES=(
    "E_CONFIG=1"
    "E_PERMISSION=2"
    "E_RESOURCE=3"
    "E_NETWORK=4"
)
```

3. **Implement proper cleanup**
```bash
cleanup() {
    remove_temp_files
    release_locks
    restore_terminal
}
trap cleanup EXIT
```

4. **Log errors with context**
```bash
log_error() {
    local msg=$1
    local context=$2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $msg (Context: $context)" >> "$LOG_FILE"
}
```

### Best Practices
1. Never swallow errors silently
2. Always provide recovery options
3. Keep error messages user-friendly
4. Maintain audit trail of errors
5. Test error scenarios regularly
6. Document recovery procedures

These diagrams show:
1. Detailed error paths
2. Recovery strategies
3. Fallback mechanisms
4. Resource cleanup
5. State restoration
6. User notification

Would you like me to:
1. Add more specific error scenarios
2. Detail recovery strategies
3. Add error prevention patterns
4. Create error handling guidelines 