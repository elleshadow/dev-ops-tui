#!/bin/bash

# Source the test framework and menu component
source "$(dirname "${BASH_SOURCE[0]}")/../../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../tui/components/menu.sh"

describe "Menu Component Tests"

# Basic Menu Creation
it "should create a simple menu"
test_simple_menu() {
    local menu
    menu="$(create_menu "Test Menu" "Option 1" "Option 2" "Option 3")"
    assert_contains "$menu" "Test Menu"
    assert_contains "$menu" "Option 1"
    assert_matches "$menu" "\[.\] Option 1"  # Should show selection marker
}

# Menu Types
it "should create a radio menu"
test_radio_menu() {
    local menu
    menu="$(create_radio_menu "Choose One" "Red" "Green" "Blue")"
    assert_contains "$menu" "Choose One"
    assert_matches "$menu" "\(.\) Red"  # Should show radio button
}

it "should create a checkbox menu"
test_checkbox_menu() {
    local menu
    menu="$(create_checkbox_menu "Select Multiple" "Apple" "Banana" "Orange")"
    assert_contains "$menu" "Select Multiple"
    assert_matches "$menu" "\[.\] Apple"  # Should show checkbox
}

# Menu Styling
it "should apply custom menu style"
test_menu_style() {
    set_menu_style "border" "double"
    local menu
    menu="$(create_menu "Styled Menu" "Option 1")"
    assert_contains "$menu" "╔"  # Should use double border
}

# Menu Selection
it "should handle menu selection"
test_menu_selection() {
    create_menu "Test Menu" "Option 1" "Option 2"
    local selection
    selection="$(select_menu_item 1)"
    assert_equals "$selection" "Option 1"
}

# Multi-Selection
it "should handle multiple selections in checkbox menu"
test_multi_selection() {
    create_checkbox_menu "Test" "Item 1" "Item 2" "Item 3"
    toggle_menu_item 0
    toggle_menu_item 2
    local selections
    selections="$(get_selected_items)"
    assert_contains "$selections" "Item 1"
    assert_contains "$selections" "Item 3"
}

# Menu Navigation
it "should navigate menu with keyboard"
test_menu_navigation() {
    create_menu "Test" "Item 1" "Item 2"
    send_key "DOWN"
    local highlighted
    highlighted="$(get_highlighted_item)"
    assert_equals "$highlighted" "Item 2"
}

# Submenus
it "should create and handle submenus"
test_submenu() {
    local menu
    menu="$(create_submenu "Main" "Sub 1" "Item 1" "Item 2")"
    assert_contains "$menu" "Main"
    assert_contains "$menu" "Sub 1"
    assert_contains "$menu" "►"  # Submenu indicator
}

# Menu Events
it "should trigger menu selection event"
test_menu_event() {
    local event_fired=false
    on_menu_select() { event_fired=true; }
    create_menu "Test" "Item 1"
    select_menu_item 0
    assert_equals "$event_fired" "true"
}

# Menu State
it "should save and restore menu state"
test_menu_state() {
    create_menu "Test" "Item 1" "Item 2"
    select_menu_item 1
    local state
    state="$(save_menu_state)"
    clear_menu
    restore_menu_state "$state"
    local selected
    selected="$(get_selected_item)"
    assert_equals "$selected" "Item 2"
}

# Menu Shortcuts
it "should handle menu shortcuts"
test_menu_shortcuts() {
    create_menu "Test" "^F File" "^E Edit" "^Q Quit"
    local action
    action="$(handle_menu_shortcut "F")"
    assert_equals "$action" "File"
}

# Dynamic Menus
it "should update menu items dynamically"
test_dynamic_menu() {
    create_menu "Test" "Item 1"
    add_menu_item "Item 2"
    remove_menu_item "Item 1"
    local items
    items="$(get_menu_items)"
    assert_not_contains "$items" "Item 1"
    assert_contains "$items" "Item 2"
}

# Menu Scrolling
it "should handle scrolling for long menus"
test_menu_scrolling() {
    local items=()
    for i in {1..20}; do
        items+=("Item $i")
    done
    local menu
    menu="$(create_scrollable_menu "Long Menu" "${items[@]}")"
    assert_contains "$menu" "..."  # Scrolling indicator
}

run_tests