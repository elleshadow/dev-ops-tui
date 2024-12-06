#!/bin/bash

# Service management system
source "${PROJECT_ROOT}/tui/components/terminal_state.sh"
source "${PROJECT_ROOT}/tui/components/logging_system.sh"

# Constants
declare -r DOCKER_COMPOSE_FILE="${PROJECT_ROOT}/config/docker-compose.yml"
declare -r SERVICE_CONFIG="${PROJECT_ROOT}/config/services.conf"

init_service_manager() {
    # Create service configuration
    if [[ ! -f "$SERVICE_CONFIG" ]]; then
        {
            echo "# Service Configuration"
            echo "POSTGRES_PORT=5432"
            echo "PGADMIN_PORT=5050"
            echo "GRAFANA_PORT=3000"
            echo "PROMETHEUS_PORT=9090"
            echo "LOKI_PORT=3100"
            echo "TRAEFIK_PORT=8080"
        } > "$SERVICE_CONFIG"
    fi
    
    # Create docker-compose configuration
    create_docker_compose
    return 0
}

create_docker_compose() {
    cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
    ports:
      - "${TRAEFIK_PORT}:8080"
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - dev_network

  postgres:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - dev_network
    labels:
      - "traefik.enable=false"

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@localhost}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
    ports:
      - "${PGADMIN_PORT}:80"
    networks:
      - dev_network
    labels:
      - "traefik.http.routers.pgadmin.rule=Host(\`pgadmin.localhost\`)"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "${GRAFANA_PORT}:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - dev_network
    labels:
      - "traefik.http.routers.grafana.rule=Host(\`grafana.localhost\`)"

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "${PROMETHEUS_PORT}:9090"
    volumes:
      - prometheus_data:/prometheus
    networks:
      - dev_network
    labels:
      - "traefik.http.routers.prometheus.rule=Host(\`prometheus.localhost\`)"

  loki:
    image: grafana/loki:latest
    ports:
      - "${LOKI_PORT}:3100"
    volumes:
      - loki_data:/loki
    networks:
      - dev_network
    labels:
      - "traefik.http.routers.loki.rule=Host(\`loki.localhost\`)"

networks:
  dev_network:
    driver: bridge

volumes:
  postgres_data:
  grafana_data:
  prometheus_data:
  loki_data:
EOF
}

show_service_menu() {
    with_terminal_state "services" "
        while true; do
            clear
            echo -e '\033[36m=== Service Management ===\033[0m'
            echo
            echo '1) Deploy All Services'
            echo '2) Stop All Services'
            echo '3) Show Service Status'
            echo '4) View Service Logs'
            echo '5) Restart Services'
            echo 'q) Back to Main Menu'
            echo
            read -n 1 -p 'Select option: ' choice
            echo
            
            case \$choice in
                1) deploy_services ;;
                2) stop_services ;;
                3) show_status ;;
                4) view_logs ;;
                5) restart_services ;;
                q|Q) break ;;
                *) continue ;;
            esac
            
            echo
            read -n 1 -p 'Press any key to continue...'
        done
    "
}

deploy_services() {
    echo -e '\n\033[33mDeploying Services...\033[0m'
    
    # Ensure Docker is running
    if ! docker info &>/dev/null; then
        echo "Starting Docker..."
        if [[ "$(uname)" == "Darwin" ]]; then
            open -a Docker
            sleep 10  # Wait for Docker to start
        else
            sudo systemctl start docker
        fi
    fi
    
    # Deploy services
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    wait_for_services
    
    # Show service URLs
    echo -e "\n\033[32mServices Deployed!\033[0m"
    echo -e "\nAccess your services at:"
    echo "PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
    echo "pgAdmin:    http://pgadmin.localhost"
    echo "Grafana:    http://grafana.localhost"
    echo "Prometheus: http://prometheus.localhost"
    echo "Loki:      http://loki.localhost"
    echo "Traefik:    http://localhost:${TRAEFIK_PORT:-8080}"
    
    echo -e "\nDefault Credentials:"
    echo "pgAdmin:  admin@localhost / admin"
    echo "Grafana:  admin / admin"
    
    echo -e "\n\033[32mEnvironment ready! You can now continue in your browser.\033[0m"
}

stop_services() {
    echo -e '\n\033[33mStopping Services...\033[0m'
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
}

show_status() {
    echo -e '\n\033[33mService Status\033[0m'
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
}

view_logs() {
    echo -e '\n\033[33mService Logs\033[0m'
    docker-compose -f "$DOCKER_COMPOSE_FILE" logs --tail=100 -f
}

restart_services() {
    echo -e '\n\033[33mRestarting Services...\033[0m'
    docker-compose -f "$DOCKER_COMPOSE_FILE" restart
    wait_for_services
}

wait_for_services() {
    echo "Waiting for services to be ready..."
    local services=(
        "postgres:${POSTGRES_PORT:-5432}"
        "pgadmin:${PGADMIN_PORT:-5050}"
        "grafana:${GRAFANA_PORT:-3000}"
        "prometheus:${PROMETHEUS_PORT:-9090}"
        "loki:${LOKI_PORT:-3100}"
        "traefik:${TRAEFIK_PORT:-8080}"
    )
    
    for service in "${services[@]}"; do
        local name port
        IFS=':' read -r name port <<< "$service"
        echo -n "Waiting for $name..."
        while ! nc -z localhost "$port"; do
            echo -n "."
            sleep 1
        done
        echo " ready!"
    done
}

cleanup_service_manager() {
    # Optional: Stop services on exit
    if [[ "${AUTO_CLEANUP:-false}" == "true" ]]; then
        stop_services
    fi
    return 0
} 