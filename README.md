# DevOps Pipeline for Multi-Service Application

This project demonstrates a complete DevOps pipeline for a multi-service application with containerization, monitoring, security scanning, and automation.

## Project Overview

This application consists of:
- **Frontend**: React.js web application
- **Backend**: Node.js/Express API service
- **Database**: PostgreSQL database
- **Monitoring**: Prometheus for metrics collection and Grafana for visualization
- **Security**: Trivy for container image scanning
- **Automation**: Ansible playbooks for deployment automation

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │    │   Backend   │    │  Database   │
│  (React)    │◄──►│  (Node.js)  │◄──►│ (PostgreSQL)│
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌─────────────┐
                    │ Prometheus  │
                    │ (Monitoring)│
                    └─────────────┘
                           │
                    ┌─────────────┐
                    │   Grafana   │
                    │(Visualization)│
                    └─────────────┘
```

## Services

### Frontend Service
- **Technology**: React.js
- **Port**: 3000
- **Features**: User interface for the application
- **Health Check**: `/health` endpoint

### Backend Service
- **Technology**: Node.js with Express
- **Port**: 5000
- **Features**: REST API endpoints
- **Health Check**: `/health` endpoint
- **Endpoints**: 
  - `GET /api/users` - List users
  - `POST /api/users` - Create user
  - `GET /api/metrics` - Application metrics

### Database Service
- **Technology**: PostgreSQL
- **Port**: 5432
- **Features**: Data persistence
- **Credentials**: Managed via environment variables

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Custom Metrics**: Application-specific metrics for monitoring

## Prerequisites

- Docker and Docker Compose
- Git
- (Optional) Ansible for automation

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd devops-final
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Build and run the application**
   ```bash
   docker-compose up --build
   ```

4. **Access the services**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - Grafana: http://localhost:3001 (admin/admin)
   - Prometheus: http://localhost:9090

## Security Implementation

### Container Security Scanning
- **Tool**: Trivy
- **Scan Command**: `trivy image <image-name>`
- **Integration**: Automated scanning in CI/CD pipeline
- **Reports**: Stored in `security-reports/` directory

### Secrets Management
- **Method**: Docker secrets and .env files
- **Sensitive Data**: Database credentials, API keys
- **Security**: No hardcoded secrets in code

## Monitoring Implementation

### Prometheus Configuration
- **Targets**: Frontend, Backend, Database
- **Metrics**: CPU, Memory, HTTP requests, Custom application metrics
- **Scrape Interval**: 15 seconds

### Grafana Dashboards
- **System Overview**: CPU, Memory, Disk usage
- **Application Metrics**: Request rate, Response times, Error rates
- **Custom Dashboards**: Application-specific monitoring

## Incident Simulation and Post-Mortem

### Simulated Incident
- **Scenario**: Backend service failure
- **Detection**: Prometheus alerts and Grafana dashboards
- **Response**: Automated restart via Docker Compose
- **Resolution**: Service recovery and monitoring

### Post-Mortem Report
- **Location**: `docs/post-mortem.md`
- **Contents**: Incident timeline, root cause analysis, lessons learned

## Automation

### Ansible Playbooks
- **Deployment**: Automated application deployment
- **Configuration**: Environment setup and configuration
- **Monitoring**: Prometheus and Grafana setup

### Usage
```bash
# Deploy the application
ansible-playbook playbooks/deploy.yml

# Configure monitoring
ansible-playbook playbooks/monitoring.yml
```

## Development Workflow

1. **Local Development**
   ```bash
   docker-compose up -d
   ```

2. **Testing**
   ```bash
   docker-compose exec backend npm test
   docker-compose exec frontend npm test
   ```

3. **Security Scanning**
   ```bash
   ./scripts/security-scan.sh
   ```

4. **Deployment**
   ```bash
   ansible-playbook playbooks/deploy.yml
   ```

## File Structure

```
devops-final/
├── frontend/                 # React frontend application
├── backend/                  # Node.js backend API
├── monitoring/              # Prometheus and Grafana configs
├── ansible/                 # Ansible playbooks and roles
├── scripts/                 # Utility scripts
├── docs/                    # Documentation
├── security-reports/        # Security scan reports
├── docker-compose.yml       # Main orchestration file
├── .env.example            # Environment variables template
└── README.md               # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and security scans
5. Submit a pull request

## License

This project is licensed under the MIT License.