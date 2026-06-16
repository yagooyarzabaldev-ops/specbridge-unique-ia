# Execution Contract: Issue 224 Token And Context Governance

## Contract Metadata

- contract_id: issue-224-token-context-governance
- run_id: sb-20260616-0224a11d
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/224
- created_by: ChatGPT/Codex
- created_at: 2026-06-16
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add an auditable SpecBridge token and context governance standard for Codex and Claude Code execution, aligned with current official provider guidance, and keep the operator health signal clean when no current PR exists.

## Context

SpecBridge already records bounded Claude Code runtime launch budgets through `max_budget_usd`, runtime preflight checks, runtime execution diagnostics, and audit packet secret omission rules. It does not yet have a single repository-local standard that explains how Codex and Claude Code context, token, cost, tool, compaction, and usage-limit behavior should be governed across multi-agent execution. The latest operator health check also surfaced a false online `branch_convention_violation:#` warning when there is no current PR to inspect.

This task must convert current public provider guidance into deterministic repository policy and status evidence. It must not reveal or store secrets, raw tokens, private prompts, billing details, or protected credentials.

## Source References

- `README.md` - product vision and current status.
- `SPECBRIDGE.md` - technical contract and control hierarchy.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active repository policy.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next-task guidance.
- `scripts/lib/runtime.ps1` - runtime launch budget and diagnostics implementation.
- `scripts/lib/intake-doctor.ps1` - doctor/fix-plan implementation.
- `scripts/specbridge.ps1` - CLI entry point.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `.claude/settings.json` - project Claude Code permission baseline.
- Anthropic Claude Code settings documentation, retrieved 2026-06-16.
- Anthropic Claude Code CLI reference, retrieved 2026-06-16.
- Anthropic Claude Code cost management documentation, retrieved 2026-06-16.
- Anthropic Claude Code MCP documentation, retrieved 2026-06-16.
- Anthropic Claude Code GitHub Actions documentation, retrieved 2026-06-16.
- Anthropic Claude API context window and prompt caching documentation, retrieved 2026-06-16.
- OpenAI Codex manual fetched with the local `openai-docs` skill helper on 2026-06-16.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task changes repository governance, status reporting, tests, and a small doctor diagnostic edge. It must remain read-only at runtime except for declared evidence artifacts and must not change billing, secrets, CI/CD security, authentication, authorization, dependency installation, cleanup enforcement, or deployment behavior.

## Allowed Scope

```text
.specbridge/contracts/issue-224-token-context-governance.execution.md
.specbridge/scopes/issue-224-token-context-governance.scope.json
.specbridge/policies/token-context-governance.json
.specbridge/reports/issue-224-token-context-governance.final-report.json
.specbridge/audit-packets/issue-224-token-context-governance.audit-packet.json
.specbridge/audits/issue-224-token-context-governance.chatgpt-audit.json
.specbridge/github-evidence/issue-224-token-context-governance.closure.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/token-governance/current.status.json
docs/specbridge-token-context-governance.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/token-governance.ps1
scripts/lib/intake-doctor.ps1
scripts/test-specbridge-cli.ps1
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
```

## Acceptance Criteria

1. A repository-local token/context governance policy artifact exists and records provider source URLs, retrieval date, SpecBridge standards, runtime limits, blocked disclosures, and audit evidence requirements.
2. A deterministic `specbridge-token-governance-status` CLI command exists.
3. The command returns valid JSON and performs no network calls, Claude launches, Codex launches, GitHub mutations, dependency installation, secret access, billing changes, cleanup enforcement, or deployment.
4. The command reports Codex context governance, Claude Code runtime governance, MCP/tool context governance, multi-agent slice governance, blocked disclosures, usage-limit handling, and evidence source paths.
5. The command is read-only when `-OutputPath` is omitted.
6. The command can optionally write `.specbridge/token-governance/current.status.json` through `-OutputPath` and requires `-Force` when replacing the artifact.
7. The command status must include explicit boundaries for `max_budget_usd`, `max_turns`, `no_session_persistence`, prompt/cache/compaction guidance, MCP tool search guidance, and provider-token secrecy.
8. Documentation explains how SpecBridge should manage Codex and Claude Code context, token/cost budget, usage-limit failures, MCP tool context, prompt caching/compaction, multi-agent slice prompts, and audit packets.
9. The doctor/fix-plan online mode no longer emits a `branch_convention_violation:#` warning when `gh pr list` returns no open PRs.
10. CLI regression coverage validates command shape, required fields, read-only behavior, output-path behavior, force behavior, bad path behavior, blocked disclosures, max budget policy, max turns policy, and the doctor no-open-PR false-warning edge.
11. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
12. Required validation scripts and full smoke pass locally and in GitHub Actions.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, provider tokens, private keys, raw hidden prompt export, raw chat transcript export, raw unbounded tool output export, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, branch cleanup enforcement, artifact retention enforcement, cleanup apply mode, changing operator decisions, reviving issue #194, or implementing the digital twin.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must use bounded non-interactive execution if invoked, with explicit budget, turn limit, no session persistence, and no dangerous permission bypass.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-224-token-context-governance.final-report.json`, `.specbridge/audit-packets/issue-224-token-context-governance.audit-packet.json`, and `.specbridge/audits/issue-224-token-context-governance.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when token/context governance status is implemented, the doctor false-warning edge is corrected, all required local validations pass, GitHub checks pass, PR closes issue #224, and post-merge closure evidence is recorded.
