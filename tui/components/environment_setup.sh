#!/bin/bash

# Environment setup and management
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"

# Constants
declare -r ENV_CONFIG="${PROJECT_ROOT}/config/environment.conf"
declare -r GIT_CONFIG="${PROJECT_ROOT}/config/git.conf"
declare -r DEPS_FILE="${PROJECT_ROOT}/config/dependencies.conf"

init_environment_setup() {
    mkdir -p "${PROJECT_ROOT}/config"
    
    # Create environment config if not exists
    if [[ ! -f "$ENV_CONFIG" ]]; then
        {
            echo "# Environment Configuration"
            echo "ENV_TYPE=development"
            echo "DOCKER_ENABLED=true"
            echo "REMOTE_ENABLED=true"
            echo "AUTO_UPDATE=true"
        } > "$ENV_CONFIG"
    fi
    
    # Create git config if not exists
    if [[ ! -f "$GIT_CONFIG" ]]; then
        {
            echo "# Git Configuration"
            echo "REMOTE_PROVIDER=github"
            echo "DEFAULT_BRANCH=main"
            echo "AUTO_PUSH=false"
            echo "PR_TEMPLATE=true"
        } > "$GIT_CONFIG"
    fi
    
    return 0
}

show_environment_menu() {
    with_terminal_state "environment" "
        while true; do
            clear
            echo -e '\033[36m=== Environment Management ===\033[0m'
            echo
            echo '1) Initialize New Environment'
            echo '2) Git Repository Management'
            echo '3) Dependency Management'
            echo '4) Environment Configuration'
            echo '5) Remote Management'
            echo '6) CI/CD Setup'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) setup_new_environment ;;
                2) manage_git_repository ;;
                3) manage_dependencies ;;
                4) configure_environment ;;
                5) manage_remote_connections ;;
                6) setup_cicd ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

setup_new_environment() {
    echo -e '\n\033[33mInitializing New Environment...\033[0m'
    
    # Check for git
    if ! command -v git &>/dev/null; then
        echo "Installing git..."
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install git
        else
            sudo apt-get update && sudo apt-get install -y git
        fi
    fi
    
    # Initialize git if needed
    if [[ ! -d ".git" ]]; then
        git init
        echo "Git repository initialized"
    fi
    
    # Setup git configuration
    if [[ ! -f ".gitignore" ]]; then
        {
            echo "*.log"
            echo "*.tmp"
            echo ".DS_Store"
            echo "node_modules/"
            echo "vendor/"
            echo ".env"
            echo "config/*.local.conf"
        } > ".gitignore"
    fi
    
    # Create standard directories
    mkdir -p {src,tests,docs,config,scripts,logs}
    
    echo "Environment initialized successfully"
}

manage_git_repository() {
    echo -e '\n\033[33mGit Repository Management\033[0m'
    
    # Show current status
    git status
    
    echo -e "\nOptions:"
    echo "1) Create and Push New Branch"
    echo "2) Commit Changes"
    echo "3) Push to Remote"
    echo "4) Pull Latest Changes"
    echo "5) View Branches"
    read -n 1 -p "Select option: " git_choice
    
    case $git_choice in
        1) create_and_push_branch ;;
        2) commit_changes ;;
        3) push_to_remote ;;
        4) pull_latest ;;
        5) view_branches ;;
    esac
}

create_and_push_branch() {
    read -p "Enter new branch name: " branch_name
    
    # Create and checkout branch
    git checkout -b "$branch_name"
    
    # Setup remote if not exists
    if ! git remote | grep -q "origin"; then
        read -p "Enter remote repository URL: " remote_url
        git remote add origin "$remote_url"
    fi
    
    # Push and set upstream
    git push -u origin "$branch_name"
    echo "Branch created and pushed successfully"
}

