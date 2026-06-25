# Execution Contract: Issue 260 SpecBridge v2 Release Readiness Hardening

## Contract Metadata

- contract_id: issue-260-specbridge-v2-release-readiness-hardening
- run_id: sb-20260625-0260cafe
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/260
- created_by: ChatGPT/Codex
- created_at: 2026-06-25
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Harden SpecBridge v2 into a release-ready static MVP by adding versioned
readiness evidence, rollback/release documentation, adversarial validator
coverage, and explicit v2 policy authorization for the issue #260 normal
non-force push. Use Claude Code first for the implementation attempt, then
Codex reviews, repairs if needed, validates, pushes, verifies CI, and records
v1 evidence.

## Context

SpecBridge v2 currently validates execution contracts and scope manifests
locally on PowerShell 5.1. The bootstrap, operational-hardening,
cross-reference-validation, and operation-report-hardening phases are complete
and CI is green. The next solidification step is release readiness for the
static MVP: make the current version and readiness posture machine-readable,
document the release/rollback path, and add adversarial tests for validator
edge cases without modifying CI, installing dependencies, introducing runtime
execution, or changing the existing report schema and exit-code contract.

## Source References

- `README.md` - SpecBridge operating model and current status.
- `SPECBRIDGE.md` - execution contracts, quality gates, and final report requirements.
- `AGENTS.md` - repository operating rules and non-interruption principle.
- `.specbridge/policy.yaml` - protected paths, stop conditions, quality gates, and merge policy.
- `.specbridge/context/CURRENT_GOAL.md` - recommends serious product-build pilots and governed next work.
- `D:\Antigravity\Infinite Process\specbridge-v2\README.md` - v2 usage and validator contract.
- `D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md` - v2 policy boundaries and push authorization model.
- `D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md` - completed operation-report hardening phase and next-phase placeholder.
- `D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1` - v2 validator.
- `D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1` - v2 local test suite.
- `D:\Antigravity\Infinite Process\specbridge-v2\docs\operations.md` - v2 operations guide.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. This task may modify the v2 validator, tests, documentation, context,
and policy boundary notes. It does not authorize secrets, production
configuration, billing, authentication, authorization, databases, dependency
installation, CI workflow changes, deployment automation, hosted runtimes,
repository visibility changes, branch deletion, force push, or external AI
provider integration.

## Allowed Scope

```text
.specbridge/contracts/issue-260-specbridge-v2-release-readiness-hardening.execution.md
.specbridge/scopes/issue-260-specbridge-v2-release-readiness-hardening.scope.json
.specbridge/github-evidence/issue-260-specbridge-v2-release-readiness-hardening.issue.json
.specbridge/github-evidence/issue-260-specbridge-v2-release-readiness-hardening.repo.json
.specbridge/github-evidence/issue-260-specbridge-v2-release-readiness-hardening.ci.json
.specbridge/runtime-evidence/issue-260-specbridge-v2-claude-output.md
.specbridge/reports/issue-260-specbridge-v2-release-readiness-hardening.final-report.json
.specbridge/audit-packets/issue-260-specbridge-v2-release-readiness-hardening.audit-packet.json
.specbridge/audits/issue-260-specbridge-v2-release-readiness-hardening.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v2\src\specbridge_v2.ps1
D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1
D:\Antigravity\Infinite Process\specbridge-v2\README.md
D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md
D:\Antigravity\Infinite Process\specbridge-v2\VERSION
D:\Antigravity\Infinite Process\specbridge-v2\docs\operations.md
D:\Antigravity\Infinite Process\specbridge-v2\docs\release-readiness.md
D:\Antigravity\Infinite Process\specbridge-v2\docs\rollback.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\readiness\current.status.json
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\DO_NOT_TOUCH.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\contracts\release-readiness-hardening.execution.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\scopes\release-readiness-hardening.scope.json
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
adding deployment or publish automation
shrinking required contract sections
shrinking required scope fields
runtime operation execution or sandbox implementation
```

## Acceptance Criteria

1. v2 has a dedicated `release-readiness-hardening.execution.md` contract and `release-readiness-hardening.scope.json` scope manifest.
2. v2 has a `VERSION` file and a machine-readable `.specbridge/readiness/current.status.json` artifact documenting the static MVP readiness posture, current version, validation commands, release boundaries, rollback reference, and known blocked boundaries.
3. v2 documentation explains release readiness, rollback, branch-protection limitation, and the fact that runtime operation enforcement remains future scope.
4. The validator correctly detects array field syntax when JSON property names use valid escaped characters.
5. The validator rejects rooted or parent-traversal `forbidden_paths` entries instead of treating them as valid protected declarations.
6. The validator rejects allowed or forbidden operation names with leading or trailing whitespace.
7. Existing valid scopes, including bootstrap, operational-hardening, cross-reference-validation, operation-report-hardening, and release-readiness-hardening, still validate successfully.
8. The JSON report keeps existing top-level fields and nested validation fields.
9. The exit-code contract remains unchanged: 0 pass, 1 validation failure, 2 fatal/usage error.
10. v2 tests add coverage for the readiness artifact, release docs, escaped property-name parsing, forbidden path traversal/rooting, operation whitespace, and the new contract/scope pair.
11. v2 changes are committed and pushed normally to `origin/master`; GitHub Actions CI passes.
12. SpecBridge v1 records Claude output evidence, repository/CI evidence, final report, audit packet, and ChatGPT/Codex audit.
13. Required v1 validations pass locally, or exact blockers are recorded.

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

Stop if the task requires secrets, dependency installation, production
configuration, billing, provider account configuration, authentication,
authorization, database changes, deployment automation, workflow security
changes, public visibility, force push, branch deletion, remote deletion,
destructive cleanup, hosted MCP/runtime work, mutation-capable MCP tools,
cleanup enforcement, retention enforcement, Qwen-AgentWorld integration,
runtime operation execution, contradictory acceptance criteria, impossible
validation, or writes outside the declared v1 artifacts and v2 files.

## Merge Policy

No autonomous merge into v1 `main` is performed by this contract. V1 evidence
merge requires a pull request, GitHub CI, review gate, no protected file
changes, and explicit operator merge authority.

The v2 `master` branch may receive one normal non-force push after local v2
tests pass because this contract is the dedicated execution contract required
by v2 policy for future pushes. No force push, branch deletion, remote
deletion, repository visibility change, or CI workflow change is allowed.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-260-specbridge-v2-release-readiness-hardening.final-report.json`, `.specbridge/audit-packets/issue-260-specbridge-v2-release-readiness-hardening.audit-packet.json`, and `.specbridge/audits/issue-260-specbridge-v2-release-readiness-hardening.chatgpt-audit.json`. The report must include summary, changed files, v2 pushed commit, validations, CI status, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v2 release/readiness artifacts and adversarial
validator coverage are implemented, tested locally, pushed, validated by
GitHub Actions, reviewed by Codex, and v1 evidence passes required validators
or exact blockers are documented.
