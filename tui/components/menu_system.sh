#!/bin/bash

# Menu system implementation following hierarchical pattern
source "${PROJECT_ROOT}/tui/components/menu_state.sh"
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"

# Base menu template that enforces proper state management
show_menu_template() {
    local menu_name="$1"
    local title="$2"
    local prompt="$3"
    shift 3
    local -a options=("$@")
    
    # Initialize menu state
    if ! push_menu_state "$menu_name"; then
        log_error "Failed to initialize menu state: $menu_name"
        return 1
    fi
    
    # Ensure cleanup on exit
    trap 'pop_menu_state "$menu_name"' RETURN
    
    while true; do
        # Get current status if available
        local status=""
        if type get_${menu_name}_status >/dev/null 2>&1; then
            status=$("get_${menu_name}_status")
            prompt="\n$status\n\n$prompt"
        fi
        
        # Show menu with proper dimensions
        local action
        action=$(show_menu_dialog "$title" "$prompt" "${options[@]}")
        local result=$?
        
        # Handle dialog exit codes
        if [[ $result -eq 1 || $result -eq 255 ]]; then
            return 0  # User pressed ESC or canceled
        fi
        
        # Handle menu action
        if type "handle_${menu_name}_action" >/dev/null 2>&1; then
            if ! "handle_${menu_name}_action" "$action"; then
                show_error_dialog "Error" "Operation failed. Check logs for details."
                continue
            fi
        else
            case $action in
                "Back"|"")
                    return 0
                    ;;
                *)
                    log_error "No handler defined for menu: $menu_name"
                    return 1
                    ;;
            esac
        fi
    done
}

# Main menu implementation
show_main_menu() {
    show_menu_template "main" "Main Menu" "Select an option:" \
        "Docker" "Manage Docker services" \
        "Config" "Configure settings" \
        "Logs" "View logs" \
        "Status" "System status" \
        "Back" "Exit"
}

# Docker menu implementation
show_docker_menu() {
    show_menu_template "docker" "Docker Operations" "Select an operation:" \
        "Start" "Start services" \
        "Stop" "Stop services" \
        "Restart" "Restart services" \
        "Status" "View service status" \
        "Logs" "View service logs" \
        "Back" "Return to main menu"
}

# Docker menu action handler
handle_docker_action() {
    local action="$1"
    
    case $action in
        "Start")
            with_error_handling "docker_start" start_docker_services
            ;;
        "Stop")
            with_error_handling "docker_stop" stop_docker_services
            ;;
        "Restart")
            with_error_handling "docker_restart" restart_docker_services
            ;;
        "Status")
            show_docker_status
            ;;
        "Logs")
            show_docker_logs
            ;;
        *)
            return 0
            ;;
    esac
}

# Docker status retrieval
get_docker_status() {
    local status=""
    local running=0
    local total=0
    
    while IFS= read -r container; do
        ((total++))
        if docker inspect --format='{{.State.Running}}' "$container" 2>/dev/null | grep -q "true"; then
            ((running++))
        fi
    done < <(docker ps -a --format '{{.Names}}' 2>/dev/null)
    
    if [[ $total -eq 0 ]]; then
        echo "No containers found"
    else
        echo "Services: $running/$total running"
    fi
}

# Configuration menu implementation
show_config_menu() {
    show_menu_template "config" "Configuration" "Select a configuration:" \
        "Docker" "Docker settings" \
        "Network" "Network settings" \
        "Logging" "Logging settings" \
        "Back" "Return to main menu"
}

# Logs menu implementation
show_logs_menu() {
    show_menu_template "logs" "Logs Viewer" "Select log to view:" \
        "Docker" "Docker service logs" \
        "System" "System logs" \
        "Application" "Application logs" \
        "Back" "Return to main menu"
}

# Status menu implementation
show_status_menu() {
    show_menu_template "status" "System Status" "Select status view:" \
        "Services" "Service status" \
        "Resources" "Resource usage" \
        "Network" "Network status" \
        "Back" "Return to main menu"
}

# Error handling wrapper
with_error_handling() {
    local context="$1"
    shift
    local cmd="$@"
    
    # Set up error context
    local error_log="${PROJECT_ROOT}/logs/${context}.error.log"
    
    # Run operation with error capturing
    if ! eval "$cmd" 2> >(tee -a "$error_log" >&2); then
        local error_msg=$(tail -n 1 "$error_log")
        
        # Log error with context
        log_error "Operation failed in context $context: $error_msg"
        
        # Show error to user
        show_error_dialog "Operation Failed" "Error in $context:\n\n$error_msg"
        
        return 1
    fi
    
    return 0
} 