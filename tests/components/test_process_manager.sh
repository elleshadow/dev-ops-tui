#!/bin/bash

# Source test framework and component
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/process_manager.sh"

describe "Process Manager Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_process_manager
}

teardown() {
    cleanup_process_manager
    unset TEST_MODE
}

# Process Lifecycle Tests
test_process_lifecycle() {
    it "should manage process lifecycle correctly"
    
    # Start test process
    local pid
    pid=$(start_managed_process "sleep 60")
    
    # Verify process started
    assert_true "ps -p $pid > /dev/null"
    assert_equals "RUNNING" "$(get_process_status "$pid")"
    
    # Stop process
    stop_managed_process "$pid"
    
    # Verify process stopped
    assert_false "ps -p $pid > /dev/null"
    assert_equals "STOPPED" "$(get_process_status "$pid")"
}

# Resource Management Tests
test_resource_management() {
    it "should manage process resources correctly"
    
    # Start resource-intensive process
    local pid
    pid=$(start_managed_process "yes > /dev/null")
    
    # Check resource limits
    local memory_usage
    memory_usage=$(get_process_memory "$pid")
    assert_less_than "$memory_usage" "$MAX_PROCESS_MEMORY"
    
    # Stop process
    stop_managed_process "$pid"
}

# Signal Handling Tests
test_signal_handling() {
    it "should handle process signals correctly"
    
    # Start test process
    local pid
    pid=$(start_managed_process "sleep 30")
    
    # Send SIGTERM
    kill -TERM "$pid"
    sleep 1
    
    # Verify process handled signal
    assert_false "ps -p $pid > /dev/null"
    assert_equals "TERMINATED" "$(get_process_status "$pid")"
}

# Zombie Process Tests
test_zombie_prevention() {
    it "should prevent zombie processes"
    
    # Start process that creates zombie
    local parent_pid
    parent_pid=$(start_managed_process "bash -c 'sleep 1 & wait'")
    
    # Wait for parent to finish
    sleep 2
    
    # Check for zombies
    local zombie_count
    zombie_count=$(ps aux | grep -c 'Z')
    assert_equals "0" "$zombie_count"
}

# Process Group Tests
test_process_groups() {
    it "should manage process groups correctly"
    
    # Start process group
    local group_id
    group_id=$(create_process_group "test_group")
    
    # Add processes to group
    local pid1 pid2
    pid1=$(start_managed_process "sleep 30" "$group_id")
    pid2=$(start_managed_process "sleep 30" "$group_id")
    
    # Verify group
    assert_equals "2" "$(get_group_process_count "$group_id")"
    
    # Stop group
    stop_process_group "$group_id"
    
    # Verify all processes stopped
    assert_false "ps -p $pid1 > /dev/null"
    assert_false "ps -p $pid2 > /dev/null"
}

# Error Handling Tests
test_error_handling() {
    it "should handle process errors correctly"
    
    # Start failing process
    local pid
    pid=$(start_managed_process "nonexistent_command")
    
    # Verify error handling
    assert_equals "FAILED" "$(get_process_status "$pid")"
    assert_true "[ -n '$(get_process_error "$pid")' ]"
}

# Recovery Tests
test_process_recovery() {
    it "should recover from process failures"
    
    # Start process with recovery
    local pid
    pid=$(start_managed_process "sleep 30" "" "true")
    
    # Kill process
    kill -KILL "$pid"
    sleep 1
    
    # Verify recovery
    local new_pid
    new_pid=$(get_recovered_process_id "$pid")
    assert_true "[ '$new_pid' != '$pid' ]"
    assert_true "ps -p $new_pid > /dev/null"
}

# Performance Tests
test_performance() {
    it "should handle multiple processes efficiently"
    
    local start_time end_time duration
    start_time=$(date +%s%N)
    
    # Start multiple processes
    local pids=()
    for _ in {1..10}; do
        pids+=("$(start_managed_process "sleep 1")")
    done
    
    # Wait for completion
    wait_for_processes "${pids[@]}"
    
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    assert_less_than "$duration" "2000" "Multiple process operations should complete within 2 seconds"
}

# Run all tests
run_test_suite() {
    test_process_lifecycle
    test_resource_management
    test_signal_handling
    test_zombie_prevention
    test_process_groups
    test_error_handling
    test_process_recovery
    test_performance
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 