#!/bin/bash

# First, ensure we're in project root (dev-ops)
cd "$(dirname "$0")"

# Create full directory structure
mkdir -p {core,tui,docker,services}
mkdir -p tui/components
mkdir -p tests/{core,tui,docker,services}
mkdir -p tests/tui/components

# Create test framework
cat > tests/test_framework.sh << 'EOF'
#!/bin/bash

# Test state
CURRENT_SUITE=""
CURRENT_TEST=""
TESTS_RUN=0
TESTS_FAILED=0
TESTS_PASSED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Assert functions
assert_equals() {
    if [ "$1" = "$2" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected: $1"
        echo "    Got: $2"
    fi
}

assert_true() {
    if [ "$1" = "true" ] || [ "$1" = "0" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected true, got: $1"
    fi
}

assert_false() {
    if [ "$1" = "false" ] || [ "$1" = "1" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected false, got: $1"
    fi
}

assert_contains() {
    if echo "$1" | grep -q "$2"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected '$1' to contain '$2'"
    fi
}

assert_not_empty() {
    if [ -n "$1" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected non-empty value"
    fi
}

assert_matches() {
    if [[ "$1" =~ $2 ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected '$1' to match pattern '$2'"
    fi
}

# Run the test suite and report results
run_tests() {
    echo -e "\nTest Summary:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total:  $TESTS_RUN"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        exit 1
    fi
}
EOF

# Create empty component files
touch {core,tui,docker,services}/*.sh
touch tui/components/{menu,dialog,status}.sh

# Create a proper test runner
cat > run_tests.sh << 'EOF'
#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find and run all tests
find "$SCRIPT_DIR/tests" -name "*_test.sh" -type f | while read -r test; do
    echo "Running $test..."
    bash "$test"
done
EOF

# Make scripts executable
chmod +x tests/test_framework.sh
chmod +x run_tests.sh
find . -name "*.sh" -type f -exec chmod +x {} \;

echo "Directory structure and test framework setup complete!"
EOF