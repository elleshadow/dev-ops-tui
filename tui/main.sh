#!/bin/bash

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source core modules first
source "$PROJECT_ROOT/core/logging.sh"
source "$PROJECT_ROOT/core/db.sh"

# Initialize logging with proper error handling
if ! init_logging; then
    echo "ERROR: Failed to initialize logging"
    exit 1
fi

# Ensure database directory exists
if [[ "$DB_PATH" != ":memory:" ]]; then
    mkdir -p "$(dirname "$DB_PATH")" || {
        log_error "Failed to create database directory"
        exit 1
    }
fi

# Initialize database with retries
max_retries=3
retry_count=0
while ((retry_count < max_retries)); do
    if init_database; then
        break
    fi
    ((retry_count++))
    log_warning "Database initialization attempt $retry_count failed, retrying..."
    sleep 1
done

if ((retry_count >= max_retries)); then
    log_error "Failed to initialize database after $max_retries attempts"
    exit 1
fi

# Source remaining components
source "$PROJECT_ROOT/tui/theme.sh"
source "$PROJECT_ROOT/tui/components/dialog.sh"
source "$PROJECT_ROOT/tui/components/docker_menu.sh"
source "$PROJECT_ROOT/tui/components/auth.sh"
source "$PROJECT_ROOT/tui/components/config_menu.sh"
source "$PROJECT_ROOT/tui/components/test_viewer.sh"
source "$PROJECT_ROOT/tui/components/log_viewer.sh"
source "$PROJECT_ROOT/core/platform_info.sh"

# Handle authentication first
if ! handle_auth; then
    log_error "Authentication failed"
    exit 1
fi

# Get stored credentials for service configuration
if [[ -n "$TEST_MODE" ]]; then
    ADMIN_USER="test_admin"
    ADMIN_PASS_HASH=$(hash_password "test_password")
else
    if ! IFS='|' read -r ADMIN_USER ADMIN_PASS_HASH < <(get_auth_credentials); then
        log_error "Failed to get stored credentials"
        exit 1
    fi
fi

# Now collect platform information after authentication
log_info "Collecting platform information..."
collect_all_platform_info || {
    log_warning "Failed to collect platform information - continuing with defaults"
}

# Configure services with credentials
configure_services() {
    # Skip Docker operations in test mode
    [[ -n "$TEST_MODE" ]] && return 0
    
    # Update Grafana admin password
    docker exec grafana grafana-cli admin reset-admin-password "$ADMIN_PASS_HASH" >/dev/null 2>&1 || true
    
    # Update pgAdmin credentials
    docker rm -f pgadmin >/dev/null 2>&1 || true
    docker run -d --name pgadmin --network shadownet \
        -e PGADMIN_DEFAULT_EMAIL="$ADMIN_USER" \
        -e PGADMIN_DEFAULT_PASSWORD="$ADMIN_PASS_HASH" \
        -e PGADMIN_CONFIG_SERVER_MODE=False \
        -e PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False \
        -e PGADMIN_LISTEN_PORT=80 \
        -p 5050:80 dpage/pgadmin4:latest >/dev/null
    
    # Add basic auth to Nginx for Prometheus and cAdvisor
    local auth_file="/etc/nginx/.htpasswd"
    docker exec nginx sh -c "apk add --no-cache apache2-utils && \
        htpasswd -bc $auth_file $ADMIN_USER $ADMIN_PASS_HASH" >/dev/null 2>&1
    
    # Update Nginx config to use basic auth
    update_nginx_auth
}

update_nginx_auth() {
    # Skip Docker operations in test mode
    [[ -n "$TEST_MODE" ]] && return 0
    
    local nginx_conf="/etc/nginx/conf.d/default.conf"
    docker exec nginx sh -c "sed -i '/location \/prometheus/a \    auth_basic \"Prometheus\";\n    auth_basic_user_file /etc/nginx/.htpasswd;' $nginx_conf" >/dev/null 2>&1
    docker exec nginx sh -c "sed -i '/location \/cadvisor/a \    auth_basic \"cAdvisor\";\n    auth_basic_user_file /etc/nginx/.htpasswd;' $nginx_conf" >/dev/null 2>&1
    docker exec nginx nginx -s reload >/dev/null 2>&1
}

# Show main menu
show_main_menu() {
    local choice
    choice=$(dialog --clear --title "ShadowLab" \
        --menu "Select an option:" \
        16 50 10 \
        "1" "Deploy Services" \
        "2" "Manage Services" \
        "3" "Configure Services" \
        "4" "Shared Settings" \
        "5" "View Logs" \
        "6" "Run Tests" \
        "7" "Test Results" \
        "8" "System Logs" \
        "9" "Platform Info" \
        "10" "Exit" \
        2>&1 >/dev/tty)
    
    echo "$choice"
}

# Show platform information menu
show_platform_info_menu() {
    while true; do
        # Get all platform categories
        local categories
        categories=$(list_platform_categories)
        
        # Build menu items
        local menu_items=()
        while IFS= read -r category; do
            [[ -z "$category" ]] && continue
            menu_items+=("$category" "View $category information")
        done <<< "$categories"
        menu_items+=("back" "Return to main menu")
        
        # Show category selection menu
        local category
        category=$(dialog --clear --title "Platform Information" \
            --menu "Select a category to view:" \
            15 60 10 \
            "${menu_items[@]}" \
            2>&1 >/dev/tty)
        
        case $category in
            "back") break ;;
            *)
                if [[ -n "$category" ]]; then
                    # Get information for selected category
                    local info
                    info=$(get_platform_info_by_category "$category" | while IFS='|' read -r key value description; do
                        printf "%-20s: %s\n" "$key" "$value"
                        [[ -n "$description" ]] && printf "%-20s  %s\n" " " "$description"
                    done)
                    
                    # Show information
                    dialog --clear --title "$category Information" \
                        --msgbox "$info" \
                        20 70
                fi
                ;;
        esac
    done
}

# Show service selection menu
show_service_selection() {
    local services
    services=$(sqlite3 "$DB_PATH" "SELECT service_name FROM service_config ORDER BY service_name;")
    
    local service_list=()
    while IFS= read -r service; do
        service_list+=("$service" "")
    done <<< "$services"
    
    dialog --clear --title "Select Service" \
        --menu "Choose a service to configure:" \
        15 60 8 \
        "${service_list[@]}" \
        2>&1 >/dev/tty
}

# Configure services with stored credentials
configure_services

# Main menu loop
while true; do
    choice=$(show_main_menu)
    case $choice in
        1) deploy_services ;;
        2) manage_services ;;
        3) 
            service=$(show_service_selection)
            [[ $? -eq 0 ]] && show_service_config_menu "$service"
            ;;
        4) show_shared_config_menu ;;
        5) view_logs ;;
        6) execute_tests ;;
        7) show_test_runs_menu ;;
        8) show_logs_menu ;;
        9) show_platform_info_menu ;;
        10) break ;;
        *) continue ;;
    esac
done

# Clean up
clear

