#!/bin/bash

# Theme management for TUI components
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"

# Theme configuration
declare -r THEME_DIR="${PROJECT_ROOT}/configs/theme"
declare -A THEME_COLORS=(
    ["screen"]="CYAN,BLACK"
    ["dialog"]="BLACK,CYAN"
    ["title"]="BLACK,CYAN"
    ["button_active"]="CYAN,BLACK"
    ["button_inactive"]="BLACK,CYAN"
    ["input"]="BLACK,CYAN"
    ["error"]="RED,BLACK"
    ["warning"]="YELLOW,BLACK"
    ["info"]="CYAN,BLACK"
)

init_theme() {
    # Create theme directory
    mkdir -p "$THEME_DIR"
    
    # Initialize dialog configuration
    create_dialog_config
    
    # Set up terminal colors
    setup_terminal_colors
    return 0
}

create_dialog_config() {
    local dialogrc="${THEME_DIR}/dialogrc"
    
    # Create dialog configuration
    cat > "$dialogrc" << EOF
# Screen color
screen_color = (${THEME_COLORS["screen"]},ON)

# Dialog box color
dialog_color = (${THEME_COLORS["dialog"]},OFF)

# Dialog box title color
title_color = (${THEME_COLORS["title"]},ON)

# Active button color
button_active_color = (${THEME_COLORS["button_active"]},ON)
button_inactive_color = (${THEME_COLORS["button_inactive"]},OFF)
button_key_active_color = button_active_color
button_key_inactive_color = button_inactive_color
button_label_active_color = button_active_color
button_label_inactive_color = button_inactive_color

# Input box color
inputbox_color = (${THEME_COLORS["input"]},OFF)
inputbox_border_color = inputbox_color

# Menu box color
menubox_color = dialog_color
menubox_border_color = dialog_color

# Item color
item_color = dialog_color
item_selected_color = button_active_color

# Help color
help_color = (${THEME_COLORS["info"]},ON)
EOF
    
    # Set dialog configuration
    export DIALOGRC="$dialogrc"
    
    # Set dialog options
    export DIALOG_OPTIONS="\
        --colors \
        --no-collapse \
        --cr-wrap \
        --no-tags \
        --no-cancel \
        --default-button 'OK'"
}

setup_terminal_colors() {
    # Save current terminal state
    push_terminal_state "theme"
    
    # Set up color capabilities
    tput init
    
    # Set basic colors
    printf "\033]4;0;#000000\033\\"  # Black
    printf "\033]4;1;#CC0000\033\\"  # Red
    printf "\033]4;2;#4E9A06\033\\"  # Green
    printf "\033]4;3;#C4A000\033\\"  # Yellow
    printf "\033]4;4;#3465A4\033\\"  # Blue
    printf "\033]4;5;#75507B\033\\"  # Magenta
    printf "\033]4;6;#06989A\033\\"  # Cyan
    printf "\033]4;7;#D3D7CF\033\\"  # White
    
    # Set bright colors
    printf "\033]4;8;#555753\033\\"   # Bright Black
    printf "\033]4;9;#EF2929\033\\"   # Bright Red
    printf "\033]4;10;#8AE234\033\\"  # Bright Green
    printf "\033]4;11;#FCE94F\033\\"  # Bright Yellow
    printf "\033]4;12;#729FCF\033\\"  # Bright Blue
    printf "\033]4;13;#AD7FA8\033\\"  # Bright Magenta
    printf "\033]4;14;#34E2E2\033\\"  # Bright Cyan
    printf "\033]4;15;#EEEEEC\033\\"  # Bright White
    
    # Restore terminal state
    pop_terminal_state "theme"
}

get_theme_color() {
    local element="$1"
    echo "${THEME_COLORS[$element]:-BLACK,WHITE}"
}

with_themed_output() {
    local style="$1"
    shift
    local command="$@"
    
    # Get color code
    local color
    case "$style" in
        "error")
            color="\033[31m"  # Red
            ;;
        "warning")
            color="\033[33m"  # Yellow
            ;;
        "info")
            color="\033[36m"  # Cyan
            ;;
        "success")
            color="\033[32m"  # Green
            ;;
        *)
            color="\033[0m"   # Default
            ;;
    esac
    
    # Execute command with color
    printf "${color}"
    eval "$command"
    printf "\033[0m"
}

