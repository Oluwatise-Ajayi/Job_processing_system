# Job Processing System

This is a multi-tier job processing system consisting of a Node.js Frontend, Python/FastAPI Backend, a Python background worker, and a Redis message broker.

## Prerequisites
- **Docker**: Must be installed and running.
- **Docker Compose**: Must be installed (V2 standard).
- **Git**: To clone the repository.

## Commands to bring the stack up

1. **Clone the repository:**
   ```bash
   git clone https://github.com/chukwukelu2023/hng14-stage2-devops.git
   cd hng14-stage2-devops
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   *(Optional)* Edit the `.env` file to customize passwords and ports.

3. **Start the application:**
   ```bash
   docker compose up -d --build
   ```

## What a successful startup looks like

Once the setup is complete, you should see output similar to this when checking `docker compose ps`:

```
NAME                             IMAGE                            COMMAND                  SERVICE    CREATED          STATUS                    PORTS
job_processing_system-api-1      job_processing_system-api        "uvicorn main:app --…"   api        10 seconds ago   Up 8 seconds (healthy)    0.0.0.0:8000->8000/tcp
job_processing_system-frontend-1 job_processing_system-frontend   "docker-entrypoint.s…"   frontend   10 seconds ago   Up 7 seconds (healthy)    0.0.0.0:3000->3000/tcp
job_processing_system-redis-1    redis:7-alpine                   "docker-entrypoint.s…"   redis      12 seconds ago   Up 11 seconds (healthy)   6379/tcp
job_processing_system-worker-1   job_processing_system-worker     "python -u worker.py"    worker     10 seconds ago   Up 8 seconds (healthy)
```

- All services must show an `Up` status, and eventually show `(healthy)`.
- You can navigate to `http://localhost:3000` in your web browser. You will see the Job Processor Dashboard.
- When clicking "Submit New Job", your job ID will appear under the status list and process within a few seconds to transition from "queued" to a "completed" state.
