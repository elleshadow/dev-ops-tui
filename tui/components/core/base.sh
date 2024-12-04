#!/bin/bash

# Guard against multiple inclusion
[ -n "$_TUI_BASE_SH" ] && return
declare -r _TUI_BASE_SH=1

# Check bash version
if [ -z "${BASH_VERSINFO[0]}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Warning: Some features require Bash version 4.0 or later" >&2
    # Set a flag for conditional feature availability
    declare -r TUI_HAS_ASSOCIATIVE_ARRAYS=0
else
    declare -r TUI_HAS_ASSOCIATIVE_ARRAYS=1
fi

# Base TUI functionality and common utilities

# Constants
declare -r TUI_VERSION="1.0.0"

# Exit codes
declare -r TUI_OK=0
declare -r TUI_ERROR=1
declare -r TUI_CANCEL=2
declare -r TUI_ESC=255

# Terminal capabilities
declare -r TUI_HAS_COLORS=$(tput colors 2>/dev/null || echo 0)
declare -r TUI_HAS_UNICODE=$(locale charmap 2>/dev/null | grep -q "UTF-8" && echo 1 || echo 0)

# Terminal dimensions
declare TUI_TERM_ROWS
declare TUI_TERM_COLS

# Initialize terminal info
tui_init() {
    # Check dependencies first
    if ! tui_check_dependencies; then
        return $TUI_ERROR
    fi
    
    # Get terminal size
    local size
    size=$(stty size 2>/dev/null) || size=$(tput lines 2>/dev/null)' '$(tput cols 2>/dev/null)
    if [ -z "$size" ]; then
        tui_error "Failed to get terminal size"
        return $TUI_ERROR
    fi
    
    TUI_TERM_ROWS=${size% *}
    TUI_TERM_COLS=${size#* }
    
    if [ -z "$TUI_TERM_ROWS" ] || [ -z "$TUI_TERM_COLS" ]; then
        tui_error "Invalid terminal dimensions"
        return $TUI_ERROR
    fi
    
    # Set up trap for window resize
    trap 'tui_update_dimensions' WINCH
    
    return $TUI_OK
}

# Update terminal dimensions
tui_update_dimensions() {
    local size
    size=$(stty size 2>/dev/null) || size=$(tput lines 2>/dev/null)' '$(tput cols 2>/dev/null)
    if [ -n "$size" ]; then
        TUI_TERM_ROWS=${size% *}
        TUI_TERM_COLS=${size#* }
        return $TUI_OK
    fi
    return $TUI_ERROR
}

# Calculate optimal dialog dimensions
tui_calculate_dimensions() {
    local content_height="$1"
    local content_width="$2"
    local min_height=${3:-5}
    local min_width=${4:-20}
    local margin=${5:-2}
    
    # Update terminal dimensions
    if ! tui_update_dimensions; then
        echo "$min_height $min_width"
        return $TUI_ERROR
    fi
    
    # Calculate dimensions with margins
    local height=$(( content_height + (2 * margin) ))
    local width=$(( content_width + (2 * margin) ))
    
    # Ensure minimum size
    (( height < min_height )) && height=$min_height
    (( width < min_width )) && width=$min_width
    
    # Ensure dialog fits in terminal
    (( height > TUI_TERM_ROWS )) && height=$((TUI_TERM_ROWS - 4))
    (( width > TUI_TERM_COLS )) && width=$((TUI_TERM_COLS - 4))
    
    # Ensure minimum viable size
    (( height < 3 )) && height=3
    (( width < 20 )) && width=20
    
    echo "$height $width"
    return $TUI_OK
}

# Center content in terminal
tui_center_position() {
    local height="$1"
    local width="$2"
    
    # Update terminal dimensions
    if ! tui_update_dimensions; then
        echo "0 0"
        return $TUI_ERROR
    fi
    
    # Calculate centered position
    local row=$(( (TUI_TERM_ROWS - height) / 2 ))
    local col=$(( (TUI_TERM_COLS - width) / 2 ))
    
    # Ensure position is valid
    (( row < 0 )) && row=0
    (( col < 0 )) && col=0
    
    # Ensure dialog fits in terminal
    (( row + height > TUI_TERM_ROWS )) && row=$((TUI_TERM_ROWS - height))
    (( col + width > TUI_TERM_COLS )) && col=$((TUI_TERM_COLS - width))
    
    echo "$row $col"
    return $TUI_OK
}

# Error handling
tui_error() {
    local message="$1"
    echo "ERROR: $message" >&2
    return $TUI_ERROR
}

# Debug logging
tui_debug() {
    [ "${TUI_DEBUG:-0}" = "1" ] || return 0
    local message="$1"
    echo "DEBUG: $message" >&2
}

# Version info
tui_version() {
    echo "TUI Library version $TUI_VERSION"
}

# Check if dialog utility is available
tui_check_dependencies() {
    if ! command -v dialog >/dev/null 2>&1; then
        tui_error "dialog utility is required but not installed"
        return $TUI_ERROR
    fi
    return $TUI_OK
}

# Initialize the TUI system
if ! tui_init; then
    tui_error "Failed to initialize TUI system"
    exit $TUI_ERROR
fi 