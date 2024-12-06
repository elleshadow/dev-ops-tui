#!/bin/bash

# Logging system with proper log management and rotation
declare -r LOG_DIR="${PROJECT_ROOT}/logs"
declare -r MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB
declare -r MAX_LOG_FILES=5

init_logging_system() {
    # Create log directory structure
    mkdir -p "${LOG_DIR}"/{app,docker,system,debug}
    
    # Initialize log files with headers
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "=== Application Log Started $timestamp ===" > "${LOG_DIR}/app/app.log"
    echo "=== System Log Started $timestamp ===" > "${LOG_DIR}/system/system.log"
    echo "=== Debug Log Started $timestamp ===" > "${LOG_DIR}/debug/debug.log"
    
    # Set up log rotation
    setup_log_rotation
    return 0
}

setup_log_rotation() {
    # Create logrotate configuration
    cat > "${LOG_DIR}/logrotate.conf" << EOF
${LOG_DIR}/*/*.log {
    size ${MAX_LOG_SIZE}
    rotate ${MAX_LOG_FILES}
    missingok
    notifempty
    compress
    delaycompress
    create 0640 root root
    sharedscripts
    postrotate
        kill -HUP \$(cat ${LOG_DIR}/logging.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
EOF
    
    # Start log rotation daemon
    (
        while true; do
            logrotate -f "${LOG_DIR}/logrotate.conf"
            sleep 300  # Check every 5 minutes
        done
    ) &
    echo $! > "${LOG_DIR}/logging.pid"
}

log_message() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_file
    
    # Determine log file based on context
    case "$context" in
        "docker"*)
            log_file="${LOG_DIR}/docker/docker.log"
            ;;
        "system"*)
            log_file="${LOG_DIR}/system/system.log"
            ;;
        "debug"*)
            log_file="${LOG_DIR}/debug/debug.log"
            ;;
        *)
            log_file="${LOG_DIR}/app/app.log"
            ;;
    esac
    
    # Format message with proper color coding
    local color_code
    case "$level" in
        "ERROR")
            color_code="\033[31m"  # Red
            ;;
        "WARNING")
            color_code="\033[33m"  # Yellow
            ;;
        "INFO")
            color_code="\033[36m"  # Cyan
            ;;
        "DEBUG")
            color_code="\033[35m"  # Magenta
            ;;
        *)
            color_code="\033[0m"   # Default
            ;;
    esac
    
    # Write to log file
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$message" >> "$log_file"
    
    # Show on screen if interactive
    if [[ -t 1 ]]; then
        printf "${color_code}[%s] %-7s %s\033[0m\n" "$timestamp" "$level" "$message" >&2
    fi
}

log_error() {
    log_message "ERROR" "$1" "$2"
}

log_warning() {
    log_message "WARNING" "$1" "$2"
}

log_info() {
    log_message "INFO" "$1" "$2"
}

log_debug() {
    log_message "DEBUG" "$1" "$2"
}

show_log_viewer() {
    local log_type="$1"
    local log_file
    
    # Determine log file
    case "$log_type" in
        "docker")
            log_file="${LOG_DIR}/docker/docker.log"
            ;;
        "system")
            log_file="${LOG_DIR}/system/system.log"
            ;;
        "debug")
            log_file="${LOG_DIR}/debug/debug.log"
            ;;
        *)
            log_file="${LOG_DIR}/app/app.log"
            ;;
    esac
    
    # Show log viewer with proper terminal handling
    with_terminal_state "log_viewer" "
        clear
        echo -e '\033[36m=== $log_type Log Viewer ===\033[0m'
        echo -e '\033[33mPress q to exit, ↑/↓ to scroll\033[0m'
        echo
        
        # Use less for viewing
        less -R +G '$log_file'
    "
}

collect_system_logs() {
    local debug_dir="${LOG_DIR}/debug"
    local debug_archive="${debug_dir}/system_logs_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Collect system information
    {
        echo "=== System Information ==="
        echo "Date: $(date)"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -a)"
        echo
        echo "=== Memory Usage ==="
        free -h
        echo
        echo "=== Disk Usage ==="
        df -h
        echo
        echo "=== Process List ==="
        ps aux
        echo
        echo "=== Network Connections ==="
        netstat -tuln
    } > "${debug_dir}/system_info.log"
    
    # Create debug archive
    tar -czf "$debug_archive" \
        -C "$LOG_DIR" \
        app/app.log \
        system/system.log \
        docker/docker.log \
        debug/debug.log \
        debug/system_info.log
    
    log_info "System logs collected at: $debug_archive"
    return 0
}

cleanup_old_logs() {
    local max_age=$((30 * 24 * 3600))  # 30 days in seconds
    local current_time=$(date +%s)
    
    find "$LOG_DIR" -type f -name "*.log" -o -name "*.gz" | while read -r log_file; do
        local file_time=$(stat -f %m "$log_file")
        local age=$((current_time - file_time))
        
        if ((age > max_age)); then
            log_debug "Removing old log file: $log_file"
            rm -f "$log_file"
        fi
    done
} 