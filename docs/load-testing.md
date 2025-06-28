# Load Testing Documentation

## Overview

This document describes the load testing capabilities implemented for the DevOps pipeline application. Load testing helps ensure the application can handle expected traffic loads and identifies performance bottlenecks.

## Load Testing Tools

### 1. Bash Script (`load-testing.sh`)

- **Purpose**: Basic load testing using curl
- **Features**:
  - Sequential and concurrent request testing
  - System resource monitoring
  - Multiple endpoint testing
  - Detailed reporting
- **Usage**: `./scripts/load-testing.sh`

### 2. Python Script (`load-testing.py`)

- **Purpose**: Advanced async load testing
- **Features**:
  - Asynchronous request handling
  - Statistical analysis
  - JSON and text reporting
  - Configurable parameters
- **Usage**: `python3 scripts/load-testing.py --url http://localhost:5000 --users 10 --requests 50`

### 3. Node.js Script (`load-test.js`)

- **Purpose**: JavaScript-based load testing
- **Features**:
  - Promise-based concurrent testing
  - Detailed performance metrics
  - Markdown report generation
  - NPM script integration
- **Usage**: `node scripts/load-test.js --users 20 --requests 100`

### 4. Docker Load Testing

- **Purpose**: Containerized load testing
- **Features**:
  - Isolated testing environment
  - Automated test execution
  - Volume-mounted reports
- **Usage**: `docker-compose -f docker-compose.yml -f docker-compose.loadtest.yml up load-tester`

## Test Scenarios

### Basic Health Check Test

- **Target**: Backend health endpoint
- **Users**: 10 concurrent
- **Requests**: 50 per user
- **Expected**: 100% success rate, < 100ms response time

### API Endpoint Test

- **Targets**: `/health`, `/api/users`, `/metrics`
- **Users**: 15 concurrent
- **Requests**: 30 per endpoint
- **Expected**: 95%+ success rate, < 500ms response time

### Frontend Load Test

- **Target**: Frontend application
- **Users**: 20 concurrent
- **Requests**: 25 per user
- **Expected**: 90%+ success rate, < 1s response time

### Stress Test

- **Target**: All endpoints
- **Users**: 50 concurrent
- **Requests**: 100 per user
- **Purpose**: Identify breaking points

## Performance Baselines

### Response Time Targets

- **Excellent**: < 100ms
- **Good**: 100-500ms
- **Acceptable**: 500ms-1s
- **Poor**: > 1s

### Success Rate Targets

- **Excellent**: 99%+
- **Good**: 95-99%
- **Acceptable**: 90-95%
- **Poor**: < 90%

### Throughput Targets

- **Minimum**: 100 requests/second
- **Target**: 500 requests/second
- **Optimal**: 1000+ requests/second

## Running Load Tests

### Prerequisites

```bash
# Ensure application is running
docker-compose up -d

# Wait for services to be ready
sleep 30

# Check service health
curl http://localhost:5000/health
curl http://localhost:3000
```

### Quick Test (Bash)

```bash
# Basic load test
./scripts/load-testing.sh

# Custom configuration
CONCURRENT_USERS=20 REQUESTS_PER_USER=50 ./scripts/load-testing.sh
```

### Advanced Test (Python)

```bash
# Install dependencies
pip3 install aiohttp

# Run basic test
python3 scripts/load-testing.py

# Custom test
python3 scripts/load-testing.py \
  --url http://localhost:5000 \
  --users 25 \
  --requests 80 \
  --endpoints /health /api/users /metrics
```

### JavaScript Test (Node.js)

```bash
# Install dependencies
cd scripts && npm install

# Run basic test
npm run load-test

# Quick test
npm run load-test-quick

# Stress test
npm run load-test-stress

# Custom test
node load-test.js --users 30 --requests 60 --url http://localhost:5000
```

### Docker Load Test

```bash
# Run containerized load test
docker-compose -f docker-compose.yml -f docker-compose.loadtest.yml up load-tester

# View reports
ls -la load-test-reports/
```

