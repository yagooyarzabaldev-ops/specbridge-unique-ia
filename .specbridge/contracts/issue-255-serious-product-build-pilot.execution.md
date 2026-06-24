# Execution Contract: Issue 255 SpecBridge v2 Serious Product-Build Pilot

## Contract Metadata

- contract_id: issue-255-serious-product-build-pilot
- run_id: sb-20260624-0255c0de
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/255
- created_by: ChatGPT/Codex
- created_at: 2026-06-24
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Use SpecBridge v1 as the governing control plane to build a separate local `specbridge-v2` repository MVP, delegate the first implementation pass to Claude Code where possible, then complete validation and evidence with Codex.

## Context

SpecBridge v1 is stable enough to run the next serious product-build pilot. The user asked to create SpecBridge v2 in a new repository so experimental implementation cannot damage the v1 repository, and asked to spend Claude Code execution first where feasible before Codex continues.

This contract authorizes a local sibling repository workspace at `D:\Antigravity\Infinite Process\specbridge-v2` for the initial MVP only. SpecBridge v1 remains the governance and evidence source. External GitHub repository creation and external repository mutation remain blocked for this contract.

## Source References

- `README.md` - current SpecBridge status and next recommended serious product-build pilot.
- `SPECBRIDGE.md` - control hierarchy, contracts, quality gates, and stop conditions.
- `AGENTS.md` - repository operating rules and active stage requirements.
- `.specbridge/policy.yaml` - protected paths, stop conditions, quality gates, and apply-mode boundaries.
- `.specbridge/context/CURRENT_GOAL.md` - current next recommended task.
- `.specbridge/project-starters/serious-product-build-pilot.project-starter.json` - approved starter package for the v2 pilot.
- `docs/specbridge-project-starter-standard.md` - starter safety boundary.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task creates a separate local repository and launches Claude Code for bounded implementation. Risk is limited by local-only scope, no dependency installation, no external GitHub repository creation, no deployment, no secrets, no production configuration, and evidence captured back into SpecBridge v1.

## Allowed Scope

```text
.specbridge/project-starters/serious-product-build-pilot.project-starter.json
.specbridge/contracts/issue-255-serious-product-build-pilot.execution.md
.specbridge/scopes/issue-255-serious-product-build-pilot.scope.json
.specbridge/github-evidence/issue-255-serious-product-build-pilot.issue.json
.specbridge/runtime-evidence/issue-255-specbridge-v2-claude-output.md
.specbridge/reports/issue-255-serious-product-build-pilot.final-report.json
.specbridge/audit-packets/issue-255-serious-product-build-pilot.audit-packet.json
.specbridge/audits/issue-255-serious-product-build-pilot.chatgpt-audit.json
docs/specbridge-v2-product-build-pilot.md
D:\Antigravity\Infinite Process\specbridge-v2
```

The sibling `specbridge-v2` repository may contain only local MVP files for:

```text
README.md
AGENTS.md
.gitignore
.specbridge/context/*
.specbridge/contracts/*
.specbridge/scopes/*
.specbridge/reports/*
src/*
tests/*
scripts/*
```

## Blocked Scope

```text
GitHub repository creation for specbridge-v2
external repository mutation for specbridge-v2
dependency installation
package manager lockfile generation from installation
hosted runtime
network MCP transport
mutation-capable MCP tools
Qwen-AgentWorld integration
secrets or private keys
.env
.env.*
production configuration
billing or payment-provider configuration
provider account configuration
authentication implementation
authorization implementation
database changes
CI/CD workflow changes
.github/workflows/**
deployment automation
production deployment
branch cleanup enforcement
artifact retention enforcement
changes outside the listed v1 governance artifacts and the local v2 workspace
```

## Acceptance Criteria

1. SpecBridge v1 records the project starter, execution contract, scope manifest, GitHub issue evidence, implementation evidence, final report, audit packet, and ChatGPT/Codex audit for issue #255.
2. A separate local `specbridge-v2` repository exists outside the v1 repository.
3. The first implementation pass for `specbridge-v2` is attempted with Claude Code before Codex-side completion work.
4. The v2 MVP includes an operational README, AGENTS instructions, local context, at least one execution contract, at least one scope manifest, a validation command or script, a final report example, source code, and tests.
5. The v2 MVP validates locally without dependency installation, secrets, network services, GitHub repository creation, CI/CD workflow changes, deployment, production configuration, billing, authentication, authorization, or database changes.
6. SpecBridge v1 documentation explains the v2 pilot boundary and how v1 governed the separate repo experiment.
7. Required validations pass, or failures are recorded with exact blockers.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v2\scripts\test.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, dependency installation, external repository creation, external repository mutation beyond issue #255 evidence, production configuration, billing, provider account configuration, authentication, authorization, database changes, CI/CD workflow changes, deployment, Qwen-AgentWorld integration, hosted MCP/runtime work, mutation-capable MCP tools, cleanup enforcement, contradictory acceptance criteria, impossible validation, or writes outside the declared v1 artifacts and local v2 workspace.

## Merge Policy

No autonomous merge is performed by this contract. Any v1 PR merge requires local validations, GitHub CI, policy checks, review gate, no protected file changes, and explicit operator merge authority.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-255-serious-product-build-pilot.final-report.json`, `.specbridge/audit-packets/issue-255-serious-product-build-pilot.audit-packet.json`, and `.specbridge/audits/issue-255-serious-product-build-pilot.chatgpt-audit.json`. The report must state summary, changed files, v2 workspace files, validations, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the v2 local MVP exists, Claude Code implementation evidence is captured, Codex has completed any needed bounded fixes, v1 and v2 validations pass or exact blockers are recorded, and issue #255 evidence is auditable from the final report.
