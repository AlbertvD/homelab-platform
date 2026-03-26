# Homelab Platform

**Goal:** Build a shared tooling repository (`homelab-platform`) that provides safety evals, reusable CI workflows, Claude Code hooks, automated testing, project scaffolding, and OpenBrain-powered institutional memory.

## PLATFORM_TOKEN Onboarding
Every consuming repository must have a `PLATFORM_TOKEN` secret. 
1. Create a **fine-grained GitHub PAT** scoped to `AlbertvD/homelab-platform`.
2. Permissions: `contents:read` only. 
3. Add as `PLATFORM_TOKEN` secret in the consuming repository's settings.

## Evals
- `compose-validate.sh`: Syntax check and standard patterns for Docker Compose.
- `destructive-op-check.sh`: Scan diffs for dangerous patterns.
- `rls-check.sh`: Verify RLS policies on new/existing tables via OpenBrain.

## OpenBrain Integration
- `lesson-check.sh`: Surface past failures/guardrails during pre-commit/CI.
- `lesson-capture.sh`: Automatically record CI failures to OpenBrain.
- `db-health-check.sh`: Post-deploy probe for database health metrics.
