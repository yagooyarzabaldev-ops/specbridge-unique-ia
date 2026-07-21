# Execution Contract: SpecBridge Unique IA Single-Agent Product Build

## Contract Metadata

- contract_id: specbridge-unique-ia-single-agent-build
- run_id: sb-20260720-270a1b2c
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/270
- created_by: ChatGPT/Codex
- created_at: 2026-07-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Create a clean local sibling repository named `specbridge-unique-ia` from the committed SpecBridge snapshot and implement a provider-neutral single-agent operating model. One configured AI executable must handle planning, implementation, validation follow-up, fresh-session review, and closure without requiring a different AI product.

## Context

The user asked for a new copy of SpecBridge that performs the full governed workflow with one AI, regardless of provider, and explicitly asked Claude Code to perform the implementation pass. The current SpecBridge worktree contains unfinished issue #267 changes, so the sibling must be created from committed `HEAD` and must not copy uncommitted state.

Fresh invocations of the same configured provider may be used to reduce context bias, but switching provider identity within one run is forbidden. Deterministic policy, scope validation, tests, git evidence, and explicit human authority remain independent gates. Same-provider review must not be represented as independent multi-model review.

## Source References

- `README.md` - current product capabilities and operating model.
- `SPECBRIDGE.md` - contracts, stop conditions, gates, and evidence standard.
- `AGENTS.md` - repository rules and PowerShell 5.1 parity requirements.
- `.specbridge/policy.yaml` - protected paths and blocked boundaries.
- `.specbridge/context/CURRENT_GOAL.md` - repository phase and maintenance posture.
- `.specbridge/project-starters/specbridge-unique-ia-single-agent.project-starter.json` - approved starter.
- `.specbridge/contracts/issue-255-serious-product-build-pilot.execution.md` - governed sibling-build precedent.
- `docs/specbridge-standard-loop-v1.md` - lifecycle and evidence phases to preserve.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task creates a separate local repository and launches Claude Code for a substantial bounded implementation. The blast radius is limited by a committed local source snapshot, no remote creation or mutation, no dependency installation, no secrets, no production, no deployment, and a dedicated sibling path.

## Allowed Scope

```text
.specbridge/project-starters/specbridge-unique-ia-single-agent.project-starter.json
.specbridge/contracts/specbridge-unique-ia-single-agent-build.execution.md
.specbridge/scopes/specbridge-unique-ia-single-agent-build.scope.json
.specbridge/runtime-evidence/specbridge-unique-ia-claude-output.md
.specbridge/reports/specbridge-unique-ia-single-agent-build.final-report.json
.specbridge/audit-packets/specbridge-unique-ia-single-agent-build.audit-packet.json
.specbridge/audits/specbridge-unique-ia-single-agent-build.chatgpt-audit.json
docs/specbridge-unique-ia-product-build.md
D:\Antigravity\Infinite Process\specbridge-unique-ia
```

The sibling repository may modify copied files only as needed for the MVP. Primary product paths are `README.md`, `AGENTS.md`, `SPECBRIDGE.md`, `.gitignore`, `.unique-ai/**`, `.specbridge/context/**`, `.specbridge/contracts/**`, `.specbridge/scopes/**`, `.specbridge/reports/**`, `docs/**`, `scripts/**`, and `tests/**`.

## Blocked Scope

```text
uncommitted source worktree content
issue #267 files or changes
GitHub repository creation
remote configuration fetch pull push or mutation
dependency or provider SDK installation
package manager execution
provider account configuration
secret or private key access
.env
.env.*
production configuration
billing or payments
authentication or authorization security
database changes
CI/CD workflow or security changes
.github/workflows/**
hosted runtime
network MCP transport
deployment automation
production deployment
branch deletion pruning renaming or force push
source-repository cleanup enforcement
autonomous merge
changes outside declared v1 evidence files and sibling workspace
```

## Acceptance Criteria

1. A separate local git repository exists at `D:\Antigravity\Infinite Process\specbridge-unique-ia` and originates from committed SpecBridge `HEAD`, not the dirty source worktree.
2. Claude Code performs the first implementation pass inside the sibling before Codex makes product-code fixes.
3. Documentation names the product SpecBridge Unique IA and states that one configured AI provider handles the full lifecycle.
4. Configuration pins one provider identity and executable command for the entire run; phase-level provider switching is rejected.
5. A provider-neutral command adapter invokes the executable without importing a provider SDK or installing dependencies.
6. The lifecycle covers plan, implement, validate, fresh-session review, and close with structured artifacts and resumable state.
7. Default execution is dry-run or plan-only; provider invocation requires an explicit apply/force gate.
8. Scope, protected paths, blocked operations, timeout, retry, and budget metadata are enforced or fail closed before execution.
9. Same-provider review is labeled fresh-session self-review, not independent multi-model review.
10. Deterministic validations remain authoritative; the provider cannot self-certify completion.
11. A doctor/status command reports configuration, repository, executable discovery, policy, and resumable-run health without calling the provider.
12. Tests cover happy path, no-write dry-run, provider-lock rejection, blocked path rejection, failed validation, failed provider invocation, resume behavior, and evidence shape.
13. README, architecture documentation, example configuration, bootstrap contract/scope, and rollback guidance exist.
14. No remote repository, dependency installation, secrets, production, billing, auth, database, CI/CD security, hosted runtime, or deployment changes occur.
15. Required validations pass, or exact blockers are recorded without claiming completion.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-unique-ia\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-unique-ia\scripts\unique-ai.ps1 doctor
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-unique-ia\scripts\unique-ai.ps1 plan -TaskId smoke-single-agent -Title "Smoke single agent" -Goal "Prove deterministic plan-only lifecycle"
git -C "D:\Antigravity\Infinite Process\specbridge-unique-ia" diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
```

## Stop Conditions

Stop if the work requires secrets, provider credentials, dependency installation, provider SDK installation, remote creation or mutation, production configuration, billing, authentication, authorization, database changes, CI/CD workflow changes, deployment, hosted runtime, network MCP transport, destructive cleanup, copying issue #267 uncommitted state, contradictory acceptance criteria, impossible validation, or writes outside the declared v1 evidence files and sibling workspace.

## Merge Policy

No autonomous merge is authorized. The sibling remains local. Future remote publication, PR, branch protection, or merge requires a separate contract and explicit operator authority.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/specbridge-unique-ia-single-agent-build.final-report.json`, `.specbridge/audit-packets/specbridge-unique-ia-single-agent-build.audit-packet.json`, and `.specbridge/audits/specbridge-unique-ia-single-agent-build.chatgpt-audit.json`. Report summary, changed files, sibling state, Claude evidence, validations, policy result, review result, merge status, deployment status, risks, rollback, and completion status.

## Completion Rule

The task is complete only when the sibling exists, Claude Code implementation evidence is captured, Codex has audited the result, acceptance criteria are satisfied, required validations pass or exact blockers are recorded, and no blocked boundary was crossed.
