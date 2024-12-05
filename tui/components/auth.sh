#!/bin/bash

# Source required modules
source "$(dirname "${BASH_SOURCE[0]}")/../theme.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"

# First-time setup dialog
setup_credentials() {
    # In test mode, use default credentials
    if [[ -n "$TEST_MODE" ]]; then
        save_auth_credentials "test_admin" "test_password"
        return 0
    fi
    
    local username password confirm_password
    local height=15
    local width=60
    
    # Username input
    username=$(dialog --clear --title "First Time Setup" \
        --inputbox "Enter admin username:" $height $width \
        3>&1 1>&2 2>&3)
    local ret=$?
    [[ $ret -ne 0 ]] && return 1
    
    # Password input
    password=$(dialog --clear --title "First Time Setup" \
        --passwordbox "Enter admin password:" $height $width \
        3>&1 1>&2 2>&3)
    ret=$?
    [[ $ret -ne 0 ]] && return 1
    
    # Confirm password
    confirm_password=$(dialog --clear --title "First Time Setup" \
        --passwordbox "Confirm admin password:" $height $width \
        3>&1 1>&2 2>&3)
    ret=$?
    [[ $ret -ne 0 ]] && return 1
    
    # Validate passwords match
    if [[ "$password" != "$confirm_password" ]]; then
        dialog --clear --title "Error" \
            --msgbox "Passwords do not match!" 8 40
        return 1
    fi
    
    # Save credentials
    save_auth_credentials "$username" "$password"
    
    # Show success message
    dialog --clear --title "Success" \
        --msgbox "Credentials saved successfully!" 8 40
    
    return 0
}

# Login dialog
login_dialog() {
    # In test mode, auto-login with test credentials
    if [[ -n "$TEST_MODE" ]]; then
        verify_credentials "test_admin" "test_password"
        return $?
    fi
    
    local username password
    local height=15
    local width=60
    
    while true; do
        # Username input
        username=$(dialog --clear --title "Login" \
            --inputbox "Enter username:" $height $width \
            3>&1 1>&2 2>&3)
        local ret=$?
        [[ $ret -ne 0 ]] && return 1
        
        # Password input
        password=$(dialog --clear --title "Login" \
            --passwordbox "Enter password:" $height $width \
            3>&1 1>&2 2>&3)
        ret=$?
        [[ $ret -ne 0 ]] && return 1
        
        # Verify credentials
        if verify_credentials "$username" "$password"; then
            return 0
        else
            dialog --clear --title "Error" \
                --msgbox "Invalid credentials!" 8 40
        fi
    done
}

# Main auth function
handle_auth() {
    if check_first_run; then
        log_info "First time setup detected"
        setup_credentials || return 1
    fi
    
    login_dialog || return 1
    return 0
}

# Export functions
export -f setup_credentials
export -f login_dialog
export -f handle_auth 