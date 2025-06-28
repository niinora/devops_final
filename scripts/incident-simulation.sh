#!/bin/bash

# Incident Simulation Script
# This script simulates various incidents to test monitoring and response systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SIMULATION_DURATION=${1:-60}  # Default 60 seconds
INCIDENT_TYPE=${2:-"backend"} # Default backend incident

echo -e "${BLUE}=== DevOps Pipeline Incident Simulation ===${NC}"
echo "Simulation Type: $INCIDENT_TYPE"
echo "Duration: $SIMULATION_DURATION seconds"
echo "Timestamp: $(date)"
echo ""

# Function to check if services are running
check_services() {
    echo -e "${YELLOW}Checking service status...${NC}"
    
    # Check frontend
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Frontend: Healthy${NC}"
    else
        echo -e "${RED}✗ Frontend: Unhealthy${NC}"
    fi
    
    # Check backend
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend: Healthy${NC}"
    else
        echo -e "${RED}✗ Backend: Unhealthy${NC}"
    fi
    
    # Check database
    if docker exec devops-final-postgres-1 pg_isready -U devops_user -d devops_app > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Database: Healthy${NC}"
    else
        echo -e "${RED}✗ Database: Unhealthy${NC}"
    fi
    
    # Check Prometheus
    if curl -f http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Prometheus: Healthy${NC}"
    else
        echo -e "${RED}✗ Prometheus: Unhealthy${NC}"
    fi
    
    # Check Grafana
    if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Grafana: Healthy${NC}"
    else
        echo -e "${RED}✗ Grafana: Unhealthy${NC}"
    fi
}

# Function to simulate backend failure
simulate_backend_failure() {
    echo -e "${RED}=== Simulating Backend Service Failure ===${NC}"
    echo "Stopping backend service..."
    
    # Stop the backend container
    docker stop devops-final-backend-1
    
    echo "Backend service stopped. Monitoring systems should detect this..."
    echo "Check Grafana dashboard at http://localhost:3001"
    echo "Check Prometheus at http://localhost:9090"
    
    # Wait for simulation duration
    echo -e "${YELLOW}Waiting $SIMULATION_DURATION seconds...${NC}"
    sleep $SIMULATION_DURATION
    
    echo -e "${GREEN}Restarting backend service...${NC}"
    docker start devops-final-backend-1
    
    # Wait for service to be healthy
    echo "Waiting for backend to be healthy..."
    for i in {1..30}; do
        if curl -f http://localhost:5000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Backend service restored!${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
}

# Function to simulate database failure
simulate_database_failure() {
    echo -e "${RED}=== Simulating Database Failure ===${NC}"
    echo "Stopping database service..."
    
    # Stop the database container
    docker stop devops-final-postgres-1
    
    echo "Database service stopped. Backend should show database connection errors..."
    echo "Check backend health at http://localhost:5000/health"
    
    # Wait for simulation duration
    echo -e "${YELLOW}Waiting $SIMULATION_DURATION seconds...${NC}"
    sleep $SIMULATION_DURATION
    
    echo -e "${GREEN}Restarting database service...${NC}"
    docker start devops-final-postgres-1
    
    # Wait for database to be ready
    echo "Waiting for database to be ready..."
    for i in {1..30}; do
        if docker exec devops-final-postgres-1 pg_isready -U devops_user -d devops_app > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Database service restored!${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
}

# Function to simulate high load
simulate_high_load() {
    echo -e "${RED}=== Simulating High Load ===${NC}"
    echo "Generating high load on backend service..."
    
    # Start load generation in background
    (
        for i in {1..100}; do
            curl -s http://localhost:5000/api/users > /dev/null &
            curl -s http://localhost:5000/api/metrics > /dev/null &
            sleep 0.1
        done
        wait
    ) &
    
    LOAD_PID=$!
    
    echo "High load generated. Check monitoring dashboards for increased metrics..."
    echo "Check Grafana dashboard at http://localhost:3001"
    
    # Wait for simulation duration
    echo -e "${YELLOW}Waiting $SIMULATION_DURATION seconds...${NC}"
    sleep $SIMULATION_DURATION
    
    # Stop load generation
    kill $LOAD_PID 2>/dev/null || true
    echo -e "${GREEN}Load generation stopped.${NC}"
}

# Function to simulate memory leak
simulate_memory_leak() {
    echo -e "${RED}=== Simulating Memory Leak ===${NC}"
    echo "This simulation would require application-level changes."
    echo "For a real memory leak simulation, you would need to:"
    echo "1. Modify the backend application to leak memory"
    echo "2. Monitor memory usage in Grafana"
    echo "3. Observe container restart due to memory limits"
    echo ""
    echo "For now, we'll simulate by creating a temporary memory-intensive process..."
    
    # Create a temporary memory-intensive process
    (
        # Allocate memory in a loop
        for i in {1..100}; do
            # Create a large array (simulates memory leak)
            large_array=($(seq 1 10000))
            sleep 0.1
        done
    ) &
    
    MEMORY_PID=$!
    
    echo "Memory-intensive process started. Check container memory usage..."
    echo "Check Docker stats: docker stats devops-final-backend-1"
    
    # Wait for simulation duration
    echo -e "${YELLOW}Waiting $SIMULATION_DURATION seconds...${NC}"
    sleep $SIMULATION_DURATION
    
    # Stop memory-intensive process
    kill $MEMORY_PID 2>/dev/null || true
    echo -e "${GREEN}Memory-intensive process stopped.${NC}"
}

# Main simulation logic
echo -e "${BLUE}Pre-simulation service status:${NC}"
check_services
echo ""

case $INCIDENT_TYPE in
    "backend")
        simulate_backend_failure
        ;;
    "database")
        simulate_database_failure
        ;;
    "load")
        simulate_high_load
        ;;
    "memory")
        simulate_memory_leak
        ;;
    "all")
        echo -e "${YELLOW}Running all simulations sequentially...${NC}"
        simulate_backend_failure
        sleep 10
        simulate_database_failure
        sleep 10
        simulate_high_load
        sleep 10
        simulate_memory_leak
        ;;
    *)
        echo -e "${RED}Unknown incident type: $INCIDENT_TYPE${NC}"
        echo "Available types: backend, database, load, memory, all"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}Post-simulation service status:${NC}"
check_services
echo ""

echo -e "${GREEN}=== Incident Simulation Completed ===${NC}"
echo "Simulation Type: $INCIDENT_TYPE"
echo "Duration: $SIMULATION_DURATION seconds"
echo "Completed at: $(date)"
echo ""
echo "Next steps:"
echo "1. Review monitoring dashboards"
echo "2. Check logs: docker-compose logs"
echo "3. Analyze incident response effectiveness"
echo "4. Update post-mortem documentation" 