#!/usr/bin/env bash
# Install homelab-platform hooks
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$(pwd)"
install_claude_code_hooks() {
  echo "Installing Claude Code hooks..."

  # Default install paths match homelab-configs layout (src/hooks/, src/lib/).
  # Override with env vars if your project uses a different structure:
  #   HOOKS_TARGET_DIR=.claude/hooks HOOKS_LIB_DIR=src/lib bash install.sh --claude-code
  HOOKS_TARGET_DIR="${HOOKS_TARGET_DIR:-src/hooks}"
  HOOKS_LIB_DIR="${HOOKS_LIB_DIR:-src/lib}"

  mkdir -p "$PROJECT_DIR/$HOOKS_TARGET_DIR" "$PROJECT_DIR/$HOOKS_LIB_DIR"

  for hook in pre-tool-use.ts post-tool-use.ts stop.ts; do
    if [ -f "$PLATFORM_DIR/hooks/claude-code/$hook" ]; then
      cp "$PLATFORM_DIR/hooks/claude-code/$hook" "$PROJECT_DIR/$HOOKS_TARGET_DIR/$hook"
      echo "  Copied: $HOOKS_TARGET_DIR/$hook"
    fi
  done

  if [ -f "$PLATFORM_DIR/hooks/claude-code/lib/hook-utils.ts" ]; then
    cp "$PLATFORM_DIR/hooks/claude-code/lib/hook-utils.ts" "$PROJECT_DIR/$HOOKS_LIB_DIR/hook-utils.ts"
    echo "  Copied: $HOOKS_LIB_DIR/hook-utils.ts"
  fi

  PLATFORM_SHA=$(git -C "$PLATFORM_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  echo "$PLATFORM_SHA" > "$PROJECT_DIR/$HOOKS_TARGET_DIR/.platform-version"
  echo "  Wrote: $HOOKS_TARGET_DIR/.platform-version ($PLATFORM_SHA)"

  echo ""
  echo "Add to your .claude/settings.json (adjust paths if you used custom HOOKS_TARGET_DIR):"
  echo '  "hooks": {'
  echo "    \"PreToolUse\": [{ \"type\": \"command\", \"command\": \"~/.bun/bin/bun run $HOOKS_TARGET_DIR/pre-tool-use.ts\" }],"
  echo "    \"PostToolUse\": [{ \"type\": \"command\", \"command\": \"~/.bun/bin/bun run $HOOKS_TARGET_DIR/post-tool-use.ts\" }],"
  echo "    \"Stop\": [{ \"type\": \"command\", \"command\": \"~/.bun/bin/bun run $HOOKS_TARGET_DIR/stop.ts\" }]"
  echo '  }'
  echo ""
  echo "To install to a custom path: HOOKS_TARGET_DIR=.claude/hooks bash install.sh --claude-code"
}
install_pre_commit() {
  echo "Installing pre-commit hook..."
  cp "$PLATFORM_DIR/hooks/pre-commit" "$PROJECT_DIR/.git/hooks/pre-commit"
  chmod +x "$PROJECT_DIR/.git/hooks/pre-commit"
}
install_evals() {
  echo "Installing eval scripts..."
  mkdir -p "$PROJECT_DIR/evals/lib"
  for script in compose-validate.sh destructive-op-check.sh lesson-check.sh lesson-capture.sh rls-check.sh; do
    if [ -f "$PLATFORM_DIR/evals/$script" ]; then cp "$PLATFORM_DIR/evals/$script" "$PROJECT_DIR/evals/$script"; chmod +x "$PROJECT_DIR/evals/$script"; fi
done
  cp "$PLATFORM_DIR/evals/lib/common.sh" "$PROJECT_DIR/evals/lib/common.sh"
  cp "$PLATFORM_DIR/evals/lib/blocked-ips.txt" "$PROJECT_DIR/evals/lib/blocked-ips.txt"
  PLATFORM_SHA=$(git -C "$PLATFORM_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  echo "$PLATFORM_SHA" > "$PROJECT_DIR/evals/.platform-version"
}
case "${1:-all}" in
  --claude-code) install_claude_code_hooks ;;
  --pre-commit)  install_pre_commit ;;
  --evals)       install_evals ;;
  all)
    install_claude_code_hooks
    install_pre_commit
    install_evals
    ;;
esac
