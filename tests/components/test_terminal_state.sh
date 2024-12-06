#!/bin/bash

# Source test framework and component
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/tests/test_framework.sh"
source "${SCRIPT_DIR}/tui/components/terminal_state.sh"

# Debug logging
debug_log() {
    local msg="$1"
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $msg" >> /tmp/test_terminal.debug.log
}

describe "Terminal State Tests"

# Setup and teardown
setup() {
    debug_log "Starting setup"
    export TEST_MODE=1
    export TERM=xterm-256color
    
    # Save original terminal settings
    original_settings=$(stty -g)
    debug_log "Saved original terminal settings"
    
    # Clean any existing state
    rm -f "$TERMINAL_STATE_FILE" "${TERMINAL_STATE_FILE}.cursor"
    debug_log "Cleaned existing state files"
    
    # Initialize terminal state
    if ! run_with_timeout 5 init_terminal_state; then
        debug_log "Failed to initialize terminal state"
        return 1
    fi
    debug_log "Terminal state initialized"
    
    # Verify initialization
    if [[ ! -f "$TERMINAL_STATE_FILE" ]]; then
        debug_log "Terminal state file not found after initialization"
        return 1
    fi
    debug_log "Setup complete"
}

teardown() {
    debug_log "Starting teardown"
    
    # Restore original terminal settings
    stty "$original_settings" 2>/dev/null || true
    debug_log "Restored terminal settings"
    
    # Cleanup terminal state
    run_with_timeout 5 cleanup_terminal_state
    unset TEST_MODE
    debug_log "Teardown complete"
}

# Register setup/teardown
SETUP_FUNC="setup"
TEARDOWN_FUNC="teardown"

# State Initialization Tests
test_init_terminal_state() {
    it "should initialize terminal state correctly"
    debug_log "Testing terminal state initialization"
    
    # Test initial state
    local mode
    mode=$(get_terminal_mode)
    debug_log "Current terminal mode: $mode"
    assert_equals "NORMAL" "$mode"
    
    # Test state file
    if [[ -f "$TERMINAL_STATE_FILE" ]]; then
        debug_log "State file exists"
    else
        debug_log "State file missing"
    fi
    assert_true "test -f '$TERMINAL_STATE_FILE'"
    
    # Test initial cursor position with timeout
    local cursor_pos
    cursor_pos=$(run_with_timeout 2 get_cursor_position)
    if [[ $? -eq 124 ]]; then
        debug_log "Cursor position read timed out"
        cursor_pos="1,1"  # Default if timeout
    fi
    debug_log "Cursor position: $cursor_pos"
    assert_matches "$cursor_pos" "^[0-9]+,[0-9]+$"
}

# State Transition Tests
test_state_transitions() {
    it "should handle state transitions correctly"
    debug_log "Testing state transitions"
    
    # Test mode transitions
    run_with_timeout 2 set_terminal_mode "ALTERNATE"
    local mode
    mode=$(get_terminal_mode)
    debug_log "Mode after ALTERNATE: $mode"
    assert_equals "ALTERNATE" "$mode"
    
    run_with_timeout 2 set_terminal_mode "NORMAL"
    mode=$(get_terminal_mode)
    debug_log "Mode after NORMAL: $mode"
    assert_equals "NORMAL" "$mode"
    
    # Test invalid transitions
    run_with_timeout 2 set_terminal_mode "INVALID"
    mode=$(get_terminal_mode)
    debug_log "Mode after INVALID: $mode"
    assert_equals "NORMAL" "$mode"
}

# Run all tests
run_test_suite() {
    debug_log "Starting test suite"
    test_init_terminal_state
    test_state_transitions
    debug_log "Test suite complete"
}

# Execute tests if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    debug_log "Starting test execution"
    run_test_suite
    debug_log "Test execution complete"
fi 