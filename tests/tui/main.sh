#!/bin/bash

# Source the test framework and TUI main
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../tui/main.sh"

describe "TUI Framework Tests"

# Window Management
it "should create a new window with specified dimensions"
test_create_window() {
    local window
    window="$(create_window "Test Window" 80 24)"
    assert_not_empty "$window"
    assert_contains "$window" "Test Window"
}

# Screen Management
it "should clear the screen"
test_clear_screen() {
    local result
    result="$(clear_screen)"
    assert_equals "$?" "0"
}

it "should get terminal dimensions"
test_get_dimensions() {
    local dims
    dims="$(get_terminal_dimensions)"
    assert_matches "$dims" "^[0-9]+x[0-9]+$"
}

# Dialog Creation
it "should create a basic dialog box"
test_create_dialog() {
    local dialog
    dialog="$(create_dialog "Test Dialog" "This is a test" "OK" "Cancel")"
    assert_contains "$dialog" "Test Dialog"
    assert_contains "$dialog" "This is a test"
}

it "should handle dialog responses"
test_dialog_response() {
    local response
    response="$(handle_dialog_response 0)"  # Simulate OK button
    assert_equals "$response" "OK"
}

# Menu System
it "should create a menu with items"
test_create_menu() {
    local items=("Item 1" "Item 2" "Item 3")
    local menu
    menu="$(create_menu "Test Menu" items)"
    assert_contains "$menu" "Item 1"
    assert_contains "$menu" "Item 2"
    assert_contains "$menu" "Item 3"
}

it "should handle menu selection"
test_menu_selection() {
    local selection
    selection="$(handle_menu_selection 1)"  # Simulate first item selection
    assert_equals "$selection" "1"
}

# Form Management
it "should create an input form"
test_create_form() {
    local fields=("Name" "Email" "Phone")
    local form
    form="$(create_form "User Info" fields)"
    assert_contains "$form" "Name"
    assert_contains "$form" "Email"
    assert_contains "$form" "Phone"
}

# Event System
it "should register event handlers"
test_register_event() {
    register_event "test_event" "test_handler"
    local handlers
    handlers="$(list_event_handlers)"
    assert_contains "$handlers" "test_event"
}

it "should trigger events"
test_trigger_event() {
    local result
    result="$(trigger_event "test_event" "test_data")"
    assert_equals "$?" "0"
}

# State Management
it "should save UI state"
test_save_state() {
    local state="test_state"
    save_ui_state "$state"
    local saved
    saved="$(get_ui_state)"
    assert_equals "$saved" "$state"
}

# Layout Management
it "should calculate centered position"
test_center_position() {
    local pos
    pos="$(get_center_position 80 24 20 10)"
    assert_matches "$pos" "^[0-9]+,[0-9]+$"
}

# Input Handling
it "should handle keyboard input"
test_handle_input() {
    local input
    input="$(handle_keyboard_input)"
    assert_not_empty "$input"
}

it "should handle special keys"
test_special_keys() {
    local key
    key="$(parse_special_key "$(printf '\033[A')")"  # Up arrow
    assert_equals "$key" "UP"
}

# Focus Management
it "should manage focus between elements"
test_focus_management() {
    local focus
    set_focus "menu1"
    focus="$(get_current_focus)"
    assert_equals "$focus" "menu1"
}

run_tests