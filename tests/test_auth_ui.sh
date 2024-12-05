#!/bin/bash

# Source required files
source "$(dirname "$0")/../tui/components/auth.sh"
source "$(dirname "$0")/../core/logging.sh"

# Mock dialog command
dialog() {
    case "$2" in
        "--inputbox")
            echo "testuser"
            return 0
            ;;
        "--passwordbox")
            echo "testpass123"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Mock logging
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Setup test environment
setup_test_env() {
    export DB_PATH=":memory:"
    init_database
    export -f dialog
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
    unset -f dialog
}

# Test setup credentials
test_setup_credentials() {
    echo "Testing setup credentials..."
    
    if setup_credentials; then
        echo "✓ Setup credentials completed successfully"
        
        # Verify credentials were saved
        local saved_user
        saved_user=$(sqlite3 "$DB_PATH" "SELECT username FROM auth_config WHERE username='testuser';")
        
        if [[ "$saved_user" == "testuser" ]]; then
            echo "✓ Credentials saved correctly"
            return 0
        else
            echo "✗ Credentials not saved"
            return 1
        fi
    else
        echo "✗ Setup credentials failed"
        return 1
    fi
}

# Test login dialog
test_login_dialog() {
    echo "Testing login dialog..."
    
    # First setup test credentials
    setup_credentials
    
    if login_dialog; then
        echo "✓ Login dialog completed successfully"
        return 0
    else
        echo "✗ Login dialog failed"
        return 1
    fi
}

# Test handle auth
test_handle_auth() {
    echo "Testing handle auth..."
    
    # Test first run
    if handle_auth; then
        echo "✓ First run auth handled successfully"
    else
        echo "✗ First run auth failed"
        return 1
    fi
    
    # Test subsequent login
    if handle_auth; then
        echo "✓ Subsequent login handled successfully"
    else
        echo "✗ Subsequent login failed"
        return 1
    fi
    
    return 0
}

# Test failed login
test_failed_login() {
    echo "Testing failed login..."
    
    # Override dialog mock for wrong password
    dialog() {
        case "$2" in
            "--inputbox")
                echo "testuser"
                return 0
                ;;
            "--passwordbox")
                echo "wrongpass"
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    export -f dialog
    
    # Setup credentials first
    setup_credentials
    
    # Try login with wrong password
    if login_dialog; then
        echo "✗ Login succeeded with wrong password"
        return 1
    else
        echo "✓ Login failed correctly with wrong password"
    fi
    
    return 0
}

# Run all tests
run_auth_ui_tests() {
    local failed=0
    
    echo "Running auth UI tests..."
    echo "========================"
    
    setup_test_env
    
    # Run individual tests
    test_setup_credentials || ((failed++))
    test_login_dialog || ((failed++))
    test_handle_auth || ((failed++))
    test_failed_login || ((failed++))
    
    cleanup_test_env
    
    echo "========================"
    if ((failed == 0)); then
        echo "All auth UI tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_auth_ui_tests
fi 