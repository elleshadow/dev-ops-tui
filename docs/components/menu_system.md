# Menu System

The menu system provides a hierarchical menu structure with proper state management and user interaction handling.

## Menu Hierarchy

```mermaid
flowchart TD
    subgraph Main ["Main Menu"]
        M1[Docker]
        M2[Config]
        M3[Logs]
        M4[Monitor]
    end
    
    subgraph Docker ["Docker Menu"]
        D1[Start]
        D2[Stop]
        D3[Restart]
        D4[Status]
        D5[Logs]
    end
    
    subgraph Config ["Config Menu"]
        C1[System]
        C2[Docker]
        C3[Network]
    end
    
    subgraph Logs ["Logs Menu"]
        L1[Docker]
        L2[System]
        L3[Application]
    end
    
    subgraph Monitor ["Monitor Menu"]
        R1[Resources]
        R2[Services]
        R3[Network]
    end
    
    M1 --> Docker
    M2 --> Config
    M3 --> Logs
    M4 --> Monitor
```

## Menu State Flow

```mermaid
stateDiagram-v2
    [*] --> MainMenu: Initialize
    
    MainMenu --> DockerMenu: Select Docker
    DockerMenu --> DockerOp: Select Operation
    DockerOp --> DockerMenu: Complete
    DockerMenu --> MainMenu: Back
    
    MainMenu --> ConfigMenu: Select Config
    ConfigMenu --> ConfigEdit: Select Option
    ConfigEdit --> ConfigMenu: Save/Cancel
    ConfigMenu --> MainMenu: Back
    
    MainMenu --> LogsMenu: Select Logs
    LogsMenu --> LogView: Select Log
    LogView --> LogsMenu: Exit View
    LogsMenu --> MainMenu: Back
    
    MainMenu --> MonitorMenu: Select Monitor
    MonitorMenu --> MonitorView: Select View
    MonitorView --> MonitorMenu: Exit View
    MonitorMenu --> MainMenu: Back
    
    MainMenu --> [*]: Exit
```

## Menu Operation Flow

```mermaid
sequenceDiagram
    participant User
    participant Menu
    participant State
    participant Term
    participant Handler
    
    User->>Menu: Select Option
    Menu->>State: Push Menu State
    State->>Term: Save Screen
    Menu->>Handler: Execute Handler
    
    alt Operation Success
        Handler-->>Menu: Success
        Menu->>State: Pop Menu State
        State->>Term: Restore Screen
        Menu->>User: Show Result
    else Operation Failed
        Handler-->>Menu: Error
        Menu->>User: Show Error
        Menu->>State: Pop Menu State
        State->>Term: Restore Screen
    end
```

## Menu Template System

```mermaid
flowchart TD
    subgraph Template ["Menu Template"]
        T1[Title]
        T2[Options]
        T3[Handler]
        T4[State]
    end
    
    subgraph Instance ["Menu Instance"]
        I1[Menu Name]
        I2[Menu Items]
        I3[Callbacks]
        I4[Context]
    end
    
    subgraph Rendering ["Menu Rendering"]
        R1[Layout]
        R2[Colors]
        R3[Input]
        R4[Display]
    end
    
    T1 --> I1
    T2 --> I2
    T3 --> I3
    T4 --> I4
    
    I1 --> R1
    I2 --> R2
    I3 --> R3
    I4 --> R4
```

## Error Handling

```mermaid
flowchart TD
    subgraph Errors ["Error Types"]
        E1[Input Error]
        E2[State Error]
        E3[Handler Error]
    end
    
    subgraph Handling ["Error Handling"]
        H1[Show Error]
        H2[Log Error]
        H3[Restore State]
    end
    
    subgraph Recovery ["Recovery"]
        R1[Retry Operation]
        R2[Return to Parent]
        R3[Exit Menu]
    end
    
    E1 --> H1
    E2 --> H2
    E3 --> H3
    
    H1 --> R1
    H2 --> R2
    H3 --> R3
```

## Key Features

- Hierarchical menu structure
- State-aware menu transitions
- Consistent error handling
- Theme-aware rendering
- Context preservation
- Input validation
- Screen management

## Usage Example

```bash
# Define a menu using the template
show_menu_template "main" "Main Menu" "Select an option:" \
    "Docker" "Manage Docker services" \
    "Config" "Configure settings" \
    "Logs" "View logs" \
    "Monitor" "System status" \
    "Back" "Exit"

# Define a menu handler
handle_main_menu_action() {
    local action="$1"
    case $action in
        "Docker")
            show_docker_menu
            ;;
        "Config")
            show_config_menu
            ;;
        *)
            return 0
            ;;
    esac
}
```

## Best Practices

1. Use menu templates for consistency
2. Implement proper state management
3. Handle all error cases
4. Provide clear navigation paths
5. Maintain menu context
6. Clean up on exit
7. Validate user input
8. Show operation status
9. Use consistent styling 