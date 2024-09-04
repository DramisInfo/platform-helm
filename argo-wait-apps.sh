#!/bin/bash

NAMESPACE="argocd"
TIMEOUT=120  # 2 minutes in seconds
INTERVAL=5  # Check every 5 seconds
ELAPSED=0
declare -A PREV_STATUS

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

echo "Waiting for all applications to become healthy..."
while [ $ELAPSED -lt $TIMEOUT ]; do
  CURRENT_STATUS=$(kubectl -n $NAMESPACE get applications -o jsonpath="{range .items[*]}{.metadata.name}{': '}{.status.health.status}{'\n'}{end}")
  
  while IFS= read -r line; do
    APP_NAME=$(echo "$line" | awk -F': ' '{print $1}')
    APP_STATUS=$(echo "$line" | awk -F': ' '{print $2}')
    
    if [ "${PREV_STATUS[$APP_NAME]}" != "$APP_STATUS" ]; then
      if [ "$APP_STATUS" == "Healthy" ]; then
        echo -e "Application $APP_NAME status changed: ${PREV_STATUS[$APP_NAME]} -> ${GREEN}$APP_STATUS${NC}"
      elif [ "$APP_STATUS" == "Progressing" ]; then
        echo -e "Application $APP_NAME status changed: ${PREV_STATUS[$APP_NAME]} -> ${ORANGE}$APP_STATUS${NC}"
      else
        echo -e "Application $APP_NAME status changed: ${PREV_STATUS[$APP_NAME]} -> ${RED}$APP_STATUS${NC}"
      fi
      PREV_STATUS[$APP_NAME]=$APP_STATUS
    fi
  done <<< "$CURRENT_STATUS"
  
  UNHEALTHY_APPS=$(echo "$CURRENT_STATUS" | grep -v "Healthy")
  
  if [ -z "$UNHEALTHY_APPS" ]; then
    echo -e "${GREEN}All applications are healthy.${NC}"
    exit 0
  fi
  
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo -e "${RED}Timeout reached. Some applications are still not healthy.${NC}"
exit 1