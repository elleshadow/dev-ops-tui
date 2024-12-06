#!/bin/bash

# System maintenance component
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/process_manager.sh"
source "${PROJECT_ROOT}/tui/components/resource_monitor.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"

# Constants
declare -r MAINTENANCE_LOG="${LOG_DIR}/system/maintenance.log"
declare -r MAINTENANCE_STATE_FILE="/tmp/tui_maintenance_state"

init_system_maintenance() {
    # Initialize maintenance system
    mkdir -p "$(dirname "$MAINTENANCE_LOG")"
    touch "$MAINTENANCE_STATE_FILE"
    log_info "System maintenance initialized"
    return 0
}

show_system_maintenance_menu() {
    with_terminal_state "maintenance" "
        while true; do
            clear
            echo -e '\033[36m=== System Maintenance ===\033[0m'
            echo
            echo '1) System Health Check'
            echo '2) Process Cleanup'
            echo '3) Log Management'
            echo '4) Performance Optimization'
            echo '5) System Diagnostics'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) run_health_check ;;
                2) cleanup_system_processes ;;
                3) manage_system_logs ;;
                4) optimize_system_performance ;;
                5) run_system_diagnostics ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

run_health_check() {
    echo -e '\n\033[33mRunning System Health Check...\033[0m'
    
    # Check system resources
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    # Check running processes
    local hung_processes=$(find_hung_processes)
    local high_mem_processes=$(find_high_memory_processes)
    
    # Display results
    echo -e "\nSystem Resource Usage:"
    echo "CPU: ${cpu_usage}%"
    echo "Memory: ${mem_usage}%"
    echo "Disk: ${disk_usage}%"
    
    if [[ -n "$hung_processes" ]]; then
        echo -e "\n\033[31mHung Processes Found:\033[0m"
        echo "$hung_processes"
    fi
    
    if [[ -n "$high_mem_processes" ]]; then
        echo -e "\n\033[33mHigh Memory Processes:\033[0m"
        echo "$high_mem_processes"
    fi
    
    log_info "Health check completed"
}

cleanup_system_processes() {
    echo -e '\n\033[33mCleaning up System Processes...\033[0m'
    
    # Find and clean up zombie processes
    local zombies=$(ps aux | awk '$8=="Z"' | awk '{print $2}')
    if [[ -n "$zombies" ]]; then
        echo "Cleaning up zombie processes..."
        for pid in $zombies; do
            kill -9 "$pid" 2>/dev/null || true
        done
    fi
    
    # Clean up hung test processes
    echo "Cleaning up test processes..."
    pkill -f "test_.*\.sh" || true
    
    # Clean up temporary files
    echo "Cleaning up temporary files..."
    find /tmp -name "tui_*" -mtime +1 -delete
    
    log_info "Process cleanup completed"
}

manage_system_logs() {
    echo -e '\n\033[33mManaging System Logs...\033[0m'
    
    # Rotate logs if needed
    check_log_rotation
    
    # Clean up old log archives
    find "${LOG_DIR}" -name "*.tar.gz" -mtime +7 -delete
    
    # Collect system logs
    collect_system_logs
    
    echo "Log management completed"
}

optimize_system_performance() {
    echo -e '\n\033[33mOptimizing System Performance...\033[0m'
    
    # Clear system caches
    if [[ "$(uname)" == "Darwin" ]]; then
        sudo purge
    else
        echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
    fi
    
    # Optimize running processes
    renice_high_cpu_processes
    
    echo "Performance optimization completed"
}

run_system_diagnostics() {
    echo -e '\n\033[33mRunning System Diagnostics...\033[0m'
    
    # Create diagnostic report
    local report_file="${LOG_DIR}/debug/diagnostic_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "=== System Diagnostic Report ==="
        echo "Date: $(date)"
        echo
        echo "=== System Information ==="
        uname -a
        echo
        echo "=== Resource Usage ==="
        top -l 1 -n 0
        echo
        echo "=== Disk Usage ==="
        df -h
        echo
        echo "=== Network Status ==="
        netstat -an | grep LISTEN
        echo
        echo "=== Recent System Messages ==="
        tail -n 50 /var/log/system.log
    } > "$report_file"
    
    echo "Diagnostic report saved to: $report_file"
}

# Helper functions
find_hung_processes() {
    ps aux | awk '$8=="D"' || true
}

find_high_memory_processes() {
    ps aux | awk '$4>5.0' || true
}

renice_high_cpu_processes() {
    ps aux | awk '$3>80.0 {print $2}' | while read -r pid; do
        renice 10 "$pid" 2>/dev/null || true
    done
}

cleanup_system_maintenance() {
    rm -f "$MAINTENANCE_STATE_FILE"
    log_info "System maintenance cleaned up"
} 