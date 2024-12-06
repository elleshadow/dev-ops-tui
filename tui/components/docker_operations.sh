#!/bin/bash

# Docker operations with robust process management
source "${PROJECT_ROOT}/tui/components/process_manager.sh"

# Initialize Docker environment
init_docker_operations() {
    # Ensure log directories exist
    mkdir -p "${PROJECT_ROOT}/logs/docker"
    
    # Set up cleanup trap
    trap 'cleanup_docker_resources' EXIT
    return 0
}

# Start Docker services with proper process management
start_docker_services() {
    local compose_file="${1:-docker-compose.yml}"
    local log_dir="${PROJECT_ROOT}/logs/docker"
    local log_file="${log_dir}/docker.log"
    local error_log="${log_dir}/docker.error.log"
    
    # Clear previous logs
    echo "=== Docker Services Started $(date) ===" > "$log_file"
    echo "=== Docker Errors Started $(date) ===" > "$error_log"
    
    # Start services with output redirection
    (DOCKER_HOST="$DOCKER_HOST" docker-compose -f "$compose_file" up -d \
        > >(tee -a "$log_file") \
        2> >(tee -a "$error_log" >&2)) &
    local pid=$!
    
    # Monitor startup
    local timeout=30
    local count=0
    while ((count < timeout)); do
        if ! kill -0 $pid 2>/dev/null; then
            # Process ended, check if successful
            if grep -q "error\|failed" "$error_log"; then
                log_error "Docker services failed to start"
                collect_docker_logs
                return 1
            fi
            break
        fi
        
        # Check if services are healthy
        if docker-compose -f "$compose_file" ps | grep -q "healthy"; then
            log_info "Docker services started successfully"
            return 0
        fi
        
        sleep 1
        ((count++))
    done
    
    # Handle timeout
    if ((count >= timeout)); then
        log_error "Docker services startup timed out"
        kill $pid 2>/dev/null
        collect_docker_logs
        return 1
    fi
    
    return 0
}

# Stop Docker services gracefully
stop_docker_services() {
    local compose_file="${1:-docker-compose.yml}"
    local timeout=30
    
    # Stop services
    if ! docker-compose -f "$compose_file" stop --timeout $timeout; then
        log_error "Failed to stop Docker services gracefully"
        return 1
    fi
    
    # Verify all services stopped
    local count=0
    while ((count < timeout)); do
        if ! docker-compose -f "$compose_file" ps --quiet | grep -q .; then
            log_info "All Docker services stopped"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    # Force stop if timeout reached
    log_warning "Some services did not stop gracefully, forcing..."
    docker-compose -f "$compose_file" kill
    return 1
}

# Restart Docker services
restart_docker_services() {
    if ! stop_docker_services; then
        log_error "Failed to stop services for restart"
        return 1
    fi
    
    if ! start_docker_services; then
        log_error "Failed to restart services"
        return 1
    fi
    
    return 0
}

# Show Docker service status
show_docker_status() {
    local compose_file="${1:-docker-compose.yml}"
    
    # Use terminal state for clean display
    with_terminal_state "docker_status" "
        clear
        echo -e '\033[36m=== Docker Services Status ===\033[0m'
        docker-compose -f '$compose_file' ps
        echo
        echo 'Press any key to continue...'
        read -n 1
    "
}

# Show Docker service logs
show_docker_logs() {
    local compose_file="${1:-docker-compose.yml}"
    local service="$2"
    
    # If no service specified, show all
    local log_cmd
    if [[ -n "$service" ]]; then
        log_cmd="docker-compose -f '$compose_file' logs --tail=100 -f '$service'"
    else
        log_cmd="docker-compose -f '$compose_file' logs --tail=100 -f"
    fi
    
    # Show logs with proper terminal handling
    with_terminal_state "docker_logs" "
        clear
        echo -e '\033[36m=== Docker Services Logs ===\033[0m'
        eval '$log_cmd' &
        local log_pid=\$!
        
        # Wait for user input to exit
        read -n 1
        kill \$log_pid 2>/dev/null
    "
}

# Collect Docker logs for debugging
collect_docker_logs() {
    local compose_file="${1:-docker-compose.yml}"
    local log_dir="${PROJECT_ROOT}/logs/docker"
    local debug_log="${log_dir}/debug_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "=== Docker Debug Info $(date) ==="
        echo
        echo "=== Docker Version ==="
        docker version
        echo
        echo "=== Docker Compose Version ==="
        docker-compose version
        echo
        echo "=== Docker Services Status ==="
        docker-compose -f "$compose_file" ps
        echo
        echo "=== Docker Services Logs ==="
        docker-compose -f "$compose_file" logs --no-color
    } > "$debug_log"
    
    log_info "Debug logs collected at: $debug_log"
}

# Clean up Docker resources
cleanup_docker_resources() {
    local compose_file="${1:-docker-compose.yml}"
    
    # Stop all services
    docker-compose -f "$compose_file" stop --timeout 5 >/dev/null 2>&1 || true
    
    # Remove containers
    docker-compose -f "$compose_file" rm -f >/dev/null 2>&1 || true
    
    # Clean up networks
    docker network prune -f >/dev/null 2>&1 || true
} 