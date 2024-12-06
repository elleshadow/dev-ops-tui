#!/bin/bash

# Source test framework and components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/terminal_state.sh"
source "${SCRIPT_DIR}/tui/components/process_manager.sh"
source "${SCRIPT_DIR}/tui/components/menu_system.sh"
source "${SCRIPT_DIR}/tui/components/logging_system.sh"

describe "Performance Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_all_components
}

teardown() {
    cleanup_all_components
    unset TEST_MODE
}

# Utility Functions
measure_time() {
    local start_time end_time duration
    start_time=$(date +%s%N)
    
    "$@"
    
    end_time=$(date +%s%N)
    echo $(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
}

# Menu Performance
test_menu_performance() {
    it "should maintain menu responsiveness"
    
    # Create large menu structure
    for i in {1..50}; do
        create_menu "menu$i" "Menu $i"
        for j in {1..20}; do
            add_menu_item "menu$i" "item$j" "Item $j" "echo $j"
        done
    done
    
    # Measure navigation time
    local nav_time
    nav_time=$(measure_time navigate_menu "menu25")
    assert_less_than "$nav_time" "100" "Menu navigation should complete within 100ms"
    
    # Measure render time
    local render_time
    render_time=$(measure_time render_menu "menu25")
    assert_less_than "$render_time" "50" "Menu rendering should complete within 50ms"
}

# Process Management Performance
test_process_performance() {
    it "should handle processes efficiently"
    
    # Start multiple short processes
    local start_time
    start_time=$(measure_time start_multiple_processes 50)
    assert_less_than "$start_time" "500" "Starting 50 processes should complete within 500ms"
    
    # Monitor processes
    local monitor_time
    monitor_time=$(measure_time monitor_all_processes)
    assert_less_than "$monitor_time" "100" "Process monitoring should complete within 100ms"
}

# State Management Performance
test_state_performance() {
    it "should handle state changes efficiently"
    
    # Measure state transitions
    local transition_time
    transition_time=$(measure_time perform_state_transitions 100)
    assert_less_than "$transition_time" "200" "100 state transitions should complete within 200ms"
    
    # Measure state saves
    local save_time
    save_time=$(measure_time save_all_states)
    assert_less_than "$save_time" "50" "State saving should complete within 50ms"
}

# Logging Performance
test_logging_performance() {
    it "should maintain logging performance"
    
    # Measure logging throughput
    local log_time
    log_time=$(measure_time generate_test_logs 1000)
    assert_less_than "$log_time" "1000" "Logging 1000 entries should complete within 1 second"
    
    # Measure log rotation
    local rotation_time
    rotation_time=$(measure_time rotate_logs)
    assert_less_than "$rotation_time" "100" "Log rotation should complete within 100ms"
}

# Memory Usage
test_memory_usage() {
    it "should maintain reasonable memory usage"
    
    # Get initial memory
    local initial_memory
    initial_memory=$(get_memory_usage)
    
    # Perform memory-intensive operations
    create_large_menu_structure
    start_multiple_processes 20
    generate_test_logs 500
    
    # Get final memory
    local final_memory
    final_memory=$(get_memory_usage)
    
    # Verify memory increase is reasonable
    local memory_increase
    memory_increase=$(( final_memory - initial_memory ))
    assert_less_than "$memory_increase" "50" "Memory usage increase should be less than 50MB"
}

# CPU Usage
test_cpu_usage() {
    it "should maintain reasonable CPU usage"
    
    # Get initial CPU
    local initial_cpu
    initial_cpu=$(get_cpu_usage)
    
    # Perform CPU-intensive operations
    render_complex_menu
    process_multiple_commands 20
    rotate_all_logs
    
    # Get peak CPU
    local peak_cpu
    peak_cpu=$(get_peak_cpu_usage)
    
    # Verify CPU spike is reasonable
    assert_less_than "$peak_cpu" "80" "Peak CPU usage should be less than 80%"
}

# Disk I/O
test_disk_io() {
    it "should minimize disk operations"
    
    # Measure disk writes
    local write_count
    write_count=$(count_disk_operations write)
    assert_less_than "$write_count" "100" "Should perform less than 100 write operations"
    
    # Measure disk reads
    local read_count
    read_count=$(count_disk_operations read)
    assert_less_than "$read_count" "100" "Should perform less than 100 read operations"
}

# UI Responsiveness
test_ui_responsiveness() {
    it "should maintain UI responsiveness under load"
    
    # Start background load
    start_background_load
    
    # Measure UI operations
    local ui_time
    ui_time=$(measure_time perform_ui_operations 50)
    assert_less_than "$ui_time" "1000" "UI should remain responsive under load"
    
    # Stop background load
    stop_background_load
}

# Run all tests
run_test_suite() {
    test_menu_performance
    test_process_performance
    test_state_performance
    test_logging_performance
    test_memory_usage
    test_cpu_usage
    test_disk_io
    test_ui_responsiveness
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 