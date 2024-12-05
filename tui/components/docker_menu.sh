#!/bin/bash

# Get the actual script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required components
source "$SCRIPT_DIR/dialog.sh"
source "$SCRIPT_DIR/../../core/docker.sh"

# Docker service management menu
show_docker_service_menu() {
    debug_log "Entering Docker service menu"
    while true; do
        # Get current status
        local status_output
        status_output=$(get_docker_service_status)
        local status_code=$?
        
        # Show menu with current status
        local choice
        choice=$(tui_dialog_menu "Docker Service Management" \
            "Current Status: $status_output\n\nSelect an operation:" \
            15 60 \
            "1" "Start Docker" \
            "2" "Stop Docker" \
            "3" "Restart Docker" \
            "4" "Check Status" \
            "5" "Back to Main Menu")

        case $? in
            0)
                case $choice in
                    1)
                        debug_log "Starting Docker service"
                        local output
                        output=$(start_docker_service)
                        tui_dialog_message "Start Docker" "$output" 15 60
                        ;;
                    2)
                        if tui_dialog_yesno "Confirm" "Are you sure you want to stop Docker?" 8 40; then
                            debug_log "Stopping Docker service"
                            local output
                            output=$(stop_docker_service)
                            tui_dialog_message "Stop Docker" "$output" 15 60
                        fi
                        ;;
                    3)
                        if tui_dialog_yesno "Confirm" "Are you sure you want to restart Docker?" 8 40; then
                            debug_log "Restarting Docker service"
                            local output
                            output=$(restart_docker_service)
                            tui_dialog_message "Restart Docker" "$output" 15 60
                        fi
                        ;;
                    4)
                        debug_log "Checking Docker status"
                        local output
                        output=$(get_docker_service_status)
                        tui_dialog_message "Docker Status" "$output" 15 60
                        ;;
                    5)
                        debug_log "Exiting Docker service menu"
                        return
                        ;;
                esac
                ;;
            *)
                debug_log "Exiting Docker service menu (cancelled)"
                return
                ;;
        esac
    done
}

# Docker system check with service management option
check_docker_system() {
    debug_log "Starting Docker system check"
    local check_output=""
    local all_passed=true
    local os_type=$(uname -s)
    local error_details=""

    # Check Docker installation
    if output=$(check_docker_installed); then
        check_output+="✓ Docker Installation:\n$output\n\n"
    else
        check_output+="✗ Docker Installation Failed:\n$output\n\n"
        error_details+="Docker is not properly installed.\n"
        all_passed=false
    fi

    # Check Docker Compose
    if output=$(check_docker_compose_installed); then
        check_output+="✓ Docker Compose:\n$output\n\n"
    else
        check_output+="! Docker Compose:\n$output (optional)\n\n"
    fi

    # Check Docker daemon
    if output=$(check_docker_running); then
        check_output+="✓ Docker Daemon:\n$output\n\n"
    else
        check_output+="✗ Docker Daemon Error:\n$output\n\n"
        if [[ $os_type == "Darwin" ]]; then
            error_details+="Docker Desktop needs to be running.\n"
        else
            error_details+="Docker daemon is not running.\n"
        fi
        all_passed=false
    fi

    # Check permissions
    if output=$(check_docker_permissions); then
        check_output+="✓ Docker Permissions:\n$output\n\n"
    else
        check_output+="✗ Docker Permissions Error:\n$output\n\n"
        error_details+="Permission issues detected.\n"
        all_passed=false
    fi

    # Show results with service management option
    if [ "$all_passed" = true ]; then
        local choice
        choice=$(tui_dialog_menu "Docker System Check" \
            "✓ All checks passed!\n\n$check_output\n\nWhat would you like to do?" \
            25 80 \
            "1" "Manage Docker Service" \
            "2" "Continue" \
            "3" "Exit")
        
        case $choice in
            1) 
                debug_log "Opening Docker service menu from successful check"
                show_docker_service_menu 
                ;;
            3) 
                debug_log "Exiting from successful check"
                exit 0 
                ;;
        esac
        return 0
    else
        local help_msg="$(get_install_instructions "$os_type")"
        local choice
        choice=$(tui_dialog_menu "Docker System Check" \
            "✗ System check failed!\n\nIssues Found:\n$error_details\n\n\
Detailed Status:\n$check_output\n\nWhat would you like to do?" \
            25 80 \
            "1" "Manage Docker Service" \
            "2" "View Installation Instructions" \
            "3" "Continue" \
            "4" "Exit")
        
        case $choice in
            1)
                debug_log "Opening Docker service menu from failed check"
                show_docker_service_menu 
                ;;
            2)
                debug_log "Showing installation instructions"
                tui_dialog_message "Installation Instructions" "$help_msg" 25 80
                ;;
            4)
                debug_log "Exiting from failed check"
                exit 0 
                ;;
        esac
        return 1
    fi
}

