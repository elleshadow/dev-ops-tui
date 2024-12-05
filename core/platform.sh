#!/bin/bash

# Source database functions
source "$(dirname "${BASH_SOURCE[0]}")/db.sh"

# Initialize platform information in database
init_platform_info() {
    # First ensure database and table exist
    if ! sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='platform_info';" | grep -q "platform_info"; then
        echo "Initializing database for platform info..."
        init_database || { echo "Failed to initialize database" >&2; return 1; }
    fi

    # System information
    save_platform_info "os_type" "$(uname -s)" "Operating system type" "system" || return 1
    save_platform_info "os_version" "$(uname -r)" "Operating system version" "system" || return 1
    save_platform_info "architecture" "$(uname -m)" "System architecture" "system" || return 1
    save_platform_info "hostname" "$(hostname)" "System hostname" "system" || return 1
    
    # Memory information
    if is_darwin; then
        local total_mem="$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))MB"
        save_platform_info "total_memory" "$total_mem" "Total system memory" "memory" || return 1
        save_platform_info "memory_pagesize" "$(sysctl -n hw.pagesize)" "Memory page size" "memory" || return 1
    else
        local total_mem="$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))MB"
        save_platform_info "total_memory" "$total_mem" "Total system memory" "memory" || return 1
        save_platform_info "memory_pagesize" "$(getconf PAGE_SIZE)" "Memory page size" "memory" || return 1
    fi
    
    # Verify data was saved
    local count
    count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM platform_info;")
    if [[ "$count" -eq 0 ]]; then
        echo "Error: Failed to save platform information" >&2
        return 1
    fi
    
    return 0
}

# Platform detection
is_darwin() {
    [[ "$(get_platform_info 'os_type')" == "Darwin" ]]
}

is_linux() {
    [[ "$(get_platform_info 'os_type')" == "Linux" ]]
}

# Get platform-specific paths
get_docker_socket() {
    get_platform_info 'docker_socket'
}

get_docker_config_dir() {
    get_platform_info 'docker_config_dir'
}

get_docker_data_dir() {
    get_platform_info 'docker_data_dir'
}

# Get system resources
get_system_memory() {
    get_platform_info 'total_memory'
}

get_system_cpu_count() {
    get_platform_info 'cpu_count'
}

get_system_load() {
    if is_darwin; then
        sysctl -n vm.loadavg | awk '{print $2 " " $3 " " $4}'
    else
        cat /proc/loadavg | awk '{print $1 " " $2 " " $3}'
    fi
}

# Platform-specific service management
start_docker_platform() {
    if is_darwin; then
        open -a Docker
    else
        sudo systemctl start docker
    fi
}

stop_docker_platform() {
    if is_darwin; then
        osascript -e 'quit app "Docker"'
    else
        sudo systemctl stop docker
    fi
}

get_docker_status_platform() {
    if is_darwin; then
        pgrep -f "Docker" >/dev/null
    else
        systemctl is-active docker >/dev/null
    fi
}

# Platform-specific cleanup
cleanup_platform() {
    if is_darwin; then
        local vm_dir="$(get_platform_info 'docker_vm_dir')"
        local desktop_dir="$(get_platform_info 'docker_desktop_dir')"
        rm -rf "$vm_dir"/* "$desktop_dir"/*
    else
        local data_dir="$(get_platform_info 'docker_data_dir')"
        sudo rm -rf "$data_dir"/*
    fi
}

# Initialize platform information when sourced
init_platform_info

# Export functions
export -f is_darwin
export -f is_linux
export -f get_docker_socket
export -f get_docker_config_dir
export -f get_docker_data_dir
export -f get_system_memory
export -f get_system_cpu_count
export -f get_system_load
export -f start_docker_platform
export -f stop_docker_platform
export -f get_docker_status_platform
export -f cleanup_platform

