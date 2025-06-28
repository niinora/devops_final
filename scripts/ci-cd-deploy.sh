#!/bin/bash

# CI/CD Deployment Script
# This script handles the automated deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}
COMPOSE_FILE="docker-compose.yml"

echo -e "${BLUE}🚀 Starting CI/CD deployment for environment: ${ENVIRONMENT}${NC}"

# Function to check if service is healthy
check_service_health() {
    local service_url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}Checking ${service_name} health...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "${service_url}" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ${service_name} is healthy${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Attempt ${attempt}/${max_attempts}: ${service_name} not ready yet...${NC}"
        sleep 10
        ((attempt++))
    done
    
    echo -e "${RED}❌ ${service_name} health check failed after ${max_attempts} attempts${NC}"
    return 1
}

# Pre-deployment checks
echo -e "${BLUE}🔍 Running pre-deployment checks...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running${NC}"
    exit 1
fi

# Check if Docker Compose file exists
if [ ! -f "${COMPOSE_FILE}" ]; then
    echo -e "${RED}❌ Docker Compose file not found: ${COMPOSE_FILE}${NC}"
    exit 1
fi

# Security scan
echo -e "${BLUE}🔒 Running security scans...${NC}"
if command -v trivy > /dev/null 2>&1; then
    trivy fs . --severity HIGH,CRITICAL --exit-code 1 || {
        echo -e "${RED}❌ Security scan failed${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ Security scan passed${NC}"
else
    echo -e "${YELLOW}⚠️ Trivy not found, skipping security scan${NC}"
fi

# Build and deploy
echo -e "${BLUE}🏗️ Building and deploying services...${NC}"

# Stop existing services
echo -e "${YELLOW}Stopping existing services...${NC}"
docker-compose down --remove-orphans

# Pull latest images (if using registry)
echo -e "${YELLOW}Pulling latest images...${NC}"
docker-compose pull --ignore-pull-failures

# Build and start services
echo -e "${YELLOW}Building and starting services...${NC}"
docker-compose up -d --build

# Wait for services to start
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 30

# Health checks
echo -e "${BLUE}🏥 Running health checks...${NC}"

# Check frontend
check_service_health "http://localhost:3000/health" "Frontend"

# Check backend
check_service_health "http://localhost:5000/health" "Backend"

# Check Prometheus
check_service_health "http://localhost:9090/-/healthy" "Prometheus"

# Check Grafana
check_service_health "http://localhost:3001/api/health" "Grafana"

# Post-deployment verification
echo -e "${BLUE}📊 Running post-deployment verification...${NC}"

# Check if containers are running
running_containers=$(docker-compose ps --services --filter "status=running" | wc -l)
total_containers=$(docker-compose ps --services | wc -l)

if [ "$running_containers" -eq "$total_containers" ]; then
    echo -e "${GREEN}✅ All containers are running (${running_containers}/${total_containers})${NC}"
else
    echo -e "${RED}❌ Some containers are not running (${running_containers}/${total_containers})${NC}"
    docker-compose ps
    exit 1
fi

# Check logs for errors
echo -e "${YELLOW}Checking logs for critical errors...${NC}"
if docker-compose logs --tail=50 | grep -i "error\|exception\|fatal" | grep -v "test"; then
    echo -e "${YELLOW}⚠️ Found some errors in logs, please review${NC}"
else
    echo -e "${GREEN}✅ No critical errors found in logs${NC}"
fi

# Monitoring setup verification
echo -e "${BLUE}📈 Verifying monitoring setup...${NC}"

# Check if Prometheus can scrape targets
prometheus_targets=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length' 2>/dev/null || echo "0")
if [ "$prometheus_targets" -gt 0 ]; then
    echo -e "${GREEN}✅ Prometheus is scraping ${prometheus_targets} targets${NC}"
else
    echo -e "${YELLOW}⚠️ Prometheus targets check failed${NC}"
fi

# Deployment summary
echo -e "${GREEN}"
echo "=============================================="
echo "🎉 Deployment completed successfully!"
echo "=============================================="
echo "Environment: ${ENVIRONMENT}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Services:"
echo "  - Frontend: http://localhost:3000"
echo "  - Backend API: http://localhost:5000"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3001"
echo "=============================================="
echo -e "${NC}"

# Cleanup old images (optional)
echo -e "${YELLOW}Cleaning up old Docker images...${NC}"
docker image prune -f --filter "dangling=true"

echo -e "${GREEN}🚀 CI/CD deployment completed successfully!${NC}"
