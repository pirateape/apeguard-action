#!/bin/bash
# ApeGuard GitHub Action — Scan Runner
# Executes the scan with the configured options and produces structured output.
set -euo pipefail

APEGUARD="${APEGUARD_BIN:-apeguard}"
SCAN_PATH="${SCAN_PATH:-.}"
LAYERS="${LAYERS:-secrets,sast,sca}"
FORMAT="${FORMAT:-sarif}"
FAIL_ON="${FAIL_ON:-never}"
OUTPUT_DIR="${OUTPUT_DIR:-$RUNNER_TEMP/apeguard-reports}"

echo "::group::🔍 Running ApeGuard scan"
echo "  Path:   ${SCAN_PATH}"
echo "  Layers: ${LAYERS}"
echo "  Format: ${FORMAT}"

# Map human-readable layer names to layer numbers
# 1=secrets(Gitleaks)  2=SAST(Semgrep)  3=SCA(Trivy)  4=container  5=DAST(Nuclei)
LAYER_FLAGS=""
IFS=',' read -ra LAYER_LIST <<< "$LAYERS"
for layer in "${LAYER_LIST[@]}"; do
  case "$(echo "$layer" | tr '[:upper:]' '[:lower:]' | xargs)" in
    secrets)  LAYER_FLAGS="${LAYER_FLAGS},1" ;;
    sast)     LAYER_FLAGS="${LAYER_FLAGS},2" ;;
    sca)      LAYER_FLAGS="${LAYER_FLAGS},3" ;;
    container) LAYER_FLAGS="${LAYER_FLAGS},4" ;;
    dast)     LAYER_FLAGS="${LAYER_FLAGS},5" ;;
    *)        echo "⚠️  Unknown layer: $layer (valid: secrets, sast, sca, container, dast)" ;;
  esac
done

# Remove leading comma
LAYER_FLAGS="${LAYER_FLAGS#,}"

# Build failure flag
# shellcheck disable=SC2086 # intentional word splitting for flags
case "$FAIL_ON" in
  high)     FAIL_FLAG="--fail-on high" ;;
  critical) FAIL_FLAG="--fail-on critical" ;;
  *)        FAIL_FLAG="" ;;
esac

# Run the scan
mkdir -p "$OUTPUT_DIR"

# Determine report filename
REPORT_FILE="${OUTPUT_DIR}/apeguard-report.${FORMAT}"

# Execute scan
# Note: --quiet suppresses CLI spinner/debug output, keeping action logs clean
set +e
"$APEGUARD" scan \
  --layers "$LAYER_FLAGS" \
  --format "$FORMAT" \
  --output-dir "$OUTPUT_DIR" \
  --quiet \
  $FAIL_FLAG \
  "$SCAN_PATH"

SCAN_EXIT=$?
set -e

# Check exit code
if [ $SCAN_EXIT -ne 0 ]; then
  if [ -n "$FAIL_FLAG" ]; then
    echo "⚠️  Scan found issues at or above '${FAIL_ON}' severity (exit code: ${SCAN_EXIT})"
  else
    echo "❌ Scan failed with exit code ${SCAN_EXIT}"
    # Exit with the scan's exit code unless fail-on is set
    exit $SCAN_EXIT
  fi
fi

# Extract structured outputs from JSON report if it exists
JSON_REPORT="${OUTPUT_DIR}/apeguard-report.json"
if [ -f "$JSON_REPORT" ]; then
  OVERALL_SCORE=$(python3 -c "import json; r=json.load(open('${JSON_REPORT}')); print(r.get('scorecard',{}).get('overall_score',0))" 2>/dev/null || echo "0")
  FINDINGS_COUNT=$(python3 -c "import json; r=json.load(open('${JSON_REPORT}')); print(len(r.get('findings',[])))" 2>/dev/null || echo "0")

  {
    echo "overall_score=${OVERALL_SCORE}"
    echo "findings_count=${FINDINGS_COUNT}"
    echo "report_path=${REPORT_FILE}"
  } >> "$GITHUB_OUTPUT"
else
  {
    echo "overall_score=0"
    echo "findings_count=0"
    echo "report_path=${REPORT_FILE}"
  } >> "$GITHUB_OUTPUT"
fi

# Summary for action log
echo ""
echo "═══════════════════════════════════"
echo "  ApeGuard Scan Complete"
echo "  Overall UZTF Score: ${OVERALL_SCORE:-N/A}/800"
echo "  Findings: ${FINDINGS_COUNT:-N/A}"
echo "  Report: ${REPORT_FILE}"
echo "═══════════════════════════════════"
echo "::endgroup::"
