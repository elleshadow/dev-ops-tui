#!/bin/bash

# TUI Dialog Component

# Import core modules
source "$(dirname "${BASH_SOURCE[0]}")/core/base.sh"
source "$(dirname "${BASH_SOURCE[0]}")/core/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/core/validation.sh"

# Dialog exit status codes
declare -r TUI_DIALOG_OK=0
declare -r TUI_DIALOG_CANCEL=1
declare -r TUI_DIALOG_HELP=2
declare -r TUI_DIALOG_EXTRA=3
declare -r TUI_DIALOG_ITEM_HELP=4
declare -r TUI_DIALOG_ESC=255
declare -r TUI_DIALOG_ERROR=-1

# Menu dialog
tui_dialog_menu() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    shift 4
    local items=("$@")
    local menu_height
    
    # Calculate menu height based on number of items
    menu_height=$(( ${#items[@]} / 2 ))
    
    # Ensure minimum dimensions
    [ "$height" -lt $(( menu_height + 8 )) ] && height=$(( menu_height + 8 ))
    [ "$width" -lt 40 ] && width=40
    
    # Calculate list height (leave room for border and buttons)
    menu_height=$(( height - 7 ))
    
    dialog --clear \
           --title "$title" \
           --menu "$message" \
           "$height" "$width" "$menu_height" \
           "${items[@]}" \
           2>&1 >/dev/tty
    
    return $?
}

# Basic dialog boxes
tui_dialog_message() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    
    # Ensure minimum dimensions
    [ "$height" -lt 5 ] && height=5
    [ "$width" -lt 40 ] && width=40
    
    dialog --clear \
           --title "$title" \
           --msgbox "$message" \
           "$height" "$width" \
           2>&1 >/dev/tty
    
    return $?
}

tui_dialog_yesno() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    
    # Ensure minimum dimensions
    [ "$height" -lt 5 ] && height=5
    [ "$width" -lt 40 ] && width=40
    
    dialog --clear \
           --title "$title" \
           --yesno "$message" \
           "$height" "$width" \
           2>&1 >/dev/tty
    
    return $?
}

# Input dialog
tui_dialog_input() {
    local title="$1"
    local message="$2"
    local init="$3"
    local height="$4"
    local width="$5"
    
    # Ensure minimum dimensions
    [ "$height" -lt 5 ] && height=5
    [ "$width" -lt 40 ] && width=40
    
    dialog --clear \
           --title "$title" \
           --inputbox "$message" \
           "$height" "$width" \
           "$init" \
           2>&1 >/dev/tty
    
    return $?
}

# Password dialog
tui_dialog_password() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    local insecure=${5:-false}
    
    # Ensure minimum dimensions
    [ "$height" -lt 5 ] && height=5
    [ "$width" -lt 40 ] && width=40
    
    local opts="--clear"
    [ "$insecure" = true ] && opts="$opts --insecure"
    
    dialog $opts \
           --title "$title" \
           --passwordbox "$message" \
           "$height" "$width" \
           2>&1 >/dev/tty
    
    return $?
}

# Form dialog
tui_dialog_form() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    shift 4
    local fields=("$@")
    
    # Ensure minimum dimensions
    [ "$height" -lt $(( ${#fields[@]} / 8 + 8 )) ] && height=$(( ${#fields[@]} / 8 + 8 ))
    [ "$width" -lt 40 ] && width=40
    
    dialog --clear \
           --title "$title" \
           --form "$message" \
           "$height" "$width" \
           $(( ${#fields[@]} / 8 )) \
           "${fields[@]}" \
           2>&1 >/dev/tty
    
    return $?
}

# Validated form dialog
tui_dialog_validated_form() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    shift 4
    local fields=("$@")
    
    while true; do
        # Get form input
        local values
        values=$(tui_dialog_form "$title" "$message" "$height" "$width" "${fields[@]}")
        local ret=$?
        [ $ret -ne 0 ] && return $ret
        
        # Validate each field
        local valid=true
        local error_msg=""
        local i=0
        local field_count=$(( ${#fields[@]} / 9 ))
        
        while [ $i -lt $field_count ]; do
            local value=$(echo "$values" | sed -n "$((i+1))p")
            local validation_type=${fields[$((i*9+8))]}
            
            if ! tui_validate "$value" "$validation_type"; then
                valid=false
                error_msg=$(tui_get_validation_error "$validation_type")
                error_msg="Field $((i+1)): $error_msg"
                break
            fi
            ((i++))
        done
        
        # Show error or return values
        if [ "$valid" = true ]; then
            echo "$values"
            return 0
        else
            tui_dialog_message "Validation Error" "$error_msg" 8 40
        fi
    done
}

# Initialize with default settings
tui_set_dialog_defaults

