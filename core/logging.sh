#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Log levels as integers
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_SUCCESS=2
LOG_LEVEL_WARNING=3
LOG_LEVEL_ERROR=4
LOG_LEVEL_FATAL=5

# Current log level (default: INFO)
: "${LOG_LEVEL:=1}"
CURRENT_LOG_LEVEL=$LOG_LEVEL

# Log file configuration
: "${LOG_DIR:=${HOME}/.docker-manager/logs}"
: "${LOG_FILE:=${LOG_DIR}/docker-manager.log}"
: "${MAX_LOG_SIZE:=$((10 * 1024 * 1024))}" # 10MB

# Log context
LOG_CONTEXT=""

# Last error message
LAST_ERROR=""

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Create or truncate log file
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    elif [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
}

# Set log level
set_log_level() {
    local level="$1"
    CURRENT_LOG_LEVEL=$level
}

# Get current log level
get_log_level() {
    echo "$CURRENT_LOG_LEVEL"
}

# Set log file
set_log_file() {
    local file="$1"
    LOG_FILE="$file"
    init_logging
}

# Set log context
set_log_context() {
    local context="$1"
    LOG_CONTEXT="$context"
}

# Format log message
format_log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local context_str=""
    [[ -n "$LOG_CONTEXT" ]] && context_str="[$LOG_CONTEXT] "
    echo "[$timestamp] $level $context_str$message"
}

# Get last error
get_last_error() {
    echo "$LAST_ERROR"
}

# Logging functions
log_debug() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_DEBUG)); then
        local formatted_msg
        formatted_msg=$(format_log_message "DEBUG" "$*")
        echo -e "${GRAY}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
    fi
}

log_info() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_INFO)); then
        local formatted_msg
        formatted_msg=$(format_log_message "INFO" "$*")
        echo -e "${BLUE}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
    fi
}

log_success() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_SUCCESS)); then
        local formatted_msg
        formatted_msg=$(format_log_message "SUCCESS" "$*")
        echo -e "${GREEN}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
    fi
}

log_warning() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_WARNING)); then
        local formatted_msg
        formatted_msg=$(format_log_message "WARNING" "$*")
        echo -e "${YELLOW}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
    fi
}

log_error() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_ERROR)); then
        local formatted_msg
        formatted_msg=$(format_log_message "ERROR" "$*")
        echo -e "${RED}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
        LAST_ERROR="$*"
    fi
}

log_fatal() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_FATAL)); then
        local formatted_msg
        formatted_msg=$(format_log_message "FATAL" "$*")
        echo -e "${PURPLE}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
        LAST_ERROR="$*"
    fi
}

# Progress logging
log_step() {
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_INFO)); then
        local formatted_msg
        formatted_msg=$(format_log_message "STEP" "$*")
        echo -e "${CYAN}$formatted_msg${NC}" | tee -a "$LOG_FILE" >&2
    fi
}

log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    if ((CURRENT_LOG_LEVEL <= LOG_LEVEL_INFO)); then
        local formatted_msg
        formatted_msg=$(format_log_message "PROGRESS" "$message")
        printf "\r${CYAN}%s [%-50s] %d%%" "$formatted_msg" \
            "$(printf '#%.0s' $(seq 1 $((current * 50 / total))))" \
            $((current * 100 / total)) >&2
        echo "$message" >> "$LOG_FILE"
    fi
}

# Export logging functions and variables
export LOG_LEVEL_DEBUG
export LOG_LEVEL_INFO
export LOG_LEVEL_SUCCESS
export LOG_LEVEL_WARNING
export LOG_LEVEL_ERROR
export LOG_LEVEL_FATAL
export CURRENT_LOG_LEVEL
export LOG_DIR
export LOG_FILE
export -f log_debug
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_fatal
export -f log_step
export -f log_progress
export -f set_log_level
export -f get_log_level
export -f set_log_file
export -f set_log_context
export -f format_log_message
export -f get_last_error