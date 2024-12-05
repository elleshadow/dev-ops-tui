#!/bin/bash

# Source the database functions
source "$(dirname "${BASH_SOURCE[0]}")/db.sh"

# Collect and store OS information
collect_os_info() {
    # OS Type and Version
    save_platform_info "os_type" "$(uname -s)" "Operating System Type" "system"
    save_platform_info "os_version" "$(uname -r)" "Operating System Version" "system"
    save_platform_info "os_machine" "$(uname -m)" "Machine Architecture" "system"
    
    # Get more detailed OS information if available
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        save_platform_info "os_name" "$NAME" "OS Distribution Name" "system"
        save_platform_info "os_id" "$ID" "OS Distribution ID" "system"
        save_platform_info "os_version_id" "$VERSION_ID" "OS Version ID" "system"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        save_platform_info "os_name" "macOS" "OS Distribution Name" "system"
        save_platform_info "os_version_id" "$(sw_vers -productVersion)" "OS Version ID" "system"
    fi
}

# Collect and store Docker information
collect_docker_info() {
    if command -v docker >/dev/null 2>&1; then
        save_platform_info "docker_version" "$(docker version --format '{{.Server.Version}}')" "Docker Version" "docker"
        save_platform_info "docker_api_version" "$(docker version --format '{{.Server.APIVersion}}')" "Docker API Version" "docker"
        save_platform_info "docker_root_dir" "$(docker info --format '{{.DockerRootDir}}')" "Docker Root Directory" "docker"
        save_platform_info "docker_driver" "$(docker info --format '{{.Driver}}')" "Docker Storage Driver" "docker"
    fi
}

# Collect and store hardware information
collect_hardware_info() {
    # CPU information
    if [[ "$(uname -s)" == "Darwin" ]]; then
        save_platform_info "cpu_cores" "$(sysctl -n hw.ncpu)" "Number of CPU Cores" "hardware"
        save_platform_info "memory_total" "$(sysctl -n hw.memsize)" "Total Memory in Bytes" "hardware"
    else
        save_platform_info "cpu_cores" "$(nproc)" "Number of CPU Cores" "hardware"
        save_platform_info "memory_total" "$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')" "Total Memory in Bytes" "hardware"
    fi
}

# Collect and store network information
collect_network_info() {
    # Get default interface
    if [[ "$(uname -s)" == "Darwin" ]]; then
        default_interface=$(route -n get default | grep interface | awk '{print $2}')
    else
        default_interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    fi
    
    save_platform_info "default_interface" "$default_interface" "Default Network Interface" "network"
    
    # Get IP address
    if [[ "$(uname -s)" == "Darwin" ]]; then
        ip_address=$(ipconfig getifaddr "$default_interface")
    else
        ip_address=$(ip addr show "$default_interface" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    fi
    
    save_platform_info "ip_address" "$ip_address" "Primary IP Address" "network"
}

# Main function to collect all platform information
collect_all_platform_info() {
    collect_os_info
    collect_docker_info
    collect_hardware_info
    collect_network_info
}

# Export functions
export -f collect_os_info
export -f collect_docker_info
export -f collect_hardware_info
export -f collect_network_info
export -f collect_all_platform_info

# Collect information if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    collect_all_platform_info
fi 