import redis
import time
import os
import signal

redis_host = os.environ.get("REDIS_HOST", "localhost")
redis_port = int(os.environ.get("REDIS_PORT", 6379))
redis_password = os.environ.get("REDIS_PASSWORD", None)
r = redis.Redis(host=redis_host, port=redis_port, password=redis_password)


def process_job(job_id):
    print(f"Processing job {job_id}")
    time.sleep(2)  # simulate work
    r.hset(f"job:{job_id}", "status", "completed")
    print(f"Done: {job_id}")


running = True


def handle_signal(signum, frame):
    global running
    print("Received signal, shutting down...")
    running = False


signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

while running:
    try:
        job = r.brpop("job", timeout=5)
        if job:
            _, job_id = job
            process_job(job_id.decode())
    except Exception as e:
        print(f"Error processing job: {e}")
        time.sleep(1)