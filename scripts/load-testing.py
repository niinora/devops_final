#!/usr/bin/env python3
"""
Simple Load Testing Script for DevOps Pipeline Application
This script provides basic load testing capabilities using Python requests library
"""

import asyncio
import aiohttp
import time
import json
import sys
import argparse
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import statistics
import os

class LoadTester:
    def __init__(self, base_url, concurrent_users=10, requests_per_user=50):
        self.base_url = base_url.rstrip('/')
        self.concurrent_users = concurrent_users
        self.requests_per_user = requests_per_user
        self.results = []
        self.report_dir = "./load-test-reports"
        
        # Create report directory
        os.makedirs(self.report_dir, exist_ok=True)
    
    def log(self, message, level="INFO"):
        """Simple logging function"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
    
    async def make_request(self, session, url, timeout=10):
        """Make a single HTTP request"""
        start_time = time.time()
        try:
            async with session.get(url, timeout=timeout) as response:
                end_time = time.time()
                return {
                    'url': url,
                    'status': response.status,
                    'response_time': end_time - start_time,
                    'success': response.status == 200,
                    'timestamp': start_time
                }
        except Exception as e:
            end_time = time.time()
            return {
                'url': url,
                'status': 0,
                'response_time': end_time - start_time,
                'success': False,
                'error': str(e),
                'timestamp': start_time
            }
    
    async def user_simulation(self, user_id, endpoints):
        """Simulate a single user making requests"""
        user_results = []
        
        # Create session for this user
        timeout = aiohttp.ClientTimeout(total=30)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            
            for request_num in range(self.requests_per_user):
                # Rotate through endpoints
                endpoint = endpoints[request_num % len(endpoints)]
                url = f"{self.base_url}{endpoint}"
                
                result = await self.make_request(session, url)
                result['user_id'] = user_id
                result['request_num'] = request_num
                user_results.append(result)
                
                # Small delay between requests (0.1 seconds)
                await asyncio.sleep(0.1)
        
        return user_results
    
    async def run_load_test(self, endpoints):
        """Run the load test with multiple concurrent users"""
        self.log(f"Starting load test with {self.concurrent_users} users")
        self.log(f"Each user will make {self.requests_per_user} requests")
        self.log(f"Target endpoints: {endpoints}")
        
        start_time = time.time()
        
        # Create tasks for all users
        tasks = []
        for user_id in range(self.concurrent_users):
            task = self.user_simulation(user_id, endpoints)
            tasks.append(task)
        
        # Run all users concurrently
        user_results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        
        # Flatten results
        for user_result in user_results:
            self.results.extend(user_result)
        
        self.log(f"Load test completed in {end_time - start_time:.2f} seconds")
        return self.results
    
    def analyze_results(self):
        """Analyze the test results"""
        if not self.results:
            self.log("No results to analyze", "ERROR")
            return
        
        total_requests = len(self.results)
        successful_requests = sum(1 for r in self.results if r['success'])
        failed_requests = total_requests - successful_requests
        
        response_times = [r['response_time'] for r in self.results if r['success']]
        
        analysis = {
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'failed_requests': failed_requests,
            'success_rate': (successful_requests / total_requests) * 100,
            'avg_response_time': statistics.mean(response_times) if response_times else 0,
            'min_response_time': min(response_times) if response_times else 0,
            'max_response_time': max(response_times) if response_times else 0,
            'median_response_time': statistics.median(response_times) if response_times else 0,
            'concurrent_users': self.concurrent_users,
            'requests_per_user': self.requests_per_user
        }
        
        return analysis
    
    def generate_report(self, analysis):
        """Generate detailed test report"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Console output
        print("\n" + "="*60)
        print("LOAD TEST RESULTS")
        print("="*60)
        print(f"Total Requests: {analysis['total_requests']}")
        print(f"Successful Requests: {analysis['successful_requests']}")
        print(f"Failed Requests: {analysis['failed_requests']}")
        print(f"Success Rate: {analysis['success_rate']:.2f}%")
        print(f"Average Response Time: {analysis['avg_response_time']:.3f}s")
        print(f"Min Response Time: {analysis['min_response_time']:.3f}s")
        print(f"Max Response Time: {analysis['max_response_time']:.3f}s")
        print(f"Median Response Time: {analysis['median_response_time']:.3f}s")
        print(f"Concurrent Users: {analysis['concurrent_users']}")
        print(f"Requests per User: {analysis['requests_per_user']}")
        print("="*60)
        
        # Save detailed JSON report
        json_report_path = f"{self.report_dir}/load_test_detailed_{timestamp}.json"
        with open(json_report_path, 'w') as f:
            json.dump({
                'analysis': analysis,
                'detailed_results': self.results
            }, f, indent=2)
        
        # Save summary report
        summary_report_path = f"{self.report_dir}/load_test_summary_{timestamp}.txt"
        with open(summary_report_path, 'w') as f:
            f.write("Load Test Summary Report\n")
            f.write("="*30 + "\n")
            f.write(f"Generated: {datetime.now()}\n")
            f.write(f"Target URL: {self.base_url}\n\n")
            f.write(f"Test Configuration:\n")
            f.write(f"- Concurrent Users: {analysis['concurrent_users']}\n")
            f.write(f"- Requests per User: {analysis['requests_per_user']}\n")
            f.write(f"- Total Requests: {analysis['total_requests']}\n\n")
            f.write(f"Results:\n")
            f.write(f"- Successful Requests: {analysis['successful_requests']}\n")
            f.write(f"- Failed Requests: {analysis['failed_requests']}\n")
            f.write(f"- Success Rate: {analysis['success_rate']:.2f}%\n")
            f.write(f"- Average Response Time: {analysis['avg_response_time']:.3f}s\n")
            f.write(f"- Median Response Time: {analysis['median_response_time']:.3f}s\n")
            f.write(f"- Min Response Time: {analysis['min_response_time']:.3f}s\n")
            f.write(f"- Max Response Time: {analysis['max_response_time']:.3f}s\n\n")
            
            # Response time distribution
            if self.results:
                response_times = [r['response_time'] for r in self.results if r['success']]
                if response_times:
                    f.write("Response Time Distribution:\n")
                    f.write(f"- < 100ms: {sum(1 for t in response_times if t < 0.1)} requests\n")
                    f.write(f"- 100-500ms: {sum(1 for t in response_times if 0.1 <= t < 0.5)} requests\n")
                    f.write(f"- 500ms-1s: {sum(1 for t in response_times if 0.5 <= t < 1.0)} requests\n")
                    f.write(f"- > 1s: {sum(1 for t in response_times if t >= 1.0)} requests\n")
        
        self.log(f"Detailed report saved: {json_report_path}")
        self.log(f"Summary report saved: {summary_report_path}")
        
        return summary_report_path, json_report_path

