#!/bin/bash

# Source the test framework and dialog component
source "$(dirname "${BASH_SOURCE[0]}")/../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../tui/components/dialog.sh"

describe "Dialog Component Tests"

# Basic Dialog Types
it "should create a message box"
test_message_box() {
    local dialog
    dialog="$(create_msgbox "Info" "Test message")"
    assert_contains "$dialog" "Info"
    assert_contains "$dialog" "Test message"
    assert_contains "$dialog" "[OK]"
}

it "should create a yes/no box"
test_yesno_box() {
    local dialog
    dialog="$(create_yesno "Question" "Proceed?")"
    assert_contains "$dialog" "Question"
    assert_contains "$dialog" "[Yes]"
    assert_contains "$dialog" "[No]"
}

it "should create an input box"
test_input_box() {
    local dialog
    dialog="$(create_inputbox "Name" "Enter your name:" "default")"
    assert_contains "$dialog" "Name"
    assert_contains "$dialog" "default"
}

# Selection Dialogs
it "should create a menu box"
test_menu_box() {
    local items=("1" "Option 1" "2" "Option 2")
    local dialog
    dialog="$(create_menu "Choose" "Select an option:" items)"
    assert_contains "$dialog" "Option 1"
    assert_contains "$dialog" "Option 2"
}

it "should create a checklist"
test_checklist() {
    local items=("1" "Option 1" "off" "2" "Option 2" "on")
    local dialog
    dialog="$(create_checklist "Multiple" "Select items:" items)"
    assert_contains "$dialog" "[X]"
    assert_contains "$dialog" "[ ]"
}

it "should create a radiolist"
test_radiolist() {
    local items=("1" "Red" "off" "2" "Green" "on" "3" "Blue" "off")
    local dialog
    dialog="$(create_radiolist "Color" "Choose color:" items)"
    assert_contains "$dialog" "(X)"
    assert_contains "$dialog" "( )"
}

# File Operations
it "should create a file selection dialog"
test_file_select() {
    local dialog
    dialog="$(create_fselect "/tmp" "Select file:")"
    assert_contains "$dialog" "Directory:"
    assert_contains "$dialog" "Files:"
}

it "should create a directory selection dialog"
test_dir_select() {
    local dialog
    dialog="$(create_dselect "/home" "Select directory:")"
    assert_contains "$dialog" "Directory:"
}

# Progress Indicators
it "should create a gauge"
test_gauge() {
    local dialog
    dialog="$(create_gauge "Progress" "Processing..." 50)"
    assert_contains "$dialog" "Progress"
    assert_contains "$dialog" "50%"
}

it "should create a progress box"
test_progress_box() {
    local dialog
    dialog="$(create_progressbox "Status" "Running...")"
    assert_contains "$dialog" "Status"
}

# Forms and Text
it "should create a form"
test_form() {
    local fields=("Name:" 1 1 "" 1 20 20 0
                 "Email:" 2 1 "" 2 20 30 0)
    local dialog
    dialog="$(create_form "User Info" "Enter details:" fields)"
    assert_contains "$dialog" "Name:"
    assert_contains "$dialog" "Email:"
}

it "should create a password box"
test_password_box() {
    local dialog
    dialog="$(create_passwordbox "Password" "Enter password:")"
    assert_contains "$dialog" "Password"
    assert_contains "$dialog" "*"  # Password mask
}

# Calendar and Time
it "should create a calendar dialog"
test_calendar() {
    local dialog
    dialog="$(create_calendar "Date" "Select date:" "2024" "1" "1")"
    assert_contains "$dialog" "January"
    assert_contains "$dialog" "2024"
}

it "should create a timebox"
test_timebox() {
    local dialog
    dialog="$(create_timebox "Time" "Select time:" "12" "00" "00")"
    assert_contains "$dialog" "Hour"
    assert_contains "$dialog" "Minute"
}

# Advanced Features
it "should create a buildlist"
test_buildlist() {
    local items=("1" "Item 1" "off" "2" "Item 2" "on")
    local dialog
    dialog="$(create_buildlist "Build" "Select items:" items)"
    assert_contains "$dialog" "Available"
    assert_contains "$dialog" "Selected"
}

it "should create a tree view"
test_treeview() {
    local items=("1" "Root" "0" "2" "Child" "1")
    local dialog
    dialog="$(create_treeview "Tree" "Select item:" items)"
    assert_contains "$dialog" "Root"
    assert_contains "$dialog" "Child"
}

# Dialog Behavior
it "should handle dialog exit codes"
test_exit_codes() {
    create_msgbox "Test" "Message"
    local code=$?
    assert_equals "$code" "0"  # OK button
}

it "should support dialog dimensions"
test_dimensions() {
    local dialog
    dialog="$(create_msgbox "Test" "Message" 10 40)"
    # Add assertions for box dimensions
    assert_not_empty "$dialog"
}

it "should support dialog colors"
test_colors() {
    set_dialog_colors "blue" "white" "black"
    local dialog
    dialog="$(create_msgbox "Test" "Message")"
    assert_contains "$dialog" "\033["  # ANSI color codes
}

run_tests