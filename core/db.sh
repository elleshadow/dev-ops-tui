#!/bin/bash

# Database configuration
: "${DB_PATH:=${HOME}/.docker-manager/config.db}"

# Ensure SQLite3 is available
if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "Error: sqlite3 is required but not installed"
    exit 1
fi

# Hash function that works on both Linux and macOS
hash_password() {
    local password="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        echo -n "$password" | sha256sum | cut -d' ' -f1
    else
        echo -n "$password" | shasum -a 256 | cut -d' ' -f1
    fi
}

# Initialize database with all required tables
init_database() {
    log_info "Initializing database at $DB_PATH..."
    
    # Create data directory if needed
    if [[ "$DB_PATH" != ":memory:" ]]; then
        mkdir -p "$(dirname "$DB_PATH")" || {
            log_error "Failed to create database directory"
            return 1
        }
    fi
    
    # Check if database is accessible
    if ! sqlite3 "$DB_PATH" "SELECT 1;" >/dev/null 2>&1; then
        log_warning "Database may be corrupted or inaccessible, attempting to recreate"
        rm -f "$DB_PATH"
    fi
    
    # Create tables without transaction (SQLite handles DDL outside transactions)
    if ! sqlite3 "$DB_PATH" "
    CREATE TABLE IF NOT EXISTS auth_config (
        username TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS service_config (
        service_name TEXT PRIMARY KEY,
        image TEXT NOT NULL,
        config TEXT,
        status TEXT DEFAULT 'disabled'
    );

    CREATE TABLE IF NOT EXISTS port_config (
        service_name TEXT,
        host_port INTEGER,
        container_port INTEGER,
        protocol TEXT DEFAULT 'tcp',
        PRIMARY KEY (service_name, host_port),
        FOREIGN KEY (service_name) REFERENCES service_config(service_name)
    );

    CREATE TABLE IF NOT EXISTS volume_config (
        service_name TEXT,
        host_path TEXT,
        container_path TEXT,
        mode TEXT DEFAULT 'rw',
        PRIMARY KEY (service_name, container_path),
        FOREIGN KEY (service_name) REFERENCES service_config(service_name)
    );

    CREATE TABLE IF NOT EXISTS env_config (
        service_name TEXT,
        env_key TEXT,
        env_value TEXT,
        PRIMARY KEY (service_name, env_key),
        FOREIGN KEY (service_name) REFERENCES service_config(service_name)
    );

    CREATE TABLE IF NOT EXISTS service_dependencies (
        service_name TEXT,
        depends_on TEXT,
        PRIMARY KEY (service_name, depends_on),
        FOREIGN KEY (service_name) REFERENCES service_config(service_name),
        FOREIGN KEY (depends_on) REFERENCES service_config(service_name)
    );

    CREATE TABLE IF NOT EXISTS shared_config (
        config_key TEXT PRIMARY KEY,
        config_value TEXT,
        description TEXT
    );

    CREATE TABLE IF NOT EXISTS platform_info (
        info_key TEXT PRIMARY KEY,
        info_value TEXT,
        description TEXT,
        category TEXT
    );

    CREATE TABLE IF NOT EXISTS test_results (
        test_id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_name TEXT NOT NULL,
        status TEXT NOT NULL,
        output TEXT,
        duration REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS menu_state (
        id INTEGER PRIMARY KEY,
        menu_name TEXT NOT NULL,
        position INTEGER DEFAULT 0,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS container_config (
        container_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        config_json TEXT,
        status TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );"; then
        log_error "Failed to create tables"
        return 1
    fi
    
    # Verify all required tables exist
    local required_tables=(
        "auth_config" "service_config" "port_config" "volume_config"
        "env_config" "service_dependencies" "shared_config" "platform_info"
        "test_results" "config" "menu_state" "container_config"
    )
    
    local missing_tables=()
    for table in "${required_tables[@]}"; do
        if ! sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';" | grep -q "$table"; then
            missing_tables+=("$table")
        fi
    done
    
    if ((${#missing_tables[@]} > 0)); then
        log_error "Failed to create tables: ${missing_tables[*]}"
        return 1
    fi
    
    # Verify database is writable
    if ! sqlite3 "$DB_PATH" "PRAGMA quick_check;" >/dev/null 2>&1; then
        log_error "Database integrity check failed"
        return 1
    fi
    
    log_info "Database initialized successfully"
    return 0
}

# Auth functions
save_auth_credentials() {
    local username="$1"
    local password="$2"
    local password_hash=$(hash_password "$password")
    
    if ! sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO auth_config (username, password_hash) VALUES ('$username', '$password_hash');"; then
        log_error "Failed to save auth credentials for user $username"
        return 1
    fi
    log_info "Saved auth credentials for user $username"
    return 0
}

verify_credentials() {
    local username="$1"
    local password="$2"
    local password_hash=$(hash_password "$password")
    local stored_hash
    
    stored_hash=$(sqlite3 "$DB_PATH" "SELECT password_hash FROM auth_config WHERE username='$username';")
    if [[ -z "$stored_hash" ]]; then
        log_error "No credentials found for user $username"
        return 1
    fi
    
    if [[ "$stored_hash" != "$password_hash" ]]; then
        log_error "Invalid password for user $username"
        return 1
    fi
    
    log_info "Successfully verified credentials for user $username"
    return 0
}

get_auth_credentials() {
    local result
    result=$(sqlite3 "$DB_PATH" "SELECT username, password_hash FROM auth_config LIMIT 1;")
    if [[ -z "$result" ]]; then
        log_error "No auth credentials found in database"
        return 1
    fi
    echo "$result"
    return 0
}

check_first_run() {
    local count
    count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM auth_config;")
    [[ "$count" -eq 0 ]]
}

# Reset auth credentials by clearing the auth_config table
reset_auth_credentials() {
    if ! sqlite3 "$DB_PATH" "DELETE FROM auth_config;"; then
        log_error "Failed to reset auth credentials"
        return 1
    fi
    log_info "Successfully reset auth credentials"
    return 0
}

# Configuration functions
set_config() {
    local key="$1"
    local value="$2"
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO config (key, value, updated_at) VALUES ('$key', '$value', CURRENT_TIMESTAMP);"
}

get_config() {
    local key="$1"
    sqlite3 "$DB_PATH" "SELECT value FROM config WHERE key='$key';"
}

delete_config() {
    local key="$1"
    sqlite3 "$DB_PATH" "DELETE FROM config WHERE key='$key';"
}

get_all_configs() {
    sqlite3 "$DB_PATH" "SELECT key, value FROM config;"
}

# Service configuration functions
save_container_config() {
    local name="$1"
    local image="$2"
    local config="$3"
    local status="$4"
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO service_config (service_name, image, config, status) VALUES ('$name', '$image', '$config', '$status');"
}

get_container_config() {
    local name="$1"
    sqlite3 "$DB_PATH" "SELECT config FROM service_config WHERE service_name='$name';"
}

update_container_status() {
    local name="$1"
    local status="$2"
    sqlite3 "$DB_PATH" "UPDATE service_config SET status='$status' WHERE service_name='$name';"
}

delete_container_config() {
    local name="$1"
    sqlite3 "$DB_PATH" "DELETE FROM service_config WHERE service_name='$name';"
}

container_exists() {
    local name="$1"
    local count
    count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM service_config WHERE service_name='$name';")
    [[ "$count" -gt 0 ]]
}

get_containers_by_status() {
    local status="$1"
    sqlite3 "$DB_PATH" "SELECT service_name || '|' || image || '|' || status FROM service_config WHERE status='$status';"
}

# Menu state functions
save_menu_state() {
    local menu_name="$1"
    local position="$2"
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO menu_state (id, menu_name, position, updated_at) VALUES (1, '$menu_name', $position, CURRENT_TIMESTAMP);"
}

get_menu_state() {
    sqlite3 "$DB_PATH" "SELECT menu_name || '|' || position FROM menu_state WHERE id=1;"
}

# Platform information functions
save_platform_info() {
    local key="$1"
    local value="$2"
    local description="$3"
    local category="$4"
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO platform_info (info_key, info_value, description, category) VALUES ('$key', '$value', '$description', '$category');"
}

get_platform_info() {
    local key="$1"
    sqlite3 "$DB_PATH" "SELECT info_value FROM platform_info WHERE info_key='$key';"
}

# Test results functions
save_test_result() {
    local test_name="$1"
    local status="$2"
    local output="$3"
    local duration="$4"
    sqlite3 "$DB_PATH" "INSERT INTO test_results (test_name, status, output, duration) VALUES ('$test_name', '$status', '$output', $duration);"
}

get_test_results() {
    local test_name="$1"
    if [[ -n "$test_name" ]]; then
        sqlite3 "$DB_PATH" "SELECT * FROM test_results WHERE test_name='$test_name' ORDER BY timestamp DESC;"
    else
        sqlite3 "$DB_PATH" "SELECT * FROM test_results ORDER BY timestamp DESC;"
    fi
}

# Export functions
export -f hash_password
export -f init_database
export -f save_auth_credentials
export -f verify_credentials
export -f get_auth_credentials
export -f check_first_run
export -f reset_auth_credentials
export -f set_config
export -f get_config
export -f delete_config
export -f get_all_configs
export -f save_container_config
export -f get_container_config
export -f update_container_status
export -f delete_container_config
export -f container_exists
export -f get_containers_by_status
export -f save_menu_state
export -f get_menu_state
export -f save_platform_info
export -f get_platform_info
export -f save_test_result
export -f get_test_results

# Initialize database if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_database
fi