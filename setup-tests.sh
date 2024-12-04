#!/bin/bash

# Create test directory structure mirroring main structure
mkdir -p tests/{core,tui,docker,services}
mkdir -p tests/tui/components

# Create core test files
cat > tests/core/logging_test.sh << 'EOF'
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"

describe "Logging"

it "should output error messages in red"
test_error_output() {
    local output
    output=$(log_error "test error" 2>&1)
    assert_contains "$output" "ERROR"
    assert_contains "$output" "test error"
}

it "should output info messages in blue"
test_info_output() {
    local output
    output=$(log_info "test info")
    assert_contains "$output" "INFO"
    assert_contains "$output" "test info"
}

run_tests
EOF

# Create the test framework
cat > tests/test_framework.sh << 'EOF'
#!/bin/bash

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""
CURRENT_DESCRIPTION=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test framework functions
describe() {
    CURRENT_DESCRIPTION="$1"
    echo -e "\n${BLUE}Testing: $1${NC}"
}

it() {
    CURRENT_TEST="$1"
    echo -n "  - $1... "
}

assert_equals() {
    if [ "$1" = "$2" ]; then
        pass
    else
        fail "Expected: $1, Got: $2"
    fi
}

assert_contains() {
    if echo "$1" | grep -q "$2"; then
        pass
    else
        fail "Expected '$1' to contain '$2'"
    fi
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}PASS${NC}"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}FAIL${NC}"
    echo "    $1"
}

run_tests() {
    echo -e "\nTest Summary:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        exit 1
    fi
}
EOF

# Create test runner
cat > run_tests.sh << 'EOF'
#!/bin/bash

# Find and run all tests
find tests -name "*_test.sh" -type f | while read -r test; do
    echo "Running $test..."
    bash "$test"
done
EOF

# Make all scripts executable
chmod +x tests/core/*_test.sh
chmod +x tests/test_framework.sh
chmod +x run_tests.sh

echo "Test structure created successfully!"
EOF