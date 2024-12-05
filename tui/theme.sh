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

# Create a temporary dialogrc file
create_dialog_config() {
    cat > "$HOME/.dialogrc" << 'EOF'
# Screen color
screen_color = (CYAN,BLACK,ON)

# Shadow's color
shadow_color = (BLACK,BLACK,ON)

# Dialog box color
dialog_color = (BLACK,CYAN,OFF)

# Dialog box title color
title_color = (BLACK,CYAN,ON)

# Dialog box border color
border_color = (BLACK,CYAN,ON)
border2_color = border_color

# Active button color
button_active_color = (CYAN,BLACK,ON)
button_inactive_color = dialog_color
button_key_active_color = button_active_color
button_key_inactive_color = (RED,CYAN,OFF)
button_label_active_color = (CYAN,BLACK,ON)
button_label_inactive_color = (BLACK,CYAN,ON)

# Input box color
inputbox_color = dialog_color
inputbox_border_color = dialog_color

# Search box color
searchbox_color = dialog_color
searchbox_title_color = title_color
searchbox_border_color = border_color

# Menu box color
menubox_color = dialog_color
menubox_border_color = border_color
menubox_border2_color = border_color

# Item color
item_color = dialog_color
item_selected_color = button_active_color

# Tag color
tag_color = title_color
tag_selected_color = button_active_color
tag_key_color = button_key_inactive_color
tag_key_selected_color = (BLACK,CYAN,ON)

# Up/Down arrow color
uarrow_color = (GREEN,CYAN,ON)
darrow_color = (GREEN,CYAN,ON)

# Item help-text color
itemhelp_color = (WHITE,BLACK,OFF)

# Active form text color
form_active_text_color = button_active_color
form_text_color = (CYAN,CYAN,ON)

# Readonly form item color
form_item_readonly_color = (CYAN,BLACK,ON)

# Dialog box gauge color
gauge_color = title_color

# Dialog box check list color
check_color = (BLACK,CYAN,OFF)
check_selected_color = button_active_color

# Dialog box radio list color
radio_color = (BLACK,CYAN,OFF)
radio_selected_color = button_active_color

# Help color
help_color = (CYAN,BLACK,ON)
EOF

    export DIALOGRC="$HOME/.dialogrc"
}

# Dialog appearance settings
export DIALOG_OK=0
export DIALOG_CANCEL=1
export DIALOG_ESC=255

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

# Create the dialog config if not in test mode
if [[ -z "$TEST_MODE" ]]; then
    create_dialog_config
fi

