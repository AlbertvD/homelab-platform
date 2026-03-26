#!/usr/bin/env bash
# Homelab Platform — Project Scaffold
set -euo pipefail
PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="$PLATFORM_DIR/scaffold/templates"
print_usage() {
  echo "Usage: $0 new <project-name> [--port <port>]"
}
scaffold_new() {
  local PROJECT_NAME="$1"
  local PORT="${2:-3000}"
  local PROJECT_DIR="$(pwd)/$PROJECT_NAME"
  if [ -d "$PROJECT_DIR" ]; then echo "Error: Directory $PROJECT_DIR already exists"; exit 1; fi
  mkdir -p "$PROJECT_DIR"/{frontend,backend,tests/{api,auth,e2e/journeys},docs/plans,scripts}
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{PORT}}/$PORT/g" "$TEMPLATE_DIR/CLAUDE.md.tmpl" > "$PROJECT_DIR/CLAUDE.md"
  sed "s/{{SERVICE_NAME}}/$PROJECT_NAME/g; s/{{PORT}}/$PORT/g" "$TEMPLATE_DIR/docker-compose.tmpl.yml" > "$PROJECT_DIR/docker-compose.yml"
  mkdir -p "$PROJECT_DIR/.github/workflows"
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATE_DIR/.github/workflows/ci.tmpl.yml" > "$PROJECT_DIR/.github/workflows/ci.yml"
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATE_DIR/Makefile.tmpl" > "$PROJECT_DIR/Makefile"
  (cd "$PROJECT_DIR" && git init && git add -A && git commit -m "feat: scaffold $PROJECT_NAME from homelab-platform")
  (cd "$PROJECT_DIR" && bash "$PLATFORM_DIR/hooks/install.sh")
}
case "${1:-}" in
  new)
    [ -z "${2:-}" ] && { print_usage; exit 1; }
    PORT="3000"
    if [ "${3:-}" = "--port" ]; then PORT="${4:-3000}"; fi
    scaffold_new "$2" "$PORT"
    ;;
  *)
    print_usage; exit 1 ;;
esac
