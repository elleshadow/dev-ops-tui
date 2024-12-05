#!/bin/bash

# Enable debug output for this script
DEBUG=${DEBUG:-false}

debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: $*" >&2
    fi
}

# Docker system checks
check_docker_installed() {
    debug_log "Checking Docker installation..."
    if command -v docker >/dev/null 2>&1; then
        docker_path=$(which docker)
        docker_version=$(docker --version 2>/dev/null)
        debug_log "Docker found at: $docker_path"
        debug_log "Version info: $docker_version"
        echo "Docker found at: $docker_path"
        echo "Version: $docker_version"
        return 0
    fi
    debug_log "Docker binary not found in PATH"
    echo "Docker binary not found in PATH"
    return 1
}

check_docker_compose_installed() {
    debug_log "Checking Docker Compose installation..."
    if command -v docker-compose >/dev/null 2>&1; then
        compose_path=$(which docker-compose)
        compose_version=$(docker-compose --version 2>/dev/null)
        debug_log "Docker Compose found at: $compose_path"
        debug_log "Version info: $compose_version"
        echo "Docker Compose found at: $compose_path"
        echo "Version: $compose_version"
        return 0
    elif docker compose version >/dev/null 2>&1; then
        debug_log "Docker Compose plugin found"
        echo "Docker Compose plugin installed"
        echo "Version: $(docker compose version 2>/dev/null)"
        return 0
    fi
    debug_log "Docker Compose not found"
    echo "Docker Compose not found"
    return 1
}

check_docker_running() {
    debug_log "Checking Docker daemon..."
    local error_msg
    
    # On macOS, first check if Docker Desktop is running
    if [[ $(uname -s) == "Darwin" ]]; then
        if ! pgrep -f "Docker Desktop" >/dev/null 2>&1; then
            debug_log "Docker Desktop is not running on macOS"
            echo "Docker Desktop is not running"
            echo "Please start Docker Desktop from your Applications folder"
            echo "or click the Docker icon in your menu bar"
            return 1
        fi
    fi

    if ! error_msg=$(docker info 2>&1); then
        debug_log "Docker info failed: $error_msg"
        if [[ $error_msg == *"Cannot connect to the Docker daemon"* ]]; then
            if [[ $(uname -s) == "Darwin" ]]; then
                echo "Docker Desktop is installed but not responding"
                echo "Try these steps:"
                echo "1. Open Docker Desktop from Applications"
                echo "2. Wait for it to finish starting up"
                echo "3. If problem persists, restart Docker Desktop"
            else
                echo "Docker daemon is not running"
                echo "Try: sudo systemctl start docker"
            fi
            echo "Error: $error_msg"
        else
            echo "Docker daemon check failed"
            echo "Error: $error_msg"
        fi
        return 1
    fi
    debug_log "Docker daemon is running"
    echo "Docker daemon is running"
    return 0
}

check_docker_permissions() {
    debug_log "Checking Docker permissions..."
    local error_msg
    if ! error_msg=$(docker ps 2>&1); then
        debug_log "Docker ps failed: $error_msg"
        if [[ $error_msg == *"permission denied"* ]]; then
            echo "Permission denied accessing Docker"
            echo "Try: sudo usermod -aG docker $USER"
        elif [[ $error_msg == *"Cannot connect to the Docker daemon"* ]]; then
            echo "Cannot connect to Docker daemon"
            echo "Error: $error_msg"
        else
            echo "Docker permission check failed"
            echo "Error: $error_msg"
        fi
        return 1
    fi
    debug_log "User has Docker permissions"
    echo "User has Docker permissions"
    return 0
}

get_install_instructions() {
    local os_type="$1"
    case "$os_type" in
        "Darwin")
            echo "Docker Desktop for macOS:\n\n\
1. Visit https://docs.docker.com/desktop/mac/install/\n\
2. Download Docker Desktop\n\
3. Install and launch Docker Desktop\n\
4. Start Docker Desktop from Applications folder\n\
\nNote: Make sure Docker Desktop is running before using this tool."
            ;;
        "Linux")
            echo "To install Docker on Linux:\n\n\
1. Update package index:\n\
   sudo apt-get update\n\n\
2. Install prerequisites:\n\
   sudo apt-get install ca-certificates curl gnupg\n\n\
3. Add Docker's official GPG key:\n\
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg\n\n\
4. Install Docker:\n\
   sudo apt-get install docker-ce docker-ce-cli containerd.io\n\n\
5. Start Docker daemon:\n\
   sudo systemctl start docker\n\
   sudo systemctl enable docker"
            ;;
        *)
            echo "Please visit https://docs.docker.com/engine/install/ for installation instructions."
            ;;
    esac
}

# Container operations
list_containers() {
    local format='table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
    if [ "$1" = "all" ]; then
        docker ps -a --format "$format"
    else
        docker ps --format "$format"
    fi
}

start_container() {
    local container_id="$1"
    docker start "$container_id"
}

stop_container() {
    local container_id="$1"
    docker stop "$container_id"
}

restart_container() {
    local container_id="$1"
    docker restart "$container_id"
}

remove_container() {
    local container_id="$1"
    local force="$2"
    if [ "$force" = "force" ]; then
        docker rm -f "$container_id"
    else
        docker rm "$container_id"
    fi
}

get_container_logs() {
    local container_id="$1"
    local lines="${2:-100}"
    docker logs --tail "$lines" "$container_id"
}

get_container_stats() {
    local container_id="$1"
    docker stats --no-stream "$container_id"
}

# Image operations
list_images() {
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}

pull_image() {
    local image="$1"
    local tag="${2:-latest}"
    docker pull "$image:$tag"
}

