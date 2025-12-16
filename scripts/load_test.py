#!/usr/bin/env python3
# =============================================================================
# LOAD TEST SCRIPT - load_test.py
# =============================================================================
# This script generates load on the Flask API to trigger auto-scaling
# 
# Usage:
#   python3 load_test.py http://ALB-DNS-NAME/items
#   python3 load_test.py http://ALB-DNS-NAME/items --workers 200 --requests 10000
#
# Requirements:
#   pip3 install requests
# =============================================================================

import requests
import concurrent.futures
import argparse
import time
import sys
from datetime import datetime

def make_request(url, timeout=2):
    """Make a single HTTP request"""
    try:
        response = requests.get(url, timeout=timeout)
        return response.status_code
    except requests.exceptions.Timeout:
        return "TIMEOUT"
    except requests.exceptions.ConnectionError:
        return "CONN_ERROR"
    except Exception as e:
        return f"ERROR: {str(e)}"

def run_load_test(url, num_workers=100, num_requests=5000, duration=None):
    """
    Run load test against the specified URL
    
    Args:
        url: Target URL to test
        num_workers: Number of concurrent workers (threads)
        num_requests: Total number of requests to make
        duration: If set, run for this many seconds instead of fixed requests
    """
    print("=" * 60)
    print("CAPSTONE PROJECT - LOAD TEST")
    print("=" * 60)
    print(f"Target URL:      {url}")
    print(f"Workers:         {num_workers}")
    print(f"Total Requests:  {num_requests}")
    print(f"Start Time:      {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    print("\nStarting load test... (Press Ctrl+C to stop)\n")
    
    results = {
        200: 0,
        "TIMEOUT": 0,
        "CONN_ERROR": 0,
        "OTHER": 0
    }
    
    start_time = time.time()
    completed = 0
    
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
            # Submit all requests
            futures = [executor.submit(make_request, url) for _ in range(num_requests)]
            
            # Process results as they complete
            for future in concurrent.futures.as_completed(futures):
                status = future.result()
                completed += 1
                
                if status == 200:
                    results[200] += 1
                elif status == "TIMEOUT":
                    results["TIMEOUT"] += 1
                elif status == "CONN_ERROR":
                    results["CONN_ERROR"] += 1
                else:
                    results["OTHER"] += 1
                
                # Progress update every 500 requests
                if completed % 500 == 0:
                    elapsed = time.time() - start_time
                    rps = completed / elapsed if elapsed > 0 else 0
                    print(f"Progress: {completed}/{num_requests} requests "
                          f"({rps:.1f} req/sec) - "
                          f"Success: {results[200]}, "
                          f"Timeouts: {results['TIMEOUT']}, "
                          f"Errors: {results['CONN_ERROR']}")
                          
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
    
    # Final results
    end_time = time.time()
    duration = end_time - start_time
    
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(f"Duration:        {duration:.2f} seconds")
    print(f"Total Requests:  {completed}")
    print(f"Requests/sec:    {completed/duration:.2f}")
    print(f"")
    print(f"Status Codes:")
    print(f"  ✅ 200 OK:      {results[200]} ({100*results[200]/completed:.1f}%)")
    print(f"  ⏱️  Timeouts:    {results['TIMEOUT']} ({100*results['TIMEOUT']/completed:.1f}%)")
    print(f"  ❌ Conn Errors: {results['CONN_ERROR']} ({100*results['CONN_ERROR']/completed:.1f}%)")
    print(f"  ⚠️  Other:       {results['OTHER']} ({100*results['OTHER']/completed:.1f}%)")
    print("=" * 60)
    print("\n📊 Check AWS Console for Auto-Scaling activity:")
    print("   EC2 → Auto Scaling Groups → capstone-app-asg → Activity")
    print("   CloudWatch → Alarms → capstone-high-cpu")
    print("")

def main():
    parser = argparse.ArgumentParser(
        description='Load test script for Capstone Project',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s http://my-alb-123.us-east-1.elb.amazonaws.com/items
  %(prog)s http://my-alb-123.us-east-1.elb.amazonaws.com/items -w 200 -n 10000
        """
    )
    parser.add_argument('url', help='Target URL (e.g., http://ALB-DNS/items)')
    parser.add_argument('-w', '--workers', type=int, default=100,
                        help='Number of concurrent workers (default: 100)')
    parser.add_argument('-n', '--requests', type=int, default=5000,
                        help='Total number of requests (default: 5000)')
    
    args = parser.parse_args()
    
    # Validate URL
    if not args.url.startswith('http'):
        print("Error: URL must start with http:// or https://")
        sys.exit(1)
    
    run_load_test(args.url, args.workers, args.requests)

if __name__ == '__main__':
    main()
