#!/bin/bash

# Define log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Current settings
_CURRENT_LOG_LEVEL="$LOG_LEVEL_INFO"  # Default to INFO
_CURRENT_LOG_FILE=""
_CURRENT_LOG_CONTEXT=""
_LAST_ERROR=""
_LOG_MAX_SIZE=$((1024 * 1024))  # 1MB default

# Color codes
readonly _COLOR_DEBUG='\033[0;34m'   # Blue
readonly _COLOR_INFO='\033[0;32m'    # Green
readonly _COLOR_WARN='\033[1;33m'    # Yellow
readonly _COLOR_ERROR='\033[0;31m'   # Red
readonly _COLOR_RESET='\033[0m'

# Helper to convert to uppercase without ${VAR^^}
_to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Helper to get numeric level from string
_get_level_number() {
    case "$(_to_upper "$1")" in
        "DEBUG") echo "$LOG_LEVEL_DEBUG" ;;
        "INFO")  echo "$LOG_LEVEL_INFO" ;;
        "WARN"|"WARNING") echo "$LOG_LEVEL_WARN" ;;
        "ERROR") echo "$LOG_LEVEL_ERROR" ;;
        *) echo "$LOG_LEVEL_INFO" ;; # Default to INFO
    esac
}

# Helper to get level name from number
_get_level_name() {
    case "$1" in
        "$LOG_LEVEL_DEBUG") echo "DEBUG" ;;
        "$LOG_LEVEL_INFO")  echo "INFO" ;;
        "$LOG_LEVEL_WARN")  echo "WARN" ;;
        "$LOG_LEVEL_ERROR") echo "ERROR" ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Set current log level
set_log_level() {
    _CURRENT_LOG_LEVEL="$(_get_level_number "$1")"
}

# Get current log level
get_log_level() {
    _get_level_name "$_CURRENT_LOG_LEVEL"
}

# Format a log message
format_log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    if [ -n "$_CURRENT_LOG_CONTEXT" ]; then
        echo "[$timestamp] [$level] [$_CURRENT_LOG_CONTEXT] $message"
    else
        echo "[$timestamp] [$level] $message"
    fi
}

# Get color for level
_get_level_color() {
    case "$1" in
        "$LOG_LEVEL_DEBUG") echo "$_COLOR_DEBUG" ;;
        "$LOG_LEVEL_INFO")  echo "$_COLOR_INFO" ;;
        "$LOG_LEVEL_WARN")  echo "$_COLOR_WARN" ;;
        "$LOG_LEVEL_ERROR") echo "$_COLOR_ERROR" ;;
        *) echo "$_COLOR_RESET" ;;
    esac
}

# Check if file needs rotation
_check_rotation() {
    local file="$1"
    local size
    
    if [ -f "$file" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            size=$(stat -f%z "$file")
        else
            size=$(stat -c%s "$file")
        fi
        
        if [ "$size" -gt "$_LOG_MAX_SIZE" ]; then
            mv "$file" "${file}.1"
        fi
    fi
}

# Base logging function
_log() {
    local level="$1"
    local message="$2"
    local level_name
    level_name="$(_get_level_name "$level")"
    
    # Check if we should log this level
    if [ "$level" -ge "$_CURRENT_LOG_LEVEL" ] 2>/dev/null; then
        local formatted_message color
        formatted_message="$(format_log_message "$level_name" "$message")"
        color="$(_get_level_color "$level")"
        
        # Add color if outputting to terminal
        if [ -t 1 ]; then
            printf "%b%s%b\n" "$color" "$formatted_message" "$_COLOR_RESET"
        else
            echo "$formatted_message"
        fi
        
        # Write to log file if configured
        if [ -n "$_CURRENT_LOG_FILE" ]; then
            _check_rotation "$_CURRENT_LOG_FILE"
            echo "$formatted_message" >> "$_CURRENT_LOG_FILE"
        fi
    fi
}

# Individual log level functions
log_debug() { _log "$LOG_LEVEL_DEBUG" "$1"; }
log_info() { _log "$LOG_LEVEL_INFO" "$1"; }
log_warn() { _log "$LOG_LEVEL_WARN" "$1"; }
log_error() { _log "$LOG_LEVEL_ERROR" "$1"; }

# Log file management
set_log_file() {
    _CURRENT_LOG_FILE="$1"
    
    # Create log directory if needed
    local dir
    dir="$(dirname "$_CURRENT_LOG_FILE")"
    if [ "$dir" != "." ]; then
        mkdir -p "$dir" 2>/dev/null || return 1
    fi
    
    # Create or clear the log file
    touch "$_CURRENT_LOG_FILE" 2>/dev/null || return 1
    
    # Verify we can write to it
    if [ ! -w "$_CURRENT_LOG_FILE" ]; then
        return 1
    fi
    
    return 0
}

get_log_file() {
    echo "$_CURRENT_LOG_FILE"
}

# Context management
set_log_context() {
    _CURRENT_LOG_CONTEXT="$1"
}

# Error handling
catch_and_log() {
    local output status
    
    # Execute the command and capture both output and status
    output=$("$@" 2>&1)
    status=$?
    
    # If the command failed, log the error
    if [ $status -ne 0 ]; then
        _LAST_ERROR="$output"
        log_error "$output"
        return $status
    fi
    
    # Command succeeded
    echo "$output"
    return 0
}

get_last_error() {
    echo "$_LAST_ERROR"
}