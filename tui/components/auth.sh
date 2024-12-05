#!/bin/bash

# Source required modules
source "$(dirname "${BASH_SOURCE[0]}")/../theme.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/logging.sh"

# First-time setup dialog
setup_credentials() {
    # In test mode, use default credentials
    if [[ -n "$TEST_MODE" ]]; then
        save_auth_credentials "test_admin" "test_password" || {
            log_error "Failed to save test credentials"
            return 1
        }
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
    if [[ $ret -ne 0 ]]; then
        log_error "User cancelled username input"
        return 1
    fi
    
    # Password input
    password=$(dialog --clear --title "First Time Setup" \
        --passwordbox "Enter admin password:" $height $width \
        3>&1 1>&2 2>&3)
    ret=$?
    if [[ $ret -ne 0 ]]; then
        log_error "User cancelled password input"
        return 1
    fi
    
    # Confirm password
    confirm_password=$(dialog --clear --title "First Time Setup" \
        --passwordbox "Confirm admin password:" $height $width \
        3>&1 1>&2 2>&3)
    ret=$?
    if [[ $ret -ne 0 ]]; then
        log_error "User cancelled password confirmation"
        return 1
    fi
    
    # Validate passwords match
    if [[ "$password" != "$confirm_password" ]]; then
        log_error "Passwords do not match"
        dialog --clear --title "Error" \
            --msgbox "Passwords do not match!" 8 40
        return 1
    fi
    
    # Save credentials
    if ! save_auth_credentials "$username" "$password"; then
        log_error "Failed to save credentials"
        dialog --clear --title "Error" \
            --msgbox "Failed to save credentials. Please check logs." 8 40
        return 1
    fi
    
    log_info "Credentials saved successfully for user $username"
    dialog --clear --title "Success" \
        --msgbox "Credentials saved successfully!" 8 40
    
    return 0
}

# Login dialog
login_dialog() {
    # In test mode, auto-login with test credentials
    if [[ -n "$TEST_MODE" ]]; then
        verify_credentials "test_admin" "test_password" || {
            log_error "Test mode authentication failed"
            return 1
        }
        return 0
    fi
    
    local username password
    local height=15
    local width=60
    local attempts=0
    local max_attempts=3
    
    while ((attempts < max_attempts)); do
        # Username input
        username=$(dialog --clear --title "Login" \
            --inputbox "Enter username:" $height $width \
            3>&1 1>&2 2>&3)
        local ret=$?
        if [[ $ret -ne 0 ]]; then
            log_error "User cancelled login"
            return 1
        fi
        
        # Password input
        password=$(dialog --clear --title "Login" \
            --passwordbox "Enter password:" $height $width \
            3>&1 1>&2 2>&3)
        ret=$?
        if [[ $ret -ne 0 ]]; then
            log_error "User cancelled password input"
            return 1
        fi
        
        # Verify credentials
        if verify_credentials "$username" "$password"; then
            log_info "User $username logged in successfully"
            return 0
        fi
        
        # Increment attempts and show error
        ((attempts++))
        log_warning "Failed login attempt $attempts/$max_attempts for user $username"
        
        if ((attempts >= max_attempts)); then
            log_error "Maximum login attempts exceeded for user $username"
            dialog --clear --title "Error" \
                --msgbox "Maximum login attempts exceeded!\nPlease try again later." 8 50
            return 1
        else
            dialog --clear --title "Error" \
                --msgbox "Invalid credentials! ($attempts/$max_attempts attempts remaining)" 8 50
        fi
    done
    
    # Should never reach here, but just in case
    log_error "Login loop exited unexpectedly"
    return 1
}

# Reset credentials dialog
reset_credentials_dialog() {
    local height=15
    local width=60
    
    # Confirm reset
    dialog --clear --title "Reset Credentials" \
        --yesno "This will reset all credentials. You will need to set up new credentials.\n\nAre you sure?" \
        $height $width
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_info "User cancelled credentials reset"
        return 1
    fi
    
    # Reset credentials
    if reset_auth_credentials; then
        log_info "Credentials reset successfully"
        dialog --clear --title "Success" \
            --msgbox "Credentials have been reset.\nPlease set up new credentials." 8 40
        setup_credentials
        return $?
    else
        log_error "Failed to reset credentials"
        dialog --clear --title "Error" \
            --msgbox "Failed to reset credentials! Check logs for details." 8 40
        return 1
    fi
}

# Main auth function
handle_auth() {
    log_info "Starting authentication process"
    
    if check_first_run; then
        log_info "First time setup detected"
        setup_credentials || {
            log_error "First time setup failed"
            return 1
        }
    fi
    
    # Add reset option to login dialog
    while true; do
        local choice
        choice=$(dialog --clear --title "Authentication" \
            --menu "Choose an option:" 15 60 2 \
            "1" "Login" \
            "2" "Reset Credentials" \
            3>&1 1>&2 2>&3)
        local ret=$?
        if [[ $ret -ne 0 ]]; then
            log_error "User cancelled authentication"
            return 1
        fi
        
        case $choice in
            "1")
                if login_dialog; then
                    return 0
                fi
                ;;
            "2")
                reset_credentials_dialog
                ;;
        esac
    done
}

# Export functions
export -f setup_credentials
export -f login_dialog
export -f reset_credentials_dialog
export -f handle_auth 