# Execution Contract: Issue 259 SpecBridge v2 Operation and Report Hardening

## Contract Metadata

- contract_id: issue-259-specbridge-v2-operation-report-hardening
- run_id: sb-20260625-0259fade
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/259
- created_by: ChatGPT/Codex
- created_at: 2026-06-25
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Continue SpecBridge v2 hardening by implementing the next declared solidification phase: operation-list validation and explicit report-schema regression evidence. Use Claude Code first for the implementation attempt, then Codex reviews, repairs if needed, validates, pushes, verifies CI, and records v1 evidence.

## Context

SpecBridge v2 already has a local validator, CI, operational hardening, and cross-reference validation. Its current goal lists operation-list enforcement and additional report-schema evidence as the next candidates. This contract authorizes a bounded implementation of both, without changing the public exit-code contract or removing/renaming existing report fields.

## Source References

- `README.md` - SpecBridge operating model and current status.
- `SPECBRIDGE.md` - execution contracts, quality gates, and final report requirements.
- `AGENTS.md` - repository operating rules and non-interruption principle.
- `.specbridge/policy.yaml` - protected paths, stop conditions, quality gates, and merge policy.
- `.specbridge/context/CURRENT_GOAL.md` - recommends serious product-build pilots and governed next work.
- `D:\Antigravity\Infinite Process\specbridge-v2\README.md` - v2 usage and validator contract.
- `D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md` - v2 policy boundaries.
- `D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md` - completed cross-reference phase and next candidates.
- `D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1` - v2 validator.
- `D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1` - v2 local test suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. This task modifies the v2 validator, tests, and documentation, but it does not change secrets, production configuration, billing, authentication, authorization, databases, deployment automation, dependency installation, hosted runtimes, repository visibility, or CI workflow security.

## Allowed Scope

```text
.specbridge/contracts/issue-259-specbridge-v2-operation-report-hardening.execution.md
.specbridge/scopes/issue-259-specbridge-v2-operation-report-hardening.scope.json
.specbridge/github-evidence/issue-259-specbridge-v2-operation-report-hardening.issue.json
.specbridge/github-evidence/issue-259-specbridge-v2-operation-report-hardening.repo.json
.specbridge/github-evidence/issue-259-specbridge-v2-operation-report-hardening.ci.json
.specbridge/runtime-evidence/issue-259-specbridge-v2-claude-output.md
.specbridge/reports/issue-259-specbridge-v2-operation-report-hardening.final-report.json
.specbridge/audit-packets/issue-259-specbridge-v2-operation-report-hardening.audit-packet.json
.specbridge/audits/issue-259-specbridge-v2-operation-report-hardening.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1
D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1
D:\Antigravity\Infinite Process\specbridge-v2\README.md
D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md
D:\Antigravity\Infinite Process\specbridge-v2\docs\operations.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\DO_NOT_TOUCH.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\contracts\operation-report-hardening.execution.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\scopes\operation-report-hardening.scope.json
```

The only authorized remote repository target is:

```text
https://github.com/yagooyarzabaldev-ops/specbridge-v2
```

## Blocked Scope

```text
secrets
.env
.env.*
private keys
dependency installation
package manager execution
production configuration
billing configuration
authentication implementation
authorization implementation
database changes
deployment automation
hosted runtime
mutation-capable MCP tools
Qwen-AgentWorld integration
external AI provider integration
public repository visibility
force push
branch deletion
remote deletion
destructive cleanup
CI workflow security changes
.github/workflows/**
changing validator exit codes 0/1/2
removing or renaming existing report fields
shrinking required contract sections
shrinking required scope fields
```

## Acceptance Criteria

1. v2 has a dedicated `operation-report-hardening.execution.md` contract and `operation-report-hardening.scope.json` scope manifest.
2. `src/specbridge_v2.ps1` rejects required array fields when a field is not a JSON array.
3. `src/specbridge_v2.ps1` rejects blank or non-string entries in `allowed_paths`, `forbidden_paths`, and `allowed_operations`.
4. `src/specbridge_v2.ps1` validates optional `forbidden_operations` as an array of non-blank strings when present.
5. `src/specbridge_v2.ps1` rejects duplicate operation names and rejects any operation listed in both `allowed_operations` and `forbidden_operations`, using case-insensitive comparison.
6. Existing valid scopes, including bootstrap, operational-hardening, and cross-reference-validation, still validate successfully.
7. The JSON report keeps existing top-level fields and nested validation fields.
8. The exit-code contract remains unchanged: 0 pass, 1 validation failure, 2 fatal/usage error.
9. v2 tests add coverage for operation-list failures, report-schema regression, and the new contract/scope pair.
10. v2 changes are committed and pushed normally to `origin/master`; GitHub Actions CI passes.
11. SpecBridge v1 records Claude output evidence, repository/CI evidence, final report, audit packet, and ChatGPT/Codex audit.
12. Required v1 validations pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v2\scripts\test.ps1
git diff --check
gh run view <run-id> --repo yagooyarzabaldev-ops/specbridge-v2 --json databaseId,headSha,status,conclusion,url,createdAt,updatedAt,name,displayTitle,event,jobs
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, dependency installation, production configuration, billing, provider account configuration, authentication, authorization, database changes, deployment automation, workflow security changes, public visibility, force push, branch deletion, remote deletion, destructive cleanup, hosted MCP/runtime work, mutation-capable MCP tools, cleanup enforcement, retention enforcement, Qwen-AgentWorld integration, contradictory acceptance criteria, impossible validation, or writes outside the declared v1 artifacts and v2 files.

## Merge Policy

No autonomous merge into v1 `main` is performed by this contract. V1 evidence merge requires a pull request, GitHub CI, review gate, no protected file changes, and explicit operator merge authority.

The v2 `master` branch may receive a normal non-force push after local v2 tests pass because this contract is the dedicated execution contract required by v2 policy for future pushes. No force push, branch deletion, remote deletion, or repository visibility change is allowed.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-259-specbridge-v2-operation-report-hardening.final-report.json`, `.specbridge/audit-packets/issue-259-specbridge-v2-operation-report-hardening.audit-packet.json`, and `.specbridge/audits/issue-259-specbridge-v2-operation-report-hardening.chatgpt-audit.json`. The report must include summary, changed files, v2 pushed commit, validations, CI status, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v2 operation-list validation and report-schema regression coverage are implemented, tested locally, pushed, validated by GitHub Actions, reviewed by Codex, and v1 evidence passes required validators or exact blockers are documented.
