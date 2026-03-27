# Homelab Platform

**Goal:** Build a shared tooling repository (`homelab-platform`) that provides safety evals, reusable CI workflows, Claude Code hooks, automated testing, project scaffolding, and OpenBrain-powered institutional memory.

## PLATFORM_TOKEN Onboarding

**⚠️ CRITICAL:** Use a **fine-grained PAT** (not a classic `repo`-scope PAT). Classic PATs grant access to all repositories you own — if compromised, an attacker gains write access to every homelab project. Fine-grained PATs limit blast radius to this repository only.

### Setup
1. Create a **fine-grained GitHub PAT** at https://github.com/settings/tokens?type=beta
   - **Name:** `homelab-platform-read`
   - **Description:** "Read-only access to homelab-platform"
   - **Resource owner:** Personal account
   - **Repository access:** Only `AlbertvD/homelab-platform`
   - **Permissions:** Repository permissions → `contents:read` only
   - **Expiration:** 90 days (set calendar reminder to rotate)

2. Add as `PLATFORM_TOKEN` secret in your consuming repo's GitHub settings

3. **Never commit `PLATFORM_TOKEN` to Git.** If exposed, delete it immediately and regenerate.

### Key Rotation
Every 90 days (or after rotation reminder), generate a new PAT:
1. Create new fine-grained PAT with same settings above
2. Update `PLATFORM_TOKEN` secret in consuming repo
3. Delete old PAT from GitHub settings
4. If you lose track: visit https://github.com/settings/tokens to see all active PATs and expiry dates

## Evals
- `compose-validate.sh`: Syntax check and standard patterns for Docker Compose.
- `destructive-op-check.sh`: Scan diffs for dangerous patterns.
- `rls-check.sh`: Verify RLS policies on new/existing tables via OpenBrain.

## Using Reusable Workflows

In your consuming project's `.github/workflows/ci.yml`, reference platform workflows with `@v1` tag:

```yaml
jobs:
  safety:
    uses: AlbertvD/homelab-platform/.github/workflows/safety.yml@v1
    with:
      run_compose_validate: true
    secrets: inherit

  test:
    needs: safety
    uses: AlbertvD/homelab-platform/.github/workflows/test.yml@v1
    with:
      run_unit: true
      run_api: true
    secrets: inherit

  build:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: AlbertvD/homelab-platform/.github/workflows/build-push.yml@v1
    with:
      context: .
      dockerfile: ./Dockerfile
      image_name: my-service
      registry: ghcr.io/albertvd/homelab-configs
      required_build_args: "MY_BUILD_VAR"
      build_args: |
        MY_BUILD_VAR=${{ secrets.MY_BUILD_VAR }}
    secrets: inherit
```

**Always use `@v1` tag**, never `@main` or `@latest`. This ensures consuming repos get stable, tested workflows.

## OpenBrain Integration
- `lesson-check.sh`: Surface past failures/guardrails during pre-commit/CI.
- `lesson-capture.sh`: Automatically record CI failures to OpenBrain.
- `db-health-check.sh`: Post-deploy probe for database health metrics.

## Adding New Evals

To add a new eval script:

1. **Create the script** at `evals/my-new-eval.sh`:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
   source "$SCRIPT_DIR/lib/common.sh"

   # Your eval logic here
   echo "✓ Eval passed"
   ```

2. **Use the `eval_fail` helper** for errors:
   ```bash
   # In lib/common.sh, use:
   eval_fail "my-new-eval" "error message"
   ```

3. **Test locally**:
   ```bash
   bash evals/my-new-eval.sh
   ```

4. **Integrate into pre-commit hook** (if applicable):
   - Edit `hooks/pre-commit` to call your eval
   - Document when it should run (pre-commit, CI-only, post-deploy, etc.)

5. **Update consuming projects**:
   - Run `hooks/install.sh --evals` in each consuming repo
   - Verify new eval runs: `bash evals/my-new-eval.sh`

6. **Tag and release**:
   - Commit your changes
   - Tag: `git tag v1 -f && git push --tags -f`
   - Consuming projects using `@v1` will pick up the new eval automatically
