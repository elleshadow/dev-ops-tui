#!/bin/bash

# Test state
CURRENT_SUITE=""
CURRENT_TEST=""
TESTS_RUN=0
TESTS_FAILED=0
TESTS_PASSED=0
TEST_OUTPUT=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test hooks
SETUP_FUNC=""
TEARDOWN_FUNC=""

# Initialize test environment
init_test_env() {
    TEST_OUTPUT=$(mktemp)
    if [ ! -f "$TEST_OUTPUT" ]; then
        echo "Error: Failed to create temp file"
        exit 1
    fi
}

# Cleanup test environment
cleanup_test_env() {
    [ -f "$TEST_OUTPUT" ] && rm -f "$TEST_OUTPUT"
}

# Start a test suite
describe() {
    CURRENT_SUITE="$1"
    echo -e "\nTesting: $1"
}

# Define a test case
it() {
    CURRENT_TEST="$1"
    echo -n "  - $1... "
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Set setup function
setup() {
    SETUP_FUNC="$1"
}

# Set teardown function
teardown() {
    TEARDOWN_FUNC="$1"
}

# Run a test with setup/teardown
run_test() {
    local test_func="$1"
    local output
    
    # Clear test output
    echo -n > "$TEST_OUTPUT"
    
    # Run setup if defined
    [ -n "$SETUP_FUNC" ] && $SETUP_FUNC
    
    # Run test and capture output
    output=$($test_func 2>&1)
    local result=$?
    
    # Run teardown if defined
    [ -n "$TEARDOWN_FUNC" ] && $TEARDOWN_FUNC
    
    # Return test result
    return $result
}

# Assert functions
assert_equals() {
    if [ "$1" = "$2" ]; then
        test_pass
    else
        test_fail "Expected: '$1', Got: '$2'"
    fi
}

assert_true() {
    if [ "$1" = "true" ] || [ "$1" = "0" ]; then
        test_pass
    else
        test_fail "Expected true, got: $1"
    fi
}

assert_false() {
    if [ "$1" = "false" ] || [ "$1" = "1" ]; then
        test_pass
    else
        test_fail "Expected false, got: $1"
    fi
}

assert_contains() {
    if echo "$1" | grep -q "$2"; then
        test_pass
    else
        test_fail "Expected '$1' to contain '$2'"
    fi
}

assert_not_contains() {
    if ! echo "$1" | grep -q "$2"; then
        test_pass
    else
        test_fail "Expected '$1' to not contain '$2'"
    fi
}

assert_not_empty() {
    if [ -n "$1" ]; then
        test_pass
    else
        test_fail "Expected non-empty value"
    fi
}

assert_matches() {
    if [[ "$1" =~ $2 ]]; then
        test_pass
    else
        test_fail "Expected '$1' to match pattern '$2'"
    fi
}

assert_file_exists() {
    if [ -f "$1" ]; then
        test_pass
    else
        test_fail "Expected file '$1' to exist"
    fi
}

assert_directory_exists() {
    if [ -d "$1" ]; then
        test_pass
    else
        test_fail "Expected directory '$1' to exist"
    fi
}

assert_exit_code() {
    if [ "$1" -eq "$2" ]; then
        test_pass
    else
        test_fail "Expected exit code $2, got $1"
    fi
}

# Test pass/fail helpers
test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}FAIL${NC}"
    echo "    $1"
    return 1
}

# Run the test suite and report results
run_tests() {
    # Initialize test environment
    init_test_env
    
    # Find all test functions
    local test_funcs
    test_funcs=$(declare -F | awk '{print $3}' | grep '^test_')
    
    # Run each test
    for func in $test_funcs; do
        run_test "$func"
    done
    
    # Print summary
    echo -e "\nTest Summary:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total:  $TESTS_RUN"
    
    # Cleanup test environment
    cleanup_test_env
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed${NC}"
        return 1
    fi
}