# Container management menu
show_container_menu() {
    while true; do
        local containers=$(docker ps -a --format "{{.Names}}\n{{.Status}}\n{{.Image}}" 2>/dev/null)
        
        action=$(dialog --clear --title "Container Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 8 \
            "List Containers" "Show all containers" \
            "Start Container" "Start a stopped container" \
            "Stop Container" "Stop a running container" \
            "Remove Container" "Remove a container" \
            "Container Stats" "Show container statistics" \
            "Container Logs" "View container logs" \
            "Health Check" "Check container health" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Containers")
                docker ps -a | less
                ;;
            "Start Container")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to start:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker start "$container"
                fi
                ;;
            "Stop Container")
                local container
                container=$(docker ps --format "{{.Names}}" | \
                    dialog --menu "Select container to stop:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker stop "$container"
                fi
                ;;
            "Remove Container")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    if dialog --yesno "Are you sure you want to remove $container?" 8 40; then
                        docker rm -f "$container"
                    fi
                fi
                ;;
            "Container Stats")
                docker stats --no-stream | less
                ;;
            "Container Logs")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to view logs:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker logs "$container" | less
                fi
                ;;
            "Health Check")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to check:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    perform_health_check "$container" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

# Image management menu
show_image_menu() {
    while true; do
        action=$(dialog --clear --title "Image Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 7 \
            "List Images" "Show all images" \
            "Pull Image" "Pull a new image" \
            "Remove Image" "Remove an image" \
            "Prune Images" "Remove unused images" \
            "Image History" "Show image history" \
            "Image Inspect" "Inspect image details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Images")
                docker images | less
                ;;
            "Pull Image")
                local image
                image=$(dialog --inputbox "Enter image name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker pull "$image" | less
                fi
                ;;
            "Remove Image")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    if dialog --yesno "Are you sure you want to remove $image?" 8 40; then
                        docker rmi "$image"
                    fi
                fi
                ;;
            "Prune Images")
                if dialog --yesno "Are you sure you want to remove all unused images?" 8 40; then
                    docker image prune -a
                fi
                ;;
            "Image History")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to view history:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker history "$image" | less
                fi
                ;;
            "Image Inspect")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker inspect "$image" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

# Volume management menu
show_volume_menu() {
    while true; do
        action=$(dialog --clear --title "Volume Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "List Volumes" "Show all volumes" \
            "Create Volume" "Create a new volume" \
            "Remove Volume" "Remove a volume" \
            "Prune Volumes" "Remove unused volumes" \
            "Volume Inspect" "Inspect volume details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Volumes")
                docker volume ls | less
                ;;
            "Create Volume")
                local name
                name=$(dialog --inputbox "Enter volume name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$name" ]; then
                    docker volume create "$name"
                fi
                ;;
            "Remove Volume")
                local volume
                volume=$(docker volume ls --format "{{.Name}}" | \
                    dialog --menu "Select volume to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$volume" ]; then
                    if dialog --yesno "Are you sure you want to remove $volume?" 8 40; then
                        docker volume rm "$volume"
                    fi
                fi
                ;;
            "Prune Volumes")
                if dialog --yesno "Are you sure you want to remove all unused volumes?" 8 40; then
                    docker volume prune
                fi
                ;;
            "Volume Inspect")
                local volume
                volume=$(docker volume ls --format "{{.Name}}" | \
                    dialog --menu "Select volume to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$volume" ]; then
                    docker volume inspect "$volume" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

