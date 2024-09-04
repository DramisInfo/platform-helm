#!/bin/bash

NAMESPACE="argocd"
TIMEOUT=120  # 2 minutes in seconds
INTERVAL=5  # Check every 5 seconds
ELAPSED=0
declare -A PREV_STATUS

echo "Waiting for all applications to become healthy..."
while [ $ELAPSED -lt $TIMEOUT ]; do
  CURRENT_STATUS=$(kubectl -n $NAMESPACE get applications -o jsonpath="{range .items[*]}{.metadata.name}{': '}{.status.health.status}{'\n'}{end}")
  
  while IFS= read -r line; do
    APP_NAME=$(echo "$line" | awk -F': ' '{print $1}')
    APP_STATUS=$(echo "$line" | awk -F': ' '{print $2}')
    
    if [ "${PREV_STATUS[$APP_NAME]}" != "$APP_STATUS" ]; then
      echo "Application $APP_NAME status changed: ${PREV_STATUS[$APP_NAME]} -> $APP_STATUS"
      PREV_STATUS[$APP_NAME]=$APP_STATUS
    fi
  done <<< "$CURRENT_STATUS"
  
  UNHEALTHY_APPS=$(echo "$CURRENT_STATUS" | grep -v "Healthy")
  
  if [ -z "$UNHEALTHY_APPS" ]; then
    echo "All applications are healthy."
    exit 0
  fi
  
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "Timeout reached. Some applications are still not healthy."
exit 1