#!/bin/bash

# Check for dialog command
if ! command -v dialog >/dev/null 2>&1; then
    echo "Error: dialog command not found. Please install dialog package first."
    echo "On macOS: brew install dialog"
    echo "On Ubuntu/Debian: sudo apt-get install dialog"
    echo "On CentOS/RHEL: sudo yum install dialog"
    exit 1
fi

# Import TUI components
source "$(dirname "${BASH_SOURCE[0]}")/../tui/components/dialog.sh"

# Show welcome message
show_welcome() {
    tui_dialog_message "TUI Demo" \
        "Welcome to the TUI Demo Application!\n\n\
This demo will showcase various features of the TUI library:\n\n\
• Basic dialogs and messages\n\
• Input forms with validation\n\
• Menus and selection lists\n\
• File operations\n\
• Progress indicators\n\
• Calendar and time selection\n\
• And more!\n\n\
Press OK to continue..." 20 70 || return 1
}

# Basic dialog demos
demo_basic_dialogs() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Basic Dialogs" "Select a demo:" 15 60 \
            "message" "Message Box" \
            "yesno" "Yes/No Dialog" \
            "info" "Info Box" \
            "error" "Error Dialog" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "message")
                tui_dialog_message "Message Demo" "This is a simple message box.\nIt can display multiple lines of text." 10 50 || return 1
                ;;
            "yesno")
                if tui_dialog_yesno "Question" "Would you like to see more demos?" 10 50; then
                    tui_dialog_message "Response" "You selected Yes!" 8 40 || return 1
                else
                    tui_dialog_message "Response" "You selected No!" 8 40 || return 1
                fi
                ;;
            "info")
                tui_dialog_message "Info Demo" "This is an informational message.\n\nIt uses different styling." 10 50 || return 1
                ;;
            "error")
                tui_dialog_message "Error Demo" "This is what an error message looks like.\n\nIt often includes details about what went wrong." 10 50 || return 1
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Input form demos
demo_input_forms() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Input & Forms" "Select a demo:" 15 60 \
            "input" "Simple Input" \
            "password" "Password Input" \
            "form" "Multi-field Form" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "input")
                local name
                name=$(tui_dialog_input "Input Demo" "Please enter your name:" "" 8 50)
                [ $? -eq 0 ] && tui_dialog_message "Input Result" "Hello, $name!" 8 40
                ;;
            "password")
                local password
                password=$(tui_dialog_password "Password Demo" "Enter a password:" 8 50)
                [ $? -eq 0 ] && tui_dialog_message "Password Result" "Password received (not shown for security)" 8 40
                ;;
            "form")
                local result
                result=$(tui_dialog_form "User Info" "Enter your details:" 15 60 \
                    "Name:" 1 1 "" 1 20 20 0 \
                    "Email:" 2 1 "" 2 20 30 0 \
                    "Age:" 3 1 "" 3 20 3 0)
                [ $? -eq 0 ] && tui_dialog_message "Form Result" "Received:\n$result" 12 50
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Menu demos
demo_menus() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Menus & Selection" "Select a demo:" 15 60 \
            "simple" "Simple Menu" \
            "nested" "Nested Menu" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "simple")
                local selection
                selection=$(tui_dialog_menu "Simple Menu" "Select an option:" 12 50 \
                    "1" "Option One" \
                    "2" "Option Two" \
                    "3" "Option Three")
                [ $? -eq 0 ] && tui_dialog_message "Menu Result" "You selected: $selection" 8 40
                ;;
            "nested")
                local selection
                selection=$(tui_dialog_menu "Settings" "Select a category:" 15 60 \
                    "network" "Network Settings" \
                    "display" "Display Settings" \
                    "sound" "Sound Settings")
                if [ $? -eq 0 ]; then
                    case "$selection" in
                        "network")
                            tui_dialog_menu "Network" "Network Options:" 12 50 \
                                "wifi" "WiFi Settings" \
                                "eth" "Ethernet Settings"
                            ;;
                        "display")
                            tui_dialog_menu "Display" "Display Options:" 12 50 \
                                "res" "Resolution" \
                                "bright" "Brightness"
                            ;;
                        "sound")
                            tui_dialog_menu "Sound" "Sound Options:" 12 50 \
                                "vol" "Volume" \
                                "dev" "Devices"
                            ;;
                    esac
                fi
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# File operation demos
demo_file_operations() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "File Operations" "Select a demo:" 15 60 \
            "create" "Create File" \
            "edit" "Edit File" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "create")
                local filename
                filename=$(tui_dialog_input "Create File" "Enter filename:" "" 8 50)
                if [ $? -eq 0 ]; then
                    touch "$filename" 2>/dev/null && \
                        tui_dialog_message "Success" "File created: $filename" 8 40 || \
                        tui_dialog_message "Error" "Failed to create file" 8 40
                fi
                ;;
            "edit")
                local filename
                filename=$(tui_dialog_input "Edit File" "Enter filename:" "" 8 50)
                if [ $? -eq 0 ] && [ -f "$filename" ]; then
                    local content
                    content=$(tui_dialog_input "Edit File" "Edit content:" "$(cat "$filename")" 12 60)
                    [ $? -eq 0 ] && echo "$content" > "$filename" && \
                        tui_dialog_message "Success" "File saved" 8 40
                fi
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Progress indicator demos
demo_progress() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Progress Indicators" "Select a demo:" 15 60 \
            "simple" "Simple Progress" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "simple")
                for i in {0..100..10}; do
                    echo "$i"
                    sleep 0.1
                done | dialog --gauge "Processing..." 8 40 0
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Calendar and time demos
demo_calendar_time() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Calendar & Time" "Select a demo:" 15 60 \
            "date" "Select Date" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "date")
                local today
                today=$(date +%Y-%m-%d)
                tui_dialog_input "Date" "Enter date (YYYY-MM-DD):" "$today" 8 50
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Input validation demos
demo_validation() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "Input Validation" "Select a demo:" 15 60 \
            "email" "Email Validation" \
            "number" "Number Validation" \
            "back" "Return to Main Menu")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "email")
                local result
                result=$(tui_dialog_validated_form "Email" "Enter email:" 12 60 \
                    "Email:" 1 1 "" 1 20 30 0 "email")
                [ $? -eq 0 ] && tui_dialog_message "Success" "Valid email: $result" 8 40
                ;;
            "number")
                local result
                result=$(tui_dialog_validated_form "Number" "Enter number:" 12 60 \
                    "Number:" 1 1 "" 1 20 10 0 "number")
                [ $? -eq 0 ] && tui_dialog_message "Success" "Valid number: $result" 8 40
                ;;
            "back"|"") return 0 ;;
            *) return 1 ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        local choice
        choice=$(tui_dialog_menu "TUI Demo" "Select a demo section:" 20 70 \
            "basic" "Basic Dialogs" \
            "input" "Input & Forms" \
            "menu" "Menus & Selection" \
            "file" "File Operations" \
            "progress" "Progress Indicators" \
            "calendar" "Calendar & Time" \
            "validation" "Input Validation" \
            "quit" "Exit Demo")
        
        [ $? -ne 0 ] && return 1
        
        case "$choice" in
            "basic") 
                demo_basic_dialogs || return 1
                ;;
            "input") 
                demo_input_forms || return 1
                ;;
            "menu") 
                demo_menus || return 1
                ;;
            "file") 
                demo_file_operations || return 1
                ;;
            "progress") 
                demo_progress || return 1
                ;;
            "calendar") 
                demo_calendar_time || return 1
                ;;
            "validation") 
                demo_validation || return 1
                ;;
            "quit"|"") 
                return 0
                ;;
            *) 
                return 1
                ;;
        esac
    done
}

# Run the demo
if ! show_welcome; then
    exit 1
fi

if ! main_menu; then
    tui_dialog_message "Error" "An error occurred while running the demo.\nPress OK to exit." 8 40
    exit 1
fi

tui_dialog_message "Goodbye" "Thank you for trying the TUI Demo!\n\nPress OK to exit." 8 40

exit 0 