# Network management menu
show_network_menu() {
    while true; do
        action=$(dialog --clear --title "Network Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "List Networks" "Show all networks" \
            "Create Network" "Create a new network" \
            "Remove Network" "Remove a network" \
            "Prune Networks" "Remove unused networks" \
            "Network Inspect" "Inspect network details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Networks")
                docker network ls | less
                ;;
            "Create Network")
                local name
                name=$(dialog --inputbox "Enter network name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$name" ]; then
                    docker network create "$name"
                fi
                ;;
            "Remove Network")
                local network
                network=$(docker network ls --format "{{.Name}}" | \
                    dialog --menu "Select network to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$network" ]; then
                    if dialog --yesno "Are you sure you want to remove $network?" 8 40; then
                        docker network rm "$network"
                    fi
                fi
                ;;
            "Prune Networks")
                if dialog --yesno "Are you sure you want to remove all unused networks?" 8 40; then
                    docker network prune
                fi
                ;;
            "Network Inspect")
                local network
                network=$(docker network ls --format "{{.Name}}" | \
                    dialog --menu "Select network to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$network" ]; then
                    docker network inspect "$network" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

# System management menu
show_system_menu() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "System Management" \
            "Select an operation:" \
            15 60 \
            "1" "System Info" \
            "2" "Disk Usage" \
            "3" "Prune System" \
            "4" "Back to Main Menu")

        case $? in
            0)
                case $choice in
                    1) show_system_info ;;
                    2) show_disk_usage ;;
                    3) system_prune_dialog ;;
                    4) return ;;
                esac
                ;;
            *)
                return
                ;;
        esac
    done
}

# Container operations dialogs
show_running_containers() {
    local containers
    containers=$(list_containers)
    tui_dialog_message "Running Containers" "$containers" 20 80
}

show_all_containers() {
    local containers
    containers=$(list_containers "all")
    tui_dialog_message "All Containers" "$containers" 20 80
}

start_container_dialog() {
    local container_id
    container_id=$(tui_dialog_input "Start Container" "Enter container ID:" 10 60)
    [ $? -eq 0 ] && [ -n "$container_id" ] && start_container "$container_id"
}

stop_container_dialog() {
    local container_id
    container_id=$(tui_dialog_input "Stop Container" "Enter container ID:" 10 60)
    [ $? -eq 0 ] && [ -n "$container_id" ] && stop_container "$container_id"
}

restart_container_dialog() {
    local container_id
    container_id=$(tui_dialog_input "Restart Container" "Enter container ID:" 10 60)
    [ $? -eq 0 ] && [ -n "$container_id" ] && restart_container "$container_id"
}

remove_container_dialog() {
    local container_id
    container_id=$(tui_dialog_input "Remove Container" "Enter container ID:" 10 60)
    if [ $? -eq 0 ] && [ -n "$container_id" ]; then
        if tui_dialog_yesno "Confirm" "Force remove container?" 8 40; then
            remove_container "$container_id" "force"
        else
            remove_container "$container_id"
        fi
    fi
}

view_container_logs_dialog() {
    local container_id
    container_id=$(tui_dialog_input "View Logs" "Enter container ID:" 10 60)
    if [ $? -eq 0 ] && [ -n "$container_id" ]; then
        local logs
        logs=$(get_container_logs "$container_id")
        tui_dialog_message "Container Logs" "$logs" 20 80
    fi
}

