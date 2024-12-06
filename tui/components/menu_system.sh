#!/bin/bash

# Menu system constants
MENU_STATE_FILE="/tmp/tui_menu_state"
MENU_ERROR_STATE=""
EDUCATION_STATE_FILE="/tmp/tui_education_state"
HELP_HISTORY_FILE="/tmp/tui_help_history"

# Menu data structures
declare -A MENUS=()
declare -A MENU_ITEMS=()
declare -A MENU_TITLES=()
declare -A MENU_STATES=()
declare -A MENU_HELP=()
declare -A MENU_LEARN_MORE=()

init_menu_system() {
    # Initialize menu structures
    MENUS=()
    MENU_ITEMS=()
    MENU_TITLES=()
    MENU_STATES=()
    MENU_HELP=()
    MENU_LEARN_MORE=()
    
    # Initialize state files
    echo "{}" > "$MENU_STATE_FILE"
    [[ -f "$EDUCATION_STATE_FILE" ]] || echo "show_tips=true" > "$EDUCATION_STATE_FILE"
    
    # Clear error state
    MENU_ERROR_STATE=""
    
    return 0
}

create_menu() {
    local menu_id=$1
    local title=$2
    
    # Check for duplicate menu
    if menu_exists "$menu_id"; then
        return 1
    fi
    
    # Create menu
    MENUS[$menu_id]=1
    MENU_TITLES[$menu_id]="$title"
    MENU_ITEMS[$menu_id]=""
    
    return 0
}

menu_exists() {
    local menu_id=$1
    [[ -n "${MENUS[$menu_id]}" ]]
}

add_menu_item() {
    local menu_id=$1
    local item_id=$2
    local label=$3
    local command=$4
    
    # Verify menu exists
    if ! menu_exists "$menu_id"; then
        return 1
    fi
    
    # Add item
    local items="${MENU_ITEMS[$menu_id]}"
    MENU_ITEMS[$menu_id]="${items:+$items:}$item_id|$label|$command"
    
    return 0
}

get_menu_item_count() {
    local menu_id=$1
    local items="${MENU_ITEMS[$menu_id]}"
    
    if [[ -z "$items" ]]; then
        echo "0"
        return
    fi
    
    echo "$items" | tr ':' '\n' | wc -l
}

get_menu_title() {
    local menu_id=$1
    echo "${MENU_TITLES[$menu_id]}"
}

navigate_menu() {
    local menu_id=$1
    
    # Verify menu exists
    if ! menu_exists "$menu_id"; then
        MENU_ERROR_STATE="ERROR"
        return 1
    fi
    
    # Set current menu
    echo "$menu_id" > "${MENU_STATE_FILE}.current"
    return 0
}

get_current_menu() {
    if [[ -f "${MENU_STATE_FILE}.current" ]]; then
        cat "${MENU_STATE_FILE}.current"
    fi
}

navigate_back() {
    rm -f "${MENU_STATE_FILE}.current"
}

set_menu_state() {
    local menu_id=$1
    local key=$2
    local value=$3
    
    MENU_STATES["${menu_id}_${key}"]="$value"
}

get_menu_state() {
    local menu_id=$1
    local key=$2
    
    echo "${MENU_STATES["${menu_id}_${key}"]:-}"
}

clear_menu_state() {
    local menu_id=$1
    
    # Clear all states for menu
    for key in "${!MENU_STATES[@]}"; do
        if [[ $key == ${menu_id}_* ]]; then
            unset MENU_STATES[$key]
        fi
    done
}

render_menu() {
    local menu_id=$1
    local output=""
    
    # Add title
    output+="${MENU_TITLES[$menu_id]}\n\n"
    
    # Add items
    local items="${MENU_ITEMS[$menu_id]}"
    if [[ -n "$items" ]]; then
        while IFS=: read -r item; do
            IFS='|' read -r id label _ <<< "$item"
            output+="$label\n"
        done <<< "$items"
    fi
    
    # Add educational options if available
    if [[ -n "${MENU_LEARN_MORE[$menu_id]}" ]]; then
        output+="\n?: Help\nl: Learn More\n"
    fi
    
    # Add tip if enabled
    if show_tips_enabled && [[ -n "${MENU_HELP[$menu_id]}" ]]; then
        local tip
        tip=$(echo "${MENU_HELP[$menu_id]}" | head -n 1)
        output+="\n\033[33mTip: $tip\033[0m\n"
    fi
    
    echo -e "$output"
}

