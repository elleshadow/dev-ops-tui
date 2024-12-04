#!/bin/bash

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"

# Test state
export TEST_OUTPUT="/tmp/tui_demo_test.log"
DIALOG_RESPONSE=""
DIALOG_EXIT_CODE=0

# Prevent dialog from clearing screen
export DIALOGRC=/dev/null
export TERM=vt100

# Mock dialog command
dialog() {
    echo "DIALOG: $*" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

# Mock TUI functions
tui_dialog_message() {
    local title="$1"
    local message="$2"
    echo "MESSAGE: $title: $message" >> "$TEST_OUTPUT"
    return $DIALOG_EXIT_CODE
}

tui_dialog_menu() {
    local title="$1"
    local message="$2"
    shift 4
    echo "MENU: $title: $message: $*" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

tui_dialog_yesno() {
    local title="$1"
    local message="$2"
    echo "YESNO: $title: $message" >> "$TEST_OUTPUT"
    return $DIALOG_EXIT_CODE
}

tui_dialog_input() {
    local title="$1"
    local message="$2"
    echo "INPUT: $title: $message" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

tui_dialog_password() {
    local title="$1"
    local message="$2"
    echo "PASSWORD: $title: $message" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

tui_dialog_form() {
    local title="$1"
    local message="$2"
    shift 4
    echo "FORM: $title: $message: $*" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

tui_dialog_validated_form() {
    local title="$1"
    local message="$2"
    shift 4
    echo "VALIDATED_FORM: $title: $message: $*" >> "$TEST_OUTPUT"
    [ -n "$DIALOG_RESPONSE" ] && echo "$DIALOG_RESPONSE"
    return $DIALOG_EXIT_CODE
}

# Setup and teardown
setup() {
    echo -n > "$TEST_OUTPUT"
    DIALOG_RESPONSE=""
    DIALOG_EXIT_CODE=0
}

teardown() {
    :  # No cleanup needed
}

# Source the demo after mocks are in place
source "$(dirname "${BASH_SOURCE[0]}")/../../demo/tui_demo.sh"

# Test cases
describe "TUI Demo"

it "should show welcome screen"
test_welcome() {
    show_welcome
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Welcome to the TUI Demo Application"
}

it "should show main menu with all sections"
test_main_menu() {
    DIALOG_RESPONSE="quit"
    main_menu
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Basic Dialogs"
    assert_contains "$output" "Input & Forms"
    assert_contains "$output" "Menus & Selection"
    assert_contains "$output" "File Operations"
    assert_contains "$output" "Progress Indicators"
    assert_contains "$output" "Calendar & Time"
    assert_contains "$output" "Input Validation"
}

it "should handle basic dialogs"
test_basic_dialogs() {
    # Test message box
    DIALOG_RESPONSE="message"
    demo_basic_dialogs
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Message Demo"
    
    # Test yes/no dialog
    DIALOG_RESPONSE="yesno"
    DIALOG_EXIT_CODE=0  # Simulate "Yes"
    demo_basic_dialogs
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Question"
    
    # Test error dialog
    DIALOG_RESPONSE="error"
    demo_basic_dialogs
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Error Demo"
}

it "should handle input forms"
test_input_forms() {
    # Test simple input
    DIALOG_RESPONSE="John Doe"
    demo_input_forms
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Input Demo"
    
    # Test password input
    DIALOG_RESPONSE="secret"
    demo_input_forms
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Password Demo"
    
    # Test form input
    DIALOG_RESPONSE="test@example.com"
    demo_input_forms
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "User Info"
}

it "should handle menu navigation"
test_menu_navigation() {
    # Test simple menu
    DIALOG_RESPONSE="simple"
    demo_menus
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Simple Menu"
    
    # Test nested menu
    DIALOG_RESPONSE="nested"
    demo_menus
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Settings"
}

it "should handle file operations"
test_file_operations() {
    # Test file creation
    DIALOG_RESPONSE="test.txt"
    demo_file_operations
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Create File"
    
    # Test file editing
    DIALOG_RESPONSE="test.txt"
    demo_file_operations
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Edit File"
}

it "should handle progress indicators"
test_progress() {
    DIALOG_RESPONSE="simple"
    demo_progress
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Progress"
}

it "should handle calendar and time"
test_calendar_time() {
    DIALOG_RESPONSE="2024-01-01"
    demo_calendar_time
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Date"
}

it "should handle input validation"
test_validation() {
    # Test email validation
    DIALOG_RESPONSE="test@example.com"
    demo_validation
    local output
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Email"
    
    # Test number validation
    DIALOG_RESPONSE="123"
    demo_validation
    output=$(cat "$TEST_OUTPUT")
    assert_contains "$output" "Number"
}

# Run all tests
run_tests 