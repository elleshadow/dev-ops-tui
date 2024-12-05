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

# Test test run creation
test_run_creation() {
    echo "Testing test run creation..."
    
    # Start test run
    local run_id
    run_id=$(start_test_run)
    
    # Verify run exists
    local run_exists
    run_exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM test_runs WHERE run_id='$run_id';")
    
    if [[ "$run_exists" -eq 1 ]]; then
        echo "✓ Test run created successfully"
    else
        echo "✗ Failed to create test run"
        return 1
    fi
    
    return 0
}

# Test result recording
test_result_recording() {
    echo "Testing result recording..."
    
    # Create test run
    local run_id
    run_id=$(start_test_run)
    
    # Record test results
    record_test_result "$run_id" "test_suite" "test_case" "PASS" 100 "" ""
    record_test_result "$run_id" "test_suite" "failed_test" "FAIL" 50 "Test error" "Error trace"
    
    # Verify results
    local result_count
    result_count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM test_results WHERE run_id='$run_id';")
    
    if [[ "$result_count" -eq 2 ]]; then
        echo "✓ Test results recorded successfully"
    else
        echo "✗ Failed to record test results"
        return 1
    fi
    
    # Verify result details
    local failed_test
    failed_test=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM test_results 
        WHERE run_id='$run_id' AND status='FAIL' AND error_message='Test error';")
    
    if [[ "$failed_test" -eq 1 ]]; then
        echo "✓ Test result details recorded correctly"
    else
        echo "✗ Failed to record test result details"
        return 1
    fi
    
    return 0
}

# Test run completion
test_run_completion() {
    echo "Testing run completion..."
    
    # Create and complete test run
    local run_id
    run_id=$(start_test_run)
    
    record_test_result "$run_id" "suite1" "test1" "PASS" 100 "" ""
    record_test_result "$run_id" "suite1" "test2" "FAIL" 50 "Error" ""
    record_test_result "$run_id" "suite2" "test3" "PASS" 75 "" ""
    
    complete_test_run "$run_id" 3 2 1 225
    
    # Verify completion
    local completed_run
    completed_run=$(sqlite3 "$DB_PATH" "SELECT json_object(
        'total', total_tests,
        'passed', passed_tests,
        'failed', failed_tests,
        'duration', duration_ms
    ) FROM test_runs WHERE run_id='$run_id';")
    
    if [[ -n "$completed_run" ]]; then
        local total passed failed duration
        total=$(echo "$completed_run" | jq -r '.total')
        passed=$(echo "$completed_run" | jq -r '.passed')
        failed=$(echo "$completed_run" | jq -r '.failed')
        duration=$(echo "$completed_run" | jq -r '.duration')
        
        if [[ "$total" -eq 3 && "$passed" -eq 2 && "$failed" -eq 1 && "$duration" -eq 225 ]]; then
            echo "✓ Test run completed successfully"
        else
            echo "✗ Test run completion data incorrect"
            return 1
        fi
    else
        echo "✗ Failed to complete test run"
        return 1
    fi
    
    return 0
}

# Test coverage recording
test_coverage_recording() {
    echo "Testing coverage recording..."
    
    # Create test run
    local run_id
    run_id=$(start_test_run)
    
    # Record coverage
    record_test_coverage "$run_id" "test_file.sh" 100 80 80.0 "20,21,35-40"
    
    # Verify coverage
    local coverage
    coverage=$(sqlite3 "$DB_PATH" "SELECT json_object(
        'total', total_lines,
        'covered', covered_lines,
        'percent', coverage_percent,
        'uncovered', uncovered_lines
    ) FROM test_coverage WHERE run_id='$run_id';")
    
    if [[ -n "$coverage" ]]; then
        local total covered percent uncovered
        total=$(echo "$coverage" | jq -r '.total')
        covered=$(echo "$coverage" | jq -r '.covered')
        percent=$(echo "$coverage" | jq -r '.percent')
        uncovered=$(echo "$coverage" | jq -r '.uncovered')
        
        if [[ "$total" -eq 100 && "$covered" -eq 80 && 
              "$percent" == "80.0" && "$uncovered" == "20,21,35-40" ]]; then
            echo "✓ Coverage recorded successfully"
        else
            echo "✗ Coverage data incorrect"
            return 1
        fi
    else
        echo "✗ Failed to record coverage"
        return 1
    fi
    
    return 0
}

# Test result retrieval
test_result_retrieval() {
    echo "Testing result retrieval..."
    
    # Create test run with results
    local run_id
    run_id=$(start_test_run)
    
    record_test_result "$run_id" "suite1" "test1" "PASS" 100 "" ""
    record_test_result "$run_id" "suite1" "test2" "FAIL" 50 "Error" "Trace"
    complete_test_run "$run_id" 2 1 1 150
    
    # Get test run summary
    local summary
    summary=$(get_test_run_summary "$run_id")
    
    if [[ -n "$summary" && $(echo "$summary" | jq -r '.total_tests') -eq 2 ]]; then
        echo "✓ Test summary retrieved successfully"
    else
        echo "✗ Failed to retrieve test summary"
        return 1
    fi
    
    # Get test results
    local results
    results=$(get_test_results "$run_id")
    
    if [[ -n "$results" && $(echo "$results" | jq '. | length') -eq 2 ]]; then
        echo "✓ Test results retrieved successfully"
    else
        echo "✗ Failed to retrieve test results"
        return 1
    fi
    
    return 0
}

# Run all tests
run_test_results_tests() {
    local failed=0
    
    echo "Running test results system tests..."
    echo "==================================="
    
    setup_test_env
    
    # Run individual tests
    test_run_creation || ((failed++))
    test_result_recording || ((failed++))
    test_run_completion || ((failed++))
    test_coverage_recording || ((failed++))
    test_result_retrieval || ((failed++))
    
    cleanup_test_env
    
    echo "==================================="
    if ((failed == 0)); then
        echo "All test results system tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_results_tests
fi 