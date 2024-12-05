#!/bin/bash

# Debug mode
: "${DEBUG:=0}"
debug() {
    if [[ "$DEBUG" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Docker paths
DOCKER_CLI_SOCKET="/var/run/docker.sock"
DOCKER_SOCKET="/var/run/docker.sock"
DOCKER_VM_DIR="$HOME/Library/Containers/com.docker.docker"
DOCKER_DESKTOP_DIR="$HOME/Library/Application Support/Docker Desktop"

# Recovery timeouts and attempts
RECOVERY_TIMEOUT=300  # 5 minutes
MAX_RECOVERY_ATTEMPTS=3
MONITOR_INTERVAL=5    # seconds between monitoring cycles
MAX_MONITOR_CYCLES=60 # maximum monitoring cycles (5 minutes with 5-second interval)

# Service dependencies
WEB_DEPS="api cache"
API_DEPS="db cache"
CACHE_DEPS="db"
DB_DEPS=""

# Recovery attempt tracking
declare -a RECOVERY_ORDER
declare -i web_attempts=0
declare -i api_attempts=0
declare -i cache_attempts=0
declare -i db_attempts=0

# Check if Docker is accessible
check_docker_access() {
    debug "Checking Docker access..."
    if ! safe_timeout 5 docker info >/dev/null 2>&1; then
        debug "Docker is not accessible"
        return 1
    fi
    debug "Docker is accessible"
    return 0
}

# Check if Docker is ready
check_docker_ready() {
    debug "Checking if Docker is ready..."
    check_docker_access
    return $?
}

# Check dependencies
check_dependencies() {
    local service="${1:-}"
    debug "Checking dependencies for service: ${service:-none}"
    
    # If no service is specified, check Docker daemon
    if [[ -z "$service" ]]; then
        debug "No service specified, checking Docker daemon"
        check_docker_access
        return $?
    fi
    
    local deps
    deps=$(get_service_deps "$service")
    debug "Dependencies for $service: ${deps:-none}"
    
    if [[ -z "$deps" ]]; then
        debug "No dependencies for $service"
        return 0
    fi
    
    for dep in $deps; do
        debug "Checking dependency: $dep"
        if ! safe_timeout 5 docker ps -q -f "name=$dep" -f "health=healthy" >/dev/null 2>&1; then
            debug "Dependency $dep is not healthy"
            return 1
        fi
        debug "Dependency $dep is healthy"
    done
    
    debug "All dependencies for $service are satisfied"
    return 0
}

get_service_attempts() {
    local service="${1:-}"
    debug "Getting attempts for service: ${service:-none}"
    
    if [[ -z "$service" ]]; then
        debug "No service name provided to get_service_attempts"
        return 1
    fi
    
    case "$service" in
        "web") echo "$web_attempts" ;;
        "api") echo "$api_attempts" ;;
        "cache") echo "$cache_attempts" ;;
        "db") echo "$db_attempts" ;;
        *) echo "0" ;;
    esac
}

increment_service_attempts() {
    local service="${1:-}"
    debug "Incrementing attempts for service: ${service:-none}"
    
    if [[ -z "$service" ]]; then
        debug "No service name provided to increment_service_attempts"
        return 1
    fi
    
    case "$service" in
        "web") ((web_attempts++)) ;;
        "api") ((api_attempts++)) ;;
        "cache") ((cache_attempts++)) ;;
        "db") ((db_attempts++)) ;;
        *) debug "Unknown service: $service" ;;
    esac
}

get_service_deps() {
    local service="${1:-}"
    debug "Getting dependencies for service: ${service:-none}"
    
    if [[ -z "$service" ]]; then
        debug "No service name provided to get_service_deps"
        return 1
    fi
    
    case "$service" in
        "web") echo "$WEB_DEPS" ;;
        "api") echo "$API_DEPS" ;;
        "cache") echo "$CACHE_DEPS" ;;
        "db") echo "$DB_DEPS" ;;
        *) echo "" ;;
    esac
}

