#!/bin/bash

# Database configuration
DB_FILE="config.db"
DB_PATH="$(dirname "$(readlink -f "$0")")/../$DB_FILE"

# Initialize database tables
init_database() {
    sqlite3 "$DB_PATH" <<EOF
    CREATE TABLE IF NOT EXISTS configurations (
        key TEXT PRIMARY KEY,
        value TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS container_configs (
        container_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        config_json TEXT,
        status TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS menu_state (
        id INTEGER PRIMARY KEY,
        last_menu TEXT,
        last_position INTEGER,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Trigger to update the updated_at timestamp
    CREATE TRIGGER IF NOT EXISTS update_configurations_timestamp 
    AFTER UPDATE ON configurations
    BEGIN
        UPDATE configurations SET updated_at = CURRENT_TIMESTAMP WHERE key = NEW.key;
    END;

    CREATE TRIGGER IF NOT EXISTS update_container_configs_timestamp 
    AFTER UPDATE ON container_configs
    BEGIN
        UPDATE container_configs SET updated_at = CURRENT_TIMESTAMP WHERE container_id = NEW.container_id;
    END;

    CREATE TRIGGER IF NOT EXISTS update_menu_state_timestamp 
    AFTER UPDATE ON menu_state
    BEGIN
        UPDATE menu_state SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;
EOF
}

# Set a configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Error: Both key and value are required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO configurations (key, value) VALUES ('$key', '$value');"
}

# Get a configuration value
get_config() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo "Error: Key is required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "SELECT value FROM configurations WHERE key='$key';"
}

# Save container configuration
save_container_config() {
    local container_id="$1"
    local name="$2"
    local config_json="$3"
    local status="$4"
    
    if [[ -z "$container_id" || -z "$name" ]]; then
        echo "Error: Container ID and name are required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO container_configs (container_id, name, config_json, status) 
                        VALUES ('$container_id', '$name', '$config_json', '$status');"
}

# Get container configuration
get_container_config() {
    local container_id="$1"
    
    if [[ -z "$container_id" ]]; then
        echo "Error: Container ID is required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "SELECT config_json FROM container_configs WHERE container_id='$container_id';"
}

# List all containers
list_containers() {
    sqlite3 "$DB_PATH" "SELECT container_id, name, status FROM container_configs;"
}

# Save menu state
save_menu_state() {
    local menu="$1"
    local position="${2:-0}"
    
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO menu_state (id, last_menu, last_position) 
                        VALUES (1, '$menu', $position);"
}

# Get last menu state
get_menu_state() {
    sqlite3 "$DB_PATH" "SELECT last_menu, last_position FROM menu_state WHERE id=1;"
}

# Delete configuration
delete_config() {
    local key="$1"
    
    if [[ -z "$key" ]]; then
        echo "Error: Key is required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "DELETE FROM configurations WHERE key='$key';"
}

# Delete container configuration
delete_container_config() {
    local container_id="$1"
    
    if [[ -z "$container_id" ]]; then
        echo "Error: Container ID is required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "DELETE FROM container_configs WHERE container_id='$container_id';"
}

# Get all configurations
get_all_configs() {
    sqlite3 -separator "|" "$DB_PATH" "SELECT key, value, updated_at FROM configurations ORDER BY key;"
}

# Get containers by status
get_containers_by_status() {
    local status="$1"
    
    if [[ -z "$status" ]]; then
        echo "Error: Status is required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "SELECT container_id, name, status FROM container_configs WHERE status='$status';"
}

# Update container status
update_container_status() {
    local container_id="$1"
    local status="$2"
    
    if [[ -z "$container_id" || -z "$status" ]]; then
        echo "Error: Container ID and status are required" >&2
        return 1
    fi

    sqlite3 "$DB_PATH" "UPDATE container_configs SET status='$status' WHERE container_id='$container_id';"
}

# Check if container exists
container_exists() {
    local container_id="$1"
    
    if [[ -z "$container_id" ]]; then
        echo "Error: Container ID is required" >&2
        return 1
    fi

    local count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM container_configs WHERE container_id='$container_id';")
    [[ $count -gt 0 ]]
}

# Backup database
backup_database() {
    local backup_dir="${1:-backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/config_${timestamp}.db"
    
    mkdir -p "$backup_dir"
    sqlite3 "$DB_PATH" ".backup '$backup_file'"
}

# Get database stats
get_db_stats() {
    sqlite3 "$DB_PATH" <<EOF
    SELECT 
        (SELECT COUNT(*) FROM configurations) as config_count,
        (SELECT COUNT(*) FROM container_configs) as container_count,
        (SELECT COUNT(*) FROM menu_state) as menu_state_count;
EOF
}

# Initialize the database if it doesn't exist
if [[ ! -f "$DB_PATH" ]]; then
    init_database
fi 