#!/bin/bash

# DevOps Pipeline Setup Script
# This script sets up the complete DevOps pipeline environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DevOps Pipeline Setup ===${NC}"
echo "This script will set up the complete DevOps pipeline environment"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        echo "Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed${NC}"
        echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        echo "Please install Git from https://git-scm.com/"
        exit 1
    fi
    
    # Check Node.js (optional, for local development)
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓ Node.js: $(node --version)${NC}"
    else
        echo -e "${YELLOW}⚠ Node.js: Not installed (optional for local development)${NC}"
    fi
    
    # Check Trivy (optional)
    if command -v trivy &> /dev/null; then
        echo -e "${GREEN}✓ Trivy: $(trivy --version | head -n1)${NC}"
    else
        echo -e "${YELLOW}⚠ Trivy: Not installed (optional for security scanning)${NC}"
        echo "Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
    fi
    
    # Check Ansible (optional)
    if command -v ansible &> /dev/null; then
        echo -e "${GREEN}✓ Ansible: $(ansible --version | head -n1)${NC}"
    else
        echo -e "${YELLOW}⚠ Ansible: Not installed (optional for automation)${NC}"
        echo "Install with: pip install ansible"
    fi
    
    echo -e "${GREEN}✓ Prerequisites check completed${NC}"
    echo ""
}

# Function to create environment file
setup_environment() {
    echo -e "${YELLOW}Setting up environment...${NC}"
    
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            echo -e "${GREEN}✓ Created .env file from template${NC}"
        else
            echo -e "${RED}Error: env.example not found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ .env file already exists${NC}"
    fi
    
    echo ""
}

# Function to create necessary directories
create_directories() {
    echo -e "${YELLOW}Creating necessary directories...${NC}"
    
    mkdir -p security-reports
    mkdir -p docs
    mkdir -p logs
    
    echo -e "${GREEN}✓ Directories created${NC}"
    echo ""
}

# Function to make scripts executable
make_scripts_executable() {
    echo -e "${YELLOW}Making scripts executable...${NC}"
    
    chmod +x scripts/*.sh
    
    echo -e "${GREEN}✓ Scripts made executable${NC}"
    echo ""
}

# Function to build and start services
build_and_start() {
    echo -e "${YELLOW}Building and starting services...${NC}"
    
    # Build images
    echo "Building Docker images..."
    docker-compose build
    
    # Start services
    echo "Starting services..."
    docker-compose up -d
    
    echo -e "${GREEN}✓ Services started${NC}"
    echo ""
}

# Function to wait for services to be ready
wait_for_services() {
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    
    # Wait for backend
    echo "Waiting for backend service..."
    for i in {1..30}; do
        if curl -f http://localhost:5000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Backend service ready${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    # Wait for frontend
    echo "Waiting for frontend service..."
    for i in {1..30}; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Frontend service ready${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    # Wait for Prometheus
    echo "Waiting for Prometheus..."
    for i in {1..30}; do
        if curl -f http://localhost:9090/-/healthy > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Prometheus ready${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    # Wait for Grafana
    echo "Waiting for Grafana..."
    for i in {1..30}; do
        if curl -f http://localhost:3001/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Grafana ready${NC}"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    echo ""
}

# Function to run security scan
run_security_scan() {
    if command -v trivy &> /dev/null; then
        echo -e "${YELLOW}Running security scan...${NC}"
        ./scripts/security-scan.sh
        echo ""
    else
        echo -e "${YELLOW}Skipping security scan (Trivy not installed)${NC}"
        echo ""
    fi
}

# Function to display final information
display_final_info() {
    echo -e "${GREEN}=== Setup Completed Successfully! ===${NC}"
    echo ""
    echo -e "${BLUE}Service URLs:${NC}"
    echo "  Frontend:     http://localhost:3000"
    echo "  Backend API:  http://localhost:5000"
    echo "  Grafana:      http://localhost:3001 (admin/admin)"
    echo "  Prometheus:   http://localhost:9090"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  View logs:           docker-compose logs -f"
    echo "  Stop services:       docker-compose down"
    echo "  Restart services:    docker-compose restart"
    echo "  Security scan:       ./scripts/security-scan.sh"
    echo "  Incident simulation: ./scripts/incident-simulation.sh"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Open http://localhost:3000 to access the application"
    echo "  2. Check monitoring dashboards in Grafana"
    echo "  3. Review security scan reports"
    echo "  4. Test incident simulation"
    echo "  5. Explore the codebase and documentation"
    echo ""
    echo -e "${GREEN}Happy DevOps-ing! 🚀${NC}"
}

# Main execution
main() {
    check_prerequisites
    setup_environment
    create_directories
    make_scripts_executable
    build_and_start
    wait_for_services
    run_security_scan
    display_final_info
}

# Run main function
main 