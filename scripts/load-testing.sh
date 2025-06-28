#!/bin/bash

# Basic Load Testing Script for DevOps Pipeline Application
# This script performs load testing on the frontend and backend services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL=${BACKEND_URL:-"http://localhost:5000"}
FRONTEND_URL=${FRONTEND_URL:-"http://localhost:3000"}
CONCURRENT_USERS=${CONCURRENT_USERS:-10}
DURATION=${DURATION:-30}
REQUESTS_PER_USER=${REQUESTS_PER_USER:-100}
REPORT_DIR="./load-test-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}🚀 Starting Load Testing for DevOps Pipeline Application${NC}"
echo -e "${BLUE}======================================================${NC}"

# Create report directory
mkdir -p "$REPORT_DIR"

# Function to check if service is available
check_service() {
    local url=$1
    local service_name=$2
    
    echo -e "${YELLOW}Checking ${service_name} availability...${NC}"
    if curl -f -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ${service_name} is available at ${url}${NC}"
        return 0
    else
        echo -e "${RED}❌ ${service_name} is not available at ${url}${NC}"
        return 1
    fi
}

# Function to run basic load test with curl
run_curl_load_test() {
    local url=$1
    local test_name=$2
    local requests=$3
    
    echo -e "${YELLOW}Running ${test_name} load test with curl...${NC}"
    
    local start_time=$(date +%s)
    local success_count=0
    local error_count=0
    
    for ((i=1; i<=requests; i++)); do
        if curl -f -s "$url" > /dev/null 2>&1; then
            ((success_count++))
        else
            ((error_count++))
        fi
        
        # Progress indicator
        if ((i % 10 == 0)); then
            echo -ne "${BLUE}Progress: ${i}/${requests} requests completed\r${NC}"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local rps=$(echo "scale=2; $requests / $duration" | bc -l 2>/dev/null || echo "N/A")
    
    echo -e "\n${GREEN}${test_name} Load Test Results:${NC}"
    echo -e "  Total Requests: $requests"
    echo -e "  Successful: $success_count"
    echo -e "  Failed: $error_count"
    echo -e "  Duration: ${duration}s"
    echo -e "  Requests/sec: $rps"
    echo -e "  Success Rate: $(echo "scale=2; $success_count * 100 / $requests" | bc -l 2>/dev/null || echo "N/A")%"
    
    # Save results to file
    cat > "$REPORT_DIR/${test_name,,}_${TIMESTAMP}.txt" << EOF
${test_name} Load Test Report
Generated: $(date)
=====================================
Target URL: $url
Total Requests: $requests
Successful Requests: $success_count
Failed Requests: $error_count
Test Duration: ${duration}s
Requests per Second: $rps
Success Rate: $(echo "scale=2; $success_count * 100 / $requests" | bc -l 2>/dev/null || echo "N/A")%
=====================================
EOF
}

# Function to run concurrent load test
run_concurrent_test() {
    local url=$1
    local test_name=$2
    local users=$3
    local requests_per_user=$4
    
    echo -e "${YELLOW}Running ${test_name} concurrent load test...${NC}"
    echo -e "${BLUE}Users: $users, Requests per user: $requests_per_user${NC}"
    
    local start_time=$(date +%s)
    local pids=()
    
    # Create temporary directory for individual results
    local temp_dir="/tmp/load_test_$$"
    mkdir -p "$temp_dir"
    
    # Start concurrent users
    for ((u=1; u<=users; u++)); do
        (
            local user_success=0
            local user_errors=0
            
            for ((r=1; r<=requests_per_user; r++)); do
                if curl -f -s "$url" > /dev/null 2>&1; then
                    ((user_success++))
                else
                    ((user_errors++))
                fi
            done
            
            echo "$user_success $user_errors" > "$temp_dir/user_$u.result"
        ) &
        pids+=($!)
    done
    
    # Wait for all users to complete
    echo -e "${YELLOW}Waiting for all users to complete...${NC}"
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Aggregate results
    local total_success=0
    local total_errors=0
    
    for ((u=1; u<=users; u++)); do
        if [[ -f "$temp_dir/user_$u.result" ]]; then
            read success errors < "$temp_dir/user_$u.result"
            total_success=$((total_success + success))
            total_errors=$((total_errors + errors))
        fi
    done
    
    local total_requests=$((total_success + total_errors))
    local rps=$(echo "scale=2; $total_requests / $duration" | bc -l 2>/dev/null || echo "N/A")
    
    echo -e "\n${GREEN}${test_name} Concurrent Load Test Results:${NC}"
    echo -e "  Concurrent Users: $users"
    echo -e "  Requests per User: $requests_per_user"
    echo -e "  Total Requests: $total_requests"
    echo -e "  Successful: $total_success"
    echo -e "  Failed: $total_errors"
    echo -e "  Duration: ${duration}s"
    echo -e "  Requests/sec: $rps"
    echo -e "  Success Rate: $(echo "scale=2; $total_success * 100 / $total_requests" | bc -l 2>/dev/null || echo "N/A")%"
    
    # Save results
    cat > "$REPORT_DIR/${test_name,,}_concurrent_${TIMESTAMP}.txt" << EOF
${test_name} Concurrent Load Test Report
Generated: $(date)
========================================
Target URL: $url
Concurrent Users: $users
Requests per User: $requests_per_user
Total Requests: $total_requests
Successful Requests: $total_success
Failed Requests: $total_errors
Test Duration: ${duration}s
Requests per Second: $rps
Success Rate: $(echo "scale=2; $total_success * 100 / $total_requests" | bc -l 2>/dev/null || echo "N/A")%
========================================
EOF
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function to test API endpoints
test_api_endpoints() {
    echo -e "${BLUE}Testing Backend API Endpoints${NC}"
    
    local endpoints=(
        "$BACKEND_URL/health"
        "$BACKEND_URL/api/users"
        "$BACKEND_URL/metrics"
    )
    
    for endpoint in "${endpoints[@]}"; do
        echo -e "${YELLOW}Testing endpoint: $endpoint${NC}"
        
        if curl -f -s "$endpoint" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Endpoint responsive${NC}"
            
            # Quick load test on each endpoint
            run_curl_load_test "$endpoint" "$(basename $endpoint)" 50
        else
            echo -e "${RED}❌ Endpoint not available${NC}"
        fi
        echo ""
    done
}

# Function to monitor system resources during load test
monitor_resources() {
    local duration=$1
    local output_file="$REPORT_DIR/system_resources_${TIMESTAMP}.log"
    
    echo -e "${YELLOW}Monitoring system resources for ${duration}s...${NC}"
    
    # Start resource monitoring in background
    (
        echo "Timestamp,CPU%,Memory%,DiskIO" > "$output_file"
        
        for ((i=1; i<=duration; i++)); do
            local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "N/A")
            local memory=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' || echo "N/A")
            local disk_io=$(iostat -d 1 1 2>/dev/null | tail -n +4 | awk '{sum+=$4} END {print sum}' || echo "N/A")
            
            echo "$timestamp,$cpu,$memory,$disk_io" >> "$output_file"
            sleep 1
        done
    ) &
    
    local monitor_pid=$!
    return $monitor_pid
}

