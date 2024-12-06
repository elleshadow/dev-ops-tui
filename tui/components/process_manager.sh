#!/bin/bash

# Process management data structures
declare -A MANAGED_PROCESSES=()
declare -A PROCESS_LOGS=()
declare -A PROCESS_ERRORS=()

init_process_manager() {
    # Initialize process tracking
    MANAGED_PROCESSES=()
    PROCESS_LOGS=()
    PROCESS_ERRORS=()
    
    # Create logs directory if it doesn't exist
    mkdir -p "${PROJECT_ROOT}/logs"
    
    # Set up process cleanup trap
    trap 'cleanup_processes' EXIT INT TERM
    return 0
}

start_managed_process() {
    local process_name="$1"
    local command="$2"
    local timeout="${3:-30}"  # Default 30 second timeout
    
    # Set up log files
    local log_file="${PROJECT_ROOT}/logs/${process_name}.log"
    local error_log="${PROJECT_ROOT}/logs/${process_name}.error.log"
    
    # Clear previous logs
    echo "=== Process Started: $(date) ===" > "$log_file"
    echo "=== Process Started: $(date) ===" > "$error_log"
    
    # Start process with output redirection
    (eval "$command" > >(tee -a "$log_file") 2> >(tee -a "$error_log" >&2)) &
    local pid=$!
    
    # Store process information
    MANAGED_PROCESSES["$process_name"]=$pid
    PROCESS_LOGS["$process_name"]=$log_file
    PROCESS_ERRORS["$process_name"]=$error_log
    
    # Wait for process to start
    local count=0
    while ((count < timeout)); do
        if ! kill -0 $pid 2>/dev/null; then
            log_error "Process $process_name failed to start"
            cleanup_process "$process_name"
            return 1
        fi
        
        # Check for successful startup in logs
        if grep -q "Started successfully" "$log_file" 2>/dev/null; then
            log_info "Process $process_name started successfully"
            return 0
        fi
        
        sleep 1
        ((count++))
    done
    
    log_error "Process $process_name startup timed out"
    cleanup_process "$process_name"
    return 1
}

stop_managed_process() {
    local process_name="$1"
    local timeout="${2:-30}"  # Default 30 second timeout
    
    # Check if process exists
    local pid="${MANAGED_PROCESSES[$process_name]}"
    if [[ -z "$pid" ]]; then
        log_warning "Process $process_name not found"
        return 0
    fi
    
    # Try graceful shutdown first
    kill -TERM $pid 2>/dev/null
    
    # Wait for process to stop
    local count=0
    while ((count < timeout)); do
        if ! kill -0 $pid 2>/dev/null; then
            cleanup_process "$process_name"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    # Force kill if necessary
    log_warning "Process $process_name failed to stop gracefully, forcing..."
    kill -9 $pid 2>/dev/null
    cleanup_process "$process_name"
    return 1
}

cleanup_process() {
    local process_name="$1"
    
    # Kill process if still running
    local pid="${MANAGED_PROCESSES[$process_name]}"
    if [[ -n "$pid" ]]; then
        kill -9 $pid 2>/dev/null || true
    fi
    
    # Remove from tracking
    unset MANAGED_PROCESSES["$process_name"]
    unset PROCESS_LOGS["$process_name"]
    unset PROCESS_ERRORS["$process_name"]
}

cleanup_processes() {
    # Stop all managed processes
    local process_name
    for process_name in "${!MANAGED_PROCESSES[@]}"; do
        stop_managed_process "$process_name" 5  # Short timeout for cleanup
    done
}

get_process_status() {
    local process_name="$1"
    
    # Check if process is being tracked
    local pid="${MANAGED_PROCESSES[$process_name]}"
    if [[ -z "$pid" ]]; then
        echo "not_running"
        return 0
    fi
    
    # Check if process is actually running
    if ! kill -0 $pid 2>/dev/null; then
        echo "dead"
        return 1
    fi
    
    echo "running"
    return 0
}

tail_process_logs() {
    local process_name="$1"
    local log_file="${PROCESS_LOGS[$process_name]}"
    local error_log="${PROCESS_ERRORS[$process_name]}"
    
    if [[ ! -f "$log_file" || ! -f "$error_log" ]]; then
        log_error "Log files not found for process $process_name"
        return 1
    fi
    
    # Use terminal state management for clean display
    with_terminal_state "log_view" "
        clear
        echo -e '\033[36m=== Output Log ===\033[0m'
        tail -f '$log_file' &
        local tail_pid=\$!
        
        echo -e '\033[31m=== Error Log ===\033[0m'
        tail -f '$error_log' &
        local error_tail_pid=\$!
        
        # Wait for user input to exit
        read -n 1
        kill \$tail_pid \$error_tail_pid 2>/dev/null
    "
} 