view_container_stats_dialog() {
    local container_id
    container_id=$(tui_dialog_input "View Stats" "Enter container ID:" 10 60)
    if [ $? -eq 0 ] && [ -n "$container_id" ]; then
        local stats
        stats=$(get_container_stats "$container_id")
        tui_dialog_message "Container Stats" "$stats" 20 80
    fi
}

# Image operations dialogs
show_images() {
    local images
    images=$(list_images)
    tui_dialog_message "Docker Images" "$images" 20 80
}

pull_image_dialog() {
    local image
    image=$(tui_dialog_input "Pull Image" "Enter image name:" 10 60)
    if [ $? -eq 0 ] && [ -n "$image" ]; then
        local tag
        tag=$(tui_dialog_input "Image Tag" "Enter tag (default: latest):" 10 60)
        [ $? -eq 0 ] && pull_image "$image" "${tag:-latest}"
    fi
}

remove_image_dialog() {
    local image
    image=$(tui_dialog_input "Remove Image" "Enter image ID or name:" 10 60)
    if [ $? -eq 0 ] && [ -n "$image" ]; then
        if tui_dialog_yesno "Confirm" "Force remove image?" 8 40; then
            remove_image "$image" "force"
        else
            remove_image "$image"
        fi
    fi
}

# Volume operations dialogs
show_volumes() {
    local volumes
    volumes=$(list_volumes)
    tui_dialog_message "Docker Volumes" "$volumes" 20 80
}

create_volume_dialog() {
    local name
    name=$(tui_dialog_input "Create Volume" "Enter volume name:" 10 60)
    [ $? -eq 0 ] && [ -n "$name" ] && create_volume "$name"
}

remove_volume_dialog() {
    local name
    name=$(tui_dialog_input "Remove Volume" "Enter volume name:" 10 60)
    if [ $? -eq 0 ] && [ -n "$name" ]; then
        if tui_dialog_yesno "Confirm" "Force remove volume?" 8 40; then
            remove_volume "$name" "force"
        else
            remove_volume "$name"
        fi
    fi
}

# Network operations dialogs
show_networks() {
    local networks
    networks=$(list_networks)
    tui_dialog_message "Docker Networks" "$networks" 20 80
}

create_network_dialog() {
    local name
    name=$(tui_dialog_input "Create Network" "Enter network name:" 10 60)
    if [ $? -eq 0 ] && [ -n "$name" ]; then
        local driver
        driver=$(tui_dialog_input "Network Driver" "Enter driver (default: bridge):" 10 60)
        [ $? -eq 0 ] && create_network "$name" "${driver:-bridge}"
    fi
}

remove_network_dialog() {
    local name
    name=$(tui_dialog_input "Remove Network" "Enter network name:" 10 60)
    [ $? -eq 0 ] && [ -n "$name" ] && remove_network "$name"
}

# System operations dialogs
show_system_info() {
    local info
    info=$(get_system_info)
    tui_dialog_message "System Info" "$info" 20 80
}

show_disk_usage() {
    local usage
    usage=$(get_disk_usage)
    tui_dialog_message "Disk Usage" "$usage" 20 80
}

system_prune_dialog() {
    if tui_dialog_yesno "System Prune" "Remove all unused containers, networks, images, and volumes?" 8 60; then
        if tui_dialog_yesno "Confirm" "Include all unused images?" 8 40; then
            system_prune "all"
        else
            system_prune
        fi
    fi
}

