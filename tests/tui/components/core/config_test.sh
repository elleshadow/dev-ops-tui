#!/bin/bash

# Source the test framework and config module
source "$(dirname "${BASH_SOURCE[0]}")/../../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../../tui/components/core/config.sh"

describe "TUI Configuration Module Tests"

# Default settings tests
it "should have correct default settings"
test_default_settings() {
    assert_equals "$TUI_DIALOG_HEIGHT" "0"
    assert_equals "$TUI_DIALOG_WIDTH" "0"
    assert_equals "$TUI_DIALOG_BACKTITLE" ""
    assert_equals "$TUI_DIALOG_TITLE" ""
    assert_equals "$TUI_DIALOG_COLORS" "false"
    assert_equals "$TUI_DIALOG_ASCII_LINES" "false"
    assert_equals "$TUI_DIALOG_NO_SHADOW" "false"
    assert_equals "$TUI_DIALOG_NO_MOUSE" "false"
    assert_equals "$TUI_DIALOG_TAB_CORRECT" "false"
    assert_equals "$TUI_DIALOG_TAB_LEN" "8"
}

# Dialog defaults tests
it "should set dialog defaults"
test_set_defaults() {
    tui_set_dialog_defaults 20 80 "Test Title"
    assert_equals "$TUI_DIALOG_HEIGHT" "20"
    assert_equals "$TUI_DIALOG_WIDTH" "80"
    assert_equals "$TUI_DIALOG_BACKTITLE" "Test Title"
}

# Dialog options tests
it "should generate correct dialog options"
test_dialog_options() {
    # Reset to defaults
    tui_reset_config
    
    # Test with no options enabled
    local options
    options=$(tui_get_dialog_options)
    assert_equals "$options" ""
    
    # Test with colors enabled
    TUI_DIALOG_COLORS=true
    options=$(tui_get_dialog_options)
    assert_contains "$options" "--colors"
    
    # Test with multiple options
    TUI_DIALOG_ASCII_LINES=true
    TUI_DIALOG_NO_SHADOW=true
    options=$(tui_get_dialog_options)
    assert_contains "$options" "--colors"
    assert_contains "$options" "--ascii-lines"
    assert_contains "$options" "--no-shadow"
    
    # Test with titles
    TUI_DIALOG_BACKTITLE="Back Title"
    TUI_DIALOG_TITLE="Main Title"
    options=$(tui_get_dialog_options)
    assert_contains "$options" '--backtitle "Back Title"'
    assert_contains "$options" '--title "Main Title"'
}

# Configuration file tests
it "should save and load configuration"
test_config_file() {
    local config_file
    config_file=$(mktemp)
    
    # Set some non-default values
    TUI_DIALOG_HEIGHT=25
    TUI_DIALOG_WIDTH=100
    TUI_DIALOG_BACKTITLE="Test Back"
    TUI_DIALOG_COLORS=true
    TUI_DIALOG_NO_SHADOW=true
    
    # Save configuration
    tui_save_config "$config_file"
    assert_equals "$?" "$TUI_OK"
    
    # Reset to defaults
    tui_reset_config
    
    # Load saved configuration
    tui_load_config "$config_file"
    assert_equals "$?" "$TUI_OK"
    
    # Verify loaded values
    assert_equals "$TUI_DIALOG_HEIGHT" "25"
    assert_equals "$TUI_DIALOG_WIDTH" "100"
    assert_equals "$TUI_DIALOG_BACKTITLE" "Test Back"
    assert_equals "$TUI_DIALOG_COLORS" "true"
    assert_equals "$TUI_DIALOG_NO_SHADOW" "true"
    
    # Clean up
    rm -f "$config_file"
}

# Configuration reset tests
it "should reset configuration to defaults"
test_config_reset() {
    # Set some non-default values
    TUI_DIALOG_HEIGHT=30
    TUI_DIALOG_WIDTH=120
    TUI_DIALOG_COLORS=true
    TUI_DIALOG_NO_SHADOW=true
    
    # Reset configuration
    tui_reset_config
    
    # Verify defaults
    assert_equals "$TUI_DIALOG_HEIGHT" "0"
    assert_equals "$TUI_DIALOG_WIDTH" "0"
    assert_equals "$TUI_DIALOG_COLORS" "false"
    assert_equals "$TUI_DIALOG_NO_SHADOW" "false"
}

# Error handling tests
it "should handle configuration errors"
test_config_errors() {
    # Test loading non-existent file
    tui_load_config "/nonexistent/file" >/dev/null 2>&1
    assert_equals "$?" "$TUI_ERROR"
    
    # Test loading invalid file
    local invalid_file
    invalid_file=$(mktemp)
    echo "invalid=config=file" > "$invalid_file"
    tui_load_config "$invalid_file" >/dev/null 2>&1
    assert_equals "$?" "$TUI_ERROR"
    rm -f "$invalid_file"
}

run_tests 