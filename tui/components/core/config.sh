#!/bin/bash

# Guard against multiple inclusion
[ -n "$_TUI_CONFIG_SH" ] && return
declare -r _TUI_CONFIG_SH=1

# Import base module
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Dialog appearance
declare TUI_DIALOG_HEIGHT=0
declare TUI_DIALOG_WIDTH=0
declare TUI_DIALOG_BACKTITLE=""
declare TUI_DIALOG_TITLE=""
declare TUI_DIALOG_COLORS=false
declare TUI_DIALOG_ASCII_LINES=false
declare TUI_DIALOG_NO_SHADOW=false
declare TUI_DIALOG_NO_MOUSE=false
declare TUI_DIALOG_TAB_CORRECT=false
declare TUI_DIALOG_TAB_LEN=8

# Dialog behavior
declare TUI_DIALOG_SEPARATE_OUTPUT=false
declare TUI_DIALOG_NO_COLLAPSE=false
declare TUI_DIALOG_CR_WRAP=false
declare TUI_DIALOG_TRIM=false
declare TUI_DIALOG_NO_NL_EXPAND=false
declare TUI_DIALOG_ASPECT=9

# Set dialog defaults
tui_set_dialog_defaults() {
    local height=${1:-0}
    local width=${2:-0}
    local backtitle=${3:-""}
    
    TUI_DIALOG_HEIGHT=$height
    TUI_DIALOG_WIDTH=$width
    TUI_DIALOG_BACKTITLE=$backtitle
}

# Get common dialog options
tui_get_dialog_options() {
    local options=""
    
    # Appearance options
    [ "$TUI_DIALOG_COLORS" = true ] && options="$options --colors"
    [ "$TUI_DIALOG_ASCII_LINES" = true ] && options="$options --ascii-lines"
    [ "$TUI_DIALOG_NO_SHADOW" = true ] && options="$options --no-shadow"
    [ "$TUI_DIALOG_NO_MOUSE" = true ] && options="$options --no-mouse"
    [ "$TUI_DIALOG_TAB_CORRECT" = true ] && options="$options --tab-correct"
    
    # Behavior options
    [ "$TUI_DIALOG_NO_COLLAPSE" = true ] && options="$options --no-collapse"
    [ "$TUI_DIALOG_CR_WRAP" = true ] && options="$options --cr-wrap"
    [ "$TUI_DIALOG_TRIM" = true ] && options="$options --trim"
    [ "$TUI_DIALOG_NO_NL_EXPAND" = true ] && options="$options --no-nl-expand"
    
    # Titles
    [ -n "$TUI_DIALOG_BACKTITLE" ] && options="$options --backtitle \"$TUI_DIALOG_BACKTITLE\""
    [ -n "$TUI_DIALOG_TITLE" ] && options="$options --title \"$TUI_DIALOG_TITLE\""
    
    echo "$options"
}

# Load configuration from file
tui_load_config() {
    local config_file="$1"
    [ ! -f "$config_file" ] && return $TUI_ERROR
    
    # Source the config file
    source "$config_file" || {
        tui_error "Failed to load configuration from $config_file"
        return $TUI_ERROR
    }
    
    return $TUI_OK
}

# Save configuration to file
tui_save_config() {
    local config_file="$1"
    
    # Create config content
    {
        echo "# TUI Configuration"
        echo "TUI_DIALOG_HEIGHT=$TUI_DIALOG_HEIGHT"
        echo "TUI_DIALOG_WIDTH=$TUI_DIALOG_WIDTH"
        echo "TUI_DIALOG_BACKTITLE=\"$TUI_DIALOG_BACKTITLE\""
        echo "TUI_DIALOG_TITLE=\"$TUI_DIALOG_TITLE\""
        echo "TUI_DIALOG_COLORS=$TUI_DIALOG_COLORS"
        echo "TUI_DIALOG_ASCII_LINES=$TUI_DIALOG_ASCII_LINES"
        echo "TUI_DIALOG_NO_SHADOW=$TUI_DIALOG_NO_SHADOW"
        echo "TUI_DIALOG_NO_MOUSE=$TUI_DIALOG_NO_MOUSE"
        echo "TUI_DIALOG_TAB_CORRECT=$TUI_DIALOG_TAB_CORRECT"
        echo "TUI_DIALOG_TAB_LEN=$TUI_DIALOG_TAB_LEN"
        echo "TUI_DIALOG_SEPARATE_OUTPUT=$TUI_DIALOG_SEPARATE_OUTPUT"
        echo "TUI_DIALOG_NO_COLLAPSE=$TUI_DIALOG_NO_COLLAPSE"
        echo "TUI_DIALOG_CR_WRAP=$TUI_DIALOG_CR_WRAP"
        echo "TUI_DIALOG_TRIM=$TUI_DIALOG_TRIM"
        echo "TUI_DIALOG_NO_NL_EXPAND=$TUI_DIALOG_NO_NL_EXPAND"
        echo "TUI_DIALOG_ASPECT=$TUI_DIALOG_ASPECT"
    } > "$config_file"
    
    return $TUI_OK
}

# Reset configuration to defaults
tui_reset_config() {
    TUI_DIALOG_HEIGHT=0
    TUI_DIALOG_WIDTH=0
    TUI_DIALOG_BACKTITLE=""
    TUI_DIALOG_TITLE=""
    TUI_DIALOG_COLORS=false
    TUI_DIALOG_ASCII_LINES=false
    TUI_DIALOG_NO_SHADOW=false
    TUI_DIALOG_NO_MOUSE=false
    TUI_DIALOG_TAB_CORRECT=false
    TUI_DIALOG_TAB_LEN=8
    TUI_DIALOG_SEPARATE_OUTPUT=false
    TUI_DIALOG_NO_COLLAPSE=false
    TUI_DIALOG_CR_WRAP=false
    TUI_DIALOG_TRIM=false
    TUI_DIALOG_NO_NL_EXPAND=false
    TUI_DIALOG_ASPECT=9
} 