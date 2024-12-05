#!/bin/bash

# Source required files
source "$(dirname "$0")/../tui/components/config_menu.sh"
source "$(dirname "$0")/../core/logging.sh"

# Setup test environment
setup_test_env() {
    export DB_PATH=":memory:"
    init_database
    export TEST_MODE=1
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
    unset TEST_MODE
}

# Test configuration flow
test_config_flow() {
    echo "Testing complete configuration flow..."
    
    # 1. Initialize service
    init_service_config "test_service" "test:latest" "8080:80" "/data:/app"
    
    # 2. Add environment variables
    sqlite3 "$DB_PATH" "INSERT INTO env_config (service_name, env_key, env_value, is_secret) 
        VALUES ('test_service', 'TEST_VAR', 'test_value', 0);"
    
    # 3. Add dependency
    sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on, connection_type) 
        VALUES ('test_service', 'nginx', 'requires');"
    
    # 4. Get complete configuration
    local config
    config=$(get_service_config "test_service")
    
    # Verify all components
    if [[ -n "$config" && "$config" != "null" ]]; then
        echo "✓ Configuration retrieved successfully"
        
        # Check image
        if echo "$config" | grep -q "test:latest"; then
            echo "✓ Image configured correctly"
        else
            echo "✗ Image configuration failed"
            return 1
        fi
        
        # Check port
        if echo "$config" | grep -q "8080"; then
            echo "✓ Port configured correctly"
        else
            echo "✗ Port configuration failed"
            return 1
        fi
        
        # Check volume
        if echo "$config" | grep -q "/data:/app"; then
            echo "✓ Volume configured correctly"
        else
            echo "✗ Volume configuration failed"
            return 1
        fi
        
        # Check environment variable
        if echo "$config" | grep -q "TEST_VAR"; then
            echo "✓ Environment variable configured correctly"
        else
            echo "✗ Environment variable configuration failed"
            return 1
        fi
    else
        echo "✗ Failed to retrieve configuration"
        return 1
    fi
    
    return 0
}

# Test configuration validation flow
test_validation_flow() {
    echo "Testing configuration validation flow..."
    
    # 1. Try duplicate port
    if sqlite3 "$DB_PATH" "INSERT INTO port_config (service_name, host_port, container_port) 
        VALUES ('test_service', 8080, 80);" 2>/dev/null; then
        echo "✗ Duplicate port allowed"
        return 1
    else
        echo "✓ Duplicate port rejected"
    fi
    
    # 2. Try invalid volume path
    if sqlite3 "$DB_PATH" "INSERT INTO volume_config (service_name, host_path, container_path) 
        VALUES ('test_service', '', '/app');" 2>/dev/null; then
        echo "✗ Invalid volume path allowed"
        return 1
    else
        echo "✓ Invalid volume path rejected"
    fi
    
    # 3. Try circular dependency
    if sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on, connection_type) 
        VALUES ('test_service', 'test_service', 'requires');" 2>/dev/null; then
        echo "✗ Circular dependency allowed"
        return 1
    else
        echo "✓ Circular dependency rejected"
    fi
    
    return 0
}

# Test configuration update flow
test_update_flow() {
    echo "Testing configuration update flow..."
    
    # 1. Update basic settings
    update_service_config "test_service" "image" "test:2.0"
    
    # 2. Update port
    sqlite3 "$DB_PATH" "UPDATE port_config SET host_port = 9090 
        WHERE service_name = 'test_service' AND host_port = 8080;"
    
    # 3. Update volume
    sqlite3 "$DB_PATH" "UPDATE volume_config SET host_path = '/new/data' 
        WHERE service_name = 'test_service' AND host_path = '/data';"
    
    # 4. Update environment variable
    sqlite3 "$DB_PATH" "UPDATE env_config SET env_value = 'new_value' 
        WHERE service_name = 'test_service' AND env_key = 'TEST_VAR';"
    
    # Verify updates
    local config
    config=$(get_service_config "test_service")
    
    if [[ -n "$config" && "$config" != "null" ]]; then
        # Check image update
        if echo "$config" | grep -q "test:2.0"; then
            echo "✓ Image updated successfully"
        else
            echo "✗ Image update failed"
            return 1
        fi
        
        # Check port update
        if echo "$config" | grep -q "9090"; then
            echo "✓ Port updated successfully"
        else
            echo "✗ Port update failed"
            return 1
        fi
        
        # Check volume update
        if echo "$config" | grep -q "/new/data"; then
            echo "✓ Volume updated successfully"
        else
            echo "✗ Volume update failed"
            return 1
        fi
        
        # Check environment variable update
        if echo "$config" | grep -q "new_value"; then
            echo "✓ Environment variable updated successfully"
        else
            echo "✗ Environment variable update failed"
            return 1
        fi
    else
        echo "✗ Failed to retrieve updated configuration"
        return 1
    fi
    
    return 0
}

# Test shared configuration flow
test_shared_config_flow() {
    echo "Testing shared configuration flow..."
    
    # 1. Set shared configurations
    update_shared_config "test_key" "test_value"
    update_shared_config "admin_email" "test@example.com"
    update_shared_config "log_level" "debug"
    
    # 2. Verify shared configurations
    local test_value admin_email log_level
    test_value=$(get_shared_config "test_key")
    admin_email=$(get_shared_config "admin_email")
    log_level=$(get_shared_config "log_level")
    
    if [[ "$test_value" == "test_value" ]]; then
        echo "✓ Basic shared config works"
    else
        echo "✗ Basic shared config failed"
        return 1
    fi
    
    if [[ "$admin_email" == "test@example.com" ]]; then
        echo "✓ Email config works"
    else
        echo "✗ Email config failed"
        return 1
    fi
    
    if [[ "$log_level" == "debug" ]]; then
        echo "✓ Log level config works"
    else
        echo "✗ Log level config failed"
        return 1
    fi
    
    return 0
}

# Run all tests
run_config_integration_tests() {
    local failed=0
    
    echo "Running configuration integration tests..."
    echo "========================================="
    
    setup_test_env
    
    # Run individual tests
    test_config_flow || ((failed++))
    test_validation_flow || ((failed++))
    test_update_flow || ((failed++))
    test_shared_config_flow || ((failed++))
    
    cleanup_test_env
    
    echo "========================================="
    if ((failed == 0)); then
        echo "All configuration integration tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_config_integration_tests
fi 