select_menu_item() {
    local item_id=$1
    local current_menu
    current_menu=$(get_current_menu)
    
    if [[ -z "$current_menu" ]]; then
        MENU_ERROR_STATE="ERROR"
        return 1
    fi
    
    # Find item command
    local items="${MENU_ITEMS[$current_menu]}"
    local command=""
    
    while IFS=: read -r item; do
        IFS='|' read -r id label cmd <<< "$item"
        if [[ "$id" == "$item_id" ]]; then
            command="$cmd"
            break
        fi
    done <<< "$items"
    
    if [[ -z "$command" ]]; then
        MENU_ERROR_STATE="ERROR"
        return 1
    fi
    
    # Execute command
    eval "$command"
}

get_selected_item() {
    local current_menu
    current_menu=$(get_current_menu)
    
    if [[ -n "${MENU_STATES["${current_menu}_selected"]}" ]]; then
        echo "${MENU_STATES["${current_menu}_selected"]}"
    fi
}

get_menu_error_state() {
    echo "$MENU_ERROR_STATE"
}

clear_menu_error_state() {
    MENU_ERROR_STATE=""
}

cleanup_menu() {
    local menu_id=$1
    
    unset MENUS[$menu_id]
    unset MENU_ITEMS[$menu_id]
    unset MENU_TITLES[$menu_id]
    clear_menu_state "$menu_id"
}

cleanup_menu_system() {
    # Clean up all menus
    for menu_id in "${!MENUS[@]}"; do
        cleanup_menu "$menu_id"
    done
    
    # Clean up state files
    rm -f "$MENU_STATE_FILE" "${MENU_STATE_FILE}.current"
    
    # Reset data structures
    MENUS=()
    MENU_ITEMS=()
    MENU_TITLES=()
    MENU_STATES=()
    MENU_ERROR_STATE=""
}

show_main_menu() {
    # Check for first run
    if [[ ! -f "${PROJECT_ROOT}/config/environment.conf" ]]; then
        show_first_run_setup
    fi
    
    with_terminal_state "main_menu" "
        while true; do
            clear
            echo -e '\033[36m=== DevOps TUI ===\033[0m'
            echo
            echo '1) Environment Management'
            echo '2) Runtime Management'
            echo '3) Secrets Management'
            echo '4) Docker Operations'
            echo '5) Resource Monitor'
            echo '6) System Maintenance'
            echo '7) Configuration'
            echo '8) Logs'
            echo '?) Help'
            echo 'l) Learn More'
            echo 'q) Quit'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) show_environment_menu ;;
                2) show_runtime_menu ;;
                3) show_secrets_menu ;;
                4) show_docker_menu ;;
                5) show_resource_monitor ;;
                6) show_system_maintenance_menu ;;
                7) show_config_menu ;;
                8) show_log_viewer ;;
                ?) show_context_help ;;
                l|L) show_learn_more ;;
                q|Q) return 0 ;;
                *) continue ;;
            esac
        done
    "
}

