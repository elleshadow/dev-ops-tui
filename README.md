# Dev-Ops TUI Library

A powerful Terminal User Interface (TUI) library for DevOps tools, built in pure Bash. This library provides a rich set of dialog components and utilities for creating interactive terminal applications, with a focus on DevOps tooling and system management.

## Project Overview

This project aims to create a comprehensive TUI framework for DevOps tools with the following goals:
- Provide a consistent and professional interface for terminal-based applications
- Simplify the creation of interactive DevOps tools
- Ensure robust error handling and system stability
- Support both basic and advanced terminal UI patterns
- Enable rapid development of DevOps automation tools

## Project Structure

```
.
├── core/           # Core functionality and utilities
├── configs/        # Configuration files and templates
├── data/          # Data storage and management
├── demo/          # Demo applications and examples
├── docker/        # Docker-related components
├── services/      # Service management modules
├── tests/         # Test suites and frameworks
├── tui/           # TUI components and modules
│   ├── components/
│   │   ├── core/      # Core TUI functionality
│   │   ├── dialog.sh  # Dialog components
│   │   ├── menu.sh    # Menu system
│   │   ├── status.sh  # Status bar and monitoring
│   │   └── test_viewer.sh  # Test results viewer
└── scripts/       # Utility scripts
```

## Features

### Dialog Components
- **Basic Dialogs**
  - Message boxes
  - Yes/No dialogs
  - Info boxes
  - Input boxes with validation
  - Password boxes with masking

- **Forms and Input**
  - Multi-field forms
  - Field validation (required, number, email, date, IP)
  - Password fields
  - Custom validation support

- **Menus and Selection**
  - Single-select menus
  - Multi-select checklists
  - Radio lists
  - Hierarchical menus
  - Keyboard shortcuts
  - Menu descriptions

- **File Operations**
  - Text file viewers
  - File editors
  - Tail viewers
  - File selection dialogs

- **Progress Indicators**
  - Progress bars
  - Gauges
  - Mixed gauges
  - Program output boxes

- **Calendar and Time**
  - Date selection
  - Time selection
  - Calendar navigation

### Advanced Features
- Automatic dialog sizing and positioning
- Terminal size awareness
- Form validation
- Keyboard navigation
- Basic mouse support
- Color support
- Unicode/ASCII line drawing
- Dialog shadows and styling
- Event system for UI updates
- State management
- Focus handling
- Window management

## Requirements

- Bash 4.0 or later
- `dialog` utility
- Standard Unix utilities (`sed`, `grep`, etc.)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dev-ops-tui.git
```

2. Install dependencies:
```bash
# For macOS
brew install dialog

# For Ubuntu/Debian
sudo apt-get install dialog

# For CentOS/RHEL
sudo yum install dialog
```

3. Source the library in your script:
```bash
source "path/to/tui/components/dialog.sh"
```

## Configuration

The library supports extensive configuration through environment variables:

```bash
# Dialog appearance
TUI_DIALOG_HEIGHT=0           # Auto-size if 0
TUI_DIALOG_WIDTH=0           # Auto-size if 0
TUI_DIALOG_BACKTITLE=""      # Background title
TUI_DIALOG_COLORS=false      # Enable colors
TUI_DIALOG_ASCII_LINES=false # Use ASCII instead of Unicode
TUI_DIALOG_NO_SHADOW=false   # Disable shadows
TUI_DIALOG_NO_MOUSE=false    # Disable mouse support
TUI_DIALOG_TAB_CORRECT=false # Enable tab correction
TUI_DIALOG_TAB_LEN=8        # Tab length

# Dialog behavior
TUI_DIALOG_SEPARATE_OUTPUT=false
TUI_DIALOG_NO_COLLAPSE=false
TUI_DIALOG_CR_WRAP=false
TUI_DIALOG_TRIM=false
TUI_DIALOG_NO_NL_EXPAND=false
TUI_DIALOG_ASPECT=9
```

## Usage Examples

### Basic Message Box
```bash
create_msgbox "Information" "Operation completed successfully"
```

### Input with Validation
```bash
create_validated_input "Email Input" "Enter your email:" "" "email"
```

### Menu with Shortcuts
```bash
create_enhanced_menu "Main Menu" "Select an option:" \
    "file" "(F)ile Operations" \
    "edit" "(E)dit Settings" \
    "quit" "(Q)uit"
```

### Form with Validation
```bash
create_validated_form "User Info" "Enter user details:" \
    "Name:" 1 1 "" 1 20 20 0 "required" \
    "Email:" 2 1 "" 2 20 30 0 "email" \
    "Age:" 3 1 "" 3 20 3 0 "number"
```

### Hierarchical Menu System
```bash
create_menu_system "Settings" "Configure System" \
    "main" \
    "network" "(N)etwork Settings" \
    "users" "(U)ser Management" \
    "---" \
    "network" \
    "ip" "IP Configuration" \
    "dns" "DNS Settings" \
    "---" \
    "users" \
    "add" "Add User" \
    "del" "Delete User"
```

## Development Status

### Completed Features
- Core TUI framework
- Basic dialog components
- Window management
- Terminal size handling
- Configuration system
- Event system
- Test framework
- Demo application

### In Progress
- Menu system enhancements
- Status bar implementation
- System monitoring
- Service status display
- Resource usage monitoring
- Notification system
- Status update events

## Testing

The project includes a comprehensive test suite:

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suite
./tests/tui/components/core/base_test.sh
```

Test coverage includes:
- Core functionality
- Dialog components
- Window management
- Terminal capabilities
- Configuration system
- Event handling
- Input validation
- Menu system

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on the `dialog` utility
- Inspired by the C Dialog library
- Thanks to all contributors