async def main():
    parser = argparse.ArgumentParser(description='Simple Load Testing Tool')
    parser.add_argument('--url', default='http://localhost:5000', 
                       help='Base URL to test (default: http://localhost:5000)')
    parser.add_argument('--users', type=int, default=10,
                       help='Number of concurrent users (default: 10)')
    parser.add_argument('--requests', type=int, default=50,
                       help='Number of requests per user (default: 50)')
    parser.add_argument('--endpoints', nargs='+', 
                       default=['/health', '/api/users', '/metrics'],
                       help='Endpoints to test (default: /health /api/users /metrics)')
    
    args = parser.parse_args()
    
    # Create load tester
    tester = LoadTester(
        base_url=args.url,
        concurrent_users=args.users,
        requests_per_user=args.requests
    )
    
    try:
        # Run the load test
        results = await tester.run_load_test(args.endpoints)
        
        # Analyze results
        analysis = tester.analyze_results()
        
        # Generate report
        tester.generate_report(analysis)
        
        # Exit with appropriate code
        success_rate = analysis['success_rate']
        if success_rate >= 95:
            tester.log("✅ Load test PASSED (Success rate >= 95%)")
            sys.exit(0)
        elif success_rate >= 80:
            tester.log("⚠️  Load test WARNING (Success rate 80-95%)")
            sys.exit(0)
        else:
            tester.log("❌ Load test FAILED (Success rate < 80%)")
            sys.exit(1)
            
    except Exception as e:
        tester.log(f"Load test failed with error: {e}", "ERROR")
        sys.exit(1)

if __name__ == "__main__":
    # Check if aiohttp is available
    try:
        import aiohttp
    except ImportError:
        print("Error: aiohttp library is required")
        print("Install with: pip install aiohttp")
        sys.exit(1)
    
    # Run the load test
    asyncio.run(main())
