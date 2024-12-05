#!/bin/bash

# Source required modules
source "$(dirname "${BASH_SOURCE[0]}")/../theme.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"

# Show service configuration menu
show_service_config_menu() {
    local service_name="$1"
    local config
    config=$(get_service_config "$service_name")
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Service Configuration - $service_name" \
            --menu "Select configuration to modify:" \
            20 70 8 \
            "1" "Basic Settings" \
            "2" "Port Mappings" \
            "3" "Volume Mappings" \
            "4" "Environment Variables" \
            "5" "Dependencies" \
            "6" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1) edit_basic_settings "$service_name" "$config" ;;
            2) edit_port_mappings "$service_name" ;;
            3) edit_volume_mappings "$service_name" ;;
            4) edit_environment_vars "$service_name" ;;
            5) edit_dependencies "$service_name" ;;
            6) break ;;
            *) continue ;;
        esac
    done
}

# Edit basic service settings
edit_basic_settings() {
    local service_name="$1"
    local config="$2"
    
    # Extract current values
    local image enabled restart_policy network
    image=$(echo "$config" | jq -r '.config.image')
    enabled=$(echo "$config" | jq -r '.config.enabled')
    restart_policy=$(echo "$config" | jq -r '.config.restart_policy')
    network=$(echo "$config" | jq -r '.config.network')
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Basic Settings - $service_name" \
            --menu "Select setting to modify:" \
            15 60 5 \
            "1" "Image ($image)" \
            "2" "Enabled ($enabled)" \
            "3" "Restart Policy ($restart_policy)" \
            "4" "Network ($network)" \
            "5" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                local new_image
                new_image=$(dialog --inputbox "Enter new image:" 8 60 "$image" 2>&1 >/dev/tty)
                [[ $? -eq 0 ]] && update_service_config "$service_name" "image" "$new_image"
                ;;
            2)
                local new_enabled
                dialog --yesno "Enable service?" 5 40
                new_enabled=$([[ $? -eq 0 ]] && echo "1" || echo "0")
                update_service_config "$service_name" "enabled" "$new_enabled"
                ;;
            3)
                local new_policy
                new_policy=$(dialog --menu "Select restart policy:" 12 50 4 \
                    "no" "Don't restart" \
                    "always" "Always restart" \
                    "on-failure" "Restart on failure" \
                    "unless-stopped" "Restart unless stopped" \
                    2>&1 >/dev/tty)
                [[ $? -eq 0 ]] && update_service_config "$service_name" "restart_policy" "$new_policy"
                ;;
            4)
                local new_network
                new_network=$(dialog --inputbox "Enter network name:" 8 60 "$network" 2>&1 >/dev/tty)
                [[ $? -eq 0 ]] && update_service_config "$service_name" "network" "$new_network"
                ;;
            5) break ;;
            *) continue ;;
        esac
    done
}

# Edit port mappings
edit_port_mappings() {
    local service_name="$1"
    local ports
    ports=$(sqlite3 "$DB_PATH" "SELECT host_port || ':' || container_port || ' (' || protocol || ')' 
        FROM port_config WHERE service_name='$service_name';")
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Port Mappings - $service_name" \
            --menu "Select action:" \
            15 60 4 \
            "1" "View Current Ports" \
            "2" "Add Port Mapping" \
            "3" "Remove Port Mapping" \
            "4" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                dialog --title "Current Port Mappings" \
                    --msgbox "$ports" \
                    15 60
                ;;
            2)
                local host_port container_port protocol
                host_port=$(dialog --inputbox "Enter host port:" 8 40 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                container_port=$(dialog --inputbox "Enter container port:" 8 40 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                protocol=$(dialog --menu "Select protocol:" 10 40 2 \
                    "tcp" "TCP" \
                    "udp" "UDP" \
                    2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                sqlite3 "$DB_PATH" "INSERT INTO port_config (service_name, host_port, container_port, protocol) 
                    VALUES ('$service_name', $host_port, $container_port, '$protocol');"
                ;;
            3)
                local port_list=()
                while IFS= read -r port; do
                    port_list+=("$port" "")
                done <<< "$ports"
                
                local to_remove
                to_remove=$(dialog --menu "Select port mapping to remove:" 15 60 8 "${port_list[@]}" 2>&1 >/dev/tty)
                
                if [[ $? -eq 0 ]]; then
                    local host_port
                    host_port=$(echo "$to_remove" | cut -d':' -f1)
                    sqlite3 "$DB_PATH" "DELETE FROM port_config 
                        WHERE service_name='$service_name' AND host_port=$host_port;"
                fi
                ;;
            4) break ;;
            *) continue ;;
        esac
    done
}

