#!/bin/bash
set -euo pipefail

# Configuration
IMAGES=("tp-final-frontend" "tp-final-api-gateway" "tp-final-auth-service" "tp-final-products-api" "tp-final-orders-api")
SEVERITY="${SEVERITY:-HIGH,CRITICAL}"
OUTPUT_DIR="${OUTPUT_DIR:-./trivy-reports}"
PARALLEL_JOBS="${PARALLEL_JOBS:-2}"
TIMEOUT="${TIMEOUT:-600}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/trivy"
REPORT_FORMAT="${REPORT_FORMAT:-json}"
MAX_RETRIES="${MAX_RETRIES:-2}"
SKIP_SARIF="${SKIP_SARIF:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

EXIT_CODE=0
TEMP_RESULTS_FILE=""
FAILED_IMAGES_FILE=""
SCAN_TIMES_FILE=""

# Setup
mkdir -p "$OUTPUT_DIR" "$CACHE_DIR"
TEMP_RESULTS_FILE=$(mktemp)
FAILED_IMAGES_FILE=$(mktemp)
SCAN_TIMES_FILE=$(mktemp)
trap "rm -f $TEMP_RESULTS_FILE $FAILED_IMAGES_FILE $SCAN_TIMES_FILE" EXIT

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $*"
}

# Check trivy installation and version
check_trivy() {
    if ! command -v trivy &>/dev/null; then
        log_error "trivy is not installed"
        return 1
    fi
    local version=$(trivy version 2>/dev/null | grep "Version" | head -1)
    log_info "Using: $version"
}

# Initialize Trivy database (only on first run)
init_trivy_db() {
    if [ ! -d "$CACHE_DIR/db" ]; then
        log_info "Initializing Trivy vulnerability database (first run)..."
        if trivy image --download-db-only --cache-dir "$CACHE_DIR" 2>&1 | grep -E "Downloaded|Skipping"; then
            log_info "Database initialized successfully"
        else
            log_warn "Database initialization may have skipped updates (offline mode)"
        fi
    else
        log_info "Database cache found, skipping initialization"
    fi
}

# Scan a single image with retry logic
scan_image() {
    local image=$1
    local attempt=1
    local json_file="$OUTPUT_DIR/${image}.json"
    local sarif_file="$OUTPUT_DIR/${image}.sarif"
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "Scanning: $image (attempt $attempt/$MAX_RETRIES)"
        
        local start_time=$(date +%s)
        
        # Main scan
        if timeout "$TIMEOUT" trivy image \
            --severity "$SEVERITY" \
            --format "${REPORT_FORMAT}" \
            --output "$json_file" \
            --cache-dir "$CACHE_DIR" \
            --quiet \
            "$image" 2>/tmp/trivy-error-$$.log; then
            
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            # Count vulnerabilities
            local vuln_count=0
            if [ -f "$json_file" ]; then
                vuln_count=$(grep -c '"Type": "vulnerability"' "$json_file" 2>/dev/null || true)
            fi
            vuln_count=${vuln_count:-0}  # Ensure it's a number, not empty
            
            # Generate SARIF only if requested (slower)
            if [ "$SKIP_SARIF" != "true" ]; then
                timeout "$((TIMEOUT/2))" trivy image \
                    --severity "$SEVERITY" \
                    --format sarif \
                    --output "$sarif_file" \
                    --cache-dir "$CACHE_DIR" \
                    --quiet \
                    "$image" 2>/dev/null || log_warn "$image: SARIF generation failed (non-critical)"
            fi
            
            # Write result
            echo "$image: $vuln_count vulnerabilities (${duration}s)" >> "$TEMP_RESULTS_FILE"
            echo "$image $duration" >> "$SCAN_TIMES_FILE"
            
            if [ "$vuln_count" -gt 0 ]; then
                log_warn "$image: Found $vuln_count vulnerabilities"
            else
                log_info "$image: Clean scan ✓"
            fi
            
            rm -f /tmp/trivy-error-$$.log
            return 0
            
        else
            local exit_code=$?
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            if [ $exit_code -eq 124 ]; then
                log_warn "$image: Timeout after ${duration}s (attempt $attempt/$MAX_RETRIES)"
            else
                log_warn "$image: Scan failed with exit code $exit_code (attempt $attempt/$MAX_RETRIES)"
                if [ -f /tmp/trivy-error-$$.log ]; then
                    log_debug "Error: $(head -3 /tmp/trivy-error-$$.log 2>/dev/null || echo 'unknown')"
                fi
            fi
            
            attempt=$((attempt + 1))
            
            if [ $attempt -le $MAX_RETRIES ]; then
                sleep $((attempt * 2))
            fi
        fi
    done
    
    log_error "$image: Failed after $MAX_RETRIES attempts"
    echo "$image" >> "$FAILED_IMAGES_FILE"
    rm -f /tmp/trivy-error-$$.log
    return 1
}

