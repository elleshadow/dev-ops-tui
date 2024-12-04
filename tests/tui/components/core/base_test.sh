#!/bin/bash

# Source the test framework and base module
source "$(dirname "${BASH_SOURCE[0]}")/../../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../../tui/components/core/base.sh"

describe "TUI Base Module Tests"

# Version tests
it "should have correct version"
test_version() {
    local version
    version=$(tui_version)
    assert_contains "$version" "TUI Library version"
}

# Terminal size tests
it "should get terminal dimensions"
test_terminal_size() {
    tui_update_dimensions
    assert_true "[ $TUI_TERM_ROWS -gt 0 ]"
    assert_true "[ $TUI_TERM_COLS -gt 0 ]"
}

# Dialog dimension tests
it "should calculate dialog dimensions"
test_dialog_dimensions() {
    local dims
    dims=$(tui_calculate_dimensions 10 40)
    assert_matches "$dims" "^[0-9]+ [0-9]+$"
    
    # Test minimum size
    dims=$(tui_calculate_dimensions 1 1 10 20)
    read height width <<< "$dims"
    assert_true "[ $height -ge 10 ]"
    assert_true "[ $width -ge 20 ]"
    
    # Test maximum size
    dims=$(tui_calculate_dimensions 1000 1000)
    read height width <<< "$dims"
    assert_true "[ $height -le $TUI_TERM_ROWS ]"
    assert_true "[ $width -le $TUI_TERM_COLS ]"
}

# Dialog positioning tests
it "should calculate centered position"
test_dialog_position() {
    local pos
    pos=$(tui_center_position 10 40)
    assert_matches "$pos" "^[0-9]+ [0-9]+$"
    
    read row col <<< "$pos"
    assert_true "[ $row -ge 0 ]"
    assert_true "[ $col -ge 0 ]"
}

# Error handling tests
it "should handle errors correctly"
test_error_handling() {
    local output
    output=$(tui_error "Test error" 2>&1)
    assert_contains "$output" "ERROR: Test error"
    
    local ret
    tui_error "Test error" >/dev/null 2>&1
    ret=$?
    assert_equals "$ret" "$TUI_ERROR"
}

# Debug logging tests
it "should handle debug logging"
test_debug_logging() {
    # Test with debug disabled
    local output
    output=$(TUI_DEBUG=0 tui_debug "Test debug" 2>&1)
    assert_equals "$output" ""
    
    # Test with debug enabled
    output=$(TUI_DEBUG=1 tui_debug "Test debug" 2>&1)
    assert_contains "$output" "DEBUG: Test debug"
}

# Dependency check tests
it "should check dependencies"
test_dependencies() {
    # Test with dialog installed
    if command -v dialog >/dev/null 2>&1; then
        tui_check_dependencies
        assert_equals "$?" "$TUI_OK"
    else
        tui_check_dependencies >/dev/null 2>&1
        assert_equals "$?" "$TUI_ERROR"
    fi
}

# Terminal capability tests
it "should detect terminal capabilities"
test_terminal_capabilities() {
    assert_true "[ $TUI_HAS_COLORS -ge 0 ]"
    assert_true "[ $TUI_HAS_UNICODE -ge 0 ]"
}

run_tests 