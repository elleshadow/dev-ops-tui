#!/bin/bash

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"
LOG_FILE="$TEST_DIR/test_output.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test configuration
MAX_TEST_DURATION=30  # Maximum duration for each test in seconds
TIMEOUT_EXIT_CODE=124

# Set test mode and environment
export TEST_MODE=1
export DB_PATH="$(mktemp)"
export TERM=dumb

# Source core functions
source "$PROJECT_ROOT/core/db.sh"

# Logging function
log() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Initialize test environment
setup_test_env() {
    log "Setting up test environment..."
    init_database
    
    # Set up test credentials
    save_auth_credentials "test_admin" "test_password"
    
    # Set up test platform info
    save_platform_info "test_os" "test_value" "Test OS" "system"
}

# Run a single test file with timeout
run_test() {
    local test_file="$1"
    local test_name="$2"
    local is_critical="$3"
    
    log -e "\n${YELLOW}Running $test_name...${NC}"
    
    # Initialize fresh database for each test
    init_database
    
    # Create a temporary file for test output
    local temp_output=$(mktemp)
    
    # Run the test with timeout
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: Use perl-based timeout
        perl -e '
            eval {
                local $SIG{ALRM} = sub { die "timeout\n" };
                alarm '$MAX_TEST_DURATION';
                system("TEST_MODE=1 bash \"$ARGV[0]\"");
                alarm 0;
            };
            if ($@ eq "timeout\n") {
                exit '$TIMEOUT_EXIT_CODE';
            }
            exit $? >> 8;
        ' "$test_file" > "$temp_output" 2>&1
    else
        # Linux: Use timeout command
        timeout "$MAX_TEST_DURATION" bash "$test_file" > "$temp_output" 2>&1
    fi
    
    local exit_code=$?
    
    # Check for timeout
    if [[ $exit_code -eq $TIMEOUT_EXIT_CODE ]]; then
        log -e "${RED}✗ $test_name timed out after $MAX_TEST_DURATION seconds${NC}"
        log "Last output before timeout:"
        tail -n 10 "$temp_output" | tee -a "$LOG_FILE"
        rm -f "$temp_output"
        if [[ "$is_critical" == "true" ]]; then
            log -e "${RED}Critical test failed - stopping test suite${NC}"
            exit 1
        fi
        return 1
    fi
    
    # Check test result
    if [[ $exit_code -eq 0 ]]; then
        log -e "${GREEN}✓ $test_name passed${NC}"
        cat "$temp_output" >> "$LOG_FILE"
        rm -f "$temp_output"
        return 0
    else
        log -e "${RED}✗ $test_name failed (exit code: $exit_code)${NC}"
        log "Test output:"
        cat "$temp_output" | tee -a "$LOG_FILE"
        rm -f "$temp_output"
        if [[ "$is_critical" == "true" ]]; then
            log -e "${RED}Critical test failed - stopping test suite${NC}"
            exit 1
        fi
        return 1
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    # Kill any remaining test processes
    pkill -f "test_.*\.sh" || true
    
    # Remove temporary files
    rm -f /tmp/test_* || true
    rm -f "$DB_PATH" || true
    
    exit $exit_code
}

# Main test runner
main() {
    # Set up cleanup trap
    trap cleanup EXIT INT TERM
    
    # Clear log file
    > "$LOG_FILE"
    
    log "Starting test suite..."
    log "===================="
    
    # Set up initial test environment
    setup_test_env
    
    local failed=0
    local total=0
    local passed=0
    local skipped=0
    
    # Define test order with dependencies
    declare -A test_files=(
        # Critical foundational tests that must pass
        ["test_core.sh"]="true"      # Core functionality
        ["test_db.sh"]="true"        # Database operations
        ["test_platform_info.sh"]="true"  # Platform information
        
        # Feature tests that depend on core functionality
        ["test_auth_db.sh"]="false"
        ["test_auth_ui.sh"]="false"
        ["test_service_auth.sh"]="false"
        ["test_config_db.sh"]="false"
        ["test_config_ui.sh"]="false"
        ["test_config_integration.sh"]="false"
        ["test_dialog_integration.sh"]="false"
        ["test_docker_management.sh"]="false"
        ["test_proxy.sh"]="false"
        ["test_logging_system.sh"]="false"
        ["test_results_system.sh"]="false"
    )
    
    # Run each test file in order
    for test_file in "${!test_files[@]}"; do
        ((total++))
        
        # Check if test file exists
        if [[ ! -f "$TEST_DIR/$test_file" ]]; then
            log -e "${YELLOW}⚠ Skipping $test_file (file not found)${NC}"
            ((skipped++))
            continue
        fi
        
        # Check if test file is executable
        if [[ ! -x "$TEST_DIR/$test_file" ]]; then
            log -e "${YELLOW}⚠ Making $test_file executable${NC}"
            chmod +x "$TEST_DIR/$test_file"
        fi
        
        test_name=$(basename "$test_file" .sh)
        is_critical="${test_files[$test_file]}"
        
        if run_test "$TEST_DIR/$test_file" "$test_name" "$is_critical"; then
            ((passed++))
        else
            ((failed++))
            # If a critical test fails, the run_test function will exit
            # Otherwise, continue with the next test
        fi
    done
    
    log "\nTest Summary"
    log "===================="
    log "Total tests: $total"
    log -e "${GREEN}Passed: $passed${NC}"
    log -e "${RED}Failed: $failed${NC}"
    log -e "${YELLOW}Skipped: $skipped${NC}"
    
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cd "$PROJECT_ROOT"
    main "$@"
fi 