#!/bin/bash

# Resource monitoring system
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"

# Resource thresholds
declare -r CPU_WARNING_THRESHOLD=75
declare -r CPU_CRITICAL_THRESHOLD=90
declare -r MEM_WARNING_THRESHOLD=80
declare -r MEM_CRITICAL_THRESHOLD=95
declare -r DISK_WARNING_THRESHOLD=85
declare -r DISK_CRITICAL_THRESHOLD=95

init_resource_monitor() {
    # Create monitoring directory
    mkdir -p "${PROJECT_ROOT}/logs/monitor"
    
    # Initialize monitoring data files
    : > "${PROJECT_ROOT}/logs/monitor/cpu.dat"
    : > "${PROJECT_ROOT}/logs/monitor/memory.dat"
    : > "${PROJECT_ROOT}/logs/monitor/disk.dat"
    
    # Start background monitoring
    start_resource_monitoring
    return 0
}

start_resource_monitoring() {
    # Start monitoring daemon
    (
        while true; do
            collect_resource_metrics
            sleep 60  # Collect metrics every minute
        done
    ) &
    echo $! > "${PROJECT_ROOT}/logs/monitor/monitor.pid"
}

collect_resource_metrics() {
    local timestamp=$(date +%s)
    local monitor_dir="${PROJECT_ROOT}/logs/monitor"
    
    # Collect CPU metrics
    local cpu_usage
    if [[ "$(uname)" == "Darwin" ]]; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    fi
    echo "$timestamp $cpu_usage" >> "${monitor_dir}/cpu.dat"
    
    # Collect memory metrics
    local mem_usage
    if [[ "$(uname)" == "Darwin" ]]; then
        mem_usage=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
        mem_usage=$((mem_usage * 4096 / 1024 / 1024))  # Convert to MB
    else
        mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    fi
    echo "$timestamp $mem_usage" >> "${monitor_dir}/memory.dat"
    
    # Collect disk metrics
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    echo "$timestamp $disk_usage" >> "${monitor_dir}/disk.dat"
    
    # Check thresholds and alert if necessary
    check_resource_thresholds "$cpu_usage" "$mem_usage" "$disk_usage"
}

check_resource_thresholds() {
    local cpu_usage="$1"
    local mem_usage="$2"
    local disk_usage="$3"
    
    # Check CPU
    if ((cpu_usage >= CPU_CRITICAL_THRESHOLD)); then
        log_error "Critical CPU usage: ${cpu_usage}%" "monitor"
    elif ((cpu_usage >= CPU_WARNING_THRESHOLD)); then
        log_warning "High CPU usage: ${cpu_usage}%" "monitor"
    fi
    
    # Check memory
    if ((mem_usage >= MEM_CRITICAL_THRESHOLD)); then
        log_error "Critical memory usage: ${mem_usage}%" "monitor"
    elif ((mem_usage >= MEM_WARNING_THRESHOLD)); then
        log_warning "High memory usage: ${mem_usage}%" "monitor"
    fi
    
    # Check disk
    if ((disk_usage >= DISK_CRITICAL_THRESHOLD)); then
        log_error "Critical disk usage: ${disk_usage}%" "monitor"
    elif ((disk_usage >= DISK_WARNING_THRESHOLD)); then
        log_warning "High disk usage: ${disk_usage}%" "monitor"
    fi
}

show_resource_monitor() {
    # Show resource monitor with proper terminal handling
    with_terminal_state "resource_monitor" "
        while true; do
            clear
            echo -e '\033[36m=== Resource Monitor ===\033[0m'
            echo
            show_cpu_usage
            echo
            show_memory_usage
            echo
            show_disk_usage
            echo
            echo -e '\033[33mPress q to exit, any other key to refresh\033[0m'
            
            read -n 1 -t 5 key
            if [[ \$key == q ]]; then
                break
            fi
        done
    "
}

show_cpu_usage() {
    local cpu_usage
    if [[ "$(uname)" == "Darwin" ]]; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    fi
    
    # Show CPU bar
    echo -e "\033[1mCPU Usage:\033[0m"
    show_usage_bar "$cpu_usage" "$CPU_WARNING_THRESHOLD" "$CPU_CRITICAL_THRESHOLD"
}

show_memory_usage() {
    local mem_usage
    if [[ "$(uname)" == "Darwin" ]]; then
        mem_usage=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
        mem_usage=$((mem_usage * 4096 / 1024 / 1024))  # Convert to MB
    else
        mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    fi
    
    # Show memory bar
    echo -e "\033[1mMemory Usage:\033[0m"
    show_usage_bar "$mem_usage" "$MEM_WARNING_THRESHOLD" "$MEM_CRITICAL_THRESHOLD"
}

show_disk_usage() {
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    
    # Show disk bar
    echo -e "\033[1mDisk Usage:\033[0m"
    show_usage_bar "$disk_usage" "$DISK_WARNING_THRESHOLD" "$DISK_CRITICAL_THRESHOLD"
}

show_usage_bar() {
    local usage="$1"
    local warning="$2"
    local critical="$3"
    local width=50
    local filled=$((usage * width / 100))
    local empty=$((width - filled))
    
    # Determine color based on thresholds
    local color
    if ((usage >= critical)); then
        color="\033[31m"  # Red
    elif ((usage >= warning)); then
        color="\033[33m"  # Yellow
    else
        color="\033[32m"  # Green
    fi
    
    # Show bar
    printf "[%s%s%s] %s%%\n" \
        "${color}$(printf '%*s' "$filled" | tr ' ' '=')\033[0m" \
        "$(printf '%*s' "$empty" | tr ' ' '-')" \
        "$usage"
}

show_resource_history() {
    local resource_type="$1"
    local data_file="${PROJECT_ROOT}/logs/monitor/${resource_type}.dat"
    local title
    
    case "$resource_type" in
        "cpu")
            title="CPU Usage History"
            ;;
        "memory")
            title="Memory Usage History"
            ;;
        "disk")
            title="Disk Usage History"
            ;;
        *)
            log_error "Unknown resource type: $resource_type"
            return 1
            ;;
    esac
    
    # Show history with proper terminal handling
    with_terminal_state "resource_history" "
        clear
        echo -e '\033[36m=== $title ===\033[0m'
        echo
        
        # Show last 24 hours of data
        local now=\$(date +%s)
        local start=\$((now - 86400))
        
        awk -v start=\$start '
            \$1 >= start {
                time=strftime(\"%H:%M\", \$1)
                printf \"%s %3d%% \", time, \$2
                for (i=0; i<\$2/2; i++) printf \"#\"
                print \"\"
            }
        ' \"\$data_file\" | tail -n \$((LINES - 5))
        
        echo
        echo -e '\033[33mPress any key to exit\033[0m'
        read -n 1
    "
}

cleanup_resource_monitor() {
    # Stop monitoring daemon
    if [[ -f "${PROJECT_ROOT}/logs/monitor/monitor.pid" ]]; then
        kill "$(cat "${PROJECT_ROOT}/logs/monitor/monitor.pid")" 2>/dev/null || true
        rm -f "${PROJECT_ROOT}/logs/monitor/monitor.pid"
    fi
    
    # Clean up old data files
    find "${PROJECT_ROOT}/logs/monitor" -name "*.dat" -mtime +7 -delete
} 