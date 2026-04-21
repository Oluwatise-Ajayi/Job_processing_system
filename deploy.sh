#!/bin/bash
set -e

# Load env variables
set -a
# shellcheck disable=SC1091
. ./.env
set +a

# Ensure Redis is up first (this also lets Compose create/own the network)
echo "Ensuring Redis is running..."
docker compose up -d redis
docker compose wait redis 2>/dev/null || sleep 5

SERVICES=("api" "worker" "frontend")

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "=== Rolling update: $SERVICE ==="
  echo "Building $SERVICE..."
  docker compose build "$SERVICE"

  IMAGE_NAME="job_processing_system-${SERVICE}:latest"
  echo "Image: $IMAGE_NAME"

  echo "Starting validation container for $SERVICE..."
  if [ "$SERVICE" == "api" ] || [ "$SERVICE" == "worker" ]; then
    TEMP_ID=$(docker run -d --network job_internal \
      -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD="$REDIS_PASSWORD" \
      "$IMAGE_NAME")
  else
    TEMP_ID=$(docker run -d --network job_internal \
      -e API_URL=http://api:8000 -e PORT=3000 \
      "$IMAGE_NAME")
  fi

  echo "Waiting up to 60s for health check of $SERVICE..."
  HEALTHY=false
  for i in $(seq 1 30); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$TEMP_ID" 2>/dev/null || echo "starting")
    echo "  Attempt $i: $STATUS"
    if [ "$STATUS" == "healthy" ]; then
      HEALTHY=true
      break
    fi
    sleep 2
  done

  docker rm -f "$TEMP_ID" >/dev/null 2>&1

  if [ "$HEALTHY" = true ]; then
    echo "$SERVICE is healthy. Deploying..."
    docker compose up -d --no-deps "$SERVICE"
  else
    echo "$SERVICE failed health check. Aborting rolling update. Old container remains running."
    exit 1
  fi
done

echo ""
echo "Deployment completed successfully!"
