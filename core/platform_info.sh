#!/bin/bash

# Source the database functions
source "$(dirname "${BASH_SOURCE[0]}")/db.sh"

# Save platform info with SQL injection protection
save_platform_info() {
    local key="$1"
    local value="$2"
    local description="$3"
    local category="$4"
    
    # Escape single quotes in all values
    local query
    query=$(printf "INSERT OR REPLACE INTO platform_info (info_key, info_value, description, category) VALUES ('%s', '%s', '%s', '%s');" \
        "${key//\'/\'\'}" "${value//\'/\'\'}" "${description//\'/\'\'}" "${category//\'/\'\'}")
    
    if ! sqlite3 "$DB_PATH" "$query"; then
        log_error "Failed to save platform info: $key"
        return 1
    fi
    return 0
}

# Collect and store OS information
collect_os_info() {
    log_info "Collecting OS information..."
    
    local failed=0
    
    # OS Type and Version
    save_platform_info "os_type" "$(uname -s)" "Operating System Type" "system" || ((failed++))
    save_platform_info "os_version" "$(uname -r)" "Operating System Version" "system" || ((failed++))
    save_platform_info "os_machine" "$(uname -m)" "Machine Architecture" "system" || ((failed++))
    
    # Get more detailed OS information if available
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        save_platform_info "os_name" "$NAME" "OS Distribution Name" "system" || ((failed++))
        save_platform_info "os_id" "$ID" "OS Distribution ID" "system" || ((failed++))
        save_platform_info "os_version_id" "$VERSION_ID" "OS Version ID" "system" || ((failed++))
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        save_platform_info "os_name" "macOS" "OS Distribution Name" "system" || ((failed++))
        save_platform_info "os_version_id" "$(sw_vers -productVersion)" "OS Version ID" "system" || ((failed++))
    fi
    
    if ((failed > 0)); then
        log_error "Failed to save some platform information ($failed failures)"
        return 1
    fi
    
    log_info "OS information collected successfully"
    return 0
}

# Main function to collect all platform information
collect_all_platform_info() {
    log_info "Starting platform information collection..."
    
    # First verify the platform_info table exists
    if ! sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='platform_info';" | grep -q "platform_info"; then
        log_error "platform_info table does not exist"
        return 1
    fi
    
    # Check if database is writable
    if ! sqlite3 "$DB_PATH" "PRAGMA quick_check;" >/dev/null 2>&1; then
        log_error "Database is not writable"
        return 1
    fi
    
    # Clear existing platform info to ensure fresh data
    if ! sqlite3 "$DB_PATH" "DELETE FROM platform_info;"; then
        log_error "Failed to clear existing platform info"
        return 1
    fi
    
    # Collect all information with error checking
    if ! collect_os_info; then
        log_warning "Failed to collect OS info - attempting to continue with partial data"
    fi
    
    # Verify we have some data
    local count
    count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM platform_info;")
    if [[ "$count" -eq 0 ]]; then
        # Add minimal platform info if nothing else worked
        save_platform_info "os_type" "$(uname -s)" "Operating System Type" "system" || {
            log_error "Failed to save minimal platform info"
            return 1
        }
    fi
    
    log_info "Successfully collected platform information"
    return 0
}

# Export functions
export -f save_platform_info
export -f collect_os_info
export -f collect_all_platform_info

# Collect information if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    collect_all_platform_info
fi 