#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find and run all tests
find "$SCRIPT_DIR/tests" -name "*_test.sh" -type f | while read -r test; do
    echo "Running $test..."
    bash "$test"
done
