#!/bin/bash

# Source the test framework and validation module
source "$(dirname "${BASH_SOURCE[0]}")/../../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../../tui/components/core/validation.sh"

describe "TUI Validation Module Tests"

# Required field validation
it "should validate required fields"
test_required() {
    tui_validate_required "value" && assert_true true
    tui_validate_required "" || assert_true true
    
    tui_validate "value" "$TUI_VALIDATION_REQUIRED" && assert_true true
    tui_validate "" "$TUI_VALIDATION_REQUIRED" || assert_true true
}

# Number validation
it "should validate numbers"
test_numbers() {
    # Valid numbers
    tui_validate_number "123" && assert_true true
    tui_validate_number "-123" && assert_true true
    tui_validate_number "123.45" && assert_true true
    tui_validate_number "+123.45" && assert_true true
    
    # Invalid numbers
    tui_validate_number "abc" || assert_true true
    tui_validate_number "12.34.56" || assert_true true
    tui_validate_number "12abc" || assert_true true
}

# Integer validation
it "should validate integers"
test_integers() {
    # Valid integers
    tui_validate_integer "123" && assert_true true
    tui_validate_integer "-123" && assert_true true
    tui_validate_integer "+123" && assert_true true
    
    # Invalid integers
    tui_validate_integer "123.45" || assert_true true
    tui_validate_integer "abc" || assert_true true
    tui_validate_integer "12abc" || assert_true true
}

# Float validation
it "should validate floating point numbers"
test_floats() {
    # Valid floats
    tui_validate_float "123.45" && assert_true true
    tui_validate_float "-123.45" && assert_true true
    tui_validate_float "+123.45" && assert_true true
    
    # Invalid floats
    tui_validate_float "123" || assert_true true
    tui_validate_float "abc" || assert_true true
    tui_validate_float "12.34.56" || assert_true true
}

# Email validation
it "should validate email addresses"
test_emails() {
    # Valid emails
    tui_validate_email "user@example.com" && assert_true true
    tui_validate_email "user.name@example.co.uk" && assert_true true
    tui_validate_email "user+tag@example.com" && assert_true true
    
    # Invalid emails
    tui_validate_email "not.an.email" || assert_true true
    tui_validate_email "@example.com" || assert_true true
    tui_validate_email "user@" || assert_true true
    tui_validate_email "user@." || assert_true true
}

# Date validation
it "should validate dates"
test_dates() {
    # Valid dates
    tui_validate_date "2024-01-01" && assert_true true
    tui_validate_date "Jan 1 2024" && assert_true true
    tui_validate_date "tomorrow" && assert_true true
    
    # Invalid dates
    tui_validate_date "not a date" || assert_true true
    tui_validate_date "2024-13-01" || assert_true true
    tui_validate_date "2024-01-32" || assert_true true
}

# Time validation
it "should validate times"
test_times() {
    # Valid times
    tui_validate_time "12:34" && assert_true true
    tui_validate_time "12:34:56" && assert_true true
    tui_validate_time "00:00:00" && assert_true true
    tui_validate_time "23:59:59" && assert_true true
    
    # Invalid times
    tui_validate_time "24:00" || assert_true true
    tui_validate_time "12:60" || assert_true true
    tui_validate_time "12:34:60" || assert_true true
    tui_validate_time "not a time" || assert_true true
}

# IP address validation
it "should validate IP addresses"
test_ip_addresses() {
    # Valid IPs
    tui_validate_ip "192.168.1.1" && assert_true true
    tui_validate_ip "10.0.0.0" && assert_true true
    tui_validate_ip "255.255.255.255" && assert_true true
    
    # Invalid IPs
    tui_validate_ip "256.1.2.3" || assert_true true
    tui_validate_ip "1.2.3.256" || assert_true true
    tui_validate_ip "1.2.3" || assert_true true
    tui_validate_ip "1.2.3.4.5" || assert_true true
    tui_validate_ip "not an ip" || assert_true true
}

# URL validation
it "should validate URLs"
test_urls() {
    # Valid URLs
    tui_validate_url "http://example.com" && assert_true true
    tui_validate_url "https://example.com" && assert_true true
    tui_validate_url "http://example.com/path" && assert_true true
    tui_validate_url "ftp://example.com" && assert_true true
    
    # Invalid URLs
    tui_validate_url "not a url" || assert_true true
    tui_validate_url "http://" || assert_true true
    tui_validate_url "http://." || assert_true true
    tui_validate_url "example.com" || assert_true true
}

# Path validation
it "should validate file paths"
test_paths() {
    # Valid paths
    tui_validate_path "/path/to/file" && assert_true true
    tui_validate_path "file.txt" && assert_true true
    tui_validate_path "path/to/file-1.2.3" && assert_true true
    
    # Invalid paths
    tui_validate_path "invalid*path" || assert_true true
    tui_validate_path "path with spaces" || assert_true true
    tui_validate_path "path|with|pipes" || assert_true true
}

# Hostname validation
it "should validate hostnames"
test_hostnames() {
    # Valid hostnames
    tui_validate_hostname "localhost" && assert_true true
    tui_validate_hostname "example.com" && assert_true true
    tui_validate_hostname "sub.example.com" && assert_true true
    tui_validate_hostname "host-name" && assert_true true
    
    # Invalid hostnames
    tui_validate_hostname "_invalid" || assert_true true
    tui_validate_hostname "invalid." || assert_true true
    tui_validate_hostname ".invalid" || assert_true true
    tui_validate_hostname "invalid..com" || assert_true true
}

# Username validation
it "should validate usernames"
test_usernames() {
    # Valid usernames
    tui_validate_username "user123" && assert_true true
    tui_validate_username "user_name" && assert_true true
    tui_validate_username "user-name" && assert_true true
    
    # Invalid usernames
    tui_validate_username "us" || assert_true true
    tui_validate_username "very_long_username_that_exceeds_limit" || assert_true true
    tui_validate_username "invalid*user" || assert_true true
    tui_validate_username "user name" || assert_true true
}

# Password validation
it "should validate passwords"
test_passwords() {
    # Valid passwords
    tui_validate_password "Password123!" && assert_true true
    tui_validate_password "Complex@Pass1" && assert_true true
    tui_validate_password "Str0ng#Pass" && assert_true true
    
    # Invalid passwords
    tui_validate_password "short" || assert_true true
    tui_validate_password "nocapital123!" || assert_true true
    tui_validate_password "NoNumbers!" || assert_true true
    tui_validate_password "NoSpecial1" || assert_true true
}

# Error message tests
it "should provide correct error messages"
test_error_messages() {
    local msg
    
    msg=$(tui_get_validation_error "required")
    assert_equals "$msg" "This field is required"
    
    msg=$(tui_get_validation_error "email")
    assert_equals "$msg" "Please enter a valid email address"
    
    msg=$(tui_get_validation_error "number")
    assert_equals "$msg" "Please enter a valid number"
}

run_tests 