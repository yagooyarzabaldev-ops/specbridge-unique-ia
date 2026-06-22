# Execution Contract: Issue 237 Governed Project Starter Standard

## Contract Metadata

- contract_id: issue-237-project-starter-standard
- run_id: sb-20260622-0237a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/237
- created_by: ChatGPT/Codex
- created_at: 2026-06-22
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Implement a deterministic, repository-local SpecBridge project starter standard so ChatGPT/Codex can turn a new product or project idea into an auditable starter package before any real implementation, dependency installation, deployment, billing, secrets, or external repository mutation occurs.

## Context

SpecBridge is ready for governed task intake after issue #234. The next useful product standard is a safe project-starting surface: a command that records a future project's initial intent, MVP boundaries, blocked scope, agent architecture, validation plan, security posture, and next SpecBridge steps as a machine-readable artifact.

This task must help future projects such as blockchain, WhatsApp/MercadoLibre AI, or marketing automation be specified safely before code is built. It must not create external repositories, install dependencies, call networks, deploy, mutate billing, or handle secrets.

## Source References

- `README.md` - current product status and user-facing command index.
- `SPECBRIDGE.md` - technical contract, stop conditions, and context package rules.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active policy and blocked paths.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next recommended task.
- `scripts/specbridge.ps1` - CLI routing.
- `scripts/lib/common.ps1` - UTF-8 helpers and shared CLI helpers.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- `docs/specbridge-standard-readiness-status.md` - current readiness standard.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task adds a new CLI surface and generated artifact family. It must remain local, deterministic, read-only except for the declared output artifact path, and free of secrets, network calls, deployment, billing, authentication, authorization, database, dependency, and CI/CD security changes.

## Allowed Scope

```text
.specbridge/contracts/issue-237-project-starter-standard.execution.md
.specbridge/scopes/issue-237-project-starter-standard.scope.json
.specbridge/reports/issue-237-project-starter-standard.final-report.json
.specbridge/audit-packets/issue-237-project-starter-standard.audit-packet.json
.specbridge/audits/issue-237-project-starter-standard.chatgpt-audit.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/standard-readiness/current.status.json
.specbridge/project-starters/*.project-starter.json
README.md
docs/specbridge-project-starter-standard.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/artifact-inventory.ps1
scripts/lib/project-starter.ps1
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
external repository creation
external repository mutation
network calls from the project starter command
real billing configuration
provider account configuration
API key or token storage
secret access
raw hidden prompt export
raw chat transcript export
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
mutation-capable MCP tools
network MCP transport
hosted MCP server deployment
branch deletion
branch pruning
branch renaming
branch movement
branch archival
fetch or pull for cleanup
force-push
artifact deletion
artifact movement
artifact compression
artifact archival
artifact upload
cleanup apply mode
retention enforcement
issue #194 lifecycle changes
digital twin implementation
unbounded Claude Code token spending
```

## Acceptance Criteria

1. A deterministic local CLI command exists for creating project starter artifacts.
2. The command writes only under `.specbridge/project-starters/*.project-starter.json` when an output path is provided.
3. The artifact includes project identity, goal, target users, MVP scope, explicit non-goals, blocked scope, suggested SpecBridge specs, agent architecture, validation plan, security review prompts, next steps, and policy boundaries.
4. Missing or invalid required inputs fail with deterministic JSON/CLI errors.
5. The implementation uses UTF-8 helpers and avoids PS 5.1 encoding traps.
6. CLI tests cover successful generation, missing required input rejection, invalid output path rejection, and artifact content shape.
7. Documentation explains how the project starter standard is used before building real projects.
8. README/current goal/readiness/dashboard evidence is updated where appropriate.
9. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
10. Required local validations pass before PR creation.

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

Stop if the task requires secrets, provider tokens, private keys, raw hidden prompt export, raw chat transcript export, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, mutation-capable MCP tools, network MCP transport, branch/artifact cleanup enforcement, changing issue #194 lifecycle, implementing the digital twin, or unbounded Claude Code token spending.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must use bounded non-interactive execution with explicit budget, no session persistence, and no dangerous permission bypass.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-237-project-starter-standard.final-report.json`, `.specbridge/audit-packets/issue-237-project-starter-standard.audit-packet.json`, and `.specbridge/audits/issue-237-project-starter-standard.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the project starter standard is implemented, required local validations pass, GitHub checks pass, PR closes issue #237, and post-merge closure evidence is recorded.
