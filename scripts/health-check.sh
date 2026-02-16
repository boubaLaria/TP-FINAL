#!/bin/bash
set -e
ENDPOINTS=(
  "http://localhost:3000/health|frontend"
  "http://localhost:8080/health|api-gateway"
  "http://localhost:8081/health|auth-service"
  "http://localhost:8082/health|products-api"
  "http://localhost:8083/health|orders-api"
  "http://localhost:9200/_cluster/health|elasticsearch"
)
EXIT_CODE=0
echo "CloudShop Health Check"
for EP in "${ENDPOINTS[@]}"; do
  URL=$(echo "$EP" | cut -d'|' -f1)
  NAME=$(echo "$EP" | cut -d'|' -f2)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL" || echo "000")
  if [[ "$HTTP_CODE" == 2* ]] || [[ "$HTTP_CODE" == 200 ]]; then
    echo "PASS: $NAME ($HTTP_CODE)"
  else
    echo "FAIL: $NAME ($HTTP_CODE)"
    EXIT_CODE=1
  fi
done
exit $EXIT_CODE