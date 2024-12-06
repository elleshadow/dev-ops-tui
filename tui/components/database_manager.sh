#!/bin/bash

# Database management system
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"
source "${PROJECT_ROOT}/tui/components/secrets_manager.sh"

# Constants - System Database (SQLite)
declare -r SYSTEM_DB_DIR="${PROJECT_ROOT}/.system/db"
declare -r SYSTEM_DB="${SYSTEM_DB_DIR}/tui.db"
declare -r SYSTEM_DB_SCHEMA="${PROJECT_ROOT}/config/system_schema.sql"

# Constants - User Database (PostgreSQL)
declare -r PG_CONFIG_DIR="${PROJECT_ROOT}/config/postgres"
declare -r PG_TEMPLATES_DIR="${PROJECT_ROOT}/templates/postgres"

# Initialize database management
init_database_manager() {
    # Initialize system database (hidden from user)
    mkdir -p "$SYSTEM_DB_DIR"
    chmod 700 "$SYSTEM_DB_DIR"
    
    if [[ ! -f "$SYSTEM_DB" ]]; then
        _init_system_db
    fi
    
    # Initialize PostgreSQL templates
    mkdir -p "$PG_CONFIG_DIR" "$PG_TEMPLATES_DIR"
    
    if [[ ! -f "${PG_TEMPLATES_DIR}/init.sql" ]]; then
        _create_pg_templates
    fi
    
    return 0
}

# System Database Functions (Internal Use Only)
_init_system_db() {
    log_info "Initializing system database"
    if ! command -v sqlite3 &>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install sqlite
        else
            sudo apt-get update && sudo apt-get install -y sqlite3
        fi
    fi
    
    # Create system schema
    cat > "$SYSTEM_DB_SCHEMA" << 'EOF'
-- System Configuration
CREATE TABLE IF NOT EXISTS system_config (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Project Database Tracking
CREATE TABLE IF NOT EXISTS project_databases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    host TEXT NOT NULL,
    port INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Database Backups
CREATE TABLE IF NOT EXISTS database_backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_db_id INTEGER,
    backup_path TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_db_id) REFERENCES project_databases(id)
);
EOF
    
    sqlite3 "$SYSTEM_DB" < "$SYSTEM_DB_SCHEMA"
    chmod 600 "$SYSTEM_DB"
}

_create_pg_templates() {
    # Create initialization template
    cat > "${PG_TEMPLATES_DIR}/init.sql" << 'EOF'
-- Basic initialization template
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Common functions
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Basic user management
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
EOF
    
    # Create backup template
    cat > "${PG_TEMPLATES_DIR}/backup.sql" << 'EOF'
-- Backup related functions
CREATE OR REPLACE FUNCTION create_backup_tables()
RETURNS void AS $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I_backup (LIKE %I INCLUDING ALL)',
            table_name, table_name
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
EOF
}

# User-Facing Database Management
show_database_menu() {
    with_terminal_state "database" "
        while true; do
            clear
            echo -e '\033[36m=== Database Management ===\033[0m'
            echo
            echo '1) Create/Remove Database'
            echo '2) Manage Migrations'
            echo '3) Backup/Restore'
            echo '4) Start/Stop Services'
            echo '5) Connection Management'
            echo '6) Open pgAdmin'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) manage_database ;;
                2) manage_migrations ;;
                3) backup_restore_db ;;
                4) manage_services ;;
                5) manage_connections ;;
                6) open_pgadmin ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

# New function to manage database lifecycle
manage_database() {
    echo -e '\n\033[33mDatabase Management\033[0m'
    
    echo "Options:"
    echo "1) Create New Database"
    echo "2) Remove Database"
    echo "3) List Databases"
    read -n 1 -p "Select option: " db_choice
    
    case $db_choice in
        1) create_database ;;
        2)
            read -p "Enter database name to remove: " db_name
            if confirm_action "Are you sure you want to remove $db_name?"; then
                remove_database "$db_name"
            fi
            ;;
        3)
            echo -e "\nCurrent Databases:"
            sqlite3 "$SYSTEM_DB" "SELECT name, host, port, created_at FROM project_databases ORDER BY created_at DESC;"
            ;;
    esac
}

