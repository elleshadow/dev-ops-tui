#!/bin/bash

# Get the test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Source the main script
source "$PROJECT_ROOT/tui/main.sh"

# Test utilities
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✓ $message"
    else
        echo "✗ $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✓ $message"
    else
        echo "✗ $message"
        echo "  Expected to find: $needle"
        echo "  In: $haystack"
        return 1
    fi
}

# Setup test environment
setup() {
    echo "Setting up test environment..."
    # Create test network
    docker network create test-network >/dev/null 2>&1 || true
    
    # Create test containers
    docker run -d --name test-nginx \
        --label com.shadowlab.managed=true \
        --label com.shadowlab.group=test \
        --network test-network \
        nginx:latest >/dev/null 2>&1 || true
        
    docker run -d --name test-redis \
        --label com.shadowlab.managed=true \
        --label com.shadowlab.group=test \
        --network test-network \
        redis:latest >/dev/null 2>&1 || true
}

# Cleanup test environment
teardown() {
    echo "Cleaning up test environment..."
    docker rm -f test-nginx test-redis >/dev/null 2>&1 || true
    docker network rm test-network >/dev/null 2>&1 || true
}

# Test container status checking
test_container_status() {
    echo "Testing container status functions..."
    
    # Test get_container_status
    local status
    status=$(get_container_status "test-nginx")
    assert_contains "$status" "Up" "Container status should show as running"
    
    # Test after stopping
    docker stop test-nginx >/dev/null 2>&1
    status=$(get_container_status "test-nginx")
    assert_contains "$status" "Exited" "Container status should show as stopped"
    
    # Test non-existent container
    status=$(get_container_status "nonexistent")
    assert_equals "Not found" "$status" "Non-existent container should return 'Not found'"
}

# Test container listing
test_container_listing() {
    echo "Testing container listing functions..."
    
    # Test get_running_containers
    local running
    running=$(get_running_containers)
    assert_contains "$running" "test-redis" "Running containers should include test-redis"
    
    # Test get_all_containers
    local all
    all=$(get_all_containers)
    assert_contains "$all" "test-nginx" "All containers should include stopped test-nginx"
    assert_contains "$all" "test-redis" "All containers should include running test-redis"
}

# Test container creation
test_container_creation() {
    echo "Testing container creation..."
    
    # Test creating a new container
    local test_config="
    image=nginx:latest
    ports=8080:80
    labels=com.shadowlab.managed=true,com.shadowlab.group=test
    restart=always"
    
    # Mock get_container_config
    get_container_config() {
        echo "$test_config"
    }
    
    create_service_container "test-new-nginx"
    local status
    status=$(get_container_status "test-new-nginx")
    assert_contains "$status" "Up" "Newly created container should be running"
    
    # Clean up test container
    docker rm -f test-new-nginx >/dev/null 2>&1
}

# Test container cleanup
test_container_cleanup() {
    echo "Testing container cleanup..."
    
    # Create some test resources
    docker volume create test-volume >/dev/null 2>&1
    docker network create test-cleanup-network >/dev/null 2>&1
    
    # Run cleanup
    clean_all
    
    # Verify cleanup
    local volumes
    volumes=$(docker volume ls --format "{{.Name}}" | grep "test-volume")
    assert_equals "" "$volumes" "Test volume should be removed"
    
    local networks
    networks=$(docker network ls --format "{{.Name}}" | grep "test-cleanup-network")
    assert_equals "" "$networks" "Test network should be removed"
    
    local containers
    containers=$(docker ps -a --format "{{.Names}}" | grep "test-")
    assert_equals "" "$containers" "All test containers should be removed"
}

# Test service grouping
test_service_grouping() {
    echo "Testing service grouping..."
    
    # Create containers with different groups
    docker run -d --name test-group1 \
        --label com.shadowlab.managed=true \
        --label com.shadowlab.group=group1 \
        nginx:latest >/dev/null 2>&1
        
    docker run -d --name test-group2 \
        --label com.shadowlab.managed=true \
        --label com.shadowlab.group=group2 \
        nginx:latest >/dev/null 2>&1
    
    # Test group filtering
    local group1
    group1=$(docker ps --filter "label=com.shadowlab.group=group1" --format "{{.Names}}")
    assert_contains "$group1" "test-group1" "Should find container in group1"
    
    local group2
    group2=$(docker ps --filter "label=com.shadowlab.group=group2" --format "{{.Names}}")
    assert_contains "$group2" "test-group2" "Should find container in group2"
    
    # Clean up test containers
    docker rm -f test-group1 test-group2 >/dev/null 2>&1
}

# Test configuration parsing
test_config_parsing() {
    echo "Testing configuration parsing..."
    
    # Test basic config
    local result
    result=$(parse_container_config "nginx")
    assert_contains "$result" "CONFIG_IMAGE='nginx:latest'" "Should parse image correctly"
    assert_contains "$result" "CONFIG_PORTS='80:80,443:443'" "Should parse ports correctly"
    
    # Test config with command
    result=$(parse_container_config "redis")
    assert_contains "$result" "CONFIG_COMMAND='redis-server --appendonly yes'" "Should parse command correctly"
    
    # Test config with environment variables
    result=$(parse_container_config "postgres")
    assert_contains "$result" "CONFIG_ENV='POSTGRES_PASSWORD=shadowlab'" "Should parse environment variables correctly"
}

# Run all tests
run_tests() {
    echo "Running Docker management tests..."
    
    # Run setup
    setup
    
    # Run individual tests
    test_container_status
    test_container_listing
    test_container_creation
    test_container_cleanup
    test_service_grouping
    test_config_parsing
    
    # Run teardown
    teardown
    
    echo "Tests completed."
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 