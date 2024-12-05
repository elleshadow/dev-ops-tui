#!/bin/bash

# Dependencies
TUI_DEPS=("dialog" "bash" "awk" "sed" "grep")
DOCKER_DEPS=("docker")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if a command exists
check_command() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "Found command: $cmd"
        return 0
    else
        echo "Command not found: $cmd"
        return 1
    fi
}

# Check if a file exists
check_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        echo "Found file: $file"
        return 0
    else
        echo "File not found: $file"
        return 1
    fi
}

# Check TUI dependencies
check_tui_deps() {
    local missing=()
    for dep in "${TUI_DEPS[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if ((${#missing[@]} > 0)); then
        echo -e "${RED}Missing TUI dependencies: ${missing[*]}${NC}"
        return 1
    fi
    return 0
}

# Check if Docker is installed
check_docker_installed() {
    if ! check_command "docker"; then
        echo -e "${RED}Docker is not installed${NC}"
        return 1
    fi
    return 0
}

# Check if Docker is running
check_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}Docker is not running${NC}"
        return 1
    fi
    return 0
}

# Start Docker if not running
start_docker() {
    if ! check_docker_running; then
        echo -e "${YELLOW}Starting Docker...${NC}"
        if is_darwin; then
            open -a Docker
        else
            sudo systemctl start docker
        fi
        
        # Wait for Docker to start
        local count=0
        while ! check_docker_running && ((count < 30)); do
            sleep 1
            ((count++))
        done
        
        if ! check_docker_running; then
            echo -e "${RED}Failed to start Docker${NC}"
            return 1
        fi
    fi
    return 0
}

# Ask for permission to install dependencies
ask_permission() {
    local deps=("$@")
    echo -e "${YELLOW}The following dependencies are missing: ${deps[*]}${NC}"
    read -p "Do you want to install them? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check all dependencies
check_all_dependencies() {
    local missing=()
    
    # Check TUI dependencies
    for dep in "${TUI_DEPS[@]}"; do
        if ! check_command "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    # Check Docker dependencies
    for dep in "${DOCKER_DEPS[@]}"; do
        if ! check_command "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    # If there are missing dependencies
    if ((${#missing[@]} > 0)); then
        if ask_permission "${missing[@]}"; then
            # Install missing dependencies
            if is_darwin; then
                brew install "${missing[@]}"
            else
                sudo apt-get update
                sudo apt-get install -y "${missing[@]}"
            fi
        else
            echo -e "${RED}Cannot proceed without required dependencies${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Export functions
export -f check_command
export -f check_file
export -f check_tui_deps
export -f check_docker_installed
export -f check_docker_running
export -f start_docker
export -f ask_permission
export -f check_all_dependencies