# New function to manage services
manage_services() {
    echo -e '\n\033[33mDatabase Services\033[0m'
    
    echo "Options:"
    echo "1) Start PostgreSQL"
    echo "2) Stop PostgreSQL"
    echo "3) Start pgAdmin"
    echo "4) Stop pgAdmin"
    echo "5) Restart All Services"
    echo "6) Show Service Status"
    read -n 1 -p "Select option: " svc_choice
    
    case $svc_choice in
        1) start_postgres ;;
        2) stop_postgres ;;
        3) start_pgadmin ;;
        4) stop_pgadmin ;;
        5) 
            stop_postgres
            stop_pgadmin
            start_postgres
            start_pgadmin
            ;;
        6) show_service_status ;;
    esac
}

# Service management functions
start_postgres() {
    echo "Starting PostgreSQL..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew services start postgresql@14
    else
        sudo systemctl start postgresql
    fi
    wait_for_postgres
}

stop_postgres() {
    echo "Stopping PostgreSQL..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew services stop postgresql@14
    else
        sudo systemctl stop postgresql
    fi
}

start_pgadmin() {
    echo "Starting pgAdmin..."
    if ! command -v docker &>/dev/null; then
        echo "Installing Docker..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install docker
        else
            sudo apt-get update && sudo apt-get install -y docker.io
        fi
    fi
    
    # Start pgAdmin container if not running
    if ! docker ps | grep -q pgadmin4; then
        docker run -d \
            --name pgadmin4 \
            -e PGADMIN_DEFAULT_EMAIL="${PGADMIN_EMAIL:-admin@localhost}" \
            -e PGADMIN_DEFAULT_PASSWORD="${PGADMIN_PASSWORD:-admin}" \
            -p 5050:80 \
            dpage/pgadmin4
        
        # Store connection in system database
        sqlite3 "$SYSTEM_DB" << EOF
INSERT OR REPLACE INTO system_config (key, value)
VALUES ('pgadmin_url', 'http://localhost:5050');
EOF
    fi
}

stop_pgadmin() {
    echo "Stopping pgAdmin..."
    docker stop pgadmin4
    docker rm pgadmin4
}

show_service_status() {
    echo -e "\nPostgreSQL Status:"
    if [[ "$(uname)" == "Darwin" ]]; then
        brew services list | grep postgresql
    else
        sudo systemctl status postgresql
    fi
    
    echo -e "\npgAdmin Status:"
    docker ps | grep pgadmin4 || echo "pgAdmin is not running"
}

# Function to open pgAdmin in browser
open_pgadmin() {
    local pgadmin_url
    pgadmin_url=$(sqlite3 "$SYSTEM_DB" "SELECT value FROM system_config WHERE key='pgadmin_url';")
    
    if [[ -z "$pgadmin_url" ]]; then
        pgadmin_url="http://localhost:5050"
    fi
    
    echo "Opening pgAdmin in browser..."
    if [[ "$(uname)" == "Darwin" ]]; then
        open "$pgadmin_url"
    else
        xdg-open "$pgadmin_url"
    fi
    
    echo -e "\nDefault credentials:"
    echo "Email: ${PGADMIN_EMAIL:-admin@localhost}"
    echo "Password: ${PGADMIN_PASSWORD:-admin}"
}

# Helper function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while ! pg_isready -q; do
        if ((attempt >= max_attempts)); then
            echo "PostgreSQL failed to start"
            return 1
        fi
        echo -n "."
        sleep 1
        ((attempt++))
    done
    echo "PostgreSQL is ready"
}

# Helper function for user confirmation
confirm_action() {
    local message="$1"
    local response
    
    read -p "${message} [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

create_database() {
    echo -e '\n\033[33mCreating New Database\033[0m'
    
    # Get database details
    read -p "Enter database name: " db_name
    read -p "Enter port (default: 5432): " db_port
    db_port=${db_port:-5432}
    
    # Create database
    if ! command -v psql &>/dev/null; then
        echo "Installing PostgreSQL..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install postgresql@14
            brew services start postgresql@14
        else
            sudo apt-get update
            sudo apt-get install -y postgresql-14
            sudo systemctl start postgresql
        fi
    fi
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE ${db_name};
CREATE USER ${db_name}_user WITH ENCRYPTED PASSWORD '$(openssl rand -base64 32)';
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_name}_user;
EOF
    
    # Initialize database
    PGPASSWORD=$DB_PASSWORD psql -h localhost -U "${db_name}_user" -d "$db_name" -f "${PG_TEMPLATES_DIR}/init.sql"
    
    # Track in system database
    sqlite3 "$SYSTEM_DB" << EOF
INSERT INTO project_databases (name, host, port)
VALUES ('${db_name}', 'localhost', ${db_port});
EOF
    
    echo "Database created successfully"
}

