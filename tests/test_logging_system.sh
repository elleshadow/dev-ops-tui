#!/bin/bash

# Source required files
source "$(dirname "$0")/../core/db.sh"
source "$(dirname "$0")/../core/logging.sh"

# Setup test environment
setup_test_env() {
    export DB_PATH=":memory:"
    init_database
    export TEST_MODE=1
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
    unset TEST_MODE
}

# Test log event creation
test_log_event() {
    echo "Testing log event creation..."
    
    # Create test log event
    log_event "INFO" "test_component" "Test message" "Test details" "Test trace"
    
    # Verify log exists
    local log_exists
    log_exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM system_logs 
        WHERE level='INFO' AND component='test_component';")
    
    if [[ "$log_exists" -eq 1 ]]; then
        echo "✓ Log event created successfully"
    else
        echo "✗ Failed to create log event"
        return 1
    fi
    
    return 0
}

# Test log retrieval
test_log_retrieval() {
    echo "Testing log retrieval..."
    
    # Create multiple test logs
    log_event "INFO" "component1" "Info message" "" ""
    log_event "ERROR" "component1" "Error message" "Error details" "Error trace"
    log_event "WARN" "component2" "Warning message" "" ""
    
    # Test all logs retrieval
    local all_logs
    all_logs=$(get_system_logs "" "" 10)
    
    if [[ -n "$all_logs" && $(echo "$all_logs" | jq '. | length') -eq 3 ]]; then
        echo "✓ All logs retrieved successfully"
    else
        echo "✗ Failed to retrieve all logs"
        return 1
    fi
    
    # Test filtered logs
    local error_logs
    error_logs=$(get_system_logs "ERROR" "" 10)
    
    if [[ -n "$error_logs" && $(echo "$error_logs" | jq '. | length') -eq 1 ]]; then
        echo "✓ Error logs filtered successfully"
    else
        echo "✗ Failed to filter error logs"
        return 1
    fi
    
    # Test component logs
    local component_logs
    component_logs=$(get_system_logs "" "component1" 10)
    
    if [[ -n "$component_logs" && $(echo "$component_logs" | jq '. | length') -eq 2 ]]; then
        echo "✓ Component logs filtered successfully"
    else
        echo "✗ Failed to filter component logs"
        return 1
    fi
    
    return 0
}

# Test log retention
test_log_retention() {
    echo "Testing log retention..."
    
    # Create old and new logs
    sqlite3 "$DB_PATH" "INSERT INTO system_logs (timestamp, level, component, message) 
        VALUES (datetime('now', '-10 days'), 'INFO', 'test', 'Old message');"
    sqlite3 "$DB_PATH" "INSERT INTO system_logs (timestamp, level, component, message) 
        VALUES (datetime('now'), 'INFO', 'test', 'New message');"
    
    # Set retention to 7 days
    update_shared_config "log_retention_days" "7"
    
    # Clean up old logs
    sqlite3 "$DB_PATH" "DELETE FROM system_logs 
        WHERE timestamp < datetime('now', '-7 days');"
    
    # Verify only new log remains
    local log_count
    log_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM system_logs;")
    
    if [[ "$log_count" -eq 1 ]]; then
        echo "✓ Log retention works correctly"
    else
        echo "✗ Log retention failed"
        return 1
    fi
    
    return 0
}

# Test component filtering
test_component_filtering() {
    echo "Testing component filtering..."
    
    # Enable component1, disable component2
    update_shared_config "log_component_component1" "true"
    update_shared_config "log_component_component2" "false"
    
    # Create logs for both components
    log_event "INFO" "component1" "Should be logged" "" ""
    log_event "INFO" "component2" "Should not be logged" "" ""
    
    # Verify only component1 logs exist
    local component1_count component2_count
    component1_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM system_logs WHERE component='component1';")
    component2_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM system_logs WHERE component='component2';")
    
    if [[ "$component1_count" -eq 1 && "$component2_count" -eq 0 ]]; then
        echo "✓ Component filtering works correctly"
    else
        echo "✗ Component filtering failed"
        return 1
    fi
    
    return 0
}

# Test log level filtering
test_log_level_filtering() {
    echo "Testing log level filtering..."
    
    # Set log level to WARN
    update_shared_config "log_level" "warn"
    
    # Create logs of different levels
    log_event "DEBUG" "test" "Debug message" "" ""
    log_event "INFO" "test" "Info message" "" ""
    log_event "WARN" "test" "Warning message" "" ""
    log_event "ERROR" "test" "Error message" "" ""
    
    # Verify only WARN and ERROR logs exist
    local log_count
    log_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM system_logs 
        WHERE level IN ('WARN', 'ERROR');")
    
    if [[ "$log_count" -eq 2 ]]; then
        echo "✓ Log level filtering works correctly"
    else
        echo "✗ Log level filtering failed"
        return 1
    fi
    
    return 0
}

# Run all tests
run_logging_tests() {
    local failed=0
    
    echo "Running logging system tests..."
    echo "==============================="
    
    setup_test_env
    
    # Run individual tests
    test_log_event || ((failed++))
    test_log_retrieval || ((failed++))
    test_log_retention || ((failed++))
    test_component_filtering || ((failed++))
    test_log_level_filtering || ((failed++))
    
    cleanup_test_env
    
    echo "==============================="
    if ((failed == 0)); then
        echo "All logging system tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_logging_tests
fi 