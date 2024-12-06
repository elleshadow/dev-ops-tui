#!/bin/bash

# Source test framework and components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/terminal_state.sh"
source "${SCRIPT_DIR}/tui/components/process_manager.sh"
source "${SCRIPT_DIR}/tui/components/menu_system.sh"
source "${SCRIPT_DIR}/tui/components/menu_state.sh"
source "${SCRIPT_DIR}/tui/components/logging_system.sh"

describe "Component Integration Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_terminal_state
    init_process_manager
    init_menu_system
    init_logging
}

teardown() {
    cleanup_terminal_state
    cleanup_process_manager
    cleanup_menu_system
    cleanup_logging
    unset TEST_MODE
}

# Menu and Process Integration
test_menu_process_integration() {
    it "should handle menu-triggered processes correctly"
    
    # Create menu with process command
    create_menu "process" "Process Test"
    add_menu_item "process" "start" "Start Process" "sleep 30"
    
    # Execute menu command
    navigate_menu "process"
    local pid
    pid=$(select_menu_item "start")
    
    # Verify process started
    assert_true "ps -p $pid > /dev/null"
    assert_equals "RUNNING" "$(get_process_status "$pid")"
    
    # Cleanup
    stop_managed_process "$pid"
}

# Terminal and Menu Integration
test_terminal_menu_integration() {
    it "should maintain terminal state during menu operations"
    
    # Save initial state
    local initial_mode
    initial_mode=$(get_terminal_mode)
    
    # Perform menu operations
    create_menu "terminal" "Terminal Test"
    navigate_menu "terminal"
    render_menu "terminal"
    
    # Verify terminal state maintained
    assert_equals "$initial_mode" "$(get_terminal_mode)"
    
    # Test screen transitions
    enter_alternate_screen
    render_menu "terminal"
    assert_equals "ALTERNATE" "$(get_terminal_mode)"
    
    exit_alternate_screen
    assert_equals "NORMAL" "$(get_terminal_mode)"
}

# Process and Logging Integration
test_process_logging_integration() {
    it "should log process lifecycle events"
    
    # Start process with logging
    local pid
    pid=$(start_managed_process "echo test")
    
    # Verify process logs
    assert_log_contains "Process started: $pid"
    
    # Wait for completion
    wait "$pid"
    
    # Verify completion logs
    assert_log_contains "Process completed: $pid"
}

# Menu State Recovery
test_menu_state_recovery() {
    it "should recover menu state after terminal reset"
    
    # Setup menu state
    create_menu "recovery" "Recovery Test"
    navigate_menu "recovery"
    set_menu_state "recovery" "selected" "item1"
    
    # Simulate terminal reset
    cleanup_terminal_state
    init_terminal_state
    
    # Verify menu state preserved
    assert_equals "item1" "$(get_menu_state 'recovery' 'selected')"
}

# Error Propagation
test_error_propagation() {
    it "should properly propagate errors between components"
    
    # Create menu with failing command
    create_menu "error" "Error Test"
    add_menu_item "error" "fail" "Fail Command" "nonexistent_command"
    
    # Execute failing command
    navigate_menu "error"
    select_menu_item "fail"
    
    # Verify error handling across components
    assert_equals "ERROR" "$(get_menu_error_state)"
    assert_log_contains "Command failed: nonexistent_command"
    assert_equals "NORMAL" "$(get_terminal_mode)"
}

# State Synchronization
test_state_synchronization() {
    it "should maintain synchronized state across components"
    
    # Create menu with state changes
    create_menu "sync" "Sync Test"
    add_menu_item "sync" "screen" "Change Screen" "enter_alternate_screen"
    
    # Execute state change
    navigate_menu "sync"
    select_menu_item "screen"
    
    # Verify synchronized states
    assert_equals "ALTERNATE" "$(get_terminal_mode)"
    assert_equals "sync" "$(get_current_menu)"
    assert_log_contains "Screen mode changed to ALTERNATE"
}

# Resource Cleanup
test_resource_cleanup() {
    it "should clean up resources across components"
    
    # Create test resources
    create_menu "cleanup" "Cleanup Test"
    local pid
    pid=$(start_managed_process "sleep 30")
    enter_alternate_screen
    
    # Trigger cleanup
    cleanup_all_components
    
    # Verify cleanup
    assert_false "ps -p $pid > /dev/null"
    assert_equals "NORMAL" "$(get_terminal_mode)"
    assert_false "menu_exists 'cleanup'"
}

# Performance Integration
test_performance_integration() {
    it "should maintain performance across component interactions"
    
    local start_time end_time duration
    start_time=$(date +%s%N)
    
    # Perform cross-component operations
    for _ in {1..10}; do
        # Create menu
        create_menu "perf$_" "Performance Test"
        
        # Start process
        local pid
        pid=$(start_managed_process "sleep 1")
        
        # Switch screens
        enter_alternate_screen
        render_menu "perf$_"
        exit_alternate_screen
        
        # Cleanup
        stop_managed_process "$pid"
        cleanup_menu "perf$_"
    done
    
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    assert_less_than "$duration" "5000" "Cross-component operations should complete within 5 seconds"
}

# Run all tests
run_test_suite() {
    test_menu_process_integration
    test_terminal_menu_integration
    test_process_logging_integration
    test_menu_state_recovery
    test_error_propagation
    test_state_synchronization
    test_resource_cleanup
    test_performance_integration
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 