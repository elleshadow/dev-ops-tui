#!/bin/bash

# Source database functions
source "$(dirname "${BASH_SOURCE[0]}")/db.sh"

# Initialize platform information in database
init_platform_info() {
    # System information
    save_platform_info "os_type" "$(uname -s)" "Operating system type"
    save_platform_info "os_version" "$(uname -r)" "Operating system version"
    save_platform_info "architecture" "$(uname -m)" "System architecture"
    save_platform_info "hostname" "$(hostname)" "System hostname"
    
    # Memory information
    if is_darwin; then
        local total_mem="$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))MB"
        save_platform_info "total_memory" "$total_mem" "Total system memory"
        save_platform_info "memory_pagesize" "$(sysctl -n hw.pagesize)" "Memory page size"
    else
        local total_mem="$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))MB"
        save_platform_info "total_memory" "$total_mem" "Total system memory"
        save_platform_info "memory_pagesize" "$(getconf PAGE_SIZE)" "Memory page size"
    fi
    
    # CPU information
    if is_darwin; then
        save_platform_info "cpu_count" "$(sysctl -n hw.ncpu)" "Number of CPU cores"
        save_platform_info "cpu_type" "$(sysctl -n machdep.cpu.brand_string)" "CPU type"
    else
        save_platform_info "cpu_count" "$(nproc)" "Number of CPU cores"
        save_platform_info "cpu_type" "$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)" "CPU type"
    fi
    
    # Docker information
    if command -v docker >/dev/null 2>&1; then
        save_platform_info "docker_version" "$(docker version --format '{{.Server.Version}}' 2>/dev/null)" "Docker version"
        save_platform_info "docker_api_version" "$(docker version --format '{{.Server.APIVersion}}' 2>/dev/null)" "Docker API version"
        save_platform_info "docker_root_dir" "$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)" "Docker root directory"
    fi
    
    # Platform-specific paths
    if is_darwin; then
        save_platform_info "docker_socket" "/var/run/docker.sock" "Docker socket path"
        save_platform_info "docker_config_dir" "$HOME/.docker" "Docker config directory"
        save_platform_info "docker_vm_dir" "$HOME/Library/Containers/com.docker.docker" "Docker VM directory"
        save_platform_info "docker_desktop_dir" "$HOME/Library/Application Support/Docker Desktop" "Docker Desktop directory"
    else
        save_platform_info "docker_socket" "/var/run/docker.sock" "Docker socket path"
        save_platform_info "docker_config_dir" "$HOME/.docker" "Docker config directory"
        save_platform_info "docker_data_dir" "/var/lib/docker" "Docker data directory"
        save_platform_info "docker_service_file" "/lib/systemd/system/docker.service" "Docker service file"
    fi
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