# Edit volume mappings
edit_volume_mappings() {
    local service_name="$1"
    local volumes
    volumes=$(sqlite3 "$DB_PATH" "SELECT host_path || ':' || container_path || ' (' || mode || ')' 
        FROM volume_config WHERE service_name='$service_name';")
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Volume Mappings - $service_name" \
            --menu "Select action:" \
            15 60 4 \
            "1" "View Current Volumes" \
            "2" "Add Volume Mapping" \
            "3" "Remove Volume Mapping" \
            "4" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                dialog --title "Current Volume Mappings" \
                    --msgbox "$volumes" \
                    15 60
                ;;
            2)
                local host_path container_path mode
                host_path=$(dialog --inputbox "Enter host path:" 8 60 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                container_path=$(dialog --inputbox "Enter container path:" 8 60 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                mode=$(dialog --menu "Select mode:" 10 40 3 \
                    "rw" "Read-Write" \
                    "ro" "Read-Only" \
                    2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                sqlite3 "$DB_PATH" "INSERT INTO volume_config (service_name, host_path, container_path, mode) 
                    VALUES ('$service_name', '$host_path', '$container_path', '$mode');"
                ;;
            3)
                local volume_list=()
                while IFS= read -r volume; do
                    volume_list+=("$volume" "")
                done <<< "$volumes"
                
                local to_remove
                to_remove=$(dialog --menu "Select volume mapping to remove:" 15 60 8 "${volume_list[@]}" 2>&1 >/dev/tty)
                
                if [[ $? -eq 0 ]]; then
                    local host_path
                    host_path=$(echo "$to_remove" | cut -d':' -f1)
                    sqlite3 "$DB_PATH" "DELETE FROM volume_config 
                        WHERE service_name='$service_name' AND host_path='$host_path';"
                fi
                ;;
            4) break ;;
            *) continue ;;
        esac
    done
}

# Edit environment variables
edit_environment_vars() {
    local service_name="$1"
    local env_vars
    env_vars=$(sqlite3 "$DB_PATH" "SELECT env_key || '=' || 
        CASE WHEN is_secret=1 THEN '********' ELSE env_value END 
        FROM env_config WHERE service_name='$service_name';")
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Environment Variables - $service_name" \
            --menu "Select action:" \
            15 60 4 \
            "1" "View Current Variables" \
            "2" "Add Variable" \
            "3" "Remove Variable" \
            "4" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                dialog --title "Current Environment Variables" \
                    --msgbox "$env_vars" \
                    15 60
                ;;
            2)
                local key value is_secret
                key=$(dialog --inputbox "Enter variable name:" 8 40 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                value=$(dialog --inputbox "Enter variable value:" 8 40 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                dialog --yesno "Is this a secret value?" 5 40
                is_secret=$([[ $? -eq 0 ]] && echo "1" || echo "0")
                
                sqlite3 "$DB_PATH" "INSERT INTO env_config (service_name, env_key, env_value, is_secret) 
                    VALUES ('$service_name', '$key', '$value', $is_secret);"
                ;;
            3)
                local var_list=()
                while IFS= read -r var; do
                    var_list+=("$var" "")
                done <<< "$env_vars"
                
                local to_remove
                to_remove=$(dialog --menu "Select variable to remove:" 15 60 8 "${var_list[@]}" 2>&1 >/dev/tty)
                
                if [[ $? -eq 0 ]]; then
                    local key
                    key=$(echo "$to_remove" | cut -d'=' -f1)
                    sqlite3 "$DB_PATH" "DELETE FROM env_config 
                        WHERE service_name='$service_name' AND env_key='$key';"
                fi
                ;;
            4) break ;;
            *) continue ;;
        esac
    done
}

