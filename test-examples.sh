#!/bin/bash

# Example test for utils.sh
cat > tests/core/utils_test.sh << 'EOF'
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../core/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"

describe "Utils"

it "should check if command exists"
test_command_exists() {
    assert_equals "$(command_exists ls)" "0"  # ls should exist
    assert_equals "$(command_exists nonexistentcommand)" "1"  # should not exist
}

run_tests
EOF

# Example test for platform.sh
cat > tests/core/platform_test.sh << 'EOF'
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../core/platform.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"

describe "Platform Detection"

it "should detect operating system"
test_os_detection() {
    local os
    os=$(get_os)
    assert_contains "$os" "Linux\|Darwin"
}

run_tests
EOF

# Example test for menu component
cat > tests/tui/components/menu_test.sh << 'EOF'
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../../tui/components/menu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../core/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../test_framework.sh"

describe "Menu Component"

it "should render menu items"
test_menu_rendering() {
    local output
    output=$(render_menu "Test Menu" "Item 1" "Item 2" "Item 3")
    assert_contains "$output" "Test Menu"
    assert_contains "$output" "Item 1"
    assert_contains "$output" "Item 2"
    assert_contains "$output" "Item 3"
}

run_tests