#!/bin/bash

# Platform detection
is_darwin() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# Custom timeout implementation
run_with_timeout() {
    local timeout="$1"
    shift
    local cmd="$@"
    
    # Start the command in the background
    $cmd &
    local pid=$!
    
    # Wait for specified timeout
    local count=0
    while kill -0 $pid 2>/dev/null; do
        if ((count >= timeout)); then
            kill -TERM $pid 2>/dev/null || true
            wait $pid 2>/dev/null || true
            return 124  # timeout exit code
        fi
        sleep 1
        ((count++))
    done
    
    wait $pid
    return $?
}

# Timeout wrapper that uses either system timeout or our implementation
safe_timeout() {
    if command -v timeout >/dev/null 2>&1; then
        timeout "$@"
    else
        run_with_timeout "$@"
    fi
}

# String manipulation
trim() {
    local var="$*"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

# Array manipulation
join_by() {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

# File operations
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_no=$1
    if [ "$exit_code" != "0" ]; then
        echo "Error on line $line_no: Command exited with status $exit_code" >&2
        if [[ -z "$TEST_MODE" ]]; then
            return $exit_code
        fi
    fi
    return 0
}

# Trap handler
cleanup_handler() {
    local exit_code=$?
    echo "Cleaning up..." >&2
    # Add cleanup tasks here
    if [[ -z "$TEST_MODE" ]]; then
        exit $exit_code
    fi
    return 0
}

# Set up error handling
if [[ -z "$TEST_MODE" ]]; then
    set -o errexit  # Exit on error
    set -o nounset  # Exit on undefined variable
    set -o pipefail # Exit on pipe failure
fi

# Set up cleanup trap
trap 'cleanup_handler' EXIT
trap 'handle_error ${LINENO}' ERR

# Export utility functions
export -f is_darwin
export -f is_linux
export -f run_with_timeout
export -f safe_timeout
export -f trim
export -f join_by
export -f ensure_dir

