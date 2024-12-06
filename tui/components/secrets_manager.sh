#!/bin/bash

# Secrets management system
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"

# Constants
declare -r SECRETS_DIR="${PROJECT_ROOT}/.secrets"
declare -r SECRETS_CONFIG="${PROJECT_ROOT}/config/secrets.conf"
declare -r VAULT_FILE="${SECRETS_DIR}/vault.gpg"
declare -r ENV_TEMPLATE="${PROJECT_ROOT}/config/env.template"

init_secrets_manager() {
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    
    # Create secrets config if not exists
    if [[ ! -f "$SECRETS_CONFIG" ]]; then
        {
            echo "# Secrets Configuration"
            echo "ENCRYPTION_TYPE=gpg"
            echo "AUTO_LOCK=true"
            echo "LOCK_TIMEOUT=300"
        } > "$SECRETS_CONFIG"
        chmod 600 "$SECRETS_CONFIG"
    fi
    
    # Create env template if not exists
    if [[ ! -f "$ENV_TEMPLATE" ]]; then
        {
            echo "# Environment Variables Template"
            echo "# Database Configuration"
            echo "DB_HOST=localhost"
            echo "DB_PORT=5432"
            echo "DB_USER="
            echo "DB_PASSWORD="
            echo
            echo "# API Keys"
            echo "API_KEY="
            echo "API_SECRET="
            echo
            echo "# Service Configuration"
            echo "SERVICE_URL="
            echo "SERVICE_TOKEN="
        } > "$ENV_TEMPLATE"
    fi
    
    return 0
}

show_secrets_menu() {
    with_terminal_state "secrets" "
        while true; do
            clear
            echo -e '\033[36m=== Secrets Management ===\033[0m'
            echo
            echo '1) Manage Environment Variables'
            echo '2) Manage API Keys'
            echo '3) Manage Credentials'
            echo '4) Configure GPG'
            echo '5) Backup/Restore Secrets'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) manage_env_vars ;;
                2) manage_api_keys ;;
                3) manage_credentials ;;
                4) configure_gpg ;;
                5) backup_restore_secrets ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

manage_env_vars() {
    echo -e '\n\033[33mManaging Environment Variables\033[0m'
    
    # Create/Edit .env file
    if [[ ! -f ".env" ]]; then
        cp "$ENV_TEMPLATE" .env
        chmod 600 .env
    fi
    
    echo "Current .env file:"
    echo "----------------"
    cat .env | grep -v '^#' | grep .
    echo "----------------"
    
    echo -e "\nOptions:"
    echo "1) Add/Update Variable"
    echo "2) Remove Variable"
    echo "3) Encrypt .env"
    echo "4) Load from Template"
    read -n 1 -p "Select option: " env_choice
    
    case $env_choice in
        1)
            read -p "Enter variable name: " var_name
            read -p "Enter variable value: " var_value
            if grep -q "^${var_name}=" .env; then
                sed -i.bak "s|^${var_name}=.*|${var_name}=${var_value}|" .env
            else
                echo "${var_name}=${var_value}" >> .env
            fi
            ;;
        2)
            read -p "Enter variable name to remove: " var_name
            sed -i.bak "/^${var_name}=/d" .env
            ;;
        3)
            gpg -c .env
            mv .env.gpg "${SECRETS_DIR}/"
            shred -u .env
            ;;
        4)
            cp "$ENV_TEMPLATE" .env
            chmod 600 .env
            ;;
    esac
    
    rm -f .env.bak
}

