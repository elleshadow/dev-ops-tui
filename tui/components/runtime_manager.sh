#!/bin/bash

# Runtime management system
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"

# Runtime configuration
declare -r RUNTIME_CONFIG="${PROJECT_ROOT}/config/runtimes.conf"
declare -r RUNTIME_DIR="${PROJECT_ROOT}/.runtimes"

# Supported version managers
declare -A VERSION_MANAGERS=(
    ["node"]="nvm"
    ["python"]="pyenv"
    ["ruby"]="rvm"
    ["go"]="gvm"
)

init_runtime_manager() {
    mkdir -p "$RUNTIME_DIR"
    
    # Create runtime config if not exists
    if [[ ! -f "$RUNTIME_CONFIG" ]]; then
        {
            echo "# Runtime Configuration"
            echo "NODE_VERSION=lts/*"
            echo "PYTHON_VERSION=3.11"
            echo "RUBY_VERSION=3.2.0"
            echo "GO_VERSION=1.20"
        } > "$RUNTIME_CONFIG"
    fi
    
    # Source version managers if installed
    setup_version_managers
    return 0
}

setup_version_managers() {
    # NVM (Node Version Manager)
    if [[ -f "${HOME}/.nvm/nvm.sh" ]]; then
        export NVM_DIR="${HOME}/.nvm"
        source "${NVM_DIR}/nvm.sh"
    fi
    
    # Pyenv (Python Version Manager)
    if command -v pyenv &>/dev/null; then
        eval "$(pyenv init -)"
    fi
    
    # RVM (Ruby Version Manager)
    if [[ -f "${HOME}/.rvm/scripts/rvm" ]]; then
        source "${HOME}/.rvm/scripts/rvm"
    fi
    
    # GVM (Go Version Manager)
    if [[ -f "${HOME}/.gvm/scripts/gvm" ]]; then
        source "${HOME}/.gvm/scripts/gvm"
    fi
}

show_runtime_menu() {
    with_terminal_state "runtime" "
        while true; do
            clear
            echo -e '\033[36m=== Runtime Management ===\033[0m'
            echo
            echo '1) Install Version Manager'
            echo '2) Install Runtime Version'
            echo '3) Set Default Version'
            echo '4) Show Installed Versions'
            echo '5) Project Runtime Config'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) install_version_manager ;;
                2) install_runtime_version ;;
                3) set_default_version ;;
                4) show_installed_versions ;;
                5) configure_project_runtime ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

install_version_manager() {
    echo -e '\n\033[33mInstalling Version Managers\033[0m'
    
    echo "Select version manager to install:"
    echo "1) NVM (Node.js)"
    echo "2) Pyenv (Python)"
    echo "3) RVM (Ruby)"
    echo "4) GVM (Go)"
    read -n 1 -p "Select option: " vm_choice
    
    case $vm_choice in
        1) install_nvm ;;
        2) install_pyenv ;;
        3) install_rvm ;;
        4) install_gvm ;;
    esac
}

install_nvm() {
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    export NVM_DIR="${HOME}/.nvm"
    source "${NVM_DIR}/nvm.sh"
    echo "NVM installed successfully"
}

install_pyenv() {
    echo "Installing Pyenv..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install pyenv
    else
        curl https://pyenv.run | bash
    fi
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    echo "Pyenv installed successfully"
}

install_rvm() {
    echo "Installing RVM..."
    gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash -s stable
    source "${HOME}/.rvm/scripts/rvm"
    echo "RVM installed successfully"
}

install_gvm() {
    echo "Installing GVM..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source "${HOME}/.gvm/scripts/gvm"
    echo "GVM installed successfully"
}

install_runtime_version() {
    echo -e '\n\033[33mInstalling Runtime Version\033[0m'
    
    echo "Select runtime:"
    echo "1) Node.js"
    echo "2) Python"
    echo "3) Ruby"
    echo "4) Go"
    read -n 1 -p "Select option: " runtime_choice
    echo
    
    read -p "Enter version (or 'lts' for Node.js): " version
    
    case $runtime_choice in
        1) 
            nvm install "$version"
            nvm use "$version"
            ;;
        2)
            pyenv install "$version"
            pyenv global "$version"
            ;;
        3)
            rvm install "$version"
            rvm use "$version" --default
            ;;
        4)
            gvm install "go$version"
            gvm use "go$version" --default
            ;;
    esac
}

set_default_version() {
    echo -e '\n\033[33mSetting Default Version\033[0m'
    
    echo "Select runtime:"
    echo "1) Node.js"
    echo "2) Python"
    echo "3) Ruby"
    echo "4) Go"
    read -n 1 -p "Select option: " runtime_choice
    echo
    
    case $runtime_choice in
        1) 
            nvm ls
            read -p "Enter version to set as default: " version
            nvm alias default "$version"
            ;;
        2)
            pyenv versions
            read -p "Enter version to set as default: " version
            pyenv global "$version"
            ;;
        3)
            rvm list
            read -p "Enter version to set as default: " version
            rvm use "$version" --default
            ;;
        4)
            gvm list
            read -p "Enter version to set as default: " version
            gvm use "go$version" --default
            ;;
    esac
}

show_installed_versions() {
    echo -e '\n\033[33mInstalled Runtime Versions\033[0m\n'
    
    echo "Node.js Versions:"
    if command -v nvm &>/dev/null; then
        nvm ls
    else
        echo "NVM not installed"
    fi
    
    echo -e "\nPython Versions:"
    if command -v pyenv &>/dev/null; then
        pyenv versions
    else
        echo "Pyenv not installed"
    fi
    
    echo -e "\nRuby Versions:"
    if command -v rvm &>/dev/null; then
        rvm list
    else
        echo "RVM not installed"
    fi
    
    echo -e "\nGo Versions:"
    if command -v gvm &>/dev/null; then
        gvm list
    else
        echo "GVM not installed"
    fi
}

configure_project_runtime() {
    echo -e '\n\033[33mConfiguring Project Runtime\033[0m'
    
    # Create runtime config files
    touch .nvmrc .python-version .ruby-version .go-version
    
    echo "Current runtime versions:"
    echo "Node.js: $(node -v 2>/dev/null || echo 'Not installed')"
    echo "Python: $(python -V 2>/dev/null || echo 'Not installed')"
    echo "Ruby: $(ruby -v 2>/dev/null || echo 'Not installed')"
    echo "Go: $(go version 2>/dev/null || echo 'Not installed')"
    
    read -p "Configure runtime versions? [y/N] " configure
    
    if [[ "$configure" =~ ^[Yy]$ ]]; then
        read -p "Node.js version (press enter to skip): " node_version
        [[ -n "$node_version" ]] && echo "$node_version" > .nvmrc
        
        read -p "Python version (press enter to skip): " python_version
        [[ -n "$python_version" ]] && echo "$python_version" > .python-version
        
        read -p "Ruby version (press enter to skip): " ruby_version
        [[ -n "$ruby_version" ]] && echo "$ruby_version" > .ruby-version
        
        read -p "Go version (press enter to skip): " go_version
        [[ -n "$go_version" ]] && echo "$go_version" > .go-version
    fi
}

cleanup_runtime_manager() {
    # Cleanup temporary files
    rm -f "${RUNTIME_CONFIG}.bak"
    return 0
} 