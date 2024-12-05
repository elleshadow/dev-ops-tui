# Core API Reference

This page documents the core functionality of the Dev-Ops TUI Library.

## Window Management

### create_window

Creates a new window with specified dimensions and properties.

```bash title="Function Signature"
create_window "title" width height [options]
```

Parameters:

| Name | Type | Description |
|------|------|-------------|
| `title` | string | Window title |
| `width` | integer | Window width in characters |
| `height` | integer | Window height in characters |
| `options` | string | Optional window properties |

Example:

```bash
# Create a basic window
create_window "My Window" 80 24

# Create a window with options
create_window "Settings" 60 20 "--shadow --center"
```

??? example "Advanced Usage"
    ```bash
    # Create a window with custom border style
    create_window "Custom" 40 10 "--border-style double"
    
    # Create a fullscreen window
    create_window "Fullscreen" 0 0 "--fullscreen"
    ```

### get_terminal_size

Gets the current terminal dimensions.

```bash title="Function Signature"
get_terminal_size
```

Returns: String in format "rows cols"

Example:

```bash
# Get terminal size
size=$(get_terminal_size)
read rows cols <<< "$size"

# Use dimensions
echo "Terminal is ${cols}x${rows}"
```

## Event System

### register_event

Registers an event handler for a specific event type.

```bash title="Function Signature"
register_event "event_name" handler_function
```

Parameters:

| Name | Type | Description |
|------|------|-------------|
| `event_name` | string | Name of the event |
| `handler_function` | function | Function to handle the event |

Example:

```bash hl_lines="2 3 4"
# Register a resize handler
handle_resize() {
    echo "Window resized to: $(get_terminal_size)"
}
register_event "resize" handle_resize
```

### trigger_event

Triggers a registered event.

```bash title="Function Signature"
trigger_event "event_name" [data]
```

Example:

```bash
# Trigger custom event
trigger_event "app_start" "{'time': '$(date)'}"
```

## Theme Engine

### set_theme

Sets the current theme for dialogs and windows.

```bash title="Function Signature"
set_theme "theme_name"
```

Available Themes:

- `default` - Standard theme
- `dark` - Dark mode theme
- `light` - Light mode theme
- `custom` - User-defined theme

Example:

```bash
# Set dark theme
set_theme "dark"

# Use custom theme
set_theme "custom" <<EOF
{
    "colors": {
        "background": "blue",
        "foreground": "white",
        "border": "cyan"
    },
    "styles": {
        "border": "double",
        "shadow": true
    }
}
EOF
```

## Error Handling

### handle_error

Handles errors and displays appropriate messages.

```bash title="Function Signature"
handle_error error_code [message]
```

Error Codes:

| Code | Description |
|------|-------------|
| 1 | General error |
| 2 | Invalid input |
| 3 | Resource not found |
| 4 | Permission denied |

Example:

```bash
if ! some_operation; then
    handle_error 1 "Operation failed"
    exit 1
fi
```

## Configuration

### load_config

Loads configuration from a file.

```bash title="Function Signature"
load_config "config_file"
```

Example Configuration:

```yaml title="config.yml"
theme:
  name: dark
  colors:
    background: blue
    foreground: white
window:
  border: double
  shadow: true
dialog:
  timeout: 30
  default_width: 60
```

Example Usage:

```bash
# Load configuration
load_config "config.yml"

# Access configuration
echo "Theme: ${CONFIG[theme.name]}"
```

!!! tip "Best Practice"
    Always validate configuration files before loading them:
    ```bash
    if validate_config "config.yml"; then
        load_config "config.yml"
    else
        echo "Invalid configuration"
        exit 1
    fi
    ```

## Debugging

### enable_debug

Enables debug mode with specified verbosity.

```bash title="Function Signature"
enable_debug [level]
```

Debug Levels:

| Level | Description |
|-------|-------------|
| 1 | Error messages |
| 2 | Warnings |
| 3 | Info messages |
| 4 | Debug messages |
| 5 | Trace messages |

Example:

```bash
# Enable full debugging
enable_debug 5

# Create window with debug info
create_window "Debug Test" 80 24
```

!!! warning "Performance Impact"
    High debug levels can impact performance. Use with caution in production. 