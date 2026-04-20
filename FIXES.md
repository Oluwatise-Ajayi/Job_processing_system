# FIXES.md

## `api/.env`
- **Line(s)**: 1-2
- **Issue**: Hardcoded secrets were committed to the repository. The `.env` file contained `REDIS_PASSWORD=supersecretpassword123`.
- **Fix**: Removed the entire history of `api/.env` from git tracking and renamed it to `.env.example` at the root directory with placeholder values, ensuring secrets are not leaked.

## `api/main.py`
- **Line(s)**: 8
- **Issue**: The Redis connection hardcoded `host="localhost"` and `port=6379` without password support or environment configuration. This prevents connecting to a separate Redis container in a Dockerized environment.
- **Fix**: Updated to fetch `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` from environment variables, defaulting to localhost if not found. Passed these to `redis.Redis()`.

- **Line(s)**: 9
- **Issue**: The API lacked a health check endpoint, preventing a container orchestrator or Docker Compose from accurately assessing service health.
- **Fix**: Added a `GET /health` endpoint returning `{"status": "healthy"}`.

## `worker/worker.py`
- **Line(s)**: 6
- **Issue**: Similar to the API, the Redis connection hardcoded `host="localhost"` and `port=6379` without password support.
- **Fix**: Modified to pull `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` from `os.environ`.

- **Line(s)**: 14-18
- **Issue**: Missing graceful shutdown handling for the worker process. The imported `signal` module was completely unused. If the container shuts down, processing could crash abruptly.
- **Fix**: Introduced a `running` boolean flag and registered `signal.SIGINT` and `signal.SIGTERM` handlers to cleanly break out of the `while` loop, and added a `try...except` block to prevent unhandled exceptions during job processing from crashing the service.

## `frontend/app.js`
- **Line(s)**: 6
- **Issue**: The backend API URL was hardcoded to `http://localhost:8000`, making it impossible to connect to the internal API endpoint in a containerized environment (e.g., `http://api:8000`).
- **Fix**: Updated to use `process.env.API_URL || "http://localhost:8000"`.

- **Line(s)**: 11
- **Issue**: Lacked a health check endpoint for robust container health checks.
- **Fix**: Added a `GET /health` route returning a 200 OK standard JSON response.

- **Line(s)**: 29
- **Issue**: Hardcoded listening on port `3000`.
- **Fix**: Modified to utilize `process.env.PORT || 3000`.
