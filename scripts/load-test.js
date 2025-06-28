#!/usr/bin/env node

/**
 * Simple Load Testing Tool for DevOps Pipeline Application
 * This tool performs basic load testing using Node.js and axios
 */

const axios = require('axios');
const { program } = require('commander');
const fs = require('fs');
const path = require('path');

class LoadTester {
    constructor(options) {
        this.baseUrl = options.url.replace(/\/$/, '');
        this.concurrentUsers = options.users;
        this.requestsPerUser = options.requests;
        this.endpoints = options.endpoints;
        this.results = [];
        this.reportDir = './load-test-reports';
        
        // Create report directory
        if (!fs.existsSync(this.reportDir)) {
            fs.mkdirSync(this.reportDir, { recursive: true });
        }
    }
    
    log(message, level = 'INFO') {
        const timestamp = new Date().toISOString();
        console.log(`[${timestamp}] ${level}: ${message}`);
    }
    
    async makeRequest(url, timeout = 10000) {
        const startTime = Date.now();
        
        try {
            const response = await axios.get(url, { 
                timeout,
                validateStatus: () => true // Don't throw on HTTP error codes
            });
            
            const endTime = Date.now();
            const responseTime = (endTime - startTime) / 1000;
            
            return {
                url,
                status: response.status,
                responseTime,
                success: response.status === 200,
                timestamp: startTime,
                size: JSON.stringify(response.data).length
            };
        } catch (error) {
            const endTime = Date.now();
            const responseTime = (endTime - startTime) / 1000;
            
            return {
                url,
                status: 0,
                responseTime,
                success: false,
                error: error.message,
                timestamp: startTime,
                size: 0
            };
        }
    }
    
