#!/bin/bash

NAMESPACE="argocd"
TIMEOUT=60  # 5 minutes in seconds
INTERVAL=5  # Check every 10 seconds
ELAPSED=0
PREV_STATUS=""

echo "Waiting for all applications to become healthy..."
while [ $ELAPSED -lt $TIMEOUT ]; do
  CURRENT_STATUS=$(kubectl -n $NAMESPACE get applications -o jsonpath="{range .items[*]}{.metadata.name}{': '}{.status.health.status}{'\n'}{end}")
  
  if [ "$CURRENT_STATUS" != "$PREV_STATUS" ]; then
    echo "Application status changed:"
    echo "$CURRENT_STATUS"
    PREV_STATUS="$CURRENT_STATUS"
  fi
  
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