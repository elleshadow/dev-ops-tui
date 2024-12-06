#!/bin/bash

# Terminal state stack for managing nested states
declare -a TERM_STATE_STACK=()

init_terminal_state() {
    # Save initial terminal state
    if ! tput smcup > /dev/null 2>&1; then
        echo "ERROR: Failed to initialize terminal state" >&2
        return 1
    fi
    
    # Set up cleanup trap
    trap 'cleanup_terminal_state' EXIT INT TERM
    
    # Initialize state stack
    TERM_STATE_STACK=()
    return 0
}

push_terminal_state() {
    local state_name="$1"
    local timestamp=$(date +%s)
    
    # Save current terminal state
    if ! tput smcup > /dev/null 2>&1; then
        log_error "Failed to save terminal state: $state_name"
        return 1
    fi
    
    # Push state onto stack
    TERM_STATE_STACK+=("${state_name}:${timestamp}")
    return 0
}

pop_terminal_state() {
    local expected_state="$1"
    
    # Verify we have states to pop
    if [[ ${#TERM_STATE_STACK[@]} -eq 0 ]]; then
        log_error "Terminal state stack is empty"
        return 1
    fi
    
    # Get current state
    local current="${TERM_STATE_STACK[-1]}"
    local state_name="${current%:*}"
    
    # Verify state matches if one was expected
    if [[ -n "$expected_state" && "$state_name" != "$expected_state" ]]; then
        log_error "Terminal state mismatch. Expected: $expected_state, Found: $state_name"
        return 1
    fi
    
    # Restore previous terminal state
    if ! tput rmcup > /dev/null 2>&1; then
        log_error "Failed to restore terminal state: $state_name"
        return 1
    }
    
    # Pop state from stack
    unset 'TERM_STATE_STACK[-1]'
    return 0
}

cleanup_terminal_state() {
    # Restore all terminal states in reverse order
    while [[ ${#TERM_STATE_STACK[@]} -gt 0 ]]; do
        pop_terminal_state
    done
    
    # Final terminal cleanup
    tput rmcup > /dev/null 2>&1
    tput cnorm > /dev/null 2>&1  # Show cursor
    stty echo > /dev/null 2>&1   # Restore echo
    return 0
}

with_terminal_state() {
    local state_name="$1"
    shift
    local cmd="$@"
    
    if ! push_terminal_state "$state_name"; then
        return 1
    fi
    
    # Execute command in new terminal state
    eval "$cmd"
    local result=$?
    
    if ! pop_terminal_state "$state_name"; then
        return 1
    fi
    
    return $result
} 