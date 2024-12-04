#!/bin/bash

# Source the database functions
source "$(dirname "$0")/../core/db.sh"

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    ((TESTS_RUN++))
    echo -n "Testing $test_name... "
    
    if eval "$test_cmd"; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
    fi
}

# Clean up before tests
cleanup() {
    rm -f "$DB_PATH"
    init_database
}

# Start tests
echo "Starting database tests..."
cleanup

# Test configuration functions
run_test "set_config" '
    set_config "test_key" "test_value" &&
    [[ $(get_config "test_key") == "test_value" ]]
'

run_test "update_config" '
    set_config "test_key" "new_value" &&
    [[ $(get_config "test_key") == "new_value" ]]
'

run_test "delete_config" '
    delete_config "test_key" &&
    [[ -z $(get_config "test_key") ]]
'

# Test container configuration functions
run_test "save_container_config" '
    save_container_config "test-container" "nginx" "{\"port\": 80}" "enabled" &&
    container_exists "test-container"
'

run_test "get_container_config" '
    [[ $(get_container_config "test-container") == "{\"port\": 80}" ]]
'

run_test "update_container_status" '
    update_container_status "test-container" "disabled" &&
    [[ $(get_containers_by_status "disabled") == "test-container|nginx|disabled" ]]
'

run_test "delete_container_config" '
    delete_container_config "test-container" &&
    ! container_exists "test-container"
'

# Test menu state functions
run_test "save_menu_state" '
    save_menu_state "main_menu" 2 &&
    [[ $(get_menu_state) == "main_menu|2" ]]
'

# Test multiple configurations
run_test "multiple_configs" '
    set_config "key1" "value1" &&
    set_config "key2" "value2" &&
    count=$(get_all_configs | grep -c "value") &&
    [[ $count -eq 2 ]]
'

# Test database stats
run_test "database_stats" '
    stats=$(get_db_stats) &&
    [[ -n "$stats" ]]
'

# Test database backup
run_test "database_backup" '
    mkdir -p test_backups &&
    backup_database "test_backups" &&
    count=$(ls test_backups/config_*.db 2>/dev/null | wc -l) &&
    [[ $count -eq 1 ]]
'

# Clean up after tests
cleanup
rm -rf test_backups

# Print test results
echo "----------------------------------------"
echo "Tests completed: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"
echo "----------------------------------------"

# Exit with appropriate status
[[ $TESTS_PASSED -eq $TESTS_RUN ]] 