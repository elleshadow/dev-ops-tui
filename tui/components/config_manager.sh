#!/bin/bash

# Configuration management system
declare -r CONFIG_DIR="${PROJECT_ROOT}/configs"
declare -A CONFIG_CACHE=()
declare -A CONFIG_VALIDATORS=()

init_config_manager() {
    # Create config directory structure
    mkdir -p "${CONFIG_DIR}"/{system,docker,network,user}
    
    # Initialize default configurations if needed
    init_default_configs
    
    # Load validators
    register_validators
    
    # Load all configurations into cache
    load_all_configs
    return 0
}

init_default_configs() {
    # System defaults
    if [[ ! -f "${CONFIG_DIR}/system/system.conf" ]]; then
        cat > "${CONFIG_DIR}/system/system.conf" << EOF
# System Configuration
LOG_LEVEL=INFO
DEBUG_MODE=false
MAX_PROCESSES=50
BACKUP_ENABLED=true
BACKUP_INTERVAL=86400
EOF
    fi
    
    # Docker defaults
    if [[ ! -f "${CONFIG_DIR}/docker/docker.conf" ]]; then
        cat > "${CONFIG_DIR}/docker/docker.conf" << EOF
# Docker Configuration
DOCKER_HOST=unix:///var/run/docker.sock
COMPOSE_PROJECT_NAME=devops
COMPOSE_FILE=docker-compose.yml
CONTAINER_PREFIX=dev
HEALTH_CHECK_INTERVAL=30
EOF
    fi
    
    # Network defaults
    if [[ ! -f "${CONFIG_DIR}/network/network.conf" ]]; then
        cat > "${CONFIG_DIR}/network/network.conf" << EOF
# Network Configuration
HTTP_PORT=8080
HTTPS_PORT=8443
ADMIN_PORT=9000
USE_SSL=true
NETWORK_MODE=bridge
EOF
    fi
}

register_validators() {
    # System validators
    CONFIG_VALIDATORS["LOG_LEVEL"]='[[ "$value" =~ ^(DEBUG|INFO|WARNING|ERROR)$ ]]'
    CONFIG_VALIDATORS["DEBUG_MODE"]='[[ "$value" =~ ^(true|false)$ ]]'
    CONFIG_VALIDATORS["MAX_PROCESSES"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value > 0 && value <= 1000))'
    CONFIG_VALIDATORS["BACKUP_ENABLED"]='[[ "$value" =~ ^(true|false)$ ]]'
    CONFIG_VALIDATORS["BACKUP_INTERVAL"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value >= 300))'
    
    # Docker validators
    CONFIG_VALIDATORS["DOCKER_HOST"]='[[ "$value" =~ ^(unix://|tcp://) ]]'
    CONFIG_VALIDATORS["COMPOSE_PROJECT_NAME"]='[[ "$value" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]'
    CONFIG_VALIDATORS["CONTAINER_PREFIX"]='[[ "$value" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]'
    CONFIG_VALIDATORS["HEALTH_CHECK_INTERVAL"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value >= 5))'
    
    # Network validators
    CONFIG_VALIDATORS["HTTP_PORT"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value > 0 && value <= 65535))'
    CONFIG_VALIDATORS["HTTPS_PORT"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value > 0 && value <= 65535))'
    CONFIG_VALIDATORS["ADMIN_PORT"]='[[ "$value" =~ ^[0-9]+$ ]] && ((value > 0 && value <= 65535))'
    CONFIG_VALIDATORS["USE_SSL"]='[[ "$value" =~ ^(true|false)$ ]]'
    CONFIG_VALIDATORS["NETWORK_MODE"]='[[ "$value" =~ ^(bridge|host|none)$ ]]'
}

load_all_configs() {
    # Clear cache
    CONFIG_CACHE=()
    
    # Load each config file
    while IFS= read -r config_file; do
        load_config_file "$config_file"
    done < <(find "$CONFIG_DIR" -type f -name "*.conf")
}

load_config_file() {
    local config_file="$1"
    
    # Read and process each line
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Trim whitespace
        key="${key##*( )}"
        key="${key%%*( )}"
        value="${value##*( )}"
        value="${value%%*( )}"
        
        # Store in cache
        CONFIG_CACHE["$key"]="$value"
    done < "$config_file"
}

get_config() {
    local key="$1"
    local default="$2"
    
    echo "${CONFIG_CACHE[$key]:-$default}"
}

set_config() {
    local key="$1"
    local value="$2"
    local config_file
    
    # Validate value
    if ! validate_config "$key" "$value"; then
        log_error "Invalid configuration value for $key: $value"
        return 1
    fi
    
    # Determine config file
    case "$key" in
        LOG_LEVEL|DEBUG_MODE|MAX_PROCESSES|BACKUP_*)
            config_file="${CONFIG_DIR}/system/system.conf"
            ;;
        DOCKER_*|COMPOSE_*)
            config_file="${CONFIG_DIR}/docker/docker.conf"
            ;;
        *_PORT|USE_SSL|NETWORK_MODE)
            config_file="${CONFIG_DIR}/network/network.conf"
            ;;
        *)
            log_error "Unknown configuration key: $key"
            return 1
            ;;
    esac
    
    # Update config file
    if ! update_config_file "$config_file" "$key" "$value"; then
        log_error "Failed to update configuration file: $config_file"
        return 1
    fi
    
    # Update cache
    CONFIG_CACHE["$key"]="$value"
    return 0
}

validate_config() {
    local key="$1"
    local value="$2"
    
    # Get validator
    local validator="${CONFIG_VALIDATORS[$key]}"
    if [[ -z "$validator" ]]; then
        log_warning "No validator found for $key"
        return 0
    fi
    
    # Run validation
    if ! eval "$validator"; then
        return 1
    fi
    
    return 0
}

update_config_file() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    local temp_file
    
    # Create temporary file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' RETURN
    
    # Update configuration
    local updated=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*= ]]; then
            echo "$key=$value"
            updated=true
        else
            echo "$line"
        fi
    done < "$config_file" > "$temp_file"
    
    # Add key if not found
    if ! $updated; then
        echo "$key=$value" >> "$temp_file"
    fi
    
    # Replace original file
    mv "$temp_file" "$config_file"
    return 0
}

show_config_editor() {
    local config_type="$1"
    local title
    local config_file
    
    # Determine config file and title
    case "$config_type" in
        "system")
            title="System Configuration"
            config_file="${CONFIG_DIR}/system/system.conf"
            ;;
        "docker")
            title="Docker Configuration"
            config_file="${CONFIG_DIR}/docker/docker.conf"
            ;;
        "network")
            title="Network Configuration"
            config_file="${CONFIG_DIR}/network/network.conf"
            ;;
        *)
            log_error "Unknown configuration type: $config_type"
            return 1
            ;;
    esac
    
    # Show editor with proper terminal handling
    with_terminal_state "config_editor" "
        clear
        echo -e '\033[36m=== $title ===\033[0m'
        echo -e '\033[33mPress i to edit, ESC :wq to save, :q! to cancel\033[0m'
        echo
        
        # Use vim for editing
        vim '$config_file'
    "
    
    # Reload configuration if file was modified
    if [[ -f "$config_file" ]]; then
        load_config_file "$config_file"
    fi
} 