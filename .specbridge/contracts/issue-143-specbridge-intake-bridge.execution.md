# Execution Contract: Issue 143 SpecBridge Intake Bridge

## Contract Metadata

- contract_id: issue-143-specbridge-intake-bridge
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/143
- created_by: Claude Code / SpecBridge executor
- created_at: 2026-06-08
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Implement the ChatGPT → SpecBridge intake bridge: a `specbridge-intake` CLI command that generates all governance files for a new task (contract, scope, evidence) and commits them to a new branch, plus a `specbridge-intake.yml` GitHub Action that allows external callers (ChatGPT, Codex, or any system with `gh` access) to trigger intake via `gh workflow run` without touching the repository manually.

## Context

The apply-mode 6-operation loop is fully operational. The missing piece is the entry point: today the user manually creates contracts and evidence files. The intake bridge closes this gap by accepting a task_id, title, and goal as inputs and producing a ready-to-execute branch. ChatGPT can trigger this via `gh workflow run specbridge-intake.yml -f task_id=... -f title=... -f goal=...`. Once the branch is created, the full 6-op operator can be run against it.

## Source References

- scripts/specbridge.ps1
- .github/workflows/specbridge-intake.yml (new)
- README.md
- SPECBRIDGE.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- Adds a new GitHub Actions workflow. The workflow only creates files and commits — it does not merge, deploy, or access secrets beyond GITHUB_TOKEN.
- `specbridge-intake` CLI generates governance files deterministically from inputs. No secrets, production, billing, auth, or deployment scope.

## Allowed Scope

```text
scripts/specbridge.ps1
.github/workflows/specbridge-intake.yml
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-143-specbridge-intake-bridge.execution.md
.specbridge/scopes/issue-143-specbridge-intake-bridge.scope.json
.specbridge/scopes/issue-142-apply-mode-issue-create.scope.json
.specbridge/reports/issue-143-specbridge-intake-bridge.final-report.json
.specbridge/audit-packets/issue-143-specbridge-intake-bridge.audit-packet.json
.specbridge/audits/issue-143-specbridge-intake-bridge.chatgpt-audit.json
.specbridge/github-evidence/issue-143-specbridge-intake-bridge.github-mutation-evidence.json
GitHub pull request for this branch
GitHub issue 143 lifecycle comments/status updates
```

## Blocked Scope

```text
.github/workflows/foundation-validation.yml
.github/workflows/specbridge-review-gate.yml
.github/workflows/specbridge-pr-review-report.yml
.github/workflows/claude-review-non-blocking.yml
.env
.env.*
secrets/**
infra/prod/**
database changes
authentication implementation
authorization implementation
billing implementation
deployment automation
production deployment
```

## Acceptance Criteria

- `specbridge-intake` CLI command exists in `specbridge.ps1`.
- Given `-TaskId`, `-Title`, `-Goal`, and `-RepositoryUrl`, it generates: contract.md, scope.json, and evidence.json with all gates set to `true`.
- It creates a branch `codex/{task_id}`, commits the files, and pushes.
- Output is a JSON summary: branch name, files created, and the exact `issue-to-merge-github` command to run next.
- `.github/workflows/specbridge-intake.yml` workflow exists with `workflow_dispatch` inputs: `task_id`, `title`, `goal`.
- The workflow runs `specbridge-intake` and outputs the branch URL and next-step command.
- All local validators pass.
- All CLI tests pass.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, database changes, or deployment automation.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete when `specbridge-intake` CLI and `specbridge-intake.yml` action exist, validators pass, and the 6-op loop executes on issue 143.