remove_image() {
    local image="$1"
    local force="$2"
    if [ "$force" = "force" ]; then
        docker rmi -f "$image"
    else
        docker rmi "$image"
    fi
}

# Volume operations
list_volumes() {
    docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

create_volume() {
    local name="$1"
    docker volume create "$name"
}

remove_volume() {
    local name="$1"
    local force="$2"
    if [ "$force" = "force" ]; then
        docker volume rm -f "$name"
    else
        docker volume rm "$name"
    fi
}

# Network operations
list_networks() {
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

create_network() {
    local name="$1"
    local driver="${2:-bridge}"
    docker network create --driver "$driver" "$name"
}

remove_network() {
    local name="$1"
    docker network rm "$name"
}

# System operations
system_prune() {
    local all="$1"
    if [ "$all" = "all" ]; then
        docker system prune -a --volumes -f
    else
        docker system prune -f
    fi
}

get_system_info() {
    docker info --format '{{json .}}'
}

get_disk_usage() {
    docker system df -v
}

# Compose operations
compose_list() {
    docker-compose ps
}

compose_up() {
    local detach="${1:-true}"
    if [ "$detach" = "true" ]; then
        docker-compose up -d
    else
        docker-compose up
    fi
}

compose_down() {
    local volumes="${1:-false}"
    if [ "$volumes" = "true" ]; then
        docker-compose down -v
    else
        docker-compose down
    fi
}

compose_logs() {
    local service="$1"
    local lines="${2:-100}"
    if [ -n "$service" ]; then
        docker-compose logs --tail "$lines" "$service"
    else
        docker-compose logs --tail "$lines"
    fi
}

# Docker Service Management
start_docker_service() {
    local os_type=$(uname -s)
    debug_log "Starting Docker service on $os_type"
    
    case "$os_type" in
        "Darwin")
            # On macOS, try to start Docker Desktop
            if [ -e "/Applications/Docker.app" ]; then
                debug_log "Found Docker.app, attempting to start"
                open -a Docker
                echo "Starting Docker Desktop..."
                # Wait for Docker to start (up to 60 seconds)
                local counter=0
                while [ $counter -lt 60 ]; do
                    if docker info >/dev/null 2>&1; then
                        echo "Docker Desktop is now running"
                        return 0
                    fi
                    echo -n "."
                    sleep 1
                    ((counter++))
                done
                echo "Docker Desktop is taking longer than usual to start"
                echo "Please check the Docker Desktop application"
                return 1
            else
                echo "Docker Desktop not found in /Applications"
                echo "Please install Docker Desktop for macOS"
                return 1
            fi
            ;;
        "Linux")
            # On Linux, use systemctl
            if command -v systemctl >/dev/null 2>&1; then
                echo "Starting Docker daemon..."
                sudo systemctl start docker
                if [ $? -eq 0 ]; then
                    echo "Docker daemon started successfully"
                    return 0
                else
                    echo "Failed to start Docker daemon"
                    return 1
                fi
            else
                echo "System service manager not found"
                echo "Please start Docker daemon manually"
                return 1
            fi
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

stop_docker_service() {
    local os_type=$(uname -s)
    debug_log "Stopping Docker service on $os_type"
    
    case "$os_type" in
        "Darwin")
            # On macOS, try to quit Docker Desktop
            if pgrep -f "Docker Desktop" >/dev/null; then
                osascript -e 'quit app "Docker"'
                echo "Stopping Docker Desktop..."
                # Wait for Docker to stop (up to 30 seconds)
                local counter=0
                while [ $counter -lt 30 ]; do
                    if ! pgrep -f "Docker Desktop" >/dev/null; then
                        echo "Docker Desktop stopped"
                        return 0
                    fi
                    echo -n "."
                    sleep 1
                    ((counter++))
                done
                echo "Docker Desktop is taking longer than usual to stop"
                echo "You may need to force quit the application"
                return 1
            else
                echo "Docker Desktop is not running"
                return 0
            fi
            ;;
        "Linux")
            # On Linux, use systemctl
            if command -v systemctl >/dev/null 2>&1; then
                echo "Stopping Docker daemon..."
                sudo systemctl stop docker
                if [ $? -eq 0 ]; then
                    echo "Docker daemon stopped successfully"
                    return 0
                else
                    echo "Failed to stop Docker daemon"
                    return 1
                fi
            else
                echo "System service manager not found"
                echo "Please stop Docker daemon manually"
                return 1
            fi
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
}

restart_docker_service() {
    local os_type=$(uname -s)
    debug_log "Restarting Docker service on $os_type"
    
    stop_docker_service
    sleep 2
    start_docker_service
}

get_docker_service_status() {
    local os_type=$(uname -s)
    debug_log "Getting Docker service status on $os_type"
    
    case "$os_type" in
        "Darwin")
            if pgrep -f "Docker Desktop" >/dev/null; then
                if docker info >/dev/null 2>&1; then
                    echo "Docker Desktop is running and responsive"
                    return 0
                else
                    echo "Docker Desktop is running but not responsive"
                    return 1
                fi
            else
                echo "Docker Desktop is not running"
                return 1
            fi
            ;;
        "Linux")
            if command -v systemctl >/dev/null 2>&1; then
                status=$(systemctl is-active docker)
                if [ "$status" = "active" ]; then
                    echo "Docker daemon is running (active)"
                    return 0
                else
                    echo "Docker daemon is not running (inactive)"
                    return 1
                fi
            else
                if docker info >/dev/null 2>&1; then
                    echo "Docker daemon is running"
                    return 0
                else
                    echo "Docker daemon is not running"
                    return 1
                fi
            fi
            ;;
        *)
            echo "Unsupported operating system"
            return 1
            ;;
    esac
} 