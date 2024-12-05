#!/bin/bash

# Get the actual script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Import modules
source "$PROJECT_ROOT/core/db.sh"
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

assert_not_empty() {
    local value="$1"
    local message="$2"
    
    ((TESTS_RUN++))
    if [[ -n "$value" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Value is empty"
        ((TESTS_FAILED++))
        return 0  # Don't fail in test mode
    fi
}

assert_matches() {
    local pattern="$1"
    local value="$2"
    local message="$3"
    
    ((TESTS_RUN++))
    if [[ "$value" =~ $pattern ]]; then
        echo -e "${GREEN}✓ $message${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        echo "  Value '$value' does not match pattern '$pattern'"
        ((TESTS_FAILED++))
        return 0  # Don't fail in test mode
    fi
}

# Setup test environment
setup_test_env() {
    export TEST_MODE=1
    export DB_PATH=":memory:"
    init_database
}

# Cleanup test environment
cleanup_test_env() {
    unset TEST_MODE
    unset DB_PATH
}

# Test OS information collection
test_os_info() {
    echo -e "\n${YELLOW}Testing OS information collection...${NC}"
    
    # Collect OS info with error handling
    if ! collect_os_info; then
        echo -e "${RED}✗ Failed to collect OS information${NC}"
        return 1
    fi
    
    # Test basic OS information
    local os_type=$(get_platform_info 'os_type')
    assert_not_empty "$os_type" "Should collect OS type"
    assert_matches "^(Darwin|Linux)$" "$os_type" "OS type should be Darwin or Linux"
    
    local os_version=$(get_platform_info 'os_version')
    assert_not_empty "$os_version" "Should collect OS version"
    
    local os_machine=$(get_platform_info 'os_machine')
    assert_not_empty "$os_machine" "Should collect machine architecture"
    assert_matches "^(x86_64|arm64|aarch64)$" "$os_machine" "Machine architecture should be valid"
}

# Test Docker information collection
test_docker_info() {
    echo -e "\n${YELLOW}Testing Docker information collection...${NC}"
    
    # Only test Docker info if Docker is available
    if command -v docker >/dev/null 2>&1; then
        if ! collect_docker_info; then
            echo -e "${RED}✗ Failed to collect Docker information${NC}"
            return 1
        fi
        
        local docker_version=$(get_platform_info 'docker_version')
        assert_not_empty "$docker_version" "Should collect Docker version"
        assert_matches "^[0-9]+\.[0-9]+\.[0-9]+.*$" "$docker_version" "Docker version should be semver"
        
        local docker_api_version=$(get_platform_info 'docker_api_version')
        assert_not_empty "$docker_api_version" "Should collect Docker API version"
        assert_matches "^[0-9]+\.[0-9]+$" "$docker_api_version" "Docker API version should be valid"
    else
        echo -e "${YELLOW}⚠ Docker not installed, skipping Docker tests${NC}"
    fi
}

# Test hardware information collection
test_hardware_info() {
    echo -e "\n${YELLOW}Testing hardware information collection...${NC}"
    
    if ! collect_hardware_info; then
        echo -e "${RED}✗ Failed to collect hardware information${NC}"
        return 1
    fi
    
    local cpu_cores=$(get_platform_info 'cpu_cores')
    assert_not_empty "$cpu_cores" "Should collect CPU core count"
    assert_matches "^[0-9]+$" "$cpu_cores" "CPU cores should be a number"
    
    local memory_total=$(get_platform_info 'memory_total')
    assert_not_empty "$memory_total" "Should collect total memory"
    assert_matches "^[0-9]+$" "$memory_total" "Total memory should be a number"
}

# Test network information collection
test_network_info() {
    echo -e "\n${YELLOW}Testing network information collection...${NC}"
    
    if ! collect_network_info; then
        echo -e "${RED}✗ Failed to collect network information${NC}"
        return 1
    fi
    
    local default_interface=$(get_platform_info 'default_interface')
    assert_not_empty "$default_interface" "Should collect default interface"
    
    local ip_address=$(get_platform_info 'ip_address')
    assert_not_empty "$ip_address" "Should collect IP address"
    assert_matches "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" "$ip_address" "IP address should be valid IPv4"
}

# Test category listing
test_categories() {
    echo -e "\n${YELLOW}Testing category listing...${NC}"
    
    if ! collect_all_platform_info; then
        echo -e "${RED}✗ Failed to collect all platform information${NC}"
        return 1
    fi
    
    local categories
    categories=$(list_platform_categories)
    
    assert_true "[[ '$categories' == *'system'* ]]" "Should have system category"
    assert_true "[[ '$categories' == *'hardware'* ]]" "Should have hardware category"
    assert_true "[[ '$categories' == *'network'* ]]" "Should have network category"
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}Starting platform information tests...${NC}"
    
    setup_test_env
    
    # Run each test in a subshell to prevent contamination
    (test_os_info)
    (test_docker_info)
    (test_hardware_info)
    (test_network_info)
    (test_categories)
    
    cleanup_test_env
    
    echo -e "\n${YELLOW}Test Summary:${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if ((TESTS_FAILED > 0)); then
        return 1
    else
        return 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 