#!/bin/bash

# Source required files
source "$(dirname "$0")/../tui/main.sh"

# Mock docker commands
docker() {
    case "$1" in
        "exec")
            case "$3" in
                "grafana-cli")
                    return 0
                    ;;
                "sh")
                    return 0
                    ;;
            esac
            ;;
        "rm")
            return 0
            ;;
        "run")
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
    export -f docker
    
    # Setup test credentials
    save_auth_credentials "testadmin" "testpass123"
    ADMIN_CREDENTIALS=($(get_auth_credentials))
    ADMIN_USER="${ADMIN_CREDENTIALS[0]}"
    ADMIN_PASS_HASH="${ADMIN_CREDENTIALS[1]}"
}

# Cleanup test environment
cleanup_test_env() {
    unset DB_PATH
    unset -f docker
    unset ADMIN_CREDENTIALS ADMIN_USER ADMIN_PASS_HASH
}

# Test Grafana password update
test_grafana_auth() {
    echo "Testing Grafana auth configuration..."
    
    # Mock specific Grafana command
    docker() {
        if [[ "$3" == "grafana-cli" && "$4" == "admin" && "$5" == "reset-admin-password" ]]; then
            if [[ "$6" == "$ADMIN_PASS_HASH" ]]; then
                echo "✓ Grafana password set correctly"
                return 0
            else
                echo "✗ Wrong password used for Grafana"
                return 1
            fi
        fi
        return 0
    }
    export -f docker
    
    configure_services
    return $?
}

# Test pgAdmin configuration
test_pgadmin_auth() {
    echo "Testing pgAdmin auth configuration..."
    
    # Mock docker run for pgAdmin
    docker() {
        if [[ "$2" == "run" ]]; then
            if [[ "$*" =~ "PGADMIN_DEFAULT_EMAIL=\"$ADMIN_USER\"" && "$*" =~ "PGADMIN_DEFAULT_PASSWORD=\"$ADMIN_PASS_HASH\"" ]]; then
                echo "✓ pgAdmin credentials set correctly"
                return 0
            else
                echo "✗ Wrong credentials used for pgAdmin"
                return 1
            fi
        fi
        return 0
    }
    export -f docker
    
    configure_services
    return $?
}

# Test Nginx auth configuration
test_nginx_auth() {
    echo "Testing Nginx auth configuration..."
    
    # Mock docker exec for Nginx
    docker() {
        if [[ "$2" == "exec" && "$3" == "nginx" ]]; then
            if [[ "$5" =~ "htpasswd -bc /etc/nginx/.htpasswd $ADMIN_USER $ADMIN_PASS_HASH" ]]; then
                echo "✓ Nginx htpasswd created correctly"
                return 0
            elif [[ "$5" =~ "sed -i" && "$5" =~ "auth_basic" ]]; then
                echo "✓ Nginx config updated correctly"
                return 0
            else
                echo "✗ Incorrect Nginx configuration"
                return 1
            fi
        fi
        return 0
    }
    export -f docker
    
    configure_services
    return $?
}

# Run all tests
run_service_auth_tests() {
    local failed=0
    
    echo "Running service auth tests..."
    echo "============================"
    
    setup_test_env
    
    # Run individual tests
    test_grafana_auth || ((failed++))
    test_pgadmin_auth || ((failed++))
    test_nginx_auth || ((failed++))
    
    cleanup_test_env
    
    echo "============================"
    if ((failed == 0)); then
        echo "All service auth tests passed!"
        return 0
    else
        echo "Failed tests: $failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_service_auth_tests
fi 