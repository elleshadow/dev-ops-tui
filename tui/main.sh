#!/bin/bash

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source core components
source "$PROJECT_ROOT/tui/components/terminal_state.sh"
source "$PROJECT_ROOT/tui/components/process_manager.sh"
source "$PROJECT_ROOT/tui/components/menu_state.sh"
source "$PROJECT_ROOT/tui/components/menu_system.sh"
source "$PROJECT_ROOT/tui/components/logging_system.sh"
source "$PROJECT_ROOT/tui/components/config_manager.sh"
source "$PROJECT_ROOT/tui/components/docker_operations.sh"
source "$PROJECT_ROOT/tui/components/resource_monitor.sh"
source "$PROJECT_ROOT/tui/components/auth.sh"

# Initialize all systems
init_systems() {
    local -a systems=(
        "terminal_state"
        "process_manager"
        "menu_state"
        "logging_system"
        "config_manager"
        "resource_monitor"
    )
    
    for system in "${systems[@]}"; do
        log_info "Initializing $system..."
        if ! init_${system}; then
            log_error "Failed to initialize $system"
            exit 1
        fi
    done
    
    return 0
}

# Ensure proper cleanup on exit
cleanup_on_exit() {
    log_info "Cleaning up..."
    cleanup_resource_monitor
    cleanup_docker_resources
    cleanup_processes
    cleanup_terminal_state
}
trap cleanup_on_exit EXIT

# Initialize all systems
init_systems

# Handle authentication
if ! with_menu_error_handling "auth" "handle_auth"; then
    log_error "Authentication failed"
    exit 1
fi

# Start the main menu loop
show_main_menu

# Clean up and exit
clear
log_info "Exiting..."
exit 0

