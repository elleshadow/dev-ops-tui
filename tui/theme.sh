#!/bin/bash

# Check for test mode
if [[ -n "$TEST_MODE" ]]; then
    # Mock dialog in test mode
    dialog() {
        case "$2" in
            "--inputbox"|"--passwordbox")
                echo "test_value"
                return 0
                ;;
            "--yesno")
                return 0
                ;;
            "--menu")
                echo "9"  # Return exit option
                return 0
                ;;
            "--msgbox")
                return 0
                ;;
            *)
                return 0
                ;;
        esac
    }
    export -f dialog
else
    # Check for dialog command
    if command -v dialog >/dev/null 2>&1; then
        export DIALOG="dialog"
    else
        echo "Error: dialog command not found"
        exit 1
    fi
fi

# Dialog appearance settings
export DIALOGRC="/dev/null"
export DIALOG_OK=0
export DIALOG_CANCEL=1
export DIALOG_ESC=255

# Colors
export DIALOG_COLOR_TITLE="blue"
export DIALOG_COLOR_BORDER="white"
export DIALOG_COLOR_MENU="white"

# Dialog dimensions
export DIALOG_HEIGHT=0  # Auto height
export DIALOG_WIDTH=0   # Auto width

# Dialog style
export DIALOG_BACKTITLE="DevOps TUI Configuration Manager"
export DIALOG_SHADOW=ON
export DIALOG_ASCII_LINES=OFF

# Set dialog options
export DIALOG_OPTIONS="\
    --colors \
    --no-collapse \
    --cr-wrap \
    --no-tags \
    --no-cancel \
    --default-button 'OK' \
    --backtitle '$DIALOG_BACKTITLE'"

