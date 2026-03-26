# Homelab Platform: CLAUDE.md

## Project Purpose
This is a standalone repository providing shared CI/CD workflows, safety evaluations, and institutional memory for all homelab projects.

## Core Mandates
- **Tag Early**: Always push a `v1` tag when making significant changes; consuming projects reference `@v1`.
- **Private Access**: This repo is private. All projects use `PLATFORM_TOKEN` (fine-grained PAT) to access it.
- **Fail Loudly**: Eval scripts must never fail silently. Use `eval_fail` helper from `evals/lib/common.sh`.

## Implementation Principles
1. **Copy-on-install**: Hooks are copied into consuming repos via `hooks/install.sh`. No runtime dependencies on the platform directory.
2. **Version Stamps**: Always write `.platform-version` files during installation.
3. **OpenBrain-first**: Every gate (pre-commit, CI, post-deploy) should query or update OpenBrain lessons.
