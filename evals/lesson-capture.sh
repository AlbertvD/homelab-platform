#!/usr/bin/env bash
# Lesson Capture: Automatically records CI failures to OpenBrain.
source "$(dirname "$0")/lib/common.sh"
STACK="${1:?Usage: lesson-capture.sh <stack> <category> <severity> <description>}"
CATEGORY="${2:-ci}"
SEVERITY="${3:-friction}"
DESCRIPTION="${4:-CI failure (no description provided)}"
OPENBRAIN_URL="${OPENBRAIN_URL:-}"
OPENBRAIN_KEY="${OPENBRAIN_KEY:-}"
if [ -z "$OPENBRAIN_KEY" ] || [ -z "$OPENBRAIN_URL" ]; then
  echo "OPENBRAIN_URL or OPENBRAIN_KEY not set — cannot capture lesson"
  exit 0
fi
BRANCH="${GITHUB_REF_NAME:-local}"
COMMIT="${GITHUB_SHA:-unknown}"
COMMIT_SHORT="${COMMIT:0:7}"
WORKFLOW="${GITHUB_WORKFLOW:-manual}"
LESSON="[CI] $DESCRIPTION (branch: $BRANCH, commit: $COMMIT_SHORT, workflow: $WORKFLOW)"
CAPTURE_RESULT=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$OPENBRAIN_URL/mcp" -H "Content-Type: application/json" -H "x-brain-key: $OPENBRAIN_KEY" -d "{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "add_deployment_lesson", "arguments": {"stack": "$STACK", "category": "$CATEGORY", "severity": "$SEVERITY", "lesson": "$LESSON"}}}" 2>/dev/null || echo "000")
if [ "$CAPTURE_RESULT" = "200" ]; then
  echo "Lesson captured to OpenBrain: $LESSON"
else
  echo "Warning: OpenBrain capture returned HTTP $CAPTURE_RESULT — lesson not saved"
fi
exit 0
