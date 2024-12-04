#!/bin/bash

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/utils.sh"

describe "Utils Tests"

# Command utilities
it "should check if commands exist"
test_command_exists() {
    assert_true "$(command_exists ls)"
    assert_false "$(command_exists nonexistentcommand123)"
}

# File operations
it "should safely create directories"
test_safe_mkdir() {
    local test_dir="test_dir"
    assert_true "$(safe_mkdir "$test_dir")"
    assert_true "[ -d '$test_dir' ]"
    rm -rf "$test_dir"
}

it "should safely remove files"
test_safe_remove() {
    local test_file="test_file"
    touch "$test_file"
    assert_true "$(safe_remove "$test_file")"
    assert_false "[ -f '$test_file' ]"
}

# String manipulation
it "should trim whitespace from strings"
test_trim() {
    assert_equals "$(trim "  hello  ")" "hello"
    assert_equals "$(trim " hello world ")" "hello world"
}

it "should check if string contains substring"
test_string_contains() {
    assert_true "$(string_contains "hello world" "world")"
    assert_false "$(string_contains "hello world" "goodbye")"
}

# Array manipulation
it "should join array elements"
test_array_join() {
    local arr=("hello" "world")
    assert_equals "$(array_join "," "${arr[@]}")" "hello,world"
}

it "should check if array contains element"
test_array_contains() {
    local arr=("apple" "banana" "orange")
    assert_true "$(array_contains "banana" "${arr[@]}")"
    assert_false "$(array_contains "grape" "${arr[@]}")"
}

# Validation utilities
it "should validate email addresses"
test_validate_email() {
    assert_true "$(validate_email "test@example.com")"
    assert_false "$(validate_email "invalid-email")"
}

it "should validate IP addresses"
test_validate_ip() {
    assert_true "$(validate_ip "192.168.1.1")"
    assert_false "$(validate_ip "256.256.256.256")"
}

# Error handling
it "should catch and return error messages"
test_catch_error() {
    local result
    result="$(catch_error "ls nonexistentfile")"
    assert_not_empty "$result"
}

it "should provide stacktrace on errors"
test_stacktrace() {
    local trace
    trace="$(get_stacktrace)"
    assert_contains "$trace" "line"
    assert_contains "$trace" "function"
}

# Time utilities
it "should format timestamps"
test_timestamp() {
    local ts
    ts="$(get_timestamp)"
    assert_matches "$ts" "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
}

it "should calculate time differences"
test_time_diff() {
    local start="2023-01-01 00:00:00"
    local end="2023-01-01 01:00:00"
    assert_equals "$(time_diff "$start" "$end")" "3600"
}

# Environment utilities
it "should get environment variables safely"
test_get_env() {
    export TEST_VAR="test_value"
    assert_equals "$(get_env "TEST_VAR" "default")" "test_value"
    assert_equals "$(get_env "NONEXISTENT_VAR" "default")" "default"
    unset TEST_VAR
}

# Temp file management
it "should create and cleanup temp files"
test_temp_file() {
    local temp_file
    temp_file="$(create_temp_file)"
    assert_true "[ -f '$temp_file' ]"
    cleanup_temp_file "$temp_file"
    assert_false "[ -f '$temp_file' ]"
}

run_tests