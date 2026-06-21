# Execution Contract: Issue 231 Claude Runtime Capability Negotiation

## Contract Metadata

- contract_id: issue-231-claude-runtime-capability-negotiation
- run_id: sb-20260620-0231c1d2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/231
- created_by: ChatGPT/Codex
- created_at: 2026-06-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add bounded Claude Code runtime capability negotiation so SpecBridge only passes conditional Claude CLI flags, especially `--max-turns`, when the installed CLI exposes support.

## Context

SpecBridge already records token/context governance and bounded runtime launch budgets. The policy explicitly says `--max-turns` should be used for live launches only when the installed Claude Code CLI supports it. The current runner always builds a fixed command and does not record a capability decision for conditional flags.

This task closes that gap without widening runtime authority. It must keep budget, timeout, no-session-persistence, allowed tools, redaction, and no-secret boundaries intact.

## Source References

- `README.md` - product status and runtime governance posture.
- `SPECBRIDGE.md` - execution contract and policy hierarchy.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active repository policy.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next-task guidance.
- `.specbridge/policies/token-context-governance.json` - max budget and conditional max-turns policy.
- `scripts/lib/status.ps1` - runtime-capability-status and local Claude capability source.
- `scripts/lib/runtime.ps1` - runtime launch planning and controlled execution.
- `scripts/specbridge.ps1` - CLI entry point and runtime parameters.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.specbridge/schemas/runtime-launch.schema.json` - runtime launch evidence schema.
- `.specbridge/schemas/runtime-execution.schema.json` - runtime execution evidence schema.
- `scripts/validate-runtime-launches.ps1` - runtime launch validator.
- `scripts/validate-runtime-executions.ps1` - runtime execution validator.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task changes controlled runtime command assembly, evidence schemas, validators, tests, documentation, and governance artifacts. Live Claude Code launches remain allowed only through existing `execute-runtime-launch -Force` gates and bounded launch plans. This task must not spend unbounded tokens or reveal provider secrets.

## Allowed Scope

```text
.specbridge/contracts/issue-231-claude-runtime-capability-negotiation.execution.md
.specbridge/scopes/issue-231-claude-runtime-capability-negotiation.scope.json
.specbridge/reports/issue-231-claude-runtime-capability-negotiation.final-report.json
.specbridge/audit-packets/issue-231-claude-runtime-capability-negotiation.audit-packet.json
.specbridge/audits/issue-231-claude-runtime-capability-negotiation.chatgpt-audit.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/standard-readiness/current.status.json
.specbridge/schemas/runtime-launch.schema.json
.specbridge/schemas/runtime-execution.schema.json
README.md
docs/specbridge-claude-runtime-capability-negotiation.md
docs/specbridge-runtime-runner.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/status.ps1
scripts/lib/runtime.ps1
scripts/test-specbridge-cli.ps1
scripts/validate-runtime-launches.ps1
scripts/validate-runtime-executions.ps1
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
.mcp.json
.mcp.*.json
dependency installation
package manager files
real billing configuration
provider account configuration
API key or token storage
secret access
raw hidden prompt export
raw chat transcript export
raw unbounded tool output export
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
branch cleanup enforcement
artifact retention enforcement
cleanup apply mode
issue #194 lifecycle changes
digital twin implementation
unbounded Claude Code token spending
raising runtime budget above policy ceiling
launching Claude outside execute-runtime-launch gates
```

## Acceptance Criteria

1. `runtime-capability-status` reports whether the local Claude CLI help output exposes `--max-turns` when Claude is available.
2. Runtime launch planning records the desired max-turns value as governed metadata without requiring old launch artifacts to change.
3. `execute-runtime-launch` includes `--max-turns <value>` only when the installed or fake Claude CLI supports the flag.
4. Runtime execution artifacts record the capability probe source, whether `--max-turns` is supported, whether the flag was applied, and the effective command parts.
5. Dry-run runtime execution evidence is deterministic and records that no live Claude launch occurred.
6. Existing budget, timeout, no-session-persistence, allowed tools, diagnostic redaction, and no-secret boundaries remain intact.
7. CLI regression coverage validates both fake Claude cases: one that supports `--max-turns` and one that does not.
8. Runtime launch and runtime execution validators accept the new optional evidence fields and continue to validate existing committed artifacts.
9. Documentation explains the negotiation behavior, why it exists, and the policy boundary for token spending.
10. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
11. Required validation scripts and full smoke pass locally and in GitHub Actions.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, provider tokens, private keys, raw hidden prompt export, raw chat transcript export, raw unbounded tool output export, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, branch cleanup enforcement, artifact retention enforcement, cleanup apply mode, changing operator decisions, reviving issue #194, implementing the digital twin, or launching Claude outside the existing bounded runtime command.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must use bounded non-interactive execution if invoked, with explicit budget, capability-detected turn limit, no session persistence, and no dangerous permission bypass.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-231-claude-runtime-capability-negotiation.final-report.json`, `.specbridge/audit-packets/issue-231-claude-runtime-capability-negotiation.audit-packet.json`, and `.specbridge/audits/issue-231-claude-runtime-capability-negotiation.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when capability negotiation is implemented, required local validations pass, GitHub checks pass, PR closes issue #231, and post-merge closure evidence is recorded.
