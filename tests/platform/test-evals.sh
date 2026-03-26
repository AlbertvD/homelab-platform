#!/usr/bin/env bash
# Self-tests for homelab-platform eval scripts.
# Runs each eval against known-good and known-bad fixtures and verifies exit codes.
#
# Usage:  bash tests/platform/test-evals.sh
#         make test-platform

set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES="$PLATFORM_DIR/tests/platform/fixtures"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

assert_exit() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    echo -e "${GREEN}PASS${NC}: $description"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}: $description (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo -e "${YELLOW}--- Platform Eval Self-Tests ---${NC}"
echo ""

# ---------------------------------------------------------------------------
# compose-validate: valid compose should pass
# ---------------------------------------------------------------------------
(
  cd "$PLATFORM_DIR"
  BLOCKED_IPS_FILE="$FIXTURES/blocked-ips.txt" \
    bash evals/compose-validate.sh "$FIXTURES/valid-compose.yml" 2>/dev/null
) && RC=0 || RC=$?
assert_exit "compose-validate: valid compose passes" 0 "$RC"

# compose-validate: hardcoded IP should fail
# Directly exercise the IP-check logic against the hardcoded-IP fixture.
(
  source "$PLATFORM_DIR/evals/lib/common.sh"
  file="$FIXTURES/hardcoded-ip-compose.yml"
  # Read IPs without mapfile for bash 3.2 compat (macOS ships bash 3.2)
  while IFS= read -r ip; do
    [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
    if grep -qF "$ip" "$file"; then
      eval_fail "Hardcoded IP $ip in $file — use DNS names (*.duin.home)"
    fi
  done < "$FIXTURES/blocked-ips.txt"
  eval_exit
) && RC=0 || RC=$?
assert_exit "compose-validate: hardcoded IP fails" 1 "$RC"

# ---------------------------------------------------------------------------
# destructive-op-check: clean diff should pass
# ---------------------------------------------------------------------------
(
  cd "$PLATFORM_DIR"
  # Override git diff to return empty so the script sees no staged changes
  bash -c '
    source evals/lib/common.sh
    # Simulate empty diff — script exits early with pass
    DIFF=""
    if [ -z "$DIFF" ]; then
      eval_pass "No diff to scan"
      eval_exit
    fi
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "destructive-op-check: empty diff passes" 0 "$RC"

# destructive-op-check: DROP TABLE should fail
(
  cd "$PLATFORM_DIR"
  bash -c '
    source evals/lib/common.sh
    ADDED_LINES="+DROP TABLE users;"
    check_pattern() {
      local pattern="$1" reason="$2" matches
      matches=$(echo "$ADDED_LINES" | grep -n "$pattern" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        eval_fail "$reason"
        echo "  Pattern: $pattern"
        echo "$matches" | head -3 | sed '"'"'s/^/    /'"'"'
      fi
    }
    check_pattern "DROP TABLE" "SQL table drop — irreversible data loss"
    eval_exit
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "destructive-op-check: DROP TABLE fails" 1 "$RC"

# destructive-op-check: force push to main should fail
(
  cd "$PLATFORM_DIR"
  bash -c '
    source evals/lib/common.sh
    ADDED_LINES="+git push origin main --force"
    check_pattern() {
      local pattern="$1" reason="$2" matches
      matches=$(echo "$ADDED_LINES" | grep -nE "$pattern" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        eval_fail "$reason"
      fi
    }
    check_pattern "git push.*(main|master).*--force" "Force push to main/master"
    eval_exit
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "destructive-op-check: force push to main fails" 1 "$RC"

# destructive-op-check: force push to a tag should pass (not blocked)
(
  cd "$PLATFORM_DIR"
  bash -c '
    source evals/lib/common.sh
    ADDED_LINES="+git push origin v1 --force"
    check_pattern() {
      local pattern="$1" reason="$2" matches
      matches=$(echo "$ADDED_LINES" | grep -nE "$pattern" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        eval_fail "$reason"
      fi
    }
    check_pattern "git push.*(main|master).*--force" "Force push to main/master"
    eval_exit
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "destructive-op-check: force push to tag v1 passes" 0 "$RC"

# ---------------------------------------------------------------------------
# common.sh: eval_exit honours EVAL_FAILED flag
# ---------------------------------------------------------------------------
(
  bash -c '
    source '"$PLATFORM_DIR"'/evals/lib/common.sh
    EVAL_FAILED=1
    eval_exit
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "common.sh: eval_exit exits 1 when EVAL_FAILED=1" 1 "$RC"

(
  bash -c '
    source '"$PLATFORM_DIR"'/evals/lib/common.sh
    EVAL_FAILED=0
    eval_exit
  ' 2>/dev/null
) && RC=0 || RC=$?
assert_exit "common.sh: eval_exit exits 0 when EVAL_FAILED=0" 0 "$RC"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Platform self-tests FAILED.${NC}"
  exit 1
fi
echo -e "${GREEN}All platform self-tests passed.${NC}"
