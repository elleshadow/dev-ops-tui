#!/bin/bash

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/../test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../core/platform.sh"

describe "Platform Tests"

# OS Detection
it "should detect operating system type"
test_os_detection() {
    local os
    os="$(get_os_type)"
    assert_matches "$os" "^(linux|darwin|windows)$"
}

it "should get OS version"
test_os_version() {
    local version
    version="$(get_os_version)"
    assert_not_empty "$version"
}

# System Resources
it "should get total memory"
test_memory_total() {
    local memory
    memory="$(get_total_memory)"
    assert_true "[ $memory -gt 0 ]"
}

it "should get available memory"
test_memory_available() {
    local memory
    memory="$(get_available_memory)"
    assert_true "[ $memory -gt 0 ]"
}

it "should get CPU count"
test_cpu_count() {
    local count
    count="$(get_cpu_count)"
    assert_true "[ $count -gt 0 ]"
}

it "should get CPU usage"
test_cpu_usage() {
    local usage
    usage="$(get_cpu_usage)"
    assert_true "[ $usage -ge 0 -a $usage -le 100 ]"
}

# Disk Space
it "should get disk space information"
test_disk_space() {
    local space
    space="$(get_disk_space "/")"
    assert_true "[ $space -gt 0 ]"
}

it "should check if disk space is low"
test_disk_space_low() {
    local is_low
    is_low="$(is_disk_space_low "/" 90)"  # 90% threshold
    assert_matches "$is_low" "^(true|false)$"
}

# Network
it "should check network connectivity"
test_network_connectivity() {
    local connected
    connected="$(check_network_connectivity)"
    assert_matches "$connected" "^(true|false)$"
}

it "should get network interface information"
test_network_interfaces() {
    local interfaces
    interfaces="$(get_network_interfaces)"
    assert_not_empty "$interfaces"
}

# Dependencies
it "should check required commands"
test_required_commands() {
    local result
    result="$(check_required_commands "bash" "ls")"
    assert_equals "$result" "true"
    
    result="$(check_required_commands "nonexistentcmd")"
    assert_equals "$result" "false"
}

it "should get command version"
test_command_version() {
    local version
    version="$(get_command_version "bash")"
    assert_not_empty "$version"
}

# Environment
it "should detect environment type"
test_environment_detection() {
    local env
    env="$(get_environment_type)"
    assert_matches "$env" "^(development|staging|production)$"
}

it "should get environment variables"
test_environment_variables() {
    local vars
    vars="$(get_environment_variables)"
    assert_not_empty "$vars"
}

# System Capabilities
it "should check system capabilities"
test_system_capabilities() {
    local caps
    caps="$(get_system_capabilities)"
    assert_not_empty "$caps"
}

it "should detect docker availability"
test_docker_available() {
    local available
    available="$(is_docker_available)"
    assert_matches "$available" "^(true|false)$"
}

# Process Management
it "should get process information"
test_process_info() {
    local pid="$$"  # Current process
    local info
    info="$(get_process_info $pid)"
    assert_not_empty "$info"
}

it "should check if process is running"
test_process_running() {
    local pid="$$"  # Current process
    local running
    running="$(is_process_running $pid)"
    assert_equals "$running" "true"
}

# System Paths
it "should get system paths"
test_system_paths() {
    local paths
    paths="$(get_system_paths)"
    assert_not_empty "$paths"
}

# Terminal Capabilities
it "should detect terminal capabilities"
test_terminal_capabilities() {
    local color_support
    color_support="$(has_color_support)"
    assert_matches "$color_support" "^(true|false)$"
    
    local term_size
    term_size="$(get_terminal_size)"
    assert_not_empty "$term_size"
}

run_tests