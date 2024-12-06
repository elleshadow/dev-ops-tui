#!/bin/bash

# Source test framework and components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/terminal_state.sh"
source "${SCRIPT_DIR}/tui/components/process_manager.sh"
source "${SCRIPT_DIR}/tui/components/menu_system.sh"
source "${SCRIPT_DIR}/tui/components/logging_system.sh"

describe "Error Scenario Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_all_components
}

teardown() {
    cleanup_all_components
    unset TEST_MODE
}

# Concurrent Access Errors
test_concurrent_access() {
    it "should handle concurrent access to resources"
    
    # Simulate concurrent menu access
    create_menu "concurrent" "Concurrent Test"
    
    # Start multiple processes accessing menu
    (navigate_menu "concurrent") &
    (navigate_menu "concurrent") &
    
    wait
    
    # Verify menu state consistency
    assert_equals "concurrent" "$(get_current_menu)"
    assert_log_contains "Concurrent access detected"
}

# Resource Exhaustion
test_resource_exhaustion() {
    it "should handle resource exhaustion gracefully"
    
    # Fill process table
    local pids=()
    for _ in {1..100}; do
        pids+=("$(start_managed_process "sleep 1")")
    done
    
    # Try to start another process
    local result
    result=$(start_managed_process "echo test")
    
    # Verify graceful handling
    assert_equals "ERROR_RESOURCE_LIMIT" "$result"
    assert_log_contains "Resource limit reached"
    
    # Cleanup
    for pid in "${pids[@]}"; do
        stop_managed_process "$pid"
    done
}

# State Corruption
test_state_corruption() {
    it "should recover from state corruption"
    
    # Corrupt multiple state files
    echo "INVALID" > "$TERMINAL_STATE_FILE"
    echo "INVALID" > "$MENU_STATE_FILE"
    echo "INVALID" > "$PROCESS_STATE_FILE"
    
    # Attempt recovery
    recover_all_states
    
    # Verify recovery
    assert_equals "NORMAL" "$(get_terminal_mode)"
    assert_true "[ -f '$MENU_STATE_FILE' ]"
    assert_true "[ -f '$PROCESS_STATE_FILE' ]"
}

# Cascading Failures
test_cascading_failures() {
    it "should prevent cascading failures"
    
    # Create failure chain
    create_menu "cascade" "Cascade Test"
    add_menu_item "cascade" "fail1" "Fail 1" "nonexistent1"
    add_menu_item "cascade" "fail2" "Fail 2" "nonexistent2"
    add_menu_item "cascade" "fail3" "Fail 3" "nonexistent3"
    
    # Execute failing chain
    navigate_menu "cascade"
    select_menu_item "fail1"
    select_menu_item "fail2"
    select_menu_item "fail3"
    
    # Verify failure isolation
    assert_equals "ERROR" "$(get_menu_error_state)"
    assert_equals "NORMAL" "$(get_terminal_mode)"
    assert_log_contains "Failure chain detected"
}

# Deadlock Prevention
test_deadlock_prevention() {
    it "should prevent deadlocks"
    
    # Create resource cycle
    create_menu "deadlock" "Deadlock Test"
    add_menu_item "deadlock" "lock1" "Lock 1" "acquire_lock 1"
    add_menu_item "deadlock" "lock2" "Lock 2" "acquire_lock 2"
    
    # Attempt deadlock
    navigate_menu "deadlock"
    select_menu_item "lock1" &
    select_menu_item "lock2" &
    
    wait
    
    # Verify deadlock prevention
    assert_log_contains "Potential deadlock detected"
    assert_equals "NORMAL" "$(get_terminal_mode)"
}

# Signal Interruption
test_signal_interruption() {
    it "should handle signal interruptions gracefully"
    
    # Start long-running process
    local pid
    pid=$(start_managed_process "sleep 30")
    
    # Send multiple signals
    kill -USR1 "$pid"
    kill -USR2 "$pid"
    kill -TERM "$pid"
    
    # Verify graceful handling
    assert_log_contains "Signal handled: USR1"
    assert_log_contains "Signal handled: USR2"
    assert_log_contains "Signal handled: TERM"
    assert_equals "NORMAL" "$(get_terminal_mode)"
}

# File System Errors
test_filesystem_errors() {
    it "should handle filesystem errors gracefully"
    
    # Make log directory read-only
    chmod 444 "$LOG_DIR"
    
    # Attempt logging
    log_error "Test error"
    
    # Verify fallback
    assert_log_contains "Switched to fallback logging"
    
    # Restore permissions
    chmod 755 "$LOG_DIR"
}

# Network Errors
test_network_errors() {
    it "should handle network errors gracefully"
    
    # Simulate network failure
    iptables -A OUTPUT -p tcp --dport 80 -j DROP
    
    # Attempt network operation
    local result
    result=$(execute_network_operation)
    
    # Verify handling
    assert_equals "ERROR_NETWORK" "$result"
    assert_log_contains "Network operation failed"
    
    # Restore network
    iptables -D OUTPUT -p tcp --dport 80 -j DROP
}

# Run all tests
run_test_suite() {
    test_concurrent_access
    test_resource_exhaustion
    test_state_corruption
    test_cascading_failures
    test_deadlock_prevention
    test_signal_interruption
    test_filesystem_errors
    test_network_errors
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 