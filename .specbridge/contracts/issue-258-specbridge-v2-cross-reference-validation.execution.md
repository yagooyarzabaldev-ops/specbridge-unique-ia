# Execution Contract: Issue 258 SpecBridge v2 Cross-Reference Validation

## Contract Metadata

- contract_id: issue-258-specbridge-v2-cross-reference-validation
- run_id: sb-20260624-0258cafe
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/258
- created_by: ChatGPT/Codex
- created_at: 2026-06-24
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Continue SpecBridge v2 by implementing the next declared phase: cross-reference validation for scope manifests. The validator must reject missing `allowed_paths` entries and reject tracked files that match `forbidden_paths` patterns, while preserving the existing exit-code contract and report schema.

## Context

SpecBridge v2 has a local MVP validator, operational hardening, a private GitHub repository, and passing CI. Its current goal explicitly declares the next phase as cross-reference checking: verify that every path listed in `allowed_paths` exists under the repository root and that no `forbidden_paths` pattern is currently matched by any tracked file.

This contract authorizes a bounded implementation of that phase in `D:\Antigravity\Infinite Process\specbridge-v2`. Claude Code should be used first for the implementation attempt, then Codex reviews, repairs if needed, validates, pushes, and records evidence.

## Source References

- `README.md` - SpecBridge operating model and CI/review role.
- `SPECBRIDGE.md` - execution contracts, quality gates, and final report requirements.
- `AGENTS.md` - active repository working method and protected boundaries.
- `.specbridge/policy.yaml` - active protected paths and stop conditions.
- `.specbridge/contracts/issue-257-finish-specbridge-v2-hardening.execution.md` - v2 operational hardening baseline.
- `.specbridge/reports/issue-257-finish-specbridge-v2-hardening.final-report.json` - v2 CI and branch-protection evidence.
- `D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1` - v2 validator.
- `D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1` - v2 local test suite.
- `D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md` - declares the next phase.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. This task modifies the v2 core validator and tests, but it does not change secrets, production configuration, billing, authentication, authorization, databases, deployment, dependency installation, hosted runtimes, or CI workflow security.

## Allowed Scope

```text
.specbridge/contracts/issue-258-specbridge-v2-cross-reference-validation.execution.md
.specbridge/scopes/issue-258-specbridge-v2-cross-reference-validation.scope.json
.specbridge/github-evidence/issue-258-specbridge-v2-cross-reference-validation.issue.json
.specbridge/github-evidence/issue-258-specbridge-v2-cross-reference-validation.repo.json
.specbridge/github-evidence/issue-258-specbridge-v2-cross-reference-validation.ci.json
.specbridge/runtime-evidence/issue-258-specbridge-v2-claude-output.md
.specbridge/reports/issue-258-specbridge-v2-cross-reference-validation.final-report.json
.specbridge/audit-packets/issue-258-specbridge-v2-cross-reference-validation.audit-packet.json
.specbridge/audits/issue-258-specbridge-v2-cross-reference-validation.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1
D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1
D:\Antigravity\Infinite Process\specbridge-v2\README.md
D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md
D:\Antigravity\Infinite Process\specbridge-v2\docs\operations.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\DO_NOT_TOUCH.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\contracts\cross-reference-validation.execution.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\scopes\cross-reference-validation.scope.json
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

1. v2 has a dedicated `cross-reference-validation.execution.md` contract and `cross-reference-validation.scope.json` scope manifest.
2. `src/specbridge_v2.ps1` rejects a scope whose `allowed_paths` includes a missing file or directory under the repository root.
3. `src/specbridge_v2.ps1` rejects a scope whose `forbidden_paths` pattern matches any tracked repository file.
4. Existing valid scopes, including bootstrap and operational-hardening, still validate successfully.
5. The JSON report keeps existing top-level fields and existing `contract_validation` and `scope_validation` fields.
6. The exit-code contract remains unchanged: 0 pass, 1 validation failure, 2 fatal/usage error.
7. v2 tests include additive coverage for both cross-reference failure modes and pass locally.
8. v2 changes are committed and pushed normally to `origin/master`; GitHub Actions CI passes.
9. SpecBridge v1 records Claude output evidence, repository/CI evidence, final report, audit packet, and ChatGPT/Codex audit.
10. Required v1 validations pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v2\scripts\test.ps1
git diff --check
gh run list --repo yagooyarzabaldev-ops/specbridge-v2 --limit 5 --json databaseId,status,conclusion,workflowName,headSha,createdAt,url
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

The v2 `master` branch may receive a normal non-force push after local v2 tests pass because this contract is the dedicated execution contract required by v2 policy for future pushes. No force push, branch deletion, or remote deletion is allowed.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-258-specbridge-v2-cross-reference-validation.final-report.json`, `.specbridge/audit-packets/issue-258-specbridge-v2-cross-reference-validation.audit-packet.json`, and `.specbridge/audits/issue-258-specbridge-v2-cross-reference-validation.chatgpt-audit.json`. The report must include summary, changed files, v2 pushed commit, validations, CI status, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v2 cross-reference validation is implemented, tested locally, pushed, validated by GitHub Actions, reviewed by Codex, and v1 evidence passes required validators or exact blockers are documented.