manage_api_keys() {
    echo -e '\n\033[33mManaging API Keys\033[0m'
    
    local api_keys_file="${SECRETS_DIR}/api_keys.gpg"
    local temp_file="/tmp/api_keys.tmp"
    
    if [[ -f "$api_keys_file" ]]; then
        gpg -d "$api_keys_file" > "$temp_file"
    else
        touch "$temp_file"
    fi
    
    echo "Current API Keys:"
    echo "----------------"
    cat "$temp_file"
    echo "----------------"
    
    echo -e "\nOptions:"
    echo "1) Add API Key"
    echo "2) Remove API Key"
    echo "3) Rotate API Key"
    read -n 1 -p "Select option: " key_choice
    
    case $key_choice in
        1)
            read -p "Enter service name: " service_name
            read -p "Enter API key: " api_key
            echo "${service_name}=${api_key}" >> "$temp_file"
            ;;
        2)
            read -p "Enter service name to remove: " service_name
            sed -i.bak "/^${service_name}=/d" "$temp_file"
            ;;
        3)
            read -p "Enter service name to rotate: " service_name
            read -p "Enter new API key: " api_key
            sed -i.bak "s|^${service_name}=.*|${service_name}=${api_key}|" "$temp_file"
            ;;
    esac
    
    gpg -c "$temp_file"
    mv "${temp_file}.gpg" "$api_keys_file"
    shred -u "$temp_file" "${temp_file}.bak"
}

manage_credentials() {
    echo -e '\n\033[33mManaging Credentials\033[0m'
    
    local creds_file="${SECRETS_DIR}/credentials.gpg"
    local temp_file="/tmp/credentials.tmp"
    
    if [[ -f "$creds_file" ]]; then
        gpg -d "$creds_file" > "$temp_file"
    else
        touch "$temp_file"
    fi
    
    echo "Current Credentials:"
    echo "----------------"
    cat "$temp_file" | sed 's/\(.*password=\).*/\1********/'
    echo "----------------"
    
    echo -e "\nOptions:"
    echo "1) Add Credentials"
    echo "2) Remove Credentials"
    echo "3) Update Credentials"
    read -n 1 -p "Select option: " cred_choice
    
    case $cred_choice in
        1)
            read -p "Enter service name: " service_name
            read -p "Enter username: " username
            read -s -p "Enter password: " password
            echo
            echo "${service_name}:username=${username}" >> "$temp_file"
            echo "${service_name}:password=${password}" >> "$temp_file"
            ;;
        2)
            read -p "Enter service name to remove: " service_name
            sed -i.bak "/^${service_name}:/d" "$temp_file"
            ;;
        3)
            read -p "Enter service name to update: " service_name
            read -p "Enter new username: " username
            read -s -p "Enter new password: " password
            echo
            sed -i.bak "/^${service_name}:/d" "$temp_file"
            echo "${service_name}:username=${username}" >> "$temp_file"
            echo "${service_name}:password=${password}" >> "$temp_file"
            ;;
    esac
    
    gpg -c "$temp_file"
    mv "${temp_file}.gpg" "$creds_file"
    shred -u "$temp_file" "${temp_file}.bak"
}

configure_gpg() {
    echo -e '\n\033[33mConfiguring GPG\033[0m'
    
    if ! command -v gpg &>/dev/null; then
        echo "Installing GPG..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install gnupg
        else
            sudo apt-get update && sudo apt-get install -y gnupg
        fi
    fi
    
    if [[ ! -f "${HOME}/.gnupg/pubring.kbx" ]]; then
        echo "Generating GPG key..."
        gpg --full-generate-key
    fi
    
    echo -e "\nCurrent GPG Keys:"
    gpg --list-keys
}

backup_restore_secrets() {
    echo -e '\n\033[33mBackup/Restore Secrets\033[0m'
    
    echo "Options:"
    echo "1) Backup Secrets"
    echo "2) Restore Secrets"
    read -n 1 -p "Select option: " backup_choice
    
    case $backup_choice in
        1)
            local backup_file="secrets_backup_$(date +%Y%m%d_%H%M%S).tar.gpg"
            tar -czf - "$SECRETS_DIR" | gpg -c > "$backup_file"
            echo "Backup created: $backup_file"
            ;;
        2)
            read -p "Enter backup file path: " backup_file
            if [[ -f "$backup_file" ]]; then
                gpg -d "$backup_file" | tar -xzf -
                echo "Secrets restored from backup"
            else
                echo "Backup file not found"
            fi
            ;;
    esac
}

cleanup_secrets_manager() {
    # Cleanup temporary files
    shred -u /tmp/api_keys.tmp* /tmp/credentials.tmp* 2>/dev/null || true
    return 0
} 