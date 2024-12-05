#!/bin/bash

# Docker cleanup operations
cleanup_containers() {
    local prefix="$1"
    log_info "Stopping containers${prefix:+ matching prefix '$prefix'}..."
    if [[ -n "$prefix" ]]; then
        local containers
        containers=$(docker ps -q --filter name="$prefix")
        if [[ -n "$containers" ]]; then
            echo "$containers" | while read -r id; do
                docker stop "$id"
                docker rm "$id"
            done
        fi
    else
        local containers
        containers=$(docker ps -q)
        if [[ -n "$containers" ]]; then
            echo "$containers" | while read -r id; do
                docker stop "$id"
                docker rm "$id"
            done
        fi
    fi
}

cleanup_volumes() {
    local prefix="$1"
    log_info "Removing volumes${prefix:+ matching prefix '$prefix'}..."
    if [[ -n "$prefix" ]]; then
        local volumes
        volumes=$(docker volume ls -q | grep "^$prefix" || true)
        if [[ -n "$volumes" ]]; then
            echo "$volumes" | while read -r vol; do
                docker volume rm "$vol"
            done
        fi
    else
        local volumes
        volumes=$(docker volume ls -q)
        if [[ -n "$volumes" ]]; then
            echo "$volumes" | while read -r vol; do
                docker volume rm "$vol"
            done
        fi
    fi
}

cleanup_networks() {
    local prefix="$1"
    log_info "Removing networks${prefix:+ matching prefix '$prefix'}..."
    if [[ -n "$prefix" ]]; then
        local networks
        networks=$(docker network ls -q | grep "^$prefix" | grep -vE '^(bridge|host|none)$' || true)
        if [[ -n "$networks" ]]; then
            echo "$networks" | while read -r net; do
                docker network rm "$net"
            done
        fi
    else
        local networks
        networks=$(docker network ls -q | grep -vE '^(bridge|host|none)$')
        if [[ -n "$networks" ]]; then
            echo "$networks" | while read -r net; do
                docker network rm "$net"
            done
        fi
    fi
}

cleanup_images() {
    local image="$1"
    log_info "Removing images${image:+ matching '$image'}..."
    if [[ -n "$image" ]]; then
        local images
        images=$(docker images "$image" -q)
        if [[ -n "$images" ]]; then
            echo "$images" | while read -r img; do
                docker rmi -f "$img"
            done
        fi
    else
        local images
        images=$(docker images -q)
        if [[ -n "$images" ]]; then
            echo "$images" | while read -r img; do
                docker rmi -f "$img"
            done
        fi
    fi
}

docker_cleanup() {
    log_info "Performing full Docker cleanup..."
    cleanup_containers
    cleanup_volumes
    cleanup_networks
    cleanup_images
}

# Resource management
check_docker_resources() {
    local container="$1"
    local warning_threshold=${2:-80}
    local critical_threshold=${3:-90}
    local issues=0

    log_step "Checking resources for container $container"

    # Check CPU usage
    local cpu_usage
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container" | sed 's/%//')
    
    if [ "${cpu_usage%.*}" -gt "$critical_threshold" ]; then
        log_error "Container CPU usage is critical: ${cpu_usage}%"
        issues=$((issues + 1))
    elif [ "${cpu_usage%.*}" -gt "$warning_threshold" ]; then
        log_warning "Container CPU usage is high: ${cpu_usage}%"
    else
        log_success "Container CPU usage is normal: ${cpu_usage}%"
    fi

    # Check memory usage
    local mem_usage
    mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$container" | sed 's/%//')
    
    if [ "${mem_usage%.*}" -gt "$critical_threshold" ]; then
        log_error "Container memory usage is critical: ${mem_usage}%"
        issues=$((issues + 1))
    elif [ "${mem_usage%.*}" -gt "$warning_threshold" ]; then
        log_warning "Container memory usage is high: ${mem_usage}%"
    else
        log_success "Container memory usage is normal: ${mem_usage}%"
    fi

    return $issues
}

manage_container_resources() {
    local container="$1"
    if check_container_resources "$container"; then
        log_info "Container $container resources are within limits"
    else
        log_warning "Container $container resources need adjustment"
        # Implement resource adjustment logic here
    fi
}

