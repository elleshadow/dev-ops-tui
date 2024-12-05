#!/bin/bash

# Source required modules
source "$(dirname "${BASH_SOURCE[0]}")/../theme.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"

# Show logs menu
show_logs_menu() {
    while true; do
        local choice
        choice=$(dialog --clear --title "System Logs" \
            --menu "Select view:" \
            15 60 6 \
            "1" "All Logs" \
            "2" "Error Logs" \
            "3" "Component Logs" \
            "4" "Export Logs" \
            "5" "Log Settings" \
            "6" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1) show_all_logs ;;
            2) show_error_logs ;;
            3) show_component_logs ;;
            4) export_logs ;;
            5) configure_logging ;;
            6) break ;;
            *) continue ;;
        esac
    done
}

# Show all logs
show_all_logs() {
    local logs
    logs=$(get_system_logs "" "" 1000)
    
    show_log_viewer "All System Logs" "$logs"
}

# Show error logs
show_error_logs() {
    local logs
    logs=$(get_system_logs "ERROR" "" 1000)
    
    show_log_viewer "Error Logs" "$logs"
}

# Show component logs
show_component_logs() {
    # Get list of components
    local components
    components=$(sqlite3 "$DB_PATH" "SELECT DISTINCT component 
        FROM system_logs ORDER BY component;")
    
    local component_list=()
    while IFS= read -r component; do
        component_list+=("$component" "")
    done <<< "$components"
    
    local component
    component=$(dialog --clear --title "Select Component" \
        --menu "Choose component to view:" \
        15 60 8 \
        "${component_list[@]}" \
        2>&1 >/dev/tty)
    
    if [[ $? -eq 0 ]]; then
        local logs
        logs=$(get_system_logs "" "$component" 1000)
        
        show_log_viewer "Logs for $component" "$logs"
    fi
}

# Show log viewer
show_log_viewer() {
    local title="$1"
    local logs="$2"
    
    local message=""
    local count=0
    
    while read -r log; do
        local timestamp level component msg details
        timestamp=$(echo "$log" | jq -r '.timestamp')
        level=$(echo "$log" | jq -r '.level')
        component=$(echo "$log" | jq -r '.component')
        msg=$(echo "$log" | jq -r '.message')
        details=$(echo "$log" | jq -r '.details')
        
        ((count++))
        
        message+="$count. [$timestamp] $level - $component\n"
        message+="   $msg\n"
        [[ -n "$details" && "$details" != "null" ]] && message+="   Details: $details\n"
        message+="\n"
    done < <(echo "$logs" | jq -c '.[]')
    
    dialog --title "$title" \
        --msgbox "$message" \
        25 80
}

# Export logs
export_logs() {
    local export_dir="$HOME/system_logs"
    mkdir -p "$export_dir"
    
    local filename="$export_dir/system_logs_$(date +%Y%m%d_%H%M%S).json"
    
    # Export all logs
    local data
    data=$(sqlite3 "$DB_PATH" "SELECT json_group_array(json_object(
        'timestamp', timestamp,
        'level', level,
        'component', component,
        'message', message,
        'details', details,
        'trace', trace
    )) FROM system_logs ORDER BY timestamp DESC;")
    
    echo "$data" > "$filename"
    
    dialog --title "Export Complete" \
        --msgbox "System logs exported to:\n$filename" \
        8 60
}

# Configure logging
configure_logging() {
    while true; do
        local choice
        choice=$(dialog --clear --title "Log Settings" \
            --menu "Select setting:" \
            15 60 4 \
            "1" "Log Level" \
            "2" "Log Retention" \
            "3" "Component Filters" \
            "4" "Back" \
            2>&1 >/dev/tty)
        
        case $choice in
            1) configure_log_level ;;
            2) configure_log_retention ;;
            3) configure_component_filters ;;
            4) break ;;
            *) continue ;;
        esac
    done
}

# Configure log level
configure_log_level() {
    local current_level
    current_level=$(get_shared_config "log_level")
    
    local new_level
    new_level=$(dialog --clear --title "Log Level" \
        --menu "Select log level:" \
        12 50 4 \
        "debug" "Debug messages" \
        "info" "Information messages" \
        "warn" "Warning messages" \
        "error" "Error messages" \
        2>&1 >/dev/tty)
    
    if [[ $? -eq 0 ]]; then
        update_shared_config "log_level" "$new_level"
        dialog --msgbox "Log level updated to: $new_level" 6 40
    fi
}

# Configure log retention
configure_log_retention() {
    local current_days
    current_days=$(get_shared_config "log_retention_days")
    
    local new_days
    new_days=$(dialog --inputbox "Enter log retention period in days:" \
        8 40 "$current_days" \
        2>&1 >/dev/tty)
    
    if [[ $? -eq 0 ]]; then
        update_shared_config "log_retention_days" "$new_days"
        
        # Clean up old logs
        sqlite3 "$DB_PATH" "DELETE FROM system_logs 
            WHERE timestamp < datetime('now', '-$new_days days');"
        
        dialog --msgbox "Log retention updated to $new_days days" 6 40
    fi
}

# Configure component filters
configure_component_filters() {
    # Get list of components
    local components
    components=$(sqlite3 "$DB_PATH" "SELECT DISTINCT component 
        FROM system_logs ORDER BY component;")
    
    local component_list=()
    while IFS= read -r component; do
        local enabled
        enabled=$(get_shared_config "log_component_${component}")
        [[ "$enabled" != "false" ]] && enabled="true"
        
        component_list+=("$component" "$enabled")
    done <<< "$components"
    
    local choices
    choices=$(dialog --separate-output \
        --checklist "Select components to log:" \
        20 60 10 \
        "${component_list[@]}" \
        2>&1 >/dev/tty)
    
    if [[ $? -eq 0 ]]; then
        # Disable all components first
        while IFS= read -r component; do
            update_shared_config "log_component_${component}" "false"
        done <<< "$components"
        
        # Enable selected components
        while IFS= read -r component; do
            update_shared_config "log_component_${component}" "true"
        done <<< "$choices"
        
        dialog --msgbox "Component filters updated" 6 40
    fi
}

# Export functions
export -f show_logs_menu
export -f show_all_logs
export -f show_error_logs
export -f show_component_logs
export -f show_log_viewer
export -f export_logs
export -f configure_logging
export -f configure_log_level
export -f configure_log_retention
export -f configure_component_filters 