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

  echo ""
  echo "Project scaffolded at: $PROJECT_DIR"
  echo ""
  echo "Next steps:"
  echo "  cd $PROJECT_NAME"
  echo "  # Edit evals/lib/blocked-ips.txt to add homelab IPs"
  echo "  # Set up frontend: cd frontend && npx create-next-app@latest . --typescript"
  echo "  # Set up backend:  cd backend && npm init -y && npm install express prisma zod"
  echo "  # Create GitHub repo: gh repo create AlbertvD/$PROJECT_NAME --private"
  echo "  # Add secrets: PLATFORM_TOKEN, SUPABASE_ANON_KEY, SUPABASE_SERVICE_KEY, OPENBRAIN_KEY"
  echo ""
  echo "Supabase onboarding checklist (shared instance):"
  echo "  1. Create schema: CREATE SCHEMA $PROJECT_NAME;"
  echo "  2. Enable RLS on every table: ALTER TABLE $PROJECT_NAME.<table> ENABLE ROW LEVEL SECURITY;"
  echo "  3. Add RLS SELECT policy for authenticated role (missing policy = silent false for all users)"
  echo "  4. Grant usage: GRANT USAGE ON SCHEMA $PROJECT_NAME TO anon, authenticated;"
  echo "  5. Grant table permissions: GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $PROJECT_NAME TO authenticated;"
  echo "  6. Do NOT use GRANT ALL — overrides selective grants and masks misconfigured RLS"
  echo "  7. Kong CORS: ensure Accept-Profile and Content-Profile are in allowed headers (Chrome strictly validates; Safari does not)"
  echo "  8. Cross-subdomain SSO: set shared storageKey, domain cookie (.duin.home), consistent Supabase client config across all apps"
  echo "  9. service_role bypasses RLS but still requires explicit GRANT on the table"
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