    async userSimulation(userId) {
        const userResults = [];
        
        this.log(`Starting user ${userId + 1}/${this.concurrentUsers}`);
        
        for (let i = 0; i < this.requestsPerUser; i++) {
            // Rotate through endpoints
            const endpoint = this.endpoints[i % this.endpoints.length];
            const url = `${this.baseUrl}${endpoint}`;
            
            const result = await this.makeRequest(url);
            result.userId = userId;
            result.requestNum = i;
            userResults.push(result);
            
            // Small delay between requests
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        this.log(`User ${userId + 1} completed ${this.requestsPerUser} requests`);
        return userResults;
    }
    
    async runLoadTest() {
        this.log(`🚀 Starting load test with ${this.concurrentUsers} concurrent users`);
        this.log(`📊 Each user will make ${this.requestsPerUser} requests`);
        this.log(`🎯 Target endpoints: ${this.endpoints.join(', ')}`);
        
        const startTime = Date.now();
        
        // Create promises for all users
        const userPromises = [];
        for (let i = 0; i < this.concurrentUsers; i++) {
            userPromises.push(this.userSimulation(i));
        }
        
        // Wait for all users to complete
        const userResults = await Promise.all(userPromises);
        
        // Flatten results
        userResults.forEach(results => {
            this.results.push(...results);
        });
        
        const endTime = Date.now();
        const duration = (endTime - startTime) / 1000;
        
        this.log(`✅ Load test completed in ${duration.toFixed(2)} seconds`);
        return this.results;
    }
    
    analyzeResults() {
        if (this.results.length === 0) {
            this.log('❌ No results to analyze', 'ERROR');
            return null;
        }
        
        const totalRequests = this.results.length;
        const successfulRequests = this.results.filter(r => r.success).length;
        const failedRequests = totalRequests - successfulRequests;
        
        const responseTimes = this.results
            .filter(r => r.success)
            .map(r => r.responseTime);
        
        const avgResponseTime = responseTimes.length > 0 
            ? responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length 
            : 0;
        
        const minResponseTime = responseTimes.length > 0 ? Math.min(...responseTimes) : 0;
        const maxResponseTime = responseTimes.length > 0 ? Math.max(...responseTimes) : 0;
        
        // Calculate median
        const sortedTimes = [...responseTimes].sort((a, b) => a - b);
        const medianResponseTime = sortedTimes.length > 0
            ? sortedTimes.length % 2 === 0
                ? (sortedTimes[sortedTimes.length / 2 - 1] + sortedTimes[sortedTimes.length / 2]) / 2
                : sortedTimes[Math.floor(sortedTimes.length / 2)]
            : 0;
        
        const requestsPerSecond = totalRequests / (this.results[this.results.length - 1].timestamp - this.results[0].timestamp) * 1000;
        
        return {
            totalRequests,
            successfulRequests,
            failedRequests,
            successRate: (successfulRequests / totalRequests) * 100,
            avgResponseTime,
            minResponseTime,
            maxResponseTime,
            medianResponseTime,
            requestsPerSecond,
            concurrentUsers: this.concurrentUsers,
            requestsPerUser: this.requestsPerUser
        };
    }
    
    generateReport(analysis) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        
        // Console output
        console.log('\n' + '='.repeat(60));
        console.log('🎯 LOAD TEST RESULTS');
        console.log('='.repeat(60));
        console.log(`📊 Total Requests: ${analysis.totalRequests}`);
        console.log(`✅ Successful Requests: ${analysis.successfulRequests}`);
        console.log(`❌ Failed Requests: ${analysis.failedRequests}`);
        console.log(`📈 Success Rate: ${analysis.successRate.toFixed(2)}%`);
        console.log(`⏱️  Average Response Time: ${analysis.avgResponseTime.toFixed(3)}s`);
        console.log(`⚡ Min Response Time: ${analysis.minResponseTime.toFixed(3)}s`);
        console.log(`🐌 Max Response Time: ${analysis.maxResponseTime.toFixed(3)}s`);
        console.log(`📊 Median Response Time: ${analysis.medianResponseTime.toFixed(3)}s`);
        console.log(`🚀 Requests per Second: ${analysis.requestsPerSecond.toFixed(2)}`);
        console.log(`👥 Concurrent Users: ${analysis.concurrentUsers}`);
        console.log(`🔄 Requests per User: ${analysis.requestsPerUser}`);
        console.log('='.repeat(60));
        
        // Performance assessment
        if (analysis.successRate >= 95) {
            console.log('🎉 Performance: EXCELLENT (Success rate >= 95%)');
        } else if (analysis.successRate >= 80) {
            console.log('⚠️  Performance: GOOD (Success rate 80-95%)');
        } else {
            console.log('❌ Performance: POOR (Success rate < 80%)');
        }
        
        if (analysis.avgResponseTime <= 0.5) {
            console.log('🚀 Response Time: EXCELLENT (< 500ms)');
        } else if (analysis.avgResponseTime <= 1.0) {
            console.log('👍 Response Time: GOOD (500ms - 1s)');
        } else {
            console.log('⚠️  Response Time: SLOW (> 1s)');
        }
        
        // Save detailed JSON report
        const jsonReportPath = path.join(this.reportDir, `load_test_${timestamp}.json`);
        const jsonReport = {
            summary: analysis,
            configuration: {
                baseUrl: this.baseUrl,
                concurrentUsers: this.concurrentUsers,
                requestsPerUser: this.requestsPerUser,
                endpoints: this.endpoints
            },
            detailedResults: this.results,
            timestamp: new Date().toISOString()
        };
        
        fs.writeFileSync(jsonReportPath, JSON.stringify(jsonReport, null, 2));
        
        // Save summary report
        const summaryReportPath = path.join(this.reportDir, `load_test_summary_${timestamp}.md`);
        const summaryReport = `# Load Test Summary Report

**Generated:** ${new Date().toISOString()}
**Target URL:** ${this.baseUrl}

## Test Configuration
- **Concurrent Users:** ${analysis.concurrentUsers}
- **Requests per User:** ${analysis.requestsPerUser}
- **Total Requests:** ${analysis.totalRequests}
- **Endpoints Tested:** ${this.endpoints.join(', ')}

## Results Summary
- **Successful Requests:** ${analysis.successfulRequests}
- **Failed Requests:** ${analysis.failedRequests}
- **Success Rate:** ${analysis.successRate.toFixed(2)}%
- **Average Response Time:** ${analysis.avgResponseTime.toFixed(3)}s
- **Median Response Time:** ${analysis.medianResponseTime.toFixed(3)}s
- **Min Response Time:** ${analysis.minResponseTime.toFixed(3)}s
- **Max Response Time:** ${analysis.maxResponseTime.toFixed(3)}s
- **Requests per Second:** ${analysis.requestsPerSecond.toFixed(2)}

## Performance Assessment
${analysis.successRate >= 95 ? '🎉 **EXCELLENT**' : analysis.successRate >= 80 ? '⚠️ **GOOD**' : '❌ **POOR**'} - Success Rate: ${analysis.successRate.toFixed(2)}%

${analysis.avgResponseTime <= 0.5 ? '🚀 **EXCELLENT**' : analysis.avgResponseTime <= 1.0 ? '👍 **GOOD**' : '⚠️ **SLOW**'} - Response Time: ${analysis.avgResponseTime.toFixed(3)}s

## Recommendations
${analysis.successRate < 95 ? '- Investigate failed requests and optimize error handling\n' : ''}${analysis.avgResponseTime > 1.0 ? '- Optimize response times (currently > 1s average)\n' : ''}${analysis.successRate >= 95 && analysis.avgResponseTime <= 0.5 ? '- Performance is excellent! Consider stress testing with higher loads\n' : ''}
- Monitor system resources during peak loads
- Implement caching for frequently accessed endpoints
- Consider horizontal scaling if needed
`;

        fs.writeFileSync(summaryReportPath, summaryReport);
        
        console.log(`\n📁 Reports saved:`);
        console.log(`   📊 Detailed: ${jsonReportPath}`);
        console.log(`   📝 Summary: ${summaryReportPath}`);
        
        return { jsonReportPath, summaryReportPath };
    }
}

// CLI setup
program
    .name('load-test')
    .description('Simple load testing tool for DevOps applications')
    .version('1.0.0')
    .option('-u, --url <url>', 'Base URL to test', 'http://localhost:5000')
    .option('-c, --users <number>', 'Number of concurrent users', '10')
    .option('-r, --requests <number>', 'Number of requests per user', '50')
    .option('-e, --endpoints <endpoints...>', 'Endpoints to test', ['/health', '/api/users', '/metrics'])
    .parse();

const options = program.opts();

// Convert string numbers to integers
options.users = parseInt(options.users);
options.requests = parseInt(options.requests);

async function main() {
    const tester = new LoadTester(options);
    
    try {
        // Run the load test
        await tester.runLoadTest();
        
        // Analyze results
        const analysis = tester.analyzeResults();
        
        if (!analysis) {
            process.exit(1);
        }
        
        // Generate report
        tester.generateReport(analysis);
        
        // Exit with appropriate code based on success rate
        if (analysis.successRate >= 95) {
            process.exit(0);
        } else if (analysis.successRate >= 80) {
            console.log('\n⚠️  Warning: Success rate below 95%');
            process.exit(0);
        } else {
            console.log('\n❌ Error: Success rate below 80%');
            process.exit(1);
        }
        
    } catch (error) {
        tester.log(`Load test failed: ${error.message}`, 'ERROR');
        process.exit(1);
    }
}

// Run the load test
main();
