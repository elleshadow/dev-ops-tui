#!/bin/bash

# Source required files
source "$(dirname "$0")/../tui/components/config_menu.sh"
source "$(dirname "$0")/../core/logging.sh"

# Mock dialog command
dialog() {
    case "$2" in
        "--menu")
            case "$3" in
                "Select configuration to modify:")
                    echo "1"  # Basic Settings
                    return 0
                    ;;
                "Select setting to modify:")
                    echo "1"  # Image
                    return 0
                    ;;
                *)
                    echo "4"  # Back/Exit
                    return 0
                    ;;
            esac
            ;;
        "--inputbox")
            echo "test:latest"
            return 0
            ;;
        "--yesno")
            return 0  # Yes
            ;;
        "--msgbox")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Setup test environment
setup_test_env() {
    export DB_PATH=":memory:"
    init_database
    export -f dialog
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
    unset -f dialog
}

# Test service configuration menu
test_service_config_menu() {
    echo "Testing service configuration menu..."
    
    if show_service_config_menu "nginx"; then
        echo "✓ Service configuration menu completed successfully"
        return 0
    else
        echo "✗ Service configuration menu failed"
        return 1
    fi
}

# Test basic settings menu
test_basic_settings() {
    echo "Testing basic settings menu..."
    
    local config='{"config":{"image":"nginx:latest","enabled":1,"restart_policy":"always","network":"shadownet"}}'
    
    if edit_basic_settings "nginx" "$config"; then
        echo "✓ Basic settings menu completed successfully"
        
        # Verify changes were saved
        local new_image
        new_image=$(sqlite3 "$DB_PATH" "SELECT image FROM service_config WHERE service_name='nginx';")
        
        if [[ "$new_image" == "test:latest" ]]; then
            echo "✓ Settings saved correctly"
            return 0
        else
            echo "✗ Settings not saved"
            return 1
        fi
    else
        echo "✗ Basic settings menu failed"
        return 1
    fi
}

# Test port mappings menu
test_port_mappings() {
    echo "Testing port mappings menu..."
    
    # Add test port first
    sqlite3 "$DB_PATH" "INSERT INTO port_config (service_name, host_port, container_port, protocol) 
        VALUES ('nginx', 8080, 80, 'tcp');"
    
    if edit_port_mappings "nginx"; then
        echo "✓ Port mappings menu completed successfully"
        return 0
    else
        echo "✗ Port mappings menu failed"
        return 1
    fi
}

# Test volume mappings menu
test_volume_mappings() {
    echo "Testing volume mappings menu..."
    
    # Add test volume first
    sqlite3 "$DB_PATH" "INSERT INTO volume_config (service_name, host_path, container_path, mode) 
        VALUES ('nginx', '/tmp/test', '/data', 'rw');"
    
    if edit_volume_mappings "nginx"; then
        echo "✓ Volume mappings menu completed successfully"
        return 0
    else
        echo "✗ Volume mappings menu failed"
        return 1
    fi
}

# Test environment variables menu
test_environment_vars() {
    echo "Testing environment variables menu..."
    
    # Add test environment variable
    sqlite3 "$DB_PATH" "INSERT INTO env_config (service_name, env_key, env_value, is_secret) 
        VALUES ('nginx', 'TEST_VAR', 'test_value', 0);"
    
    if edit_environment_vars "nginx"; then
        echo "✓ Environment variables menu completed successfully"
        return 0
    else
        echo "✗ Environment variables menu failed"
        return 1
    fi
}

# Test dependencies menu
test_dependencies() {
    echo "Testing dependencies menu..."
    
    # Add test dependency
    sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on, connection_type) 
        VALUES ('nginx', 'prometheus', 'monitors');"
    
    if edit_dependencies "nginx"; then
        echo "✓ Dependencies menu completed successfully"
        return 0
    else
        echo "✗ Dependencies menu failed"
        return 1
    fi
}

# Test shared configuration menu
test_shared_config_menu() {
    echo "Testing shared configuration menu..."
    
    if show_shared_config_menu; then
        echo "✓ Shared configuration menu completed successfully"
        
        # Verify changes were saved
        local new_value
        new_value=$(get_shared_config "admin_email")
        
        if [[ "$new_value" == "test@example.com" ]]; then
            echo "✓ Shared configuration saved correctly"
            return 0
        else
            echo "✗ Shared configuration not saved"
            return 1
        fi
    else
        echo "✗ Shared configuration menu failed"
        return 1
    fi
}

# Test configuration validation in UI
test_ui_validation() {
    echo "Testing UI validation..."
    
    # Override dialog mock for invalid input
    dialog() {
        case "$2" in
            "--inputbox")
                echo ""  # Empty input
                return 0
                ;;
            "--menu")
                echo "4"  # Back
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }
    export -f dialog
    
    # Test with invalid input
    if edit_basic_settings "nginx" "{}"; then
        local image
        image=$(sqlite3 "$DB_PATH" "SELECT image FROM service_config WHERE service_name='nginx';")
        
        if [[ -z "$image" ]]; then
            echo "✓ Invalid input rejected"
            return 0
        else
            echo "✗ Invalid input accepted"
            return 1
        fi
    else
        echo "✓ Invalid input handling worked"
        return 0
    fi
}

# Run all tests
run_config_ui_tests() {
    local failed=0
    
    echo "Running configuration UI tests..."
    echo "================================"
    
    setup_test_env
    
    # Run individual tests
    test_service_config_menu || ((failed++))
    test_basic_settings || ((failed++))
    test_port_mappings || ((failed++))
    test_volume_mappings || ((failed++))
    test_environment_vars || ((failed++))
    test_dependencies || ((failed++))
    test_shared_config_menu || ((failed++))
    test_ui_validation || ((failed++))
    
    cleanup_test_env
    
    echo "================================"
    if ((failed == 0)); then
        echo "All configuration UI tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_config_ui_tests
fi 