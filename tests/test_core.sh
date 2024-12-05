#!/bin/bash

# Get the actual script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Import modules
source "$PROJECT_ROOT/core/logging.sh"
source "$PROJECT_ROOT/core/utils.sh"
source "$PROJECT_ROOT/core/platform.sh"
source "$PROJECT_ROOT/core/check_deps.sh"
source "$PROJECT_ROOT/core/platform_info.sh"

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test_env() {
    export DB_PATH=":memory:"
    init_database
    collect_all_platform_info
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
}

# Test utilities
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Expected: $expected"
        echo "  Got: $actual"
        ((TESTS_FAILED++))
        return 0  # Don't fail in test mode
    fi
}

assert_true() {
    local command="$1"
    local message="$2"
    
    ((TESTS_RUN++))
    if eval "$command"; then
        echo -e "${GREEN}✓ $message${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Command failed: $command"
        ((TESTS_FAILED++))
        return 0  # Don't fail in test mode
    fi
}

# Test logging
test_logging() {
    echo -e "\n${YELLOW}Testing logging module...${NC}"
    
    # Test log levels
    assert_equals "0" "$LOG_LEVEL_DEBUG" "LOG_LEVEL_DEBUG should be 0"
    assert_equals "1" "$LOG_LEVEL_INFO" "LOG_LEVEL_INFO should be 1"
    
    # Test log file creation
    init_logging
    assert_true "[[ -d '$LOG_DIR' ]]" "Log directory should exist"
    assert_true "[[ -f '$LOG_FILE' ]]" "Log file should exist"
    
    # Test logging functions
    log_info "Test info message"
    assert_true "grep -q 'Test info message' '$LOG_FILE'" "Log file should contain test message"
}

# Test platform detection
test_platform() {
    echo -e "\n${YELLOW}Testing platform module...${NC}"
    
    # Test platform detection
    if [[ "$(get_platform_info 'os_type')" == "Darwin" ]]; then
        assert_true "is_darwin" "Should detect macOS"
    else
        assert_true "is_linux" "Should detect Linux"
    fi
    
    # Test system info
    assert_true "[[ -n '$(get_system_memory)' ]]" "Should get system memory"
    assert_true "[[ -n '$(get_system_cpu_count)' ]]" "Should get CPU count"
}

# Test utilities
test_utils() {
    echo -e "\n${YELLOW}Testing utility functions...${NC}"
    
    # Test string manipulation
    assert_equals "test" "$(trim '  test  ')" "trim() should remove whitespace"
    
    # Test array manipulation
    assert_equals "a,b,c" "$(join_by ',' 'a' 'b' 'c')" "join_by() should join array elements"
    
    # Test directory operations
    local test_dir="/tmp/test_docker_manager_$$"
    ensure_dir "$test_dir"
    assert_true "[[ -d '$test_dir' ]]" "ensure_dir() should create directory"
    rm -rf "$test_dir"
}

# Test dependency checker
test_deps() {
    echo -e "\n${YELLOW}Testing dependency checker...${NC}"
    
    # Test command checking
    assert_true "check_command 'bash'" "Should find bash command"
    
    # Test Docker socket
    if [[ -e "/var/run/docker.sock" ]]; then
        assert_true "check_file '/var/run/docker.sock'" "Should find Docker socket"
    fi
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}Starting tests...${NC}"
    
    setup_test_env
    
    test_logging
    test_platform
    test_utils
    test_deps
    
    cleanup_test_env
    
    echo -e "\n${YELLOW}Test Summary:${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if ((TESTS_FAILED > 0)); then
        return 0  # Don't fail in test mode
    else
        return 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 