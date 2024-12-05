#!/bin/bash

# Source required files
source "$(dirname "$0")/../core/db.sh"

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    ((TESTS_RUN++))
    echo -n "Testing $test_name... "
    
    if eval "$test_cmd"; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
    fi
}

# Initialize test environment
setup_test_env() {
    echo "Setting up test environment..."
    init_database
}

# Clean up test environment
cleanup() {
    rm -f "$DB_PATH"
}

# Start tests
echo "Running auth database tests..."
echo "==============================="

# Set up test environment
setup_test_env

# Test auth schema
run_test "auth schema creation" '
    tables=$(sqlite3 "$DB_PATH" ".tables") &&
    echo "$tables" | grep -q "auth_config"
'

# Test credential management
run_test "credential management" '
    save_auth_credentials "test_user" "test_pass" &&
    verify_credentials "test_user" "test_pass"
'

# Test first run detection
run_test "first run detection" '
    rm -f "$DB_PATH" &&
    init_database &&
    check_first_run &&
    save_auth_credentials "test_user" "test_pass" &&
    ! check_first_run
'

# Test credential retrieval
run_test "credential retrieval" '
    save_auth_credentials "test_user" "test_pass" &&
    creds=$(get_auth_credentials) &&
    echo "$creds" | grep -q "test_user"
'

# Clean up
cleanup

echo "==============================="
echo "Failed tests: $((TESTS_RUN - TESTS_PASSED))"

# Exit with status
[[ $TESTS_PASSED -eq $TESTS_RUN ]] 