manage_connections() {
    echo -e '\n\033[33mManaging Database Connections\033[0m'
    
    # Show current connections
    echo "Current Databases:"
    sqlite3 "$SYSTEM_DB" "SELECT name, host, port FROM project_databases;"
    
    echo -e "\nOptions:"
    echo "1) Add Connection"
    echo "2) Remove Connection"
    echo "3) Test Connection"
    read -n 1 -p "Select option: " conn_choice
    
    case $conn_choice in
        1)
            read -p "Enter connection name: " conn_name
            read -p "Enter host: " host
            read -p "Enter port: " port
            sqlite3 "$SYSTEM_DB" "INSERT INTO project_databases (name, host, port) VALUES ('$conn_name', '$host', $port);"
            ;;
        2)
            read -p "Enter connection name to remove: " conn_name
            sqlite3 "$SYSTEM_DB" "DELETE FROM project_databases WHERE name = '$conn_name';"
            ;;
        3)
            read -p "Enter connection name to test: " conn_name
            local conn_info
            conn_info=$(sqlite3 "$SYSTEM_DB" "SELECT host, port FROM project_databases WHERE name = '$conn_name';")
            if [[ -n "$conn_info" ]]; then
                local host port
                IFS='|' read -r host port <<< "$conn_info"
                if pg_isready -h "$host" -p "$port"; then
                    echo "Connection successful"
                else
                    echo "Connection failed"
                fi
            else
                echo "Connection not found"
            fi
            ;;
    esac
}

backup_restore_db() {
    echo -e '\n\033[33mBackup/Restore Database\033[0m'
    
    echo "Options:"
    echo "1) Create Backup"
    echo "2) Restore from Backup"
    echo "3) List Backups"
    read -n 1 -p "Select option: " backup_choice
    
    case $backup_choice in
        1)
            read -p "Enter database name: " db_name
            local backup_file="backup_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
            pg_dump -h localhost -U "${db_name}_user" "$db_name" > "$backup_file"
            sqlite3 "$SYSTEM_DB" << EOF
INSERT INTO database_backups (project_db_id, backup_path)
SELECT id, '$backup_file'
FROM project_databases
WHERE name = '$db_name';
EOF
            echo "Backup created: $backup_file"
            ;;
        2)
            read -p "Enter database name: " db_name
            echo "Available backups:"
            sqlite3 "$SYSTEM_DB" << EOF
SELECT backup_path, created_at
FROM database_backups b
JOIN project_databases p ON b.project_db_id = p.id
WHERE p.name = '$db_name'
ORDER BY created_at DESC;
EOF
            read -p "Enter backup path to restore: " backup_path
            if [[ -f "$backup_path" ]]; then
                psql -h localhost -U "${db_name}_user" "$db_name" < "$backup_path"
                echo "Database restored from backup"
            else
                echo "Backup file not found"
            fi
            ;;
        3)
            echo "All backups:"
            sqlite3 "$SYSTEM_DB" << EOF
SELECT p.name, b.backup_path, b.created_at
FROM database_backups b
JOIN project_databases p ON b.project_db_id = p.id
ORDER BY b.created_at DESC;
EOF
            ;;
    esac
}

run_migrations() {
    echo -e '\n\033[33mRunning Database Migrations\033[0m'
    
    # Check for migrations directory
    if [[ ! -d "migrations" ]]; then
        mkdir -p migrations
        echo "Created migrations directory"
    fi
    
    echo "Options:"
    echo "1) Create Migration"
    echo "2) Run Pending Migrations"
    echo "3) Rollback Migration"
    read -n 1 -p "Select option: " migration_choice
    
    case $migration_choice in
        1)
            read -p "Enter migration name: " migration_name
            local timestamp=$(date +%Y%m%d%H%M%S)
            local migration_file="migrations/${timestamp}_${migration_name}.sql"
            cat > "$migration_file" << 'EOF'
