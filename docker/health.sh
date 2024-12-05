#!/bin/bash

# Health check thresholds
CPU_WARNING_THRESHOLD=80
CPU_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=90

# Health check functions
check_container_health() {
    local container="$1"
    local health_status
    
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
    case "$health_status" in
        "healthy")
            log_success "Container $container is healthy"
            return 0
            ;;
        "unhealthy")
            log_error "Container $container is unhealthy"
            return 1
            ;;
        "starting")
            log_warning "Container $container health check is still running"
            return 2
            ;;
        *)
            if docker ps -q -f "name=$container" >/dev/null 2>&1; then
                log_warning "Container $container has no health check defined"
                return 3
            else
                log_error "Container $container is not running"
                return 1
            fi
            ;;
    esac
}

check_container_logs() {
    local container="$1"
    local error_pattern="${2:-error|exception|fatal|failed|crash}"
    local lines="${3:-100}"
    
    log_info "Checking last $lines lines of logs for container $container"
    
    if docker logs --tail "$lines" "$container" 2>&1 | grep -iE "$error_pattern" >/dev/null; then
        log_error "Found errors in container $container logs"
        return 1
    else
        log_success "No errors found in container $container logs"
        return 0
    fi
}

check_container_network() {
    local container="$1"
    local networks
    
    networks=$(docker inspect --format='{{range $net,$v := .NetworkSettings.Networks}}{{$net}} {{end}}' "$container")
    if [[ -z "$networks" ]]; then
        log_error "Container $container has no networks"
        return 1
    fi
    
    log_info "Container $container is connected to networks: $networks"
    return 0
}

check_container_mounts() {
    local container="$1"
    local mounts
    
    mounts=$(docker inspect --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' "$container")
    if [[ -z "$mounts" ]]; then
        log_warning "Container $container has no mounts"
        return 0
    fi
    
    log_info "Container $container mounts: $mounts"
    for mount in $mounts; do
        local source
        source=$(echo "$mount" | cut -d: -f1)
        if [[ ! -e "$source" ]]; then
            log_error "Mount source $source does not exist"
            return 1
        fi
    done
    
    return 0
}

check_system_resources() {
    local warning_threshold=${1:-80}
    local critical_threshold=${2:-90}
    local issues=0
    
    # Check CPU usage
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | cut -d% -f1)
    
    if [ "${cpu_usage%.*}" -gt "$critical_threshold" ]; then
        log_error "System CPU usage is critical: ${cpu_usage}%"
        issues=$((issues + 1))
    elif [ "${cpu_usage%.*}" -gt "$warning_threshold" ]; then
        log_warning "System CPU usage is high: ${cpu_usage}%"
    else
        log_success "System CPU usage is normal: ${cpu_usage}%"
    fi
    
    # Check memory usage
    local mem_usage
    if is_darwin; then
        mem_usage=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | cut -d% -f1)
    else
        mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    fi
    
    if [ "${mem_usage%.*}" -gt "$critical_threshold" ]; then
        log_error "System memory usage is critical: ${mem_usage}%"
        issues=$((issues + 1))
    elif [ "${mem_usage%.*}" -gt "$warning_threshold" ]; then
        log_warning "System memory usage is high: ${mem_usage}%"
    else
        log_success "System memory usage is normal: ${mem_usage}%"
    fi
    
    # Check disk usage
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d% -f1)
    
    if [ "$disk_usage" -gt "$critical_threshold" ]; then
        log_error "Disk usage is critical: ${disk_usage}%"
        issues=$((issues + 1))
    elif [ "$disk_usage" -gt "$warning_threshold" ]; then
        log_warning "Disk usage is high: ${disk_usage}%"
    else
        log_success "Disk usage is normal: ${disk_usage}%"
    fi
    
    return $issues
}

check_docker_daemon() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    local info
    info=$(docker info --format '{{json .}}')
    
    # Check for warnings
    local warnings
    warnings=$(echo "$info" | jq -r '.Warnings[]' 2>/dev/null)
    if [[ -n "$warnings" ]]; then
        log_warning "Docker daemon warnings:"
        echo "$warnings" | while read -r warning; do
            log_warning "  $warning"
        done
    fi
    
    # Check for errors
    if ! docker ps >/dev/null 2>&1; then
        log_error "Cannot connect to Docker daemon"
        return 1
    fi
    
    log_success "Docker daemon is healthy"
    return 0
}

perform_health_check() {
    local container="$1"
    local issues=0
    
    log_info "Starting health check for container $container"
    
    # Check container health status
    if ! check_container_health "$container"; then
        issues=$((issues + 1))
    fi
    
    # Check container logs
    if ! check_container_logs "$container"; then
        issues=$((issues + 1))
    fi
    
    # Check container network
    if ! check_container_network "$container"; then
        issues=$((issues + 1))
    fi
    
    # Check container mounts
    if ! check_container_mounts "$container"; then
        issues=$((issues + 1))
    fi
    
    # Check container resources
    if ! check_docker_resources "$container"; then
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "All health checks passed for container $container"
    else
        log_error "Found $issues issues during health check for container $container"
    fi
    
    return $issues
}

