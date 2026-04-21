# Job Processing System

A distributed job processing system with three services: a **Node.js frontend**, a **Python/FastAPI backend API**, a **Python background worker**, and **Redis** as the message broker.

## Architecture

```
Browser → Frontend (Node.js :3000) → API (FastAPI :8000) → Redis ← Worker (Python)
```

Users submit jobs via the frontend dashboard. The API enqueues them in Redis. The worker picks them up, processes them, and marks them as completed.

## Prerequisites

- **Docker** (v20.10+ recommended) — must be installed and running
- **Docker Compose** (V2, included with Docker Desktop)
- **Git**

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Oluwatise-Ajayi/Job_processing_system.git
   cd Job_processing_system
   ```

2. **Create your environment file:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to set a strong `REDIS_PASSWORD`. All other defaults work out of the box.

3. **Build and start all services:**
   ```bash
   docker compose up -d --build
   ```

4. **Wait for health checks to pass:**
   ```bash
   docker compose ps
   ```

## What a Successful Startup Looks Like

All four containers should show `Up` and `(healthy)`:

```
NAME                             SERVICE    STATUS                    PORTS
job_processing_system-redis-1    redis      Up 12 seconds (healthy)
job_processing_system-api-1      api        Up 10 seconds (healthy)   0.0.0.0:8000->8000/tcp
job_processing_system-worker-1   worker     Up 10 seconds (healthy)
job_processing_system-frontend-1 frontend   Up 8 seconds (healthy)    0.0.0.0:3000->3000/tcp
```

- **Redis** has no host port exposed (internal only) — this is by design.
- Navigate to **http://localhost:3000** to use the Job Processor Dashboard.
- Click **"Submit New Job"** — the job will appear as `queued`, then transition to `completed` within a few seconds.

## Stopping the Stack

```bash
docker compose down -v
```

## Project Structure

```
├── api/                   # FastAPI backend
│   ├── Dockerfile
│   ├── main.py
│   ├── test_main.py       # Pytest unit tests (Redis mocked)
│   └── requirements.txt
├── worker/                # Background job processor
│   ├── Dockerfile
│   ├── worker.py
│   └── requirements.txt
├── frontend/              # Express.js frontend
│   ├── Dockerfile
│   ├── app.js
│   ├── package.json
│   └── views/index.html
├── .github/workflows/     # CI/CD pipeline
│   └── main.yml
├── docker-compose.yml
├── deploy.sh              # Rolling update deployment script
├── .env.example           # Template for environment variables
├── FIXES.md               # All bugs found and fixed
└── README.md
```

## Environment Variables

All configuration is handled via `.env`. See `.env.example` for the full list:

| Variable | Purpose | Default |
| --- | --- | --- |
| `REDIS_HOST` | Redis hostname | `redis` |
| `REDIS_PORT` | Redis port | `6379` |
| `REDIS_PASSWORD` | Redis authentication password | (must set) |
| `API_URL` | Internal URL for the API | `http://api:8000` |
| `API_HOST_PORT` | Host port for the API | `8000` |
| `API_CONTAINER_PORT` | Container port for the API | `8000` |
| `FRONTEND_HOST_PORT` | Host port for the frontend | `3000` |
| `FRONTEND_CONTAINER_PORT` | Container port for the frontend | `3000` |

## CI/CD Pipeline

The GitHub Actions pipeline runs in strict order: **lint → test → build → security scan → integration test → deploy**. A failure at any stage blocks all subsequent stages. See `.github/workflows/main.yml` for full details.