-- Migration: ${migration_name}
-- Created at: $(date)

-- Write your migration here
BEGIN;

-- Add your changes here

COMMIT;

-- Rollback
-- BEGIN;
-- Add your rollback steps here
-- COMMIT;
EOF
            echo "Migration created: $migration_file"
            ;;
        2)
            for migration in migrations/*.sql; do
                if [[ -f "$migration" ]]; then
                    echo "Running migration: $(basename "$migration")"
                    psql -h localhost -U "${db_name}_user" "$db_name" < "$migration"
                fi
            done
            ;;
        3)
            echo "Available migrations:"
            ls -1 migrations/*.sql 2>/dev/null
            read -p "Enter migration file to rollback: " rollback_file
            if [[ -f "$rollback_file" ]]; then
                # Extract and run rollback section
                sed -n '/^-- Rollback/,$p' "$rollback_file" | psql -h localhost -U "${db_name}_user" "$db_name"
                echo "Migration rolled back"
            else
                echo "Migration file not found"
            fi
            ;;
    esac
}

show_db_status() {
    echo -e '\n\033[33mDatabase Status\033[0m'
    
    read -p "Enter database name: " db_name
    
    echo -e "\nDatabase Size:"
    psql -h localhost -U "${db_name}_user" "$db_name" -c "
        SELECT pg_size_pretty(pg_database_size('$db_name')) as db_size;
    "
    
    echo -e "\nTable Sizes:"
    psql -h localhost -U "${db_name}_user" "$db_name" -c "
        SELECT 
            tablename as table,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    "
    
    echo -e "\nActive Connections:"
    psql -h localhost -U "${db_name}_user" "$db_name" -c "
        SELECT * FROM pg_stat_activity WHERE datname = '$db_name';
    "
}

import_export_data() {
    echo -e '\n\033[33mImport/Export Data\033[0m'
    
    echo "Options:"
    echo "1) Export Table"
    echo "2) Import Data"
    read -n 1 -p "Select option: " data_choice
    
    case $data_choice in
        1)
            read -p "Enter database name: " db_name
            read -p "Enter table name: " table_name
            read -p "Export format (csv/json): " format
            
            local export_file="exports/${table_name}_$(date +%Y%m%d_%H%M%S).${format}"
            mkdir -p exports
            
            case $format in
                csv)
                    psql -h localhost -U "${db_name}_user" "$db_name" -c "\COPY $table_name TO '$export_file' CSV HEADER;"
                    ;;
                json)
                    psql -h localhost -U "${db_name}_user" "$db_name" -c "\COPY (SELECT row_to_json($table_name) FROM $table_name) TO '$export_file';"
                    ;;
            esac
            echo "Data exported to: $export_file"
            ;;
        2)
            read -p "Enter database name: " db_name
            read -p "Enter table name: " table_name
            read -p "Import file path: " import_file
            read -p "File format (csv/json): " format
            
            if [[ -f "$import_file" ]]; then
                case $format in
                    csv)
                        psql -h localhost -U "${db_name}_user" "$db_name" -c "\COPY $table_name FROM '$import_file' CSV HEADER;"
                        ;;
                    json)
                        # Create temporary function for JSON import
                        psql -h localhost -U "${db_name}_user" "$db_name" << 'EOF'
CREATE OR REPLACE FUNCTION import_json_data(data json)
RETURNS void AS $$
BEGIN
    INSERT INTO $table_name
    SELECT * FROM json_populate_record(null::$table_name, data);
END;
$$ LANGUAGE plpgsql;
EOF
                        # Import data
                        psql -h localhost -U "${db_name}_user" "$db_name" -c "\COPY (SELECT import_json_data(data::json) FROM '$import_file') FROM stdin;"
                        ;;
                esac
                echo "Data imported successfully"
            else
                echo "Import file not found"
            fi
            ;;
    esac
}

cleanup_database_manager() {
    # Cleanup temporary files
    rm -f /tmp/db_*.sql
    return 0
} 