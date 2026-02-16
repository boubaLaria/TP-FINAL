#!/bin/bash
set -euo pipefail

# Configuration
ENDPOINTS=(
  "http://localhost:3000/health|frontend"
  "http://localhost:8080/health|api-gateway"
  "http://localhost:8081/health|auth-service"
  "http://localhost:8082/health|products-api"
  "http://localhost:8083/health|orders-api"
  "http://localhost:9200/_cluster/health|elasticsearch"
)

MAX_WAIT="${MAX_WAIT:-120}"
TIMEOUT="${TIMEOUT:-5}"
MAX_RETRIES="${MAX_RETRIES:-10}"
RETRY_DELAY="${RETRY_DELAY:-1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

EXIT_CODE=0
PASSED=0
FAILED_SERVICES=()

log_info() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_debug() {
    if [ "${DEBUG:-false}" == "true" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# Check dependencies
if ! command -v curl &>/dev/null; then
    log_error "curl is not installed"
    exit 1
fi

# Print header
echo "================================"
echo "CloudShop Health Check"
echo "================================"
echo "Services: ${#ENDPOINTS[@]}"
echo "Max wait: ${MAX_WAIT}s | Timeout: ${TIMEOUT}s"
echo "Retries: ${MAX_RETRIES} | Delay: ${RETRY_DELAY}s"
echo "================================"
echo ""

# Check each endpoint
for endpoint_config in "${ENDPOINTS[@]}"; do
    url=$(echo "$endpoint_config" | cut -d'|' -f1)
    name=$(echo "$endpoint_config" | cut -d'|' -f2)
    
    attempt=1
    start_time=$(date +%s)
    success=false
    
    while [ $attempt -le $MAX_RETRIES ]; do
        # Check elapsed time
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $MAX_WAIT ]; then
            log_error "$name - Timeout after ${elapsed}s"
            FAILED_SERVICES+=("$name")
            EXIT_CODE=1
            break
        fi
        
        # Try to connect
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time "$TIMEOUT" \
            --connect-timeout "$TIMEOUT" \
            "$url" 2>/dev/null || echo "000")
        
        # Check response
        if [[ "$http_code" =~ ^[23][0-9]{2}$ ]]; then
            log_info "$name ($http_code)"
            PASSED=$((PASSED + 1))
            success=true
            break
        elif [[ "$http_code" =~ ^[45][0-9]{2}$ ]]; then
            log_warn "$name - HTTP $http_code (attempt $attempt/$MAX_RETRIES)"
        elif [ "$http_code" == "000" ]; then
            log_debug "$name - Connection failed (attempt $attempt/$MAX_RETRIES)"
        else
            log_debug "$name - HTTP $http_code (attempt $attempt/$MAX_RETRIES)"
        fi
        
        # Sleep before retry
        if [ $attempt -lt $MAX_RETRIES ]; then
            sleep "$RETRY_DELAY"
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ "$success" == "false" ]; then
        FAILED_SERVICES+=("$name")
        EXIT_CODE=1
    fi
done

# Print summary
echo ""
echo "================================"
echo "Health Check Summary"
echo "================================"
echo "Passed: $PASSED/${#ENDPOINTS[@]}"

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    log_info "All services healthy"
else
    echo ""
    log_error "Failed services:"
    for service in "${FAILED_SERVICES[@]}"; do
        echo "  • $service"
    done
    echo ""
    echo "Troubleshooting:"
    echo "  • Check if services are running: docker ps"
    echo "  • View service logs: docker logs <service>"
    echo "  • Increase timeout: MAX_WAIT=300 $0"
    echo "  • Test manually: curl -v http://localhost:8080/health"
    echo "  • Enable debug: DEBUG=true $0"
fi

exit $EXIT_CODE