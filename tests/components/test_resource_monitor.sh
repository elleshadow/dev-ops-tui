#!/bin/bash

# Source test framework and component
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/resource_monitor.sh"

describe "Resource Monitor Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_resource_monitor
}

teardown() {
    cleanup_resource_monitor
    unset TEST_MODE
}

# Resource Collection Tests
test_resource_collection() {
    it "should collect system resources correctly"
    
    # Collect metrics
    collect_system_metrics
    
    # Verify CPU metrics
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    assert_matches "$cpu_usage" "^[0-9]+(\.[0-9]+)?$"
    assert_less_than "$cpu_usage" "100"
    
    # Verify memory metrics
    local memory_usage
    memory_usage=$(get_memory_usage)
    assert_matches "$memory_usage" "^[0-9]+(\.[0-9]+)?$"
    assert_less_than "$memory_usage" "100"
    
    # Verify disk metrics
    local disk_usage
    disk_usage=$(get_disk_usage "/")
    assert_matches "$disk_usage" "^[0-9]+(\.[0-9]+)?$"
    assert_less_than "$disk_usage" "100"
}

# Docker Resource Tests
test_docker_resources() {
    it "should monitor Docker resources correctly"
    
    # Skip if Docker not available
    if ! command -v docker >/dev/null 2>&1; then
        skip "Docker not available"
        return
    }
    
    # Start test container
    local container_id
    container_id=$(docker run -d nginx)
    
    # Collect container metrics
    collect_container_metrics "$container_id"
    
    # Verify container CPU
    local container_cpu
    container_cpu=$(get_container_cpu_usage "$container_id")
    assert_matches "$container_cpu" "^[0-9]+(\.[0-9]+)?$"
    
    # Verify container memory
    local container_memory
    container_memory=$(get_container_memory_usage "$container_id")
    assert_matches "$container_memory" "^[0-9]+(\.[0-9]+)?$"
    
    # Cleanup
    docker rm -f "$container_id"
}

# Alert Threshold Tests
test_alert_thresholds() {
    it "should handle alert thresholds correctly"
    
    # Set test thresholds
    set_cpu_threshold 80
    set_memory_threshold 80
    set_disk_threshold 80
    
    # Simulate high usage
    mock_resource_usage 90
    
    # Check alerts
    check_thresholds
    
    # Verify alerts
    assert_true "has_cpu_alert"
    assert_true "has_memory_alert"
    assert_true "has_disk_alert"
    
    # Reset mocks
    unmock_resource_usage
}

# Historical Data Tests
test_historical_data() {
    it "should maintain historical data correctly"
    
    # Collect multiple data points
    for _ in {1..5}; do
        collect_system_metrics
        sleep 1
    done
    
    # Verify history
    local history_size
    history_size=$(get_metric_history_size)
    assert_equals "5" "$history_size"
    
    # Verify data format
    local history_data
    history_data=$(get_metric_history)
    assert_matches "$history_data" "^[0-9,. ]+$"
}

# Data Storage Tests
test_data_storage() {
    it "should store and retrieve data correctly"
    
    # Store test data
    store_metric_data "cpu" "50.5"
    store_metric_data "memory" "60.5"
    
    # Retrieve and verify
    local cpu_data memory_data
    cpu_data=$(get_stored_metric "cpu")
    memory_data=$(get_stored_metric "memory")
    
    assert_equals "50.5" "$cpu_data"
    assert_equals "60.5" "$memory_data"
}

# Alert Handler Tests
test_alert_handlers() {
    it "should execute alert handlers correctly"
    
    # Register test handler
    local alert_triggered=false
    register_alert_handler "test" "alert_triggered=true"
    
    # Trigger alert
    trigger_resource_alert "test" "High CPU usage"
    
    # Verify handler execution
    assert_true "$alert_triggered"
}

# Resource Tracking Tests
test_resource_tracking() {
    it "should track resource trends correctly"
    
    # Simulate resource usage pattern
    local -a usage_pattern=(20 40 60 80 60 40 20)
    
    for usage in "${usage_pattern[@]}"; do
        mock_resource_usage "$usage"
        collect_system_metrics
    done
    
    # Analyze trend
    local trend
    trend=$(get_resource_trend)
    
    # Verify trend analysis
    assert_matches "$trend" "^(INCREASING|DECREASING|STABLE)$"
    
    # Reset mocks
    unmock_resource_usage
}

# Performance Tests
test_performance() {
    it "should collect metrics efficiently"
    
    local start_time end_time duration
    start_time=$(date +%s%N)
    
    # Collect metrics multiple times
    for _ in {1..10}; do
        collect_system_metrics
    done
    
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    assert_less_than "$duration" "1000" "Metric collection should complete within 1 second"
}

# Run all tests
run_test_suite() {
    test_resource_collection
    test_docker_resources
    test_alert_thresholds
    test_historical_data
    test_data_storage
    test_alert_handlers
    test_resource_tracking
    test_performance
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 