#!/bin/bash

# Security scanning script using Trivy
# This script scans all Docker images for vulnerabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SEVERITY=${TRIVY_SEVERITY:-"CRITICAL,HIGH"}
EXIT_CODE=${TRIVY_EXIT_CODE:-1}
REPORT_DIR="./security-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}Starting security scan with Trivy...${NC}"
echo "Severity level: $SEVERITY"
echo "Report directory: $REPORT_DIR"
echo "Timestamp: $TIMESTAMP"

# Create report directory
mkdir -p "$REPORT_DIR"

# Function to scan an image
scan_image() {
    local image_name=$1
    local report_file="$REPORT_DIR/trivy_${image_name//[^a-zA-Z0-9]/_}_${TIMESTAMP}.json"
    
    echo -e "\n${YELLOW}Scanning image: $image_name${NC}"
    
    if trivy image --severity "$SEVERITY" --format json --output "$report_file" "$image_name"; then
        echo -e "${GREEN}✓ Scan completed for $image_name${NC}"
        
        # Check if vulnerabilities were found
        if jq -e '.Results[].Vulnerabilities' "$report_file" > /dev/null 2>&1; then
            echo -e "${RED}⚠ Vulnerabilities found in $image_name${NC}"
            jq -r '.Results[].Vulnerabilities[] | "  - \(.VulnerabilityID): \(.Title) (Severity: \(.Severity))"' "$report_file" 2>/dev/null || true
        else
            echo -e "${GREEN}✓ No vulnerabilities found in $image_name${NC}"
        fi
    else
        echo -e "${RED}✗ Scan failed for $image_name${NC}"
        return 1
    fi
}

# Function to scan a Dockerfile
scan_dockerfile() {
    local dockerfile_path=$1
    local context_path=$(dirname "$dockerfile_path")
    local report_file="$REPORT_DIR/trivy_dockerfile_$(basename "$context_path")_${TIMESTAMP}.json"
    
    echo -e "\n${YELLOW}Scanning Dockerfile: $dockerfile_path${NC}"
    
    if trivy config --severity "$SEVERITY" --format json --output "$report_file" "$context_path"; then
        echo -e "${GREEN}✓ Dockerfile scan completed for $dockerfile_path${NC}"
        
        # Check if misconfigurations were found
        if jq -e '.Results[].Misconfigurations' "$report_file" > /dev/null 2>&1; then
            echo -e "${RED}⚠ Misconfigurations found in $dockerfile_path${NC}"
            jq -r '.Results[].Misconfigurations[] | "  - \(.ID): \(.Title) (Severity: \(.Severity))"' "$report_file" 2>/dev/null || true
        else
            echo -e "${GREEN}✓ No misconfigurations found in $dockerfile_path${NC}"
        fi
    else
        echo -e "${RED}✗ Dockerfile scan failed for $dockerfile_path${NC}"
        return 1
    fi
}

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}Error: Trivy is not installed. Please install Trivy first.${NC}"
    echo "Installation instructions: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    exit 1
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. JSON parsing will be limited.${NC}"
fi

# Build images if they don't exist
echo -e "\n${YELLOW}Building Docker images...${NC}"

# Build frontend image
if ! docker image inspect devops-final-frontend:latest &> /dev/null; then
    echo "Building frontend image..."
    docker build -t devops-final-frontend:latest ./frontend
fi

# Build backend image
if ! docker image inspect devops-final-backend:latest &> /dev/null; then
    echo "Building backend image..."
    docker build -t devops-final-backend:latest ./backend
fi

# Scan images
echo -e "\n${YELLOW}Starting image scans...${NC}"

# Scan frontend image
scan_image "devops-final-frontend:latest"

# Scan backend image
scan_image "devops-final-backend:latest"

# Scan base images
scan_image "node:18-alpine"
scan_image "nginx:alpine"
scan_image "postgres:15-alpine"

# Scan Dockerfiles
echo -e "\n${YELLOW}Starting Dockerfile scans...${NC}"
scan_dockerfile "./frontend/Dockerfile"
scan_dockerfile "./backend/Dockerfile"

# Generate summary report
echo -e "\n${GREEN}Generating summary report...${NC}"
SUMMARY_FILE="$REPORT_DIR/security_summary_${TIMESTAMP}.md"

cat > "$SUMMARY_FILE" << EOF
# Security Scan Summary

**Scan Date:** $(date)
**Severity Level:** $SEVERITY
**Scanner:** Trivy

## Scan Results

### Images Scanned
- devops-final-frontend:latest
- devops-final-backend:latest
- node:18-alpine
- nginx:alpine
- postgres:15-alpine

### Dockerfiles Scanned
- ./frontend/Dockerfile
- ./backend/Dockerfile

## Detailed Reports

EOF

# Add links to detailed reports
for report in "$REPORT_DIR"/trivy_*_"$TIMESTAMP".json; do
    if [ -f "$report" ]; then
        echo "- [$(basename "$report")]($(basename "$report"))" >> "$SUMMARY_FILE"
    fi
done

echo -e "\n${GREEN}Security scan completed!${NC}"
echo "Summary report: $SUMMARY_FILE"
echo "Detailed reports: $REPORT_DIR/"

# Check if any critical vulnerabilities were found
if [ "$EXIT_CODE" -eq 1 ]; then
    echo -e "\n${YELLOW}Checking for critical vulnerabilities...${NC}"
    
    critical_found=false
    for report in "$REPORT_DIR"/trivy_*_"$TIMESTAMP".json; do
        if [ -f "$report" ] && jq -e '.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL")' "$report" > /dev/null 2>&1; then
            echo -e "${RED}Critical vulnerabilities found in $(basename "$report")${NC}"
            critical_found=true
        fi
    done
    
    if [ "$critical_found" = true ]; then
        echo -e "${RED}Critical vulnerabilities detected. Please review and fix them.${NC}"
        exit 1
    else
        echo -e "${GREEN}No critical vulnerabilities found.${NC}"
    fi
fi

echo -e "\n${GREEN}All scans completed successfully!${NC}" 