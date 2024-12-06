#!/bin/bash

# Source test framework and components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/menu_system.sh"
source "${SCRIPT_DIR}/tui/components/menu_state.sh"

describe "Menu System Tests"

# Setup and teardown
setup() {
    export TEST_MODE=1
    init_menu_system
}

teardown() {
    cleanup_menu_system
    unset TEST_MODE
}

# Menu Creation Tests
test_menu_creation() {
    it "should create menus correctly"
    
    # Create test menu
    create_menu "main" "Main Menu"
    add_menu_item "main" "option1" "Option 1" "command1"
    add_menu_item "main" "option2" "Option 2" "command2"
    
    # Verify menu structure
    assert_true "menu_exists 'main'"
    assert_equals "2" "$(get_menu_item_count 'main')"
    assert_equals "Main Menu" "$(get_menu_title 'main')"
}

# Menu Navigation Tests
test_menu_navigation() {
    it "should handle menu navigation correctly"
    
    # Create nested menus
    create_menu "main" "Main Menu"
    create_menu "sub" "Sub Menu"
    add_menu_item "main" "sub" "Sub Menu" "navigate_menu sub"
    
    # Navigate to submenu
    navigate_menu "main"
    assert_equals "main" "$(get_current_menu)"
    
    select_menu_item "sub"
    assert_equals "sub" "$(get_current_menu)"
    
    # Navigate back
    navigate_back
    assert_equals "main" "$(get_current_menu)"
}

# Menu State Tests
test_menu_state() {
    it "should maintain menu state correctly"
    
    # Create menu with state
    create_menu "test" "Test Menu"
    add_menu_item "test" "item1" "Item 1" "command1"
    
    # Set and verify state
    set_menu_state "test" "selected" "item1"
    assert_equals "item1" "$(get_menu_state 'test' 'selected')"
    
    # Clear state
    clear_menu_state "test"
    assert_equals "" "$(get_menu_state 'test' 'selected')"
}

# Menu Rendering Tests
test_menu_rendering() {
    it "should render menus correctly"
    
    # Create test menu
    create_menu "render" "Render Test"
    add_menu_item "render" "item1" "Item 1" "command1"
    add_menu_item "render" "item2" "Item 2" "command2"
    
    # Get rendered output
    local output
    output=$(render_menu "render")
    
    # Verify rendering
    assert_contains "$output" "Render Test"
    assert_contains "$output" "Item 1"
    assert_contains "$output" "Item 2"
}

# Menu Selection Tests
test_menu_selection() {
    it "should handle item selection correctly"
    
    # Create menu with items
    create_menu "select" "Selection Test"
    add_menu_item "select" "item1" "Item 1" "echo selected1"
    add_menu_item "select" "item2" "Item 2" "echo selected2"
    
    # Select item
    local output
    output=$(select_menu_item "item1")
    
    # Verify selection
    assert_equals "selected1" "$output"
    assert_equals "item1" "$(get_selected_item)"
}

# Menu Validation Tests
test_menu_validation() {
    it "should validate menu operations correctly"
    
    # Test invalid menu
    assert_false "menu_exists 'nonexistent'"
    assert_false "add_menu_item 'nonexistent' 'item' 'Item' 'command'"
    
    # Test duplicate menu
    create_menu "duplicate" "Duplicate Test"
    assert_false "create_menu 'duplicate' 'Duplicate Test'"
}

# Error Handling Tests
test_error_handling() {
    it "should handle menu errors correctly"
    
    # Test invalid navigation
    navigate_menu "nonexistent"
    assert_equals "ERROR" "$(get_menu_error_state)"
    
    # Test invalid selection
    select_menu_item "nonexistent"
    assert_equals "ERROR" "$(get_menu_error_state)"
    
    # Test recovery
    clear_menu_error_state
    assert_equals "" "$(get_menu_error_state)"
}

# Performance Tests
test_performance() {
    it "should handle menu operations efficiently"
    
    local start_time end_time duration
    start_time=$(date +%s%N)
    
    # Create large menu
    create_menu "perf" "Performance Test"
    for i in {1..100}; do
        add_menu_item "perf" "item$i" "Item $i" "echo $i"
    done
    
    # Perform operations
    navigate_menu "perf"
    render_menu "perf"
    
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    assert_less_than "$duration" "1000" "Menu operations should complete within 1 second"
}

# Run all tests
run_test_suite() {
    test_menu_creation
    test_menu_navigation
    test_menu_state
    test_menu_rendering
    test_menu_selection
    test_menu_validation
    test_error_handling
    test_performance
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite
fi 