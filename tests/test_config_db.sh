#!/bin/bash

# Source required files
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

# Initialize test environment
setup_test_env() {
    echo "Setting up test environment..."
    init_database
    
    # Set up test services
    save_container_config "nginx" "nginx:latest" "{}" "enabled"
    save_container_config "postgres" "postgres:13" "{}" "enabled"
    save_container_config "redis" "redis:latest" "{}" "disabled"
}

# Clean up test environment
cleanup() {
    rm -f "$DB_PATH"
}

# Start tests
echo "Running configuration database tests..."
echo "======================================"

# Set up test environment
setup_test_env

# Test service configuration schema
run_test "service configuration schema" '
    tables=$(sqlite3 "$DB_PATH" ".tables") &&
    for table in service_config port_config volume_config env_config service_dependencies shared_config; do
        echo "$tables" | grep -q "$table" || {
            echo "Missing table: $table"
            return 1
        }
    done
'

# Test default configurations
run_test "default configurations" '
    count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM service_config;") &&
    [[ $count -eq 3 ]]
'

# Test service configuration management
run_test "service configuration management" '
    save_container_config "test-service" "test:latest" "{\"memory\": \"512m\"}" "enabled" &&
    config=$(get_container_config "test-service") &&
    [[ "$config" == "{\"memory\": \"512m\"}" ]]
'

# Test port configuration
run_test "port configuration" '
    sqlite3 "$DB_PATH" "INSERT INTO port_config (service_name, host_port, container_port) VALUES (\"nginx\", 80, 80);" &&
    port=$(sqlite3 "$DB_PATH" "SELECT host_port FROM port_config WHERE service_name=\"nginx\";") &&
    [[ "$port" == "80" ]]
'

# Test volume configuration
run_test "volume configuration" '
    sqlite3 "$DB_PATH" "INSERT INTO volume_config (service_name, host_path, container_path) VALUES (\"postgres\", \"/data/postgres\", \"/var/lib/postgresql/data\");" &&
    path=$(sqlite3 "$DB_PATH" "SELECT container_path FROM volume_config WHERE service_name=\"postgres\";") &&
    [[ "$path" == "/var/lib/postgresql/data" ]]
'

# Test environment variable configuration
run_test "environment variable configuration" '
    sqlite3 "$DB_PATH" "INSERT INTO env_config (service_name, env_key, env_value) VALUES (\"postgres\", \"POSTGRES_PASSWORD\", \"secret\");" &&
    value=$(sqlite3 "$DB_PATH" "SELECT env_value FROM env_config WHERE service_name=\"postgres\" AND env_key=\"POSTGRES_PASSWORD\";") &&
    [[ "$value" == "secret" ]]
'

# Test service dependencies
run_test "service dependencies" '
    sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on) VALUES (\"nginx\", \"postgres\");" &&
    dep=$(sqlite3 "$DB_PATH" "SELECT depends_on FROM service_dependencies WHERE service_name=\"nginx\";") &&
    [[ "$dep" == "postgres" ]]
'

# Test shared configuration
run_test "shared configuration" '
    sqlite3 "$DB_PATH" "INSERT INTO shared_config (config_key, config_value, description) VALUES (\"log_level\", \"debug\", \"Logging level\");" &&
    value=$(sqlite3 "$DB_PATH" "SELECT config_value FROM shared_config WHERE config_key=\"log_level\";") &&
    [[ "$value" == "debug" ]]
'

# Test configuration validation
run_test "duplicate port rejection" '
    ! sqlite3 "$DB_PATH" "INSERT INTO port_config (service_name, host_port, container_port) VALUES (\"test\", 80, 8080);"
'

run_test "self-reference dependency rejection" '
    ! sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on) VALUES (\"nginx\", \"nginx\");"
'

# Clean up
cleanup

echo "======================================"
echo "Failed tests: $((TESTS_RUN - TESTS_PASSED))"

# Exit with status
[[ $TESTS_PASSED -eq $TESTS_RUN ]] 