# Main execution
main() {
    echo -e "${BLUE}Load Test Configuration:${NC}"
    echo -e "  Backend URL: $BACKEND_URL"
    echo -e "  Frontend URL: $FRONTEND_URL"
    echo -e "  Concurrent Users: $CONCURRENT_USERS"
    echo -e "  Requests per User: $REQUESTS_PER_USER"
    echo -e "  Test Duration: $DURATION seconds"
    echo -e "  Report Directory: $REPORT_DIR"
    echo ""
    
    # Check if services are running
    local services_available=true
    
    if ! check_service "$BACKEND_URL/health" "Backend"; then
        services_available=false
    fi
    
    if ! check_service "$FRONTEND_URL" "Frontend"; then
        services_available=false
    fi
    
    if [[ "$services_available" == false ]]; then
        echo -e "${RED}❌ Some services are not available. Please start the application first.${NC}"
        echo -e "${YELLOW}💡 Run: docker-compose up -d${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ All services are available. Starting load tests...${NC}"
    echo ""
    
    # Start resource monitoring
    monitor_resources $DURATION
    local monitor_pid=$!
    
    # Test 1: Basic Frontend Load Test
    echo -e "${BLUE}📊 Test 1: Frontend Basic Load Test${NC}"
    run_curl_load_test "$FRONTEND_URL" "Frontend" 100
    echo ""
    
    # Test 2: Backend Health Endpoint Load Test
    echo -e "${BLUE}📊 Test 2: Backend Health Endpoint Load Test${NC}"
    run_curl_load_test "$BACKEND_URL/health" "Backend-Health" 200
    echo ""
    
    # Test 3: Concurrent User Test
    echo -e "${BLUE}📊 Test 3: Concurrent User Load Test${NC}"
    run_concurrent_test "$BACKEND_URL/health" "Backend-Concurrent" $CONCURRENT_USERS $REQUESTS_PER_USER
    echo ""
    
    # Test 4: API Endpoints Test
    test_api_endpoints
    echo ""
    
    # Stop resource monitoring
    kill $monitor_pid 2>/dev/null || true
    
    # Generate summary report
    echo -e "${BLUE}📋 Generating Summary Report${NC}"
    cat > "$REPORT_DIR/load_test_summary_${TIMESTAMP}.md" << EOF
# Load Test Summary Report

**Generated:** $(date)
**Test Configuration:**
- Backend URL: $BACKEND_URL
- Frontend URL: $FRONTEND_URL
- Concurrent Users: $CONCURRENT_USERS
- Requests per User: $REQUESTS_PER_USER
- Test Duration: $DURATION seconds

## Test Results

### Frontend Load Test
- Target: Frontend application
- Requests: 100
- Results: See frontend_${TIMESTAMP}.txt

### Backend Health Load Test
- Target: Backend health endpoint
- Requests: 200
- Results: See backend-health_${TIMESTAMP}.txt

### Concurrent User Test
- Target: Backend health endpoint
- Users: $CONCURRENT_USERS concurrent
- Requests per User: $REQUESTS_PER_USER
- Results: See backend-concurrent_${TIMESTAMP}.txt

### API Endpoints Test
- Multiple endpoints tested
- Individual results in separate files

## System Resources
- Resource monitoring data: system_resources_${TIMESTAMP}.log

## Recommendations

1. **Performance Optimization**: Review failed requests and optimize bottlenecks
2. **Scaling**: Consider horizontal scaling if success rates < 95%
3. **Monitoring**: Implement alerts for high response times
4. **Caching**: Add caching layers for frequently accessed endpoints

EOF
    
    echo -e "${GREEN}✅ Load testing completed successfully!${NC}"
    echo -e "${BLUE}📁 Reports saved in: $REPORT_DIR${NC}"
    echo -e "${BLUE}📋 Summary report: $REPORT_DIR/load_test_summary_${TIMESTAMP}.md${NC}"
}

# Check dependencies
if ! command -v curl > /dev/null 2>&1; then
    echo -e "${RED}❌ curl is required but not installed${NC}"
    exit 1
fi

# Run main function
main "$@"
