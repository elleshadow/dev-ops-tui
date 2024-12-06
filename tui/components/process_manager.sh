#!/bin/bash

# Process management constants
PROCESS_STATE_FILE="/tmp/tui_process_state"
MAX_PROCESS_MEMORY=512  # MB

# Process management data structures
declare -A MANAGED_PROCESSES=()
declare -A PROCESS_GROUPS=()
declare -A PROCESS_STATES=()
declare -A PROCESS_ERRORS=()

init_process_manager() {
    # Initialize process tracking
    MANAGED_PROCESSES=()
    PROCESS_GROUPS=()
    PROCESS_STATES=()
    PROCESS_ERRORS=()
    
    # Initialize state file
    echo "{}" > "$PROCESS_STATE_FILE"
    
    # Set up process cleanup trap
    trap 'cleanup_process_manager' EXIT INT TERM
    return 0
}

start_managed_process() {
    local command="$1"
    local group_id="${2:-}"
    local auto_recover="${3:-false}"
    
    # Start process
    eval "$command" &
    local pid=$!
    
    # Store process information
    MANAGED_PROCESSES[$pid]="$command"
    PROCESS_STATES[$pid]="RUNNING"
    
    # Add to group if specified
    if [[ -n "$group_id" ]]; then
        PROCESS_GROUPS[$pid]="$group_id"
    fi
    
    # Set up auto-recovery if enabled
    if [[ "$auto_recover" == "true" ]]; then
        monitor_process "$pid" &
    fi
    
    echo "$pid"
}

get_process_status() {
    local pid=$1
    echo "${PROCESS_STATES[$pid]:-STOPPED}"
}

get_process_error() {
    local pid=$1
    echo "${PROCESS_ERRORS[$pid]:-}"
}

stop_managed_process() {
    local pid=$1
    
    if [[ -n "${MANAGED_PROCESSES[$pid]}" ]]; then
        kill -TERM "$pid" 2>/dev/null || true
        PROCESS_STATES[$pid]="STOPPED"
        unset MANAGED_PROCESSES[$pid]
    fi
}

create_process_group() {
    local group_name=$1
    local group_id="group_${RANDOM}"
    echo "$group_id"
}

get_group_process_count() {
    local group_id=$1
    local count=0
    
    for pid in "${!PROCESS_GROUPS[@]}"; do
        if [[ "${PROCESS_GROUPS[$pid]}" == "$group_id" ]]; then
            ((count++))
        fi
    done
    
    echo "$count"
}

stop_process_group() {
    local group_id=$1
    
    for pid in "${!PROCESS_GROUPS[@]}"; do
        if [[ "${PROCESS_GROUPS[$pid]}" == "$group_id" ]]; then
            stop_managed_process "$pid"
        fi
    done
}

get_process_memory() {
    local pid=$1
    local memory
    
    if [[ -f "/proc/$pid/status" ]]; then
        memory=$(grep 'VmRSS' "/proc/$pid/status" | awk '{print $2}')
        echo "$((memory / 1024))"  # Convert KB to MB
    else
        echo "0"
    fi
}

monitor_process() {
    local pid=$1
    
    while kill -0 "$pid" 2>/dev/null; do
        local memory
        memory=$(get_process_memory "$pid")
        
        if [[ "$memory" -gt "$MAX_PROCESS_MEMORY" ]]; then
            PROCESS_ERRORS[$pid]="Memory limit exceeded"
            stop_managed_process "$pid"
            break
        fi
        
        sleep 1
    done
}

get_recovered_process_id() {
    local old_pid=$1
    local command="${MANAGED_PROCESSES[$old_pid]}"
    
    if [[ -n "$command" ]]; then
        start_managed_process "$command"
    fi
}

wait_for_processes() {
    for pid in "$@"; do
        wait "$pid" 2>/dev/null || true
    done
}

cleanup_process_manager() {
    # Stop all managed processes
    for pid in "${!MANAGED_PROCESSES[@]}"; do
        stop_managed_process "$pid"
    done
    
    # Clean up state file
    rm -f "$PROCESS_STATE_FILE"
    
    # Reset data structures
    MANAGED_PROCESSES=()
    PROCESS_GROUPS=()
    PROCESS_STATES=()
    PROCESS_ERRORS=()
} 