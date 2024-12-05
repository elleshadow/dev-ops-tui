#!/bin/bash

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function with redirect following
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_status="$3"
    
    ((TESTS_RUN++))
    echo -e "\nTesting ${YELLOW}$test_name${NC}..."
    
    # First try without following redirects
    echo "Without following redirects:"
    curl -v $test_cmd 2>&1 | grep -E "< HTTP|Location:"
    
    echo -e "\nWith following redirects (-L):"
    local status_code=$(curl -L -s -o /dev/null -w "%{http_code}" $test_cmd)
    curl -L -v $test_cmd 2>&1 | grep -E "< HTTP|Location:"
    
    if [[ "$status_code" == "$expected_status" ]]; then
        echo -e "\n${GREEN}PASSED${NC} (Final Status: $status_code)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "\n${RED}FAILED${NC} (Expected: $expected_status, Got: $status_code)"
        return 1
    fi
}

# Test function with response body check
run_test_content() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_pattern="$3"
    
    ((TESTS_RUN++))
    echo -e "\nTesting ${YELLOW}$test_name${NC}..."
    
    local response=$(curl -L -s $test_cmd)
    local status_code=$(curl -L -s -o /dev/null -w "%{http_code}" $test_cmd)
    
    echo "Status code: $status_code"
    if echo "$response" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}PASSED${NC} (Pattern found)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAILED${NC} (Pattern not found: $expected_pattern)"
        echo "Response excerpt:"
        echo "$response" | head -n 5
        return 1
    fi
}

echo "Starting proxy tests..."

# Test main dashboard
run_test "Dashboard root" \
    "http://localhost/" \
    "200"

run_test_content "Dashboard content" \
    "http://localhost/" \
    "ShadowLab Services"

# Test Grafana
run_test "Grafana root" \
    "http://localhost/grafana/" \
    "200"

run_test_content "Grafana login page" \
    "http://localhost/grafana/" \
    "login"

# Test Prometheus
run_test "Prometheus root" \
    "http://localhost/prometheus/" \
    "200"

run_test_content "Prometheus content" \
    "http://localhost/prometheus/" \
    "Prometheus"

# Test Prometheus graph endpoint
run_test "Prometheus graph endpoint" \
    "http://localhost/prometheus/graph" \
    "200"

# Test service health
echo -e "\nTesting service health..."

# Test Grafana health
run_test "Grafana direct health" \
    "http://localhost:3000/api/health" \
    "200"

# Test Prometheus health
run_test "Prometheus direct health" \
    "http://localhost:9090/-/healthy" \
    "200"

# Print test results
echo -e "\nTests completed: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"

# Exit with status
[[ $TESTS_PASSED -eq $TESTS_RUN ]] 