# Print system diagnostics
print_diagnostics() {
    echo ""
    echo "================================"
    echo "System Diagnostics"
    echo "================================"
    
    log_info "Available memory: $(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo 'unknown')"
    log_info "Available disk: $(df -h "$OUTPUT_DIR" 2>/dev/null | tail -1 | awk '{print $4}' || echo 'unknown')"
    log_info "CPU cores: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 'unknown')"
    log_info "Active processes: $(ps aux | wc -l)"
    
    if command -v docker &>/dev/null; then
        local image_count=$(docker images --quiet 2>/dev/null | wc -l)
        log_info "Docker images available: $image_count"
    fi
}

# Main execution
echo "================================"
echo "CloudShop Security Scan v3"
echo "================================"
echo "Images: ${#IMAGES[@]}"
echo "Severity: $SEVERITY"
echo "Parallel Jobs: $PARALLEL_JOBS"
echo "Timeout per scan: ${TIMEOUT}s"
echo "Max retries: $MAX_RETRIES"
echo "Skip SARIF: $SKIP_SARIF"
echo "Reports: $OUTPUT_DIR"
echo "Cache: $CACHE_DIR"
echo "================================"
echo ""

# Pre-flight checks
check_trivy || exit 1
init_trivy_db

print_diagnostics

echo ""

# Run scans in parallel using background jobs
declare -a pids
log_info "Starting parallel scans (max $PARALLEL_JOBS concurrent jobs)..."
echo ""

for image in "${IMAGES[@]}"; do
    # Wait if we've hit the max parallel jobs
    while [ $(jobs -r | wc -l) -ge "$PARALLEL_JOBS" ]; do
        sleep 0.5
    done
    
    # Start scan in background
    scan_image "$image" &
    pids+=($!)
done

# Wait for all background jobs to complete
wait "${pids[@]}" 2>/dev/null || true

# Check for failed scans
if [ -s "$FAILED_IMAGES_FILE" ]; then
    EXIT_CODE=1
fi

# Generate summary report
echo ""
echo "================================"
echo "Scan Summary"
echo "================================"
echo ""

if [ -s "$TEMP_RESULTS_FILE" ]; then
    while IFS= read -r line; do
        echo "$line"
    done < <(sort "$TEMP_RESULTS_FILE")
else
    echo "No scan results recorded"
fi

if [ -s "$FAILED_IMAGES_FILE" ]; then
    echo ""
    log_error "Failed scans:"
    while IFS= read -r image; do
        echo "  - $image"
    done < "$FAILED_IMAGES_FILE"
fi

# Performance stats
echo ""
echo "================================"
echo "Performance Statistics"
echo "================================"

if [ -s "$SCAN_TIMES_FILE" ]; then
    total_time=$(awk '{sum+=$2} END {print sum}' "$SCAN_TIMES_FILE")
    slowest=$(sort -k2 -rn "$SCAN_TIMES_FILE" | head -1)
    echo "Total scan time: ${total_time}s"
    echo "Slowest scan: $slowest"
fi

echo ""
echo "Reports saved to: $OUTPUT_DIR"
json_count=$(ls -1 "$OUTPUT_DIR"/*.json 2>/dev/null | wc -l)
sarif_count=$(ls -1 "$OUTPUT_DIR"/*.sarif 2>/dev/null | wc -l)
echo "JSON reports: $json_count files"
echo "SARIF reports: $sarif_count files"
echo ""

# Troubleshooting recommendations
if [ $EXIT_CODE -ne 0 ]; then
    echo "================================"
    echo "Troubleshooting Recommendations"
    echo "================================"
    echo "If scans are still timing out:"
    echo "  1. Increase timeout: TIMEOUT=900 ./$(basename "$0")"
    echo "  2. Reduce parallel jobs: PARALLEL_JOBS=1 ./$(basename "$0")"
    echo "  3. Skip SARIF generation: SKIP_SARIF=true ./$(basename "$0")"
    echo "  4. Clear cache: rm -rf $CACHE_DIR && ./$(basename "$0")"
    echo ""
    echo "For more details on failed images:"
    echo "  trivy image <image-name> --severity $SEVERITY"
    echo ""
    log_error "Security scan found vulnerabilities or failures ✗"
else
    log_info "All images passed security scan ✓"
fi

exit $EXIT_CODE