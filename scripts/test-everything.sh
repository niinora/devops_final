#!/bin/bash

# Complete DevOps Project Testing Script
# Run this script to test all components and take screenshots

echo "🚀 Starting Complete DevOps Project Testing"
echo "============================================"

echo "📋 Step 1: Check Docker is running"
docker --version
docker-compose --version

echo "📋 Step 2: Start all services"
docker-compose up -d

echo "📋 Step 3: Wait for services to be ready"
sleep 30

echo "📋 Step 4: Check service status"
docker-compose ps

echo "📋 Step 5: Test Frontend (take screenshot at http://localhost:3000)"
curl -I http://localhost:3000

echo "📋 Step 6: Test Backend Health"
curl http://localhost:5000/health

echo "📋 Step 7: Test Backend API"
curl http://localhost:5000/api/users

echo "📋 Step 8: Test Prometheus (take screenshot at http://localhost:9090)"
curl -I http://localhost:9090

echo "📋 Step 9: Test Grafana (take screenshot at http://localhost:3001)"
curl -I http://localhost:3001

echo "📋 Step 10: Check Prometheus targets"
echo "Navigate to http://localhost:9090/targets and take screenshot"

echo "📋 Step 11: Check Grafana dashboards"
echo "Login to http://localhost:3001 (admin/admin) and take dashboard screenshots"

echo "📋 Step 12: Run security scan (if Trivy is installed)"
if command -v trivy > /dev/null 2>&1; then
    echo "Running Trivy scan..."
    # Add your image names here
    echo "Scan frontend and backend images with Trivy"
else
    echo "Trivy not found - install or run manually"
fi

echo "📋 Step 13: Simulate incident"
echo "Stop backend service and observe system behavior"
echo "docker-compose stop backend"
echo "Check frontend and Prometheus for errors"
echo "Then restart: docker-compose start backend"

echo "📋 Step 14: Test Ansible"
echo "Run: ansible-playbook ansible/playbooks/deploy.yml --check"

echo "✅ Testing checklist complete!"
echo ""
echo "📸 SCREENSHOT CHECKLIST:"
echo "========================"
echo "□ GitHub repository page"
echo "□ CI/CD pipeline success"
echo "□ Docker containers running"
echo "□ Frontend application"
echo "□ Backend API responses"
echo "□ Prometheus interface"
echo "□ Prometheus targets page"
echo "□ Grafana dashboards"
echo "□ Security scan results"
echo "□ Incident simulation"
echo "□ System recovery"
echo "□ Documentation files"
echo ""
echo "📝 Remember to create Word document with all evidence!"
