#!/bin/bash

# Menu state management
declare -a MENU_STACK=()
declare -A MENU_CONTEXT=()

init_menu_state() {
    # Initialize menu state tracking
    MENU_STACK=()
    MENU_CONTEXT=()
    return 0
}

push_menu_state() {
    local menu_name="$1"
    shift
    local context="$@"
    
    # Save current menu state
    MENU_STACK+=("$menu_name")
    
    # Save context if provided
    if [[ -n "$context" ]]; then
        MENU_CONTEXT["$menu_name"]="$context"
    fi
    
    # Use terminal state management for clean transitions
    push_terminal_state "menu_$menu_name"
    return 0
}

pop_menu_state() {
    local expected_menu="$1"
    
    # Verify we have menus to pop
    if [[ ${#MENU_STACK[@]} -eq 0 ]]; then
        log_error "Menu stack is empty"
        return 1
    fi
    
    # Get current menu
    local current_menu="${MENU_STACK[-1]}"
    
    # Verify menu matches if one was expected
    if [[ -n "$expected_menu" && "$current_menu" != "$expected_menu" ]]; then
        log_error "Menu state mismatch. Expected: $expected_menu, Found: $current_menu"
        return 1
    fi
    
    # Clean up menu state
    unset 'MENU_STACK[-1]'
    unset 'MENU_CONTEXT[$current_menu]'
    
    # Restore terminal state
    pop_terminal_state "menu_$current_menu"
    return 0
}

get_current_menu() {
    if [[ ${#MENU_STACK[@]} -eq 0 ]]; then
        echo ""
        return 1
    fi
    echo "${MENU_STACK[-1]}"
    return 0
}

get_menu_context() {
    local menu_name="$1"
    echo "${MENU_CONTEXT[$menu_name]}"
    return 0
}

with_menu_error_handling() {
    local menu_name="$1"
    shift
    local cmd="$@"
    
    # Save current menu state
    push_menu_state "$menu_name"
    
    # Execute command with error handling
    local error_log="${PROJECT_ROOT}/logs/menu_${menu_name}.error.log"
    if ! eval "$cmd" 2> >(tee -a "$error_log" >&2); then
        local error_msg=$(tail -n 1 "$error_log")
        dialog --clear --title "Error" \
            --msgbox "Operation failed in menu $menu_name:\n\n$error_msg" \
            10 60
        
        pop_menu_state "$menu_name"
        return 1
    fi
    
    pop_menu_state "$menu_name"
    return 0
}

show_menu_dialog() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")
    
    # Get terminal dimensions
    local term_height=$(tput lines)
    local term_width=$(tput cols)
    
    # Calculate menu dimensions
    local menu_height=$((term_height - 4))
    local menu_width=$((term_width - 4))
    
    # Show menu with proper dimensions
    dialog --clear \
        --title "$title" \
        --menu "$prompt" \
        $menu_height $menu_width $((menu_height - 4)) \
        "${options[@]}" \
        2>&1 >/dev/tty
}

show_error_dialog() {
    local title="$1"
    local message="$2"
    
    dialog --clear \
        --title "$title" \
        --msgbox "$message" \
        10 60 \
        2>&1 >/dev/tty
}

show_progress_dialog() {
    local title="$1"
    local command="$2"
    local gauge_file=$(mktemp)
    
    # Execute command with progress updates
    (
        eval "$command" | while IFS= read -r line; do
            if [[ $line =~ ^[0-9]+%$ ]]; then
                echo "$line" > "$gauge_file"
            fi
        done
    ) &
    local cmd_pid=$!
    
    # Show progress dialog
    dialog --clear \
        --title "$title" \
        --gauge "" \
        8 50 0 \
        < <(
            while kill -0 $cmd_pid 2>/dev/null; do
                if [[ -f "$gauge_file" ]]; then
                    cat "$gauge_file"
                fi
                sleep 0.1
            done
        )
    
    # Clean up
    rm -f "$gauge_file"
    wait $cmd_pid
    return $?
} 