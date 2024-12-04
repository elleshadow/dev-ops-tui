#!/bin/bash

# Create core directories and files
mkdir -p core
touch core/{logging,utils,platform,progress}.sh

# Create TUI directories and files
mkdir -p tui/components
touch tui/main.sh
touch tui/theme.sh
touch tui/components/{menu,dialog,status}.sh

# Create Docker management directories and files
mkdir -p docker
touch docker/{manager,health,network}.sh

# Create service management directories and files
mkdir -p services
touch services/{manager,health,recovery}.sh

# Make all shell scripts executable
find . -name "*.sh" -exec chmod +x {} \;

# Create basic .gitignore
cat > .gitignore << 'EOF'
.DS_Store
.env
*.log
*.tmp
/logs
/tmp
EOF

# Create empty README.md
cat > README.md << 'EOF'
# Dev-Ops TUI

A terminal user interface for development operations management.

## Structure

- `core/` - Core utilities and functions
- `tui/` - Terminal user interface components
- `docker/` - Docker management functionality
- `services/` - Service management functionality
EOF

# Print success message
echo "Project structure created successfully!"
echo "Next steps:"
echo "1. cd dev-ops"
echo "2. Initialize git repository"
echo "3. Start implementing core functionality"