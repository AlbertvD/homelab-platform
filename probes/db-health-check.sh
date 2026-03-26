#!/usr/bin/env bash
# Probe: Database Health Check
source "$(dirname "$0")/../evals/lib/common.sh"
eval_header "Database Health Check"
OPENBRAIN_URL="${OPENBRAIN_URL:-}"
OPENBRAIN_KEY="${OPENBRAIN_KEY:-}"
MAX_CONNECTIONS="${MAX_CONNECTIONS:-50}"
MIN_CACHE_HIT="${MIN_CACHE_HIT:-0.90}"
if [ -z "$OPENBRAIN_KEY" ] || [ -z "$OPENBRAIN_URL" ]; then
  eval_warn "OPENBRAIN_URL or OPENBRAIN_KEY not set — skipping DB health check"
  eval_exit
fi
STATS=$(curl -s -X POST "$OPENBRAIN_URL/mcp" -H "Content-Type: application/json" -H "x-brain-key: $OPENBRAIN_KEY" -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_database_stats","arguments":{}}}' 2>/dev/null || echo "{}")
echo "$STATS" | python3 -c "
import json, sys, os
try:
    data = json.load(sys.stdin)
    text = data.get('result', {}).get('content', [{}])[0].get('text', '{}')
    stats = json.loads(text) if text.startswith('{') else {}
    conn_count = stats.get('connection_count', 0)
    cache_hit = stats.get('cache_hit_ratio', 1.0)
    max_conn = int(os.environ.get('MAX_CONNECTIONS', 50))
    min_cache = float(os.environ.get('MIN_CACHE_HIT', 0.90))
    if conn_count > max_conn:
        print(f'WARN connection_count={conn_count} exceeds threshold={max_conn}')
    else:
        print(f'PASS connection_count={conn_count}')
    if cache_hit < min_cache:
        print(f'WARN cache_hit_ratio={cache_hit:.2f} below threshold={min_cache}')
    else:
        print(f'PASS cache_hit_ratio={cache_hit:.2f}')
except Exception as e:
    print(f'WARN could not parse stats: {e}')
" 2>/dev/null || eval_warn "Could not parse database stats"
eval_exit