# Tier 1: Soft Recovery
soft_recovery() {
    debug "Starting soft recovery..."
    local start_time=$SECONDS
    local timeout=60  # 1 minute timeout for soft recovery
    
    if is_darwin; then
        debug "Running macOS recovery"
        killall Docker || true
        open -a Docker
    else
        debug "Running Linux recovery"
        systemctl restart docker
    fi
    
    # Wait for Docker to be ready with timeout
    while ((SECONDS - start_time < timeout)); do
        debug "Waiting for Docker... ($(( SECONDS - start_time ))s)"
        if check_docker_access; then
            debug "Docker is ready"
            return 0
        fi
        sleep 1
    done
    
    debug "Soft recovery failed after ${timeout} seconds"
    return 1
}

# Tier 2: Force Recovery
force_recovery() {
    debug "Starting force recovery..."
    local start_time=$SECONDS
    local timeout=120  # 2 minutes timeout for force recovery
    
    if is_darwin; then
        debug "Running macOS force recovery"
        killall -9 Docker || true
        rm -f "${DOCKER_CLI_SOCKET}"
        open -a Docker
    else
        debug "Running Linux force recovery"
        systemctl stop docker
        rm -f "${DOCKER_SOCKET}"
        systemctl start docker
    fi
    
    # Wait for Docker to be ready with timeout
    while ((SECONDS - start_time < timeout)); do
        debug "Waiting for Docker... ($(( SECONDS - start_time ))s)"
        if check_docker_access; then
            debug "Docker is ready"
            return 0
        fi
        sleep 1
    done
    
    debug "Force recovery failed after ${timeout} seconds"
    return 1
}

