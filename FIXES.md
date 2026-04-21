# FIXES.md — All Bugs Found and Fixed

This document lists every bug, misconfiguration, and missing production requirement found in the starter repository, along with the file, line number, what the problem was, and what was changed to fix it.

---

## 1. `api/.env` — Hardcoded secrets committed to version control

- **File**: `api/.env`
- **Line(s)**: 1–2
- **Problem**: The file contained `REDIS_PASSWORD=supersecretpassword123` and `APP_ENV=production` — real credentials committed directly to the repository. This is a critical security violation; secrets must never appear in git history.
- **Fix**: Removed `api/.env` from git tracking (via `git rm --cached`), added `api/.env` to `.gitignore`, and created a root-level `.env.example` with placeholder values instead. The git history was amended to ensure the secret was never present in any reachable commit.

---

## 2. `api/main.py` line 8 — Hardcoded Redis host and port

- **File**: `api/main.py`
- **Line**: 8
- **Problem**: `r = redis.Redis(host="localhost", port=6379)` — Redis connection was hardcoded to `localhost` with no password support. Inside a Docker container, the API cannot reach Redis at `localhost`; it needs the container service name (e.g. `redis`). The password was also not passed, so authentication would fail.
- **Fix**: Changed to read `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` from environment variables via `os.environ.get()`, with sensible defaults for local development.

---

## 3. `api/main.py` — Missing health check endpoint

- **File**: `api/main.py`
- **Line**: (added after line 11)
- **Problem**: No `/health` endpoint existed. Docker HEALTHCHECK, Compose `service_healthy` conditions, and load balancers all require a health endpoint to determine service readiness.
- **Fix**: Added `GET /health` returning `{"status": "healthy"}`.

---

## 4. `api/requirements.txt` — Unpinned dependency versions

- **File**: `api/requirements.txt`
- **Line(s)**: 1–3
- **Problem**: Dependencies were listed as `fastapi`, `uvicorn`, `redis` without version pinning. This causes non-reproducible builds — a new release could break the application at any time, and Trivy flags unpinned packages as vulnerable when older versions are pulled.
- **Fix**: Pinned to `fastapi==0.136.0`, `uvicorn==0.44.0`, `redis==7.4.0`.

---

## 5. `worker/worker.py` line 6 — Hardcoded Redis host and port

- **File**: `worker/worker.py`
- **Line**: 6
- **Problem**: Same as the API — `r = redis.Redis(host="localhost", port=6379)` with no password. The worker would fail to connect to Redis inside Docker.
- **Fix**: Changed to read `REDIS_HOST`, `REDIS_PORT`, and `REDIS_PASSWORD` from environment variables.

---

## 6. `worker/worker.py` lines 4, 14–18 — Imported but unused `signal` module, no graceful shutdown

- **File**: `worker/worker.py`
- **Lines**: 4 (import), 14–18 (main loop)
- **Problem**: The `signal` module was imported but never used. The `while True:` loop had no way to terminate gracefully — when Docker sends SIGTERM to stop the container, the worker would be forcibly killed mid-job. There was also no error handling around job processing, so any Redis connection error would crash the entire process.
- **Fix**: Added a `running` boolean flag, registered `signal.SIGINT` and `signal.SIGTERM` handlers to set `running = False`, changed `while True` to `while running`, and wrapped the job processing in a `try...except` block.

---

## 7. `worker/requirements.txt` — Unpinned dependency version

- **File**: `worker/requirements.txt`
- **Line**: 1
- **Problem**: `redis` was listed without a version pin.
- **Fix**: Pinned to `redis==7.4.0`.

---

## 8. `frontend/app.js` line 6 — Hardcoded API URL

- **File**: `frontend/app.js`
- **Line**: 6
- **Problem**: `const API_URL = "http://localhost:8000"` — hardcoded to `localhost`. Inside a Docker network, the frontend container must reach the API by its service name (`http://api:8000`), not `localhost`.
- **Fix**: Changed to `process.env.API_URL || "http://localhost:8000"`.

---

## 9. `frontend/app.js` — Missing health check endpoint

- **File**: `frontend/app.js`
- **Line**: (added after line 9)
- **Problem**: No `/health` endpoint existed. The Docker HEALTHCHECK instruction needs an endpoint to probe.
- **Fix**: Added `GET /health` returning `{ status: 'healthy' }` with a 200 status code.

---

## 10. `frontend/app.js` line 29 — Hardcoded port

- **File**: `frontend/app.js`
- **Line**: 29
- **Problem**: `app.listen(3000, ...)` — the port was hardcoded. This prevents configuration via environment variables.
- **Fix**: Changed to `const PORT = process.env.PORT || 3000; app.listen(PORT, ...)`.

---

## 11. `frontend/package.json` — Outdated dependencies with known vulnerabilities

- **File**: `frontend/package.json`
- **Lines**: 9–10
- **Problem**: `express` was pinned to `^4.18.2` and `axios` to `^1.4.0`. These older versions and their transitive dependencies (e.g., `picomatch`, `brace-expansion`) have known CVEs flagged by Trivy.
- **Fix**: Updated to `express: ^4.21.2`, `axios: ^1.7.9`. Added `overrides` for `picomatch: ^4.0.2` and `brace-expansion: ^2.0.1` to force patched transitive dependencies.

---

## 12. `docker-compose.yml` line 1 — Obsolete `version` attribute

- **File**: `docker-compose.yml`
- **Line**: 1
- **Problem**: `version: '3.8'` is obsolete in modern Docker Compose V2 and produces a warning on every command.
- **Fix**: Removed the `version` key entirely.

---

## 13. Python files — PEP 8 formatting violations (flake8 errors)

- **Files**: `api/main.py`, `worker/worker.py`, `api/test_main.py`
- **Lines**: Multiple
- **Problem**: Missing blank lines between top-level definitions (E302, E305), unused imports (F401 for `main.r` in test file), missing newline at end of file (W292). These cause `flake8` to fail in CI.
- **Fix**: Added the required 2 blank lines between all functions and module-level code blocks, removed the unused `r` import from the test file, and ensured all files end with a newline.