# Edit service dependencies
edit_dependencies() {
    local service_name="$1"
    local dependencies
    dependencies=$(sqlite3 "$DB_PATH" "SELECT depends_on || ' (' || connection_type || ')' 
        FROM service_dependencies WHERE service_name='$service_name';")
    
    while true; do
        local choice
        choice=$(dialog --clear --title "Service Dependencies - $service_name" \
            --menu "Select action:" \
            15 60 4 \
            "1" "View Current Dependencies" \
            "2" "Add Dependency" \
            "3" "Remove Dependency" \
            "4" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                dialog --title "Current Dependencies" \
                    --msgbox "$dependencies" \
                    15 60
                ;;
            2)
                local depends_on connection_type
                # Get list of available services
                local services
                services=$(sqlite3 "$DB_PATH" "SELECT service_name FROM service_config 
                    WHERE service_name != '$service_name';")
                
                local service_list=()
                while IFS= read -r svc; do
                    service_list+=("$svc" "")
                done <<< "$services"
                
                depends_on=$(dialog --menu "Select dependency:" 15 60 8 "${service_list[@]}" 2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                connection_type=$(dialog --menu "Select connection type:" 10 50 4 \
                    "requires" "Must be running" \
                    "links" "Network link" \
                    "monitors" "Monitoring connection" \
                    "configures" "Configuration dependency" \
                    2>&1 >/dev/tty)
                [[ $? -ne 0 ]] && continue
                
                sqlite3 "$DB_PATH" "INSERT INTO service_dependencies (service_name, depends_on, connection_type) 
                    VALUES ('$service_name', '$depends_on', '$connection_type');"
                ;;
            3)
                local dep_list=()
                while IFS= read -r dep; do
                    dep_list+=("$dep" "")
                done <<< "$dependencies"
                
                local to_remove
                to_remove=$(dialog --menu "Select dependency to remove:" 15 60 8 "${dep_list[@]}" 2>&1 >/dev/tty)
                
                if [[ $? -eq 0 ]]; then
                    local depends_on
                    depends_on=$(echo "$to_remove" | cut -d' ' -f1)
                    sqlite3 "$DB_PATH" "DELETE FROM service_dependencies 
                        WHERE service_name='$service_name' AND depends_on='$depends_on';"
                fi
                ;;
            4) break ;;
            *) continue ;;
        esac
    done
}

# Show shared configuration menu
show_shared_config_menu() {
    while true; do
        local configs
        configs=$(sqlite3 "$DB_PATH" "SELECT config_key || ' = ' || config_value || ' (' || config_type || ')' 
            FROM shared_config ORDER BY config_key;")
        
        local config_list=()
        while IFS= read -r config; do
            config_list+=("$config" "")
        done <<< "$configs"
        
        local choice
        choice=$(dialog --clear --title "Shared Configurations" \
            --menu "Select configuration to modify:" \
            20 70 10 \
            "${config_list[@]}" \
            "BACK" "Return to main menu" \
            2>&1 >/dev/tty)
        
        case $choice in
            "BACK") break ;;
            *)
                local key value type
                key=$(echo "$choice" | cut -d' ' -f1)
                type=$(sqlite3 "$DB_PATH" "SELECT config_type FROM shared_config WHERE config_key='$key';")
                
                case "$type" in
                    "boolean")
                        dialog --yesno "Enable this setting?" 5 40
                        value=$([[ $? -eq 0 ]] && echo "true" || echo "false")
                        ;;
                    "enum:"*)
                        local options=(${type#enum:})
                        IFS=',' read -ra OPTS <<< "${options[0]}"
                        local menu_opts=()
                        for opt in "${OPTS[@]}"; do
                            menu_opts+=("$opt" "")
                        done
                        value=$(dialog --menu "Select value:" 15 40 8 "${menu_opts[@]}" 2>&1 >/dev/tty)
                        ;;
                    *)
                        value=$(dialog --inputbox "Enter new value:" 8 60 2>&1 >/dev/tty)
                        ;;
                esac
                
                [[ $? -eq 0 ]] && update_shared_config "$key" "$value"
                ;;
        esac
    done
}

# Export functions
export -f show_service_config_menu
export -f show_shared_config_menu 