manage_dependencies() {
    echo -e '\n\033[33mDependency Management\033[0m'
    
    # Detect package managers
    local package_managers=()
    [[ -f "package.json" ]] && package_managers+=("npm")
    [[ -f "requirements.txt" ]] && package_managers+=("pip")
    [[ -f "Gemfile" ]] && package_managers+=("bundler")
    [[ -f "composer.json" ]] && package_managers+=("composer")
    
    # Install dependencies based on detected package managers
    for pm in "${package_managers[@]}"; do
        echo "Installing $pm dependencies..."
        case $pm in
            npm) npm install ;;
            pip) pip install -r requirements.txt ;;
            bundler) bundle install ;;
            composer) composer install ;;
        esac
    done
    
    echo "Dependencies updated successfully"
}

configure_environment() {
    echo -e '\n\033[33mEnvironment Configuration\033[0m'
    
    # Load current config
    source "$ENV_CONFIG"
    
    # Show configuration options
    echo "Current Configuration:"
    echo "1) Environment Type: $ENV_TYPE"
    echo "2) Docker Enabled: $DOCKER_ENABLED"
    echo "3) Remote Enabled: $REMOTE_ENABLED"
    echo "4) Auto Update: $AUTO_UPDATE"
    
    read -n 1 -p "Select option to modify (q to quit): " config_choice
    
    case $config_choice in
        1) 
            read -p "Enter environment type (development/staging/production): " ENV_TYPE
            sed -i.bak "s/ENV_TYPE=.*/ENV_TYPE=$ENV_TYPE/" "$ENV_CONFIG"
            ;;
        2)
            DOCKER_ENABLED=$([[ "$DOCKER_ENABLED" == "true" ]] && echo "false" || echo "true")
            sed -i.bak "s/DOCKER_ENABLED=.*/DOCKER_ENABLED=$DOCKER_ENABLED/" "$ENV_CONFIG"
            ;;
        3)
            REMOTE_ENABLED=$([[ "$REMOTE_ENABLED" == "true" ]] && echo "false" || echo "true")
            sed -i.bak "s/REMOTE_ENABLED=.*/REMOTE_ENABLED=$REMOTE_ENABLED/" "$ENV_CONFIG"
            ;;
        4)
            AUTO_UPDATE=$([[ "$AUTO_UPDATE" == "true" ]] && echo "false" || echo "true")
            sed -i.bak "s/AUTO_UPDATE=.*/AUTO_UPDATE=$AUTO_UPDATE/" "$ENV_CONFIG"
            ;;
    esac
    
    rm -f "${ENV_CONFIG}.bak"
}

manage_remote_connections() {
    echo -e '\n\033[33mRemote Management\033[0m'
    
    # Show current remotes
    echo "Current Remotes:"
    git remote -v
    
    echo -e "\nOptions:"
    echo "1) Add Remote"
    echo "2) Remove Remote"
    echo "3) Update Remote URL"
    read -n 1 -p "Select option: " remote_choice
    
    case $remote_choice in
        1)
            read -p "Enter remote name: " remote_name
            read -p "Enter remote URL: " remote_url
            git remote add "$remote_name" "$remote_url"
            ;;
        2)
            read -p "Enter remote to remove: " remote_name
            git remote remove "$remote_name"
            ;;
        3)
            read -p "Enter remote to update: " remote_name
            read -p "Enter new URL: " remote_url
            git remote set-url "$remote_name" "$remote_url"
            ;;
    esac
}

setup_cicd() {
    echo -e '\n\033[33mSetting up CI/CD\033[0m'
    
    # Create GitHub Actions workflow directory
    mkdir -p .github/workflows
    
    # Create basic CI workflow
    cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run tests
      run: |
        ./tests/run_all.sh
EOF
    
    echo "CI/CD workflow created"
}

cleanup_environment_setup() {
    # Cleanup temporary files
    rm -f "${ENV_CONFIG}.bak" "${GIT_CONFIG}.bak"
    return 0
} 