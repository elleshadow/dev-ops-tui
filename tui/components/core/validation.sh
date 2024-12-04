#!/bin/bash

# Guard against multiple inclusion
[ -n "$_TUI_VALIDATION_SH" ] && return
declare -r _TUI_VALIDATION_SH=1

# Import base module
source "$(dirname "${BASH_SOURCE[0]}")/base.sh"

# Validation types
declare -r TUI_VALIDATION_REQUIRED="required"
declare -r TUI_VALIDATION_NUMBER="number"
declare -r TUI_VALIDATION_INTEGER="integer"
declare -r TUI_VALIDATION_FLOAT="float"
declare -r TUI_VALIDATION_EMAIL="email"
declare -r TUI_VALIDATION_DATE="date"
declare -r TUI_VALIDATION_TIME="time"
declare -r TUI_VALIDATION_IP="ip"
declare -r TUI_VALIDATION_URL="url"
declare -r TUI_VALIDATION_PATH="path"
declare -r TUI_VALIDATION_HOSTNAME="hostname"
declare -r TUI_VALIDATION_USERNAME="username"
declare -r TUI_VALIDATION_PASSWORD="password"

# Initialize validation error messages
_tui_init_validation_errors() {
    # Check if already initialized
    [ -n "$_TUI_VALIDATION_ERRORS_INIT" ] && return
    declare -r _TUI_VALIDATION_ERRORS_INIT=1
    
    if [ "$TUI_HAS_ASSOCIATIVE_ARRAYS" = "1" ]; then
        # Initialize associative array
        declare -gA TUI_VALIDATION_ERRORS
        TUI_VALIDATION_ERRORS["required"]="This field is required"
        TUI_VALIDATION_ERRORS["number"]="Please enter a valid number"
        TUI_VALIDATION_ERRORS["integer"]="Please enter a valid integer"
        TUI_VALIDATION_ERRORS["float"]="Please enter a valid decimal number"
        TUI_VALIDATION_ERRORS["email"]="Please enter a valid email address"
        TUI_VALIDATION_ERRORS["date"]="Please enter a valid date"
        TUI_VALIDATION_ERRORS["time"]="Please enter a valid time"
        TUI_VALIDATION_ERRORS["ip"]="Please enter a valid IP address"
        TUI_VALIDATION_ERRORS["url"]="Please enter a valid URL"
        TUI_VALIDATION_ERRORS["path"]="Please enter a valid file path"
        TUI_VALIDATION_ERRORS["hostname"]="Please enter a valid hostname"
        TUI_VALIDATION_ERRORS["username"]="Please enter a valid username"
        TUI_VALIDATION_ERRORS["password"]="Please enter a valid password"
    else
        # Fallback to function-based error messages
        _tui_get_validation_error() {
            case "$1" in
                "required")   echo "This field is required" ;;
                "number")    echo "Please enter a valid number" ;;
                "integer")   echo "Please enter a valid integer" ;;
                "float")     echo "Please enter a valid decimal number" ;;
                "email")     echo "Please enter a valid email address" ;;
                "date")      echo "Please enter a valid date" ;;
                "time")      echo "Please enter a valid time" ;;
                "ip")        echo "Please enter a valid IP address" ;;
                "url")       echo "Please enter a valid URL" ;;
                "path")      echo "Please enter a valid file path" ;;
                "hostname")  echo "Please enter a valid hostname" ;;
                "username")  echo "Please enter a valid username" ;;
                "password")  echo "Please enter a valid password" ;;
                *)          echo "Invalid input" ;;
            esac
        }
    fi
}

# Initialize error messages
_tui_init_validation_errors

# Get validation error message
tui_get_validation_error() {
    if [ "$TUI_HAS_ASSOCIATIVE_ARRAYS" = "1" ]; then
        echo "${TUI_VALIDATION_ERRORS[$1]}"
    else
        _tui_get_validation_error "$1"
    fi
}

# Validation functions
tui_validate_required() {
    local value="$1"
    [ -n "$value" ]
}

tui_validate_number() {
    local value="$1"
    [[ "$value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]
}

tui_validate_integer() {
    local value="$1"
    [[ "$value" =~ ^[+-]?[0-9]+$ ]]
}

tui_validate_float() {
    local value="$1"
    [[ "$value" =~ ^[+-]?[0-9]*\.[0-9]+$ ]]
}

tui_validate_email() {
    local value="$1"
    [[ "$value" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

tui_validate_date() {
    local value="$1"
    date -d "$value" >/dev/null 2>&1
}

tui_validate_time() {
    local value="$1"
    [[ "$value" =~ ^([0-1][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$ ]]
}

tui_validate_ip() {
    local value="$1"
    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ ! "$value" =~ $ip_regex ]]; then
        return 1
    fi
    
    local IFS='.'
    read -ra octets <<< "$value"
    for octet in "${octets[@]}"; do
        (( octet > 255 )) && return 1
    done
    
    return 0
}

tui_validate_url() {
    local value="$1"
    [[ "$value" =~ ^(https?|ftp)://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/[A-Za-z0-9./-]*)?$ ]]
}

tui_validate_path() {
    local value="$1"
    [[ "$value" =~ ^[A-Za-z0-9./_-]+$ ]]
}

tui_validate_hostname() {
    local value="$1"
    [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$ ]]
}

tui_validate_username() {
    local value="$1"
    [[ "$value" =~ ^[A-Za-z0-9_-]{3,32}$ ]]
}

tui_validate_password() {
    local value="$1"
    local min_length=${2:-8}
    
    # Check minimum length
    [ ${#value} -lt $min_length ] && return 1
    
    # Check for at least one uppercase letter
    [[ ! "$value" =~ [A-Z] ]] && return 1
    
    # Check for at least one lowercase letter
    [[ ! "$value" =~ [a-z] ]] && return 1
    
    # Check for at least one number
    [[ ! "$value" =~ [0-9] ]] && return 1
    
    # Check for at least one special character
    [[ ! "$value" =~ [^A-Za-z0-9] ]] && return 1
    
    return 0
}

# Main validation function
tui_validate() {
    local value="$1"
    local validation_type="$2"
    local extra_param="$3"
    
    case "$validation_type" in
        "$TUI_VALIDATION_REQUIRED") tui_validate_required "$value" ;;
        "$TUI_VALIDATION_NUMBER")   tui_validate_number "$value" ;;
        "$TUI_VALIDATION_INTEGER")  tui_validate_integer "$value" ;;
        "$TUI_VALIDATION_FLOAT")    tui_validate_float "$value" ;;
        "$TUI_VALIDATION_EMAIL")    tui_validate_email "$value" ;;
        "$TUI_VALIDATION_DATE")     tui_validate_date "$value" ;;
        "$TUI_VALIDATION_TIME")     tui_validate_time "$value" ;;
        "$TUI_VALIDATION_IP")       tui_validate_ip "$value" ;;
        "$TUI_VALIDATION_URL")      tui_validate_url "$value" ;;
        "$TUI_VALIDATION_PATH")     tui_validate_path "$value" ;;
        "$TUI_VALIDATION_HOSTNAME") tui_validate_hostname "$value" ;;
        "$TUI_VALIDATION_USERNAME") tui_validate_username "$value" ;;
        "$TUI_VALIDATION_PASSWORD") tui_validate_password "$value" "$extra_param" ;;
        *) tui_error "Unknown validation type: $validation_type"; return $TUI_ERROR ;;
    esac
} 