show_docker_management() {
    while true; do
        local docker_status=$(docker info >/dev/null 2>&1 && echo "\Z2Running\Zn" || echo "\Z1Stopped\Zn")
        local containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
        local images=$(docker images -q 2>/dev/null | wc -l | tr -d ' ')
        local volumes=$(docker volume ls -q 2>/dev/null | wc -l | tr -d ' ')
        local networks=$(docker network ls -q 2>/dev/null | wc -l | tr -d ' ')
        
        local info="Docker Status: $docker_status\n"
        info+="Active Containers: $containers\n"
        info+="Images: $images\n"
        info+="Volumes: $volumes\n"
        info+="Networks: $networks\n"
        
        action=$(dialog --clear --title "Docker Management" \
            --colors \
            --menu "$info" \
            $TUI_HEIGHT $TUI_WIDTH 15 \
            "Container Management" "Manage Docker containers" \
            "Image Management" "Manage Docker images" \
            "Volume Management" "Manage Docker volumes" \
            "Network Management" "Manage Docker networks" \
            "Resource Monitor" "Monitor system resources" \
            "Health Check" "Check Docker system health" \
            "Recovery Tools" "Docker recovery options" \
            "Cleanup Tools" "Clean Docker resources" \
            "Service Monitor" "Monitor Docker services" \
            "Logs" "View Docker logs" \
            "Settings" "Configure Docker settings" \
            "Back" "Return to main menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Container Management")
                show_container_menu
                ;;
            "Image Management")
                show_image_menu
                ;;
            "Volume Management")
                show_volume_menu
                ;;
            "Network Management")
                show_network_menu
                ;;
            "Resource Monitor")
                show_resource_menu
                ;;
            "Health Check")
                show_health_menu
                ;;
            "Recovery Tools")
                show_recovery_menu
                ;;
            "Cleanup Tools")
                show_cleanup_menu
                ;;
            "Service Monitor")
                show_service_menu
                ;;
            "Logs")
                show_logs_menu
                ;;
            "Settings")
                show_settings_menu
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_container_menu() {
    while true; do
        local containers=$(docker ps -a --format "{{.Names}}\n{{.Status}}\n{{.Image}}" 2>/dev/null)
        
        action=$(dialog --clear --title "Container Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 8 \
            "List Containers" "Show all containers" \
            "Start Container" "Start a stopped container" \
            "Stop Container" "Stop a running container" \
            "Remove Container" "Remove a container" \
            "Container Stats" "Show container statistics" \
            "Container Logs" "View container logs" \
            "Health Check" "Check container health" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Containers")
                docker ps -a | less
                ;;
            "Start Container")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to start:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker start "$container"
                fi
                ;;
            "Stop Container")
                local container
                container=$(docker ps --format "{{.Names}}" | \
                    dialog --menu "Select container to stop:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker stop "$container"
                fi
                ;;
            "Remove Container")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    if dialog --yesno "Are you sure you want to remove $container?" 8 40; then
                        docker rm -f "$container"
                    fi
                fi
                ;;
            "Container Stats")
                docker stats --no-stream | less
                ;;
            "Container Logs")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to view logs:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker logs "$container" | less
                fi
                ;;
            "Health Check")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container to check:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    perform_health_check "$container" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_image_menu() {
    while true; do
        action=$(dialog --clear --title "Image Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 7 \
            "List Images" "Show all images" \
            "Pull Image" "Pull a new image" \
            "Remove Image" "Remove an image" \
            "Prune Images" "Remove unused images" \
            "Image History" "Show image history" \
            "Image Inspect" "Inspect image details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Images")
                docker images | less
                ;;
            "Pull Image")
                local image
                image=$(dialog --inputbox "Enter image name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker pull "$image" | less
                fi
                ;;
            "Remove Image")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    if dialog --yesno "Are you sure you want to remove $image?" 8 40; then
                        docker rmi "$image"
                    fi
                fi
                ;;
            "Prune Images")
                if dialog --yesno "Are you sure you want to remove all unused images?" 8 40; then
                    docker image prune -a
                fi
                ;;
            "Image History")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to view history:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker history "$image" | less
                fi
                ;;
            "Image Inspect")
                local image
                image=$(docker images --format "{{.Repository}}:{{.Tag}}" | \
                    dialog --menu "Select image to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$image" ]; then
                    docker inspect "$image" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_volume_menu() {
    while true; do
        action=$(dialog --clear --title "Volume Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "List Volumes" "Show all volumes" \
            "Create Volume" "Create a new volume" \
            "Remove Volume" "Remove a volume" \
            "Prune Volumes" "Remove unused volumes" \
            "Volume Inspect" "Inspect volume details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Volumes")
                docker volume ls | less
                ;;
            "Create Volume")
                local name
                name=$(dialog --inputbox "Enter volume name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$name" ]; then
                    docker volume create "$name"
                fi
                ;;
            "Remove Volume")
                local volume
                volume=$(docker volume ls --format "{{.Name}}" | \
                    dialog --menu "Select volume to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$volume" ]; then
                    if dialog --yesno "Are you sure you want to remove $volume?" 8 40; then
                        docker volume rm "$volume"
                    fi
                fi
                ;;
            "Prune Volumes")
                if dialog --yesno "Are you sure you want to remove all unused volumes?" 8 40; then
                    docker volume prune
                fi
                ;;
            "Volume Inspect")
                local volume
                volume=$(docker volume ls --format "{{.Name}}" | \
                    dialog --menu "Select volume to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$volume" ]; then
                    docker volume inspect "$volume" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_network_menu() {
    while true; do
        action=$(dialog --clear --title "Network Management" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "List Networks" "Show all networks" \
            "Create Network" "Create a new network" \
            "Remove Network" "Remove a network" \
            "Prune Networks" "Remove unused networks" \
            "Network Inspect" "Inspect network details" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "List Networks")
                docker network ls | less
                ;;
            "Create Network")
                local name
                name=$(dialog --inputbox "Enter network name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$name" ]; then
                    docker network create "$name"
                fi
                ;;
            "Remove Network")
                local network
                network=$(docker network ls --format "{{.Name}}" | \
                    dialog --menu "Select network to remove:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$network" ]; then
                    if dialog --yesno "Are you sure you want to remove $network?" 8 40; then
                        docker network rm "$network"
                    fi
                fi
                ;;
            "Prune Networks")
                if dialog --yesno "Are you sure you want to remove all unused networks?" 8 40; then
                    docker network prune
                fi
                ;;
            "Network Inspect")
                local network
                network=$(docker network ls --format "{{.Name}}" | \
                    dialog --menu "Select network to inspect:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$network" ]; then
                    docker network inspect "$network" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_resource_menu() {
    while true; do
        action=$(dialog --clear --title "Resource Monitor" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 5 \
            "System Resources" "Show system resource usage" \
            "Container Resources" "Show container resource usage" \
            "Resource Limits" "Show resource limits" \
            "Resource History" "Show resource usage history" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "System Resources")
                check_system_resources | less
                ;;
            "Container Resources")
                local container
                container=$(docker ps --format "{{.Names}}" | \
                    dialog --menu "Select container:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    check_docker_resources "$container" | less
                fi
                ;;
            "Resource Limits")
                dialog --msgbox "System Limits:\n\nMax CPU: $(get_max_cpu)\nMax Memory: $(get_max_memory)" 10 40
                ;;
            "Resource History")
                docker stats --no-stream | less
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_health_menu() {
    while true; do
        action=$(dialog --clear --title "Health Check" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "Docker Health" "Check Docker daemon health" \
            "Container Health" "Check container health" \
            "Network Health" "Check network connectivity" \
            "Volume Health" "Check volume status" \
            "Full Health Check" "Run complete health check" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Docker Health")
                check_docker_daemon | less
                ;;
            "Container Health")
                local container
                container=$(docker ps --format "{{.Names}}" | \
                    dialog --menu "Select container:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    check_container_health "$container" | less
                fi
                ;;
            "Network Health")
                local network
                network=$(docker network ls --format "{{.Name}}" | \
                    dialog --menu "Select network:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$network" ]; then
                    docker network inspect "$network" | less
                fi
                ;;
            "Volume Health")
                local volume
                volume=$(docker volume ls --format "{{.Name}}" | \
                    dialog --menu "Select volume:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$volume" ]; then
                    check_container_mounts "$volume" | less
                fi
                ;;
            "Full Health Check")
                perform_health_check "all" | less
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_recovery_menu() {
    while true; do
        action=$(dialog --clear --title "Recovery Tools" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 5 \
            "Soft Recovery" "Restart Docker service" \
            "Force Recovery" "Force restart Docker" \
            "Full Recovery" "Complete Docker reset" \
            "Service Recovery" "Recover specific service" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Soft Recovery")
                if dialog --yesno "Are you sure you want to perform a soft recovery?" 8 40; then
                    soft_recovery | less
                fi
                ;;
            "Force Recovery")
                if dialog --yesno "Are you sure you want to perform a force recovery?" 8 40; then
                    force_recovery | less
                fi
                ;;
            "Full Recovery")
                if dialog --yesno "WARNING: This will reset Docker to factory settings.\nAll data will be lost.\nAre you sure?" 10 50; then
                    full_recovery | less
                fi
                ;;
            "Service Recovery")
                local service
                service=$(dialog --inputbox "Enter service name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$service" ]; then
                    recover_service "$service" | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_cleanup_menu() {
    while true; do
        action=$(dialog --clear --title "Cleanup Tools" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 6 \
            "Container Cleanup" "Remove stopped containers" \
            "Image Cleanup" "Remove unused images" \
            "Volume Cleanup" "Remove unused volumes" \
            "Network Cleanup" "Remove unused networks" \
            "Full Cleanup" "Remove all unused resources" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Container Cleanup")
                if dialog --yesno "Remove all stopped containers?" 8 40; then
                    cleanup_containers | less
                fi
                ;;
            "Image Cleanup")
                if dialog --yesno "Remove all unused images?" 8 40; then
                    cleanup_images | less
                fi
                ;;
            "Volume Cleanup")
                if dialog --yesno "Remove all unused volumes?" 8 40; then
                    cleanup_volumes | less
                fi
                ;;
            "Network Cleanup")
                if dialog --yesno "Remove all unused networks?" 8 40; then
                    cleanup_networks | less
                fi
                ;;
            "Full Cleanup")
                if dialog --yesno "WARNING: This will remove all unused Docker resources.\nAre you sure?" 8 50; then
                    docker_cleanup | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_service_menu() {
    while true; do
        action=$(dialog --clear --title "Service Monitor" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 5 \
            "Monitor Services" "Start service monitoring" \
            "Service Status" "Check service status" \
            "Service Logs" "View service logs" \
            "Service Dependencies" "View service dependencies" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Monitor Services")
                monitor_services | less
                ;;
            "Service Status")
                local service
                service=$(dialog --inputbox "Enter service name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$service" ]; then
                    check_dependencies "$service" | less
                fi
                ;;
            "Service Logs")
                local service
                service=$(dialog --inputbox "Enter service name:" 8 40 2>&1 >/dev/tty)
                if [ -n "$service" ]; then
                    check_container_logs "$service" | less
                fi
                ;;
            "Service Dependencies")
                for service in "${!SERVICE_DEPS[@]}"; do
                    local deps="${SERVICE_DEPS[$service]}"
                    echo "$service depends on: ${deps:-none}"
                done | less
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_logs_menu() {
    while true; do
        action=$(dialog --clear --title "Docker Logs" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 5 \
            "Container Logs" "View container logs" \
            "Docker Daemon Logs" "View Docker daemon logs" \
            "System Logs" "View system logs" \
            "Error Logs" "View error logs" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "Container Logs")
                local container
                container=$(docker ps -a --format "{{.Names}}" | \
                    dialog --menu "Select container:" \
                    $TUI_HEIGHT $TUI_WIDTH 10 $(cat) 2>&1 >/dev/tty)
                if [ -n "$container" ]; then
                    docker logs "$container" | less
                fi
                ;;
            "Docker Daemon Logs")
                if is_darwin; then
                    log show --predicate 'process == "com.docker.docker"' --last 1h | less
                else
                    journalctl -u docker | less
                fi
                ;;
            "System Logs")
                if is_darwin; then
                    log show --last 1h | grep -i docker | less
                else
                    journalctl | grep -i docker | less
                fi
                ;;
            "Error Logs")
                if is_darwin; then
                    log show --predicate 'process == "com.docker.docker"' --last 1h | grep -i error | less
                else
                    journalctl -u docker | grep -i error | less
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

show_settings_menu() {
    while true; do
        action=$(dialog --clear --title "Docker Settings" \
            --menu "Select action:" \
            $TUI_HEIGHT $TUI_WIDTH 5 \
            "View Settings" "Show current settings" \
            "Edit Settings" "Modify Docker settings" \
            "Reset Settings" "Reset to defaults" \
            "Import Settings" "Import settings file" \
            "Back" "Return to previous menu" \
            2>&1 >/dev/tty)
        
        case $action in
            "View Settings")
                docker info | less
                ;;
            "Edit Settings")
                if is_darwin; then
                    open -a Docker
                else
                    $EDITOR /etc/docker/daemon.json
                fi
                ;;
            "Reset Settings")
                if dialog --yesno "Reset Docker settings to defaults?" 8 40; then
                    if is_darwin; then
                        defaults delete com.docker.docker
                        killall Docker
                        open -a Docker
                    else
                        sudo systemctl stop docker
                        sudo rm -f /etc/docker/daemon.json
                        sudo systemctl start docker
                    fi
                fi
                ;;
            "Import Settings")
                local file
                file=$(dialog --fselect "$HOME/" 8 40 2>&1 >/dev/tty)
                if [ -f "$file" ]; then
                    if is_darwin; then
                        cp "$file" "$HOME/Library/Group Containers/group.com.docker/settings.json"
                        killall Docker
                        open -a Docker
                    else
                        sudo cp "$file" /etc/docker/daemon.json
                        sudo systemctl restart docker
                    fi
                fi
                ;;
            "Back"|*)
                return
                ;;
        esac
    done
}