# Tier 3: Full Recovery
full_recovery() {
    debug "Starting full recovery..."
    local start_time=$SECONDS
    local timeout=300  # 5 minutes timeout for full recovery
    
    if is_darwin; then
        debug "Running macOS full recovery"
        killall -9 Docker || true
        rm -f "${DOCKER_CLI_SOCKET}"
        rm -rf "${DOCKER_VM_DIR}"
        rm -rf "${DOCKER_DESKTOP_DIR}"
        open -a Docker
    else
        debug "Running Linux full recovery"
        systemctl stop docker
        rm -f "${DOCKER_SOCKET}"
        rm -rf /var/lib/docker/*
        systemctl start docker
    fi
    
    # Wait for Docker to be ready with timeout
    while ((SECONDS - start_time < timeout)); do
        debug "Waiting for Docker... ($(( SECONDS - start_time ))s)"
        if check_docker_access; then
            debug "Docker is ready"
            return 0
        fi
        sleep 1
    done
    
    debug "Full recovery failed after ${timeout} seconds"
    return 1
}

# Service health monitoring
monitor_services() {
    debug "Starting service monitoring..."
    local start_time=$SECONDS
    local cycle_count=0
    local recovered=0
    RECOVERY_ORDER=()
    local failed_services=()
    local last_status=""
    
    # Check Docker access first
    if ! check_docker_access; then
        debug "Docker is not accessible, cannot monitor services"
        return 1
    fi
    
    debug "Service dependencies:"
    for service in web api cache db; do
        local deps
        deps=$(get_service_deps "$service")
        debug "  $service depends on: ${deps:-none}"
    done
    
    # Monitor and recover in dependency order
    while ((SECONDS - start_time < RECOVERY_TIMEOUT && cycle_count < MAX_MONITOR_CYCLES)); do
        debug "Starting monitoring cycle $cycle_count"
        local current_status=""
        local changes=0
        
        for service in web api cache db; do
            debug "Checking service: $service"
            if check_dependencies "$service"; then
                if recover_service "$service" "${service}_container"; then
                    ((changes++))
                    debug "Service $service recovered successfully"
                else
                    debug "Service $service recovery failed"
                fi
            else
                debug "Service $service dependencies not met"
            fi
            current_status+="$(get_service_status "$service")"
        done
        
        debug "Current status: $current_status"
        debug "Last status: $last_status"
        debug "Changes: $changes"
        
        # If no changes in status for two cycles, break
        if [[ "$current_status" == "$last_status" ]] && ((changes == 0)); then
            debug "No changes detected for two cycles, monitoring complete"
            break
        fi
        
        last_status="$current_status"
        ((cycle_count++))
        
        debug "Sleeping for $MONITOR_INTERVAL seconds"
        sleep "$MONITOR_INTERVAL"
    done
    
    if ((cycle_count >= MAX_MONITOR_CYCLES)); then
        debug "Reached maximum monitoring cycles ($MAX_MONITOR_CYCLES)"
    fi
    
    if ((SECONDS - start_time >= RECOVERY_TIMEOUT)); then
        debug "Reached monitoring timeout (${RECOVERY_TIMEOUT}s)"
    fi
}

# Get service status for change detection
get_service_status() {
    local service="$1"
    local container_name="${service}_container"
    
    debug "Getting status for service: $service"
    if safe_timeout 5 docker ps -q -f "name=$container_name" -f "health=healthy" >/dev/null 2>&1; then
        debug "Service $service is healthy"
        echo "1"
    else
        debug "Service $service is not healthy"
        echo "0"
    fi
}

# Service recovery
recover_service() {
    local service="${1:-}"
    local container_name="${2:-}"
    local start_time=$SECONDS
    local timeout=60  # 1 minute timeout for service recovery
    
    debug "Starting recovery for service: ${service:-none}"
    
    if [[ -z "$service" ]]; then
        debug "No service name provided to recover_service"
        return 1
    fi
    
    if [[ -z "$container_name" ]]; then
        container_name="${service}_container"
        debug "Using default container name: $container_name"
    fi
    
    # Check recovery attempts
    local attempts
    attempts=$(get_service_attempts "$service")
    if ((attempts >= MAX_RECOVERY_ATTEMPTS)); then
        debug "Max recovery attempts reached for $service"
        return 1
    fi
    
    # Check dependencies first
    if ! check_dependencies "$service"; then
        debug "Dependencies not met for $service"
        return 1
    fi
    
    # Increment recovery attempts
    increment_service_attempts "$service"
    attempts=$(get_service_attempts "$service")
    debug "Recovery attempt $attempts for $service"
    
    # Stop unhealthy container
    if safe_timeout 5 docker ps -q -f "name=$container_name" >/dev/null 2>&1; then
        debug "Stopping container: $container_name"
        safe_timeout 10 docker stop "$container_name" >/dev/null 2>&1 || true
        safe_timeout 10 docker rm -f "$container_name" >/dev/null 2>&1 || true
    fi
    
    debug "Starting container: $container_name"
    if ! safe_timeout 10 docker run -d --name "$container_name" \
        --network "$RECOVERY_NETWORK" \
        --health-cmd="exit 0" \
        --health-interval=1s \
        --health-retries=3 \
        --health-timeout=1s \
        --restart=unless-stopped \
        alpine sh -c 'while true; do sleep 1; done' >/dev/null 2>&1; then
        debug "Failed to start container for $service"
        return 1
    fi
    
    # Wait for container to be healthy
    while ((SECONDS - start_time < timeout)); do
        debug "Waiting for container to be healthy... ($(( SECONDS - start_time ))s)"
        if safe_timeout 5 docker ps -q -f "name=$container_name" -f "health=healthy" >/dev/null 2>&1; then
            debug "Service $service is healthy"
            return 0
        fi
        sleep 1
    done
    
    debug "Service $service failed to become healthy after ${timeout} seconds"
    return 1
}

# Export functions
export DEBUG
export -f debug
export -f check_docker_access
export -f check_docker_ready
export -f check_dependencies
export -f get_service_attempts
export -f increment_service_attempts
export -f get_service_deps
export -f soft_recovery
export -f force_recovery
export -f full_recovery
export -f monitor_services
export -f recover_service
export -f get_service_status