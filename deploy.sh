#!/bin/bash
set -e

# Load env variables
export $(cat .env | xargs)

# Create network if not exists
docker network inspect job_internal >/dev/null 2>&1 || docker network create job_internal

SERVICES=("api" "worker" "frontend")

for SERVICE in "${SERVICES[@]}"; do
  echo "Building $SERVICE..."
  docker compose build $SERVICE
  IMAGE_NAME=$(docker compose config | grep -A 5 " $SERVICE:" | grep "image" | awk '{print $2}' || echo "job_processing_system-$SERVICE")
  
  if [ "$IMAGE_NAME" == "job_processing_system-$SERVICE" ]; then
    # Default compose name if not explicitly set
    IMAGE_NAME="job_processing_system-$SERVICE:latest"
  fi

  echo "Starting validation container for $SERVICE..."
  if [ "$SERVICE" == "api" ] || [ "$SERVICE" == "worker" ]; then
    TEMP_ID=$(docker run -d --network job_internal \
      -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_PASSWORD=$REDIS_PASSWORD \
      $IMAGE_NAME)
  else
    TEMP_ID=$(docker run -d --network job_internal \
      -e API_URL=http://api:8000 -e PORT=3000 \
      $IMAGE_NAME)
  fi

  echo "Waiting up to 60s for health check of $SERVICE..."
  HEALTHY=false
  for i in {1..30}; do
    STATUS=$(docker inspect --format='{{json .State.Health.Status}}' $TEMP_ID)
    if [ "$STATUS" == "\"healthy\"" ]; then
      HEALTHY=true
      break
    fi
    sleep 2
  done

  docker rm -f $TEMP_ID >/dev/null

  if [ "$HEALTHY" = true ]; then
    echo "$SERVICE is healthy. Deploying..."
    docker compose up -d $SERVICE
  else
    echo "$SERVICE failed health check. Aborting rolling update. Old container remains running."
    exit 1
  fi
done

echo "Deployment completed successfully!"
