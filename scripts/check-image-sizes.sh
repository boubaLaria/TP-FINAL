#!/usr/bin/env bash
set -e
echo "Docker Image Size Check"
EXIT_CODE=0
check_size() {
  IMG=$1
  LIMIT=$2
  SIZE_B=$(docker image inspect $IMG --format='{{.Size}}' 2>/dev/null || echo "0")
  SIZE_MB=$((SIZE_B / 1048576))
  if [ "$SIZE_MB" -le "$LIMIT" ]; then
    echo "PASS: $IMG ${SIZE_MB}MB <= ${LIMIT}MB"
  else
    echo "FAIL: $IMG ${SIZE_MB}MB > ${LIMIT}MB"
    EXIT_CODE=1
  fi
}
check_size tp-final-frontend 70
check_size tp-final-api-gateway 150
check_size tp-final-auth-service 150
check_size tp-final-products-api 180
check_size tp-final-orders-api 30
exit $EXIT_CODE