# Dev-Ops TUI Library

A powerful Terminal User Interface (TUI) library for DevOps tools, built in pure Bash. This library provides a rich set of dialog components and utilities for creating interactive terminal applications.

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

## Requirements
- Bash 4.0 or later
- `dialog` utility
- Standard Unix utilities (`sed`, `grep`, etc.)

## Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/dev-ops-tui.git
```

2. Source the library in your script:

```bash
source "path/to/tui/components/dialog.sh"
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

## Dialog Options

You can customize dialog appearance and behavior using these global variables:

```bash
DIALOG_HEIGHT=0           # Auto-size if 0
DIALOG_WIDTH=0           # Auto-size if 0
DIALOG_BACKTITLE=""      # Background title
DIALOG_COLORS=true       # Enable colors
DIALOG_ASCII_LINES=false # Use ASCII instead of Unicode
DIALOG_NO_SHADOW=false   # Disable shadows
```

## Exit Codes

The library uses standard dialog exit codes:
- `0` - OK/Yes
- `1` - Cancel/No
- `2` - Help
- `255` - ESC pressed
- `-1` - Error

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
./tests/run_tests.sh
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on the `dialog` utility
- Inspired by the C Dialog library
- Thanks to all contributors
