#!/bin/bash

# Get the test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Source the main script
source "$PROJECT_ROOT/tui/main.sh"

# Test utilities
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✓ $message"
    else
        echo "✗ $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

# Mock dialog command
mock_dialog() {
    echo "mock_result"
    return 0
}

# Test dialog availability
test_dialog_availability() {
    echo "Testing dialog availability..."
    
    if ! command -v dialog >/dev/null 2>&1; then
        echo "✗ Dialog command not available"
        echo "  Please install dialog package"
        return 1
    fi
    
    echo "✓ Dialog command is available"
}

# Test menu generation
test_menu_generation() {
    echo "Testing menu generation..."
    
    # Mock dialog command
    dialog() {
        mock_dialog "$@"
    }
    
    # Test deploy services menu
    local result
    result=$(deploy_services)
    assert_equals "mock_result" "$result" "Deploy services menu should work with mocked dialog"
    
    # Test manage services menu
    result=$(manage_services)
    assert_equals "mock_result" "$result" "Manage services menu should work with mocked dialog"
}

# Test dialog error handling
test_dialog_error_handling() {
    echo "Testing dialog error handling..."
    
    # Mock dialog with error
    dialog() {
        return 1
    }
    
    # Test error handling in deploy services
    local result
    result=$(deploy_services)
    assert_equals "" "$result" "Deploy services should handle dialog errors gracefully"
    
    # Test error handling in manage services
    result=$(manage_services)
    assert_equals "" "$result" "Manage services should handle dialog errors gracefully"
}

# Test checklist generation
test_checklist_generation() {
    echo "Testing checklist generation..."
    
    # Mock dialog with selection
    dialog() {
        echo "nginx prometheus grafana"
        return 0
    }
    
    # Test service selection
    local result
    result=$(select_services)
    assert_equals "nginx prometheus grafana" "$result" "Service selection should return selected services"
}

# Run all tests
run_tests() {
    echo "Running dialog integration tests..."
    
    test_dialog_availability
    test_menu_generation
    test_dialog_error_handling
    test_checklist_generation
    
    echo "Tests completed."
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 