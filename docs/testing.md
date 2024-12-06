# Testing Framework

## Overview

Our testing framework provides comprehensive coverage across all components with a focus on:
- Unit Testing
- Integration Testing
- Error Scenario Testing
- Performance Testing
- State Management Testing

## Test Structure

```bash
tests/
├── core/                     # Core component tests
│   ├── terminal_state_test.sh
│   ├── process_manager_test.sh
│   ├── logging_test.sh
│   └── config_test.sh
├── workflows/               # Workflow integration tests
│   ├── docker_test.sh
│   └── git_test.sh
├── integration/            # Cross-component tests
│   ├── state_logging_test.sh
│   └── workflow_error_test.sh
└── performance/           # Performance benchmarks
    └── resource_usage_test.sh
```

## Test Categories

### 1. Unit Tests

```bash
# Example unit test for logging
test_log_levels() {
    it "should have correct log levels defined"
    assert_equals "0" "$LOG_LEVEL_DEBUG"
    assert_equals "1" "$LOG_LEVEL_INFO"
    assert_equals "2" "$LOG_LEVEL_WARN"
    assert_equals "3" "$LOG_LEVEL_ERROR"
}

# Example unit test for state management
test_state_transitions() {
    it "should handle state transitions correctly"
    init_state
    set_state "RUNNING"
    assert_equals "RUNNING" "$(get_state)"
}
```

### 2. Integration Tests

```bash
# Example workflow integration test
test_workflow_logging() {
    it "should log workflow state changes"
    
    # Initialize components
    init_workflow "docker"
    init_logging
    
    # Execute workflow
    execute_workflow_command "docker" "start" "test-container"
    
    # Verify logging
    assert_log_contains "Workflow state changed: STARTING"
    assert_log_contains "Container test-container started"
}
```

### 3. Error Scenario Tests

```bash
# Example error handling test
test_error_recovery() {
    it "should recover from workflow errors"
    
    # Force error condition
    mock_command_failure "docker start"
    
    # Execute workflow
    execute_workflow_command "docker" "start" "test-container"
    
    # Verify recovery
    assert_log_contains "Error detected: Command failed"
    assert_log_contains "Recovery initiated"
    assert_equals "RECOVERED" "$(get_workflow_state)"
}
```

### 4. Performance Tests

```bash
# Example performance test
test_resource_usage() {
    it "should maintain acceptable resource usage"
    
    # Start monitoring
    start_resource_monitor
    
    # Execute heavy operation
    for i in {1..100}; do
        execute_workflow_command "docker" "ps"
    done
    
    # Check resource usage
    local memory_usage
    memory_usage=$(get_peak_memory_usage)
    assert_less_than "$memory_usage" "100MB"
}
```

## Test Utilities

### Assertions

```bash
assert_equals() {
    local expected=$1
    local actual=$2
    local message=${3:-"Expected $expected, got $actual"}
    
    if [[ "$expected" != "$actual" ]]; then
        fail "$message"
    fi
}

assert_log_contains() {
    local pattern=$1
    local log_file=${2:-"$LOG_FILE"}
    
    if ! grep -q "$pattern" "$log_file"; then
        fail "Log does not contain: $pattern"
    fi
}
```

### Mocking

```bash
mock_command() {
    local command=$1
    local output=$2
    local exit_code=${3:-0}
    
    eval "function $command() { echo '$output'; return $exit_code; }"
}

mock_command_failure() {
    local command=$1
    mock_command "$command" "Command failed" 1
}
```

### Test Lifecycle

```bash
setup_test() {
    # Create test environment
    export TEST_MODE=1
    init_test_logging
    init_test_config
}

teardown_test() {
    # Cleanup test environment
    cleanup_test_logging
    cleanup_test_config
    unset TEST_MODE
}
```

## Running Tests

### All Tests

```bash
# Run all tests
./tests/run_all.sh

# Run with coverage
COVERAGE=1 ./tests/run_all.sh
```

### Specific Tests

```bash
# Run core tests
./tests/core/run_core_tests.sh

# Run workflow tests
./tests/workflows/run_workflow_tests.sh

# Run single test file
./tests/core/logging_test.sh
```

### Test Output

```
Running tests...
==============

Core Tests
✓ Terminal state management
✓ Process lifecycle
✓ Logging system
✓ Configuration management

Workflow Tests
✓ Docker operations
✓ Git operations
✓ Error handling

Integration Tests
✓ State-logging integration
✓ Workflow error recovery

Performance Tests
✓ Resource usage within limits
✓ Operation timing acceptable

==============
Tests: 24 passed, 0 failed
Coverage: 87%
```

## Best Practices

1. **Test Organization**
   - Group related tests together
   - Use descriptive test names
   - Follow consistent naming conventions

2. **Test Independence**
   - Each test should be self-contained
   - Clean up test environment after each test
   - Avoid test interdependencies

3. **Error Testing**
   - Test both success and failure paths
   - Verify error messages and codes
   - Test recovery mechanisms

4. **Performance Testing**
   - Set clear performance baselines
   - Test under various loads
   - Monitor resource usage

5. **Test Coverage**
   - Aim for high code coverage
   - Test edge cases
   - Include regression tests

## Adding New Tests

1. Create test file in appropriate directory
2. Source required components
3. Implement setup and teardown
4. Write test cases
5. Add to test runner

Example:
```bash
#!/bin/bash

source "$(dirname "$0")/../../test_framework.sh"
source "$(dirname "$0")/../../components/new_component.sh"

describe "New Component Tests"

setup() {
    init_test_environment
}

teardown() {
    cleanup_test_environment
}

test_new_feature() {
    it "should implement new feature correctly"
    # Test implementation
}

run_tests
``` 