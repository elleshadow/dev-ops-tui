#!/bin/bash

# Check for dialog command
if ! command -v dialog >/dev/null 2>&1; then
    echo "Error: dialog command not found. Please install dialog package first."
    echo "On macOS: brew install dialog"
    echo "On Ubuntu/Debian: sudo apt-get install dialog"
    echo "On CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Cleanup function
tui_cleanup() {
    clear
    reset
    tput cnorm # Show cursor
}

# Dialog wrapper functions
tui_dialog_menu() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    shift 4
    local menu_height=$(( height - 8 ))
    [ "$menu_height" -lt 3 ] && menu_height=3
    dialog --clear --title "$title" \
        --menu "$text" "$height" "$width" "$menu_height" \
        "$@" 2>&1 >/dev/tty
}

tui_dialog_message() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    dialog --clear --title "$title" \
        --msgbox "$text" "$height" "$width" 2>&1 >/dev/tty
}

tui_dialog_yesno() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    dialog --clear --title "$title" \
        --yesno "$text" "$height" "$width" 2>&1 >/dev/tty
}

tui_dialog_input() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    dialog --clear --title "$title" \
        --inputbox "$text" "$height" "$width" 2>&1 >/dev/tty
}

tui_dialog_password() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    dialog --clear --title "$title" \
        --passwordbox "$text" "$height" "$width" 2>&1 >/dev/tty
}

tui_dialog_radiolist() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    shift 4
    dialog --clear --title "$title" \
        --radiolist "$text" "$height" "$width" $((height-8)) \
        "$@" 2>&1 >/dev/tty
}

tui_dialog_checklist() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    shift 4
    dialog --clear --title "$title" \
        --checklist "$text" "$height" "$width" $((height-8)) \
        "$@" 2>&1 >/dev/tty
}

tui_dialog_gauge() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    local percent="$5"
    echo "$percent" | dialog --clear --title "$title" \
        --gauge "$text" "$height" "$width" 0
}

# Form handling
tui_dialog_form() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    shift 4
    dialog --clear --title "$title" \
        --form "$text" "$height" "$width" $((height-8)) \
        "$@" 2>&1 >/dev/tty
}

# Calendar handling
tui_dialog_calendar() {
    local title="$1"
    local text="$2"
    local height="$3"
    local width="$4"
    local day="$5"
    local month="$6"
    local year="$7"
    dialog --clear --title "$title" \
        --calendar "$text" "$height" "$width" \
        "$day" "$month" "$year" 2>&1 >/dev/tty
}

# Initialize trap for cleanup
trap tui_cleanup EXIT INT TERM