# Deploy services with progress dialog
deploy_services() {
    # Check Docker system first
    if ! check_docker_system; then
        dialog --clear --title "Error" \
            --msgbox "Docker system check failed. Please fix the issues before deploying." 8 60
        return 1
    fi

    # Show deployment confirmation
    dialog --clear --title "Deploy Services" \
        --yesno "This will deploy all configured services. Continue?" 8 60 || return 1

    # Create progress dialog
    {
        echo "XXX"
        echo "10"
        echo "Checking Docker Compose..."
        echo "XXX"
        
        if ! check_docker_compose_installed; then
            echo "XXX"
            echo "100"
            echo "Error: Docker Compose is not installed!"
            echo "XXX"
            sleep 2
            return 1
        fi

        echo "XXX"
        echo "20"
        echo "Pulling latest images..."
        echo "XXX"
        
        docker-compose pull

        echo "XXX"
        echo "50"
        echo "Starting services..."
        echo "XXX"
        
        if ! compose_up; then
            echo "XXX"
            echo "100"
            echo "Error: Failed to start services!"
            echo "XXX"
            sleep 2
            return 1
        fi

        echo "XXX"
        echo "80"
        echo "Configuring services..."
        echo "XXX"
        
        configure_services

        echo "XXX"
        echo "100"
        echo "Deployment complete!"
        echo "XXX"
        sleep 1
    } | dialog --title "Deploying Services" --gauge "Starting deployment..." 8 60 0

    # Show completion message
    dialog --clear --title "Success" \
        --msgbox "Services have been deployed successfully!" 8 60

    return 0
}

# Export functions
export -f deploy_services 