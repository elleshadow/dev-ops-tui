#!/bin/bash

# Use absolute paths for sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/core/logging.sh"

describe "Logging System Tests"

test_log_levels() {
    it "should have correct log levels defined"
    assert_equals "0" "$LOG_LEVEL_DEBUG"
    assert_equals "1" "$LOG_LEVEL_INFO"
    assert_equals "2" "$LOG_LEVEL_WARN"
    assert_equals "3" "$LOG_LEVEL_ERROR"
}

test_level_management() {
    it "should correctly set and get log level"
    local level
    set_log_level "DEBUG"
    level="$(get_log_level)"
    assert_equals "DEBUG" "$level"
}

test_message_formatting() {
    it "should format log messages correctly"
    local result
    result="$(format_log_message "TEST" "test message")"
    assert_matches "$result" "\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\].*test message"
}

test_colors() {
    it "should apply correct colors to different log levels"
    local result
    result="$(log_error "test error")"
    assert_contains "$result" "\033[0;31m"
    
    result="$(log_warn "test warning")"
    assert_contains "$result" "\033[1;33m"
    
    result="$(log_info "test info")"
    assert_contains "$result" "\033[0;32m"
}

test_level_filtering() {
    it "should respect log level settings"
    set_log_level "ERROR"
    local debug_output error_output
    
    debug_output="$(log_debug "test debug")"
    assert_equals "" "$debug_output"
    
    error_output="$(log_error "test error")"
    assert_not_empty "$error_output"
}

test_file_output() {
    it "should write logs to file when configured"
    local test_log="test.log"
    set_log_file "$test_log"
    log_info "test message"
    assert_true "[ -f '$test_log' ]"
    rm -f "$test_log"
}

test_log_rotation() {
    it "should rotate logs when size limit is reached"
    set_log_file "rotation.log"
    for i in {1..100}; do
        log_info "test message $i"
    done
    assert_true "[ -f 'rotation.log.1' ]"
    rm -f rotation.log*
}

test_context() {
    it "should support logging with context"
    local result
    set_log_context "TestContext"
    result="$(log_info "test message")"
    assert_contains "$result" "[TestContext]"
}

test_error_handling() {
    it "should catch and log errors properly"
    local result
    result="$(catch_and_log nonexistent_command 2>/dev/null)"
    assert_equals "1" "$?"
    result="$(get_last_error)"
    assert_contains "$result" "command not found"
}

# Run all tests
test_log_levels
test_level_management
test_message_formatting
test_colors
test_level_filtering
test_file_output
test_log_rotation
test_context
test_error_handling

run_tests