## Report Analysis

### Report Types Generated

1. **Summary Reports** (`.txt`, `.md`): Human-readable summaries
2. **Detailed Reports** (`.json`): Complete test data for analysis
3. **System Resource Logs** (`.log`): Resource utilization during tests

### Key Metrics to Monitor

- **Success Rate**: Percentage of successful requests
- **Response Times**: Average, median, min, max
- **Throughput**: Requests per second
- **Error Distribution**: Types and frequencies of errors
- **Resource Usage**: CPU, memory during load

### Sample Report Structure

```
Load Test Summary Report
========================
Generated: 2024-12-28T10:30:00Z
Target URL: http://localhost:5000

Test Configuration:
- Concurrent Users: 20
- Requests per User: 50
- Total Requests: 1000

Results:
- Successful Requests: 985
- Failed Requests: 15
- Success Rate: 98.50%
- Average Response Time: 0.245s
- Requests per Second: 157.3
```

## Performance Optimization

### Based on Load Test Results

#### If Success Rate < 95%

- Check error logs for failure patterns
- Increase connection pool sizes
- Optimize database queries
- Add request timeout handling
- Implement circuit breakers

#### If Response Time > 500ms

- Enable response caching
- Optimize API endpoints
- Add database indexing
- Implement connection pooling
- Consider CDN for static assets

#### If Throughput < Target

- Scale horizontally (add instances)
- Optimize resource allocation
- Implement load balancing
- Cache frequently accessed data
- Optimize database connections

## Continuous Load Testing

### Integration with CI/CD

```yaml
# Add to GitHub Actions workflow
- name: Performance Testing
  run: |
    docker-compose up -d
    sleep 30
    python3 scripts/load-testing.py --users 10 --requests 25
    docker-compose down
```

### Monitoring Integration

- Set up alerts for performance degradation
- Track performance trends over time
- Establish performance budgets
- Automate test execution on deployments

## Troubleshooting

### Common Issues

#### "Connection Refused" Errors

- Ensure services are running: `docker-compose ps`
- Check service health: `curl http://localhost:5000/health`
- Wait longer for services to start

#### High Failure Rates

- Check service logs: `docker-compose logs backend`
- Verify resource limits: `docker stats`
- Reduce concurrent users temporarily

#### Slow Response Times

- Monitor system resources: `top`, `htop`
- Check database performance
- Verify network connectivity

### Debug Commands

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs backend frontend

# Monitor resources
docker stats

# Check network connectivity
curl -I http://localhost:5000/health
curl -I http://localhost:3000

# Test individual endpoints
curl -w "@curl-format.txt" -s -o /dev/null http://localhost:5000/health
```

## Best Practices

### Load Testing Guidelines

1. **Test in Production-like Environment**: Use similar hardware and network conditions
2. **Establish Baselines**: Record initial performance metrics
3. **Test Regularly**: Include in CI/CD pipeline
4. **Monitor Resources**: Track CPU, memory, network during tests
5. **Gradual Load Increase**: Start small and increase load progressively
6. **Test Different Scenarios**: Various user patterns and endpoints
7. **Document Results**: Keep historical performance data
8. **Fix Issues Promptly**: Address performance problems immediately

### Load Test Design

- **Realistic User Behavior**: Simulate actual usage patterns
- **Mixed Workloads**: Test different types of requests
- **Think Time**: Add delays between requests
- **Data Variation**: Use different test data sets
- **Error Handling**: Test failure scenarios
- **Peak Load**: Test expected maximum load

## Future Enhancements

### Potential Improvements

- **JMeter Integration**: Add Apache JMeter for advanced testing
- **Load Test Automation**: Scheduled performance testing
- **Performance Dashboards**: Real-time performance monitoring
- **A/B Testing**: Performance comparison between versions
- **Geographic Testing**: Multi-region load testing
- **Mobile App Testing**: Specific mobile performance testing
