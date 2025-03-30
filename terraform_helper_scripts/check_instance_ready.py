import requests
import time
import sys

instance_ip = sys.argv[1]
timeout = 600  # 10 minutes in seconds
start_time = time.time()

while True:
    try:
        response = requests.head(f"http://{instance_ip}:8080")
        if response.status_code in [200, 401]:
            print(f"Instance at {instance_ip} is ready.")
            break
    except Exception as e:
        print(f"Waiting for instance at {instance_ip} to be ready... Error: {e}")
    
    if time.time() - start_time > timeout:
        print(f"Error: Instance at {instance_ip} did not become ready within 10 minutes.")
        sys.exit(1)
    
    time.sleep(30)