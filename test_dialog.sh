#!/bin/bash

# Test basic dialog functionality
dialog --title "Test" --msgbox "Hello World" 8 40

# Test menu dialog
dialog --title "Test Menu" --menu "Select an option:" 15 40 3 \
    "1" "Option 1" \
    "2" "Option 2" \
    "3" "Option 3"

exit 0 