show_first_run_setup() {
    clear
    echo -e '\033[36m=== Welcome to DevOps TUI ===\033[0m'
    echo -e '\033[33mFirst Run Setup\033[0m'
    echo
    echo "This appears to be your first time running the TUI."
    echo "Let's set up your development environment."
    echo
    read -n 1 -p "Press any key to continue..."
    
    # Initialize core components
    echo -e "\n\033[32mInitializing Core Components...\033[0m"
    
    # 1. Environment Setup
    echo -e "\n1. Setting up environment..."
    setup_new_environment
    
    # 2. Runtime Setup
    echo -e "\n2. Setting up runtime environment..."
    if ! command -v nvm &>/dev/null; then
        echo "Installing Node Version Manager..."
        install_nvm
    fi
    if ! command -v pyenv &>/dev/null; then
        echo "Installing Python Version Manager..."
        install_pyenv
    fi
    
    # 3. Git Configuration
    echo -e "\n3. Configuring Git..."
    if [[ ! -f "${HOME}/.gitconfig" ]]; then
        echo "Setting up Git configuration..."
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
    fi
    
    # 4. SSH/GPG Setup
    echo -e "\n4. Setting up security..."
    if [[ ! -f "${HOME}/.ssh/id_rsa.pub" ]]; then
        echo "Setting up SSH key..."
        ssh-keygen -t rsa -b 4096 -C "$git_email"
        echo
        echo "Please add this SSH key to your GitHub account:"
        cat "${HOME}/.ssh/id_rsa.pub"
        echo
        read -n 1 -p "Press any key once you've added the key..."
    fi
    
    # 5. Secrets Setup
    echo -e "\n5. Setting up secrets management..."
    if ! command -v gpg &>/dev/null; then
        echo "Installing GPG..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install gnupg
        else
            sudo apt-get update && sudo apt-get install -y gnupg
        fi
    fi
    
    # 6. Environment Configuration
    echo -e "\n6. Configuring environment..."
    configure_environment
    
    echo
    echo -e '\033[32mFirst run setup complete!\033[0m'
    echo "Your development environment is now ready."
    echo
    read -n 1 -p "Press any key to continue to the main menu..."
}

add_menu_help() {
    local menu_id=$1
    local help_text=$2
    
    MENU_HELP[$menu_id]="$help_text"
}

add_learn_more() {
    local menu_id=$1
    local learn_more_id=$2
    
    MENU_LEARN_MORE[$menu_id]="$learn_more_id"
}

show_context_help() {
    local menu_id=$1
    
    if [[ -n "${MENU_HELP[$menu_id]}" ]]; then
        clear
        echo -e "\033[36m=== Help: $(get_menu_title "$menu_id") ===\033[0m\n"
        echo -e "${MENU_HELP[$menu_id]}"
        # Record that this help topic was viewed
        echo "$(date '+%Y-%m-%d %H:%M:%S') $menu_id" >> "$HELP_HISTORY_FILE"
        echo -e "\nPress any key to continue..."
        read -n 1
    fi
}

toggle_tips() {
    local current_state
    current_state=$(grep "show_tips" "$EDUCATION_STATE_FILE" | cut -d= -f2)
    
    if [[ "$current_state" == "true" ]]; then
        sed -i '' 's/show_tips=true/show_tips=false/' "$EDUCATION_STATE_FILE"
    else
        sed -i '' 's/show_tips=false/show_tips=true/' "$EDUCATION_STATE_FILE"
    fi
}

show_tips_enabled() {
    grep -q "show_tips=true" "$EDUCATION_STATE_FILE"
}

show_learn_more() {
    local menu_id
    menu_id=$(get_current_menu)
    
    if [[ -n "${MENU_LEARN_MORE[$menu_id]}" ]]; then
        clear
        echo -e "\033[36m=== Learn More: $(get_menu_title "$menu_id") ===\033[0m\n"
        echo -e "${MENU_LEARN_MORE[$menu_id]}"
        # Record that this learn more topic was viewed
        echo "$(date '+%Y-%m-%d %H:%M:%S') ${menu_id}_learn_more" >> "$HELP_HISTORY_FILE"
        echo -e "\nPress any key to continue..."
        read -n 1
    fi
}

view_learning_progress() {
    clear
    echo -e "\033[36m=== Learning Progress ===\033[0m\n"
    
    if [[ ! -f "$HELP_HISTORY_FILE" ]]; then
        echo "No help topics viewed yet."
        echo -e "\nPress any key to continue..."
        read -n 1
        return
    fi
    
    echo "Recently Viewed Topics:"
    echo "----------------------"
    tail -n 10 "$HELP_HISTORY_FILE" | while read -r line; do
        local timestamp topic
        timestamp=$(echo "$line" | cut -d' ' -f1,2)
        topic=$(echo "$line" | cut -d' ' -f3-)
        
        # Format topic name
        if [[ "$topic" == *"_learn_more" ]]; then
            topic="${topic%_learn_more} (Detailed)"
        fi
        
        echo "[$timestamp] $topic"
    done
    
    echo -e "\nTotal Topics Viewed: $(wc -l < "$HELP_HISTORY_FILE")"
    echo -e "\nPress any key to continue..."
    read -n 1
} 