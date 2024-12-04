#!/bin/bash

# Source the test framework and status component
source "$(dirname "${BASH_SOURCE[0]}")/../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../tui/components/status.sh"

describe "Status Component Tests"

# Status Bar
it "should create status bar"
test_status_bar() {
    local status
    status="$(create_status_bar)"
    assert_not_empty "$status"
    assert_matches "$status" "^[-]+$"  # Should show empty bar
}

# Status Message
it "should set status message"
test_status_message() {
    create_status_bar
    set_status_message "Ready"
    local message
    message="$(get_status_message)"
    assert_equals "$message" "Ready"
}

# Status Types
it "should handle different status types"
test_status_types() {
    create_status_bar
    
    set_error_status "Error occurred"
    local error_status
    error_status="$(get_status_message)"
    assert_contains "$error_status" "Error occurred"
    assert_contains "$error_status" "\033[31m"  # Red color
    
    set_warning_status "Warning message"
    local warning_status
    warning_status="$(get_status_message)"
    assert_contains "$warning_status" "Warning message"
    assert_contains "$warning_status" "\033[33m"  # Yellow color
    
    set_success_status "Operation complete"
    local success_status
    success_status="$(get_status_message)"
    assert_contains "$success_status" "Operation complete"
    assert_contains "$success_status" "\033[32m"  # Green color
}

# Progress Indicator
it "should show progress in status bar"
test_status_progress() {
    create_status_bar
    set_status_progress 50 "Loading..."
    local status
    status="$(get_status_content)"
    assert_contains "$status" "50%"
    assert_contains "$status" "Loading..."
}

# Multiple Fields
it "should handle multiple status fields"
test_status_fields() {
    create_status_bar
    add_status_field "User" "admin"
    add_status_field "Mode" "edit"
    local status
    status="$(get_status_content)"
    assert_contains "$status" "User: admin"
    assert_contains "$status" "Mode: edit"
}

# Status Updates
it "should handle status updates"
test_status_updates() {
    create_status_bar
    start_status_updates
    update_status "Processing item 1"
    local status
    status="$(get_status_message)"
    assert_equals "$status" "Processing item 1"
}

# Status History
it "should maintain status history"
test_status_history() {
    create_status_bar
    set_status_message "First message"
    set_status_message "Second message"
    local history
    history="$(get_status_history)"
    assert_contains "$history" "First message"
    assert_contains "$history" "Second message"
}

# Status Bar Positioning
it "should position status bar correctly"
test_status_position() {
    create_status_bar_at 23  # Last line of standard terminal
    local position
    position="$(get_status_position)"
    assert_equals "$position" "23"
}

# Status Bar Events
it "should trigger status events"
test_status_events() {
    local event_fired=false
    on_status_change() { event_fired=true; }
    create_status_bar
    set_status_message "New status"
    assert_equals "$event_fired" "true"
}

# Status Bar Style
it "should apply status bar style"
test_status_style() {
    set_status_style "double"
    local status
    status="$(create_status_bar)"
    assert_contains "$status" "═"  # Double line character
}

# Status Bar Sections
it "should handle status bar sections"
test_status_sections() {
    create_status_bar
    add_status_section "left" "Left content"
    add_status_section "center" "Center content"
    add_status_section "right" "Right content"
    local status
    status="$(get_status_content)"
    assert_contains "$status" "Left content"
    assert_contains "$status" "Center content"
    assert_contains "$status" "Right content"
}

run_tests