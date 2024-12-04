#!/bin/bash

# Test runner script

# Set up test environment
export TEST_OUTPUT="/tmp/tui_test.log"
export DIALOGRC=/dev/null
export TERM=vt100

# Initialize test output
echo -n > "$TEST_OUTPUT"

# Run all test files
for test_file in tests/**/*_test.sh; do
    if [ -f "$test_file" ]; then
        echo "Running tests in $test_file..."
        bash "$test_file"
    fi
done

# Clean up
rm -f "$TEST_OUTPUT" 