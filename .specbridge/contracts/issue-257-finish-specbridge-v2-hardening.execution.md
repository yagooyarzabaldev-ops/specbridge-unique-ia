# Execution Contract: Issue 257 Finish SpecBridge v2 Operational Hardening

## Contract Metadata

- contract_id: issue-257-finish-specbridge-v2-hardening
- run_id: sb-20260624-0257c1ab
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/257
- created_by: ChatGPT/Codex
- created_at: 2026-06-24
- autonomy_profile: full_autopilot
- risk_level: high
- status: completed

## Goal

Finish the missing operational hardening for the private `specbridge-v2` repository by adding minimal CI validation, updating v2 policy/docs to reflect the remote repository boundary, pushing those changes, collecting GitHub evidence, and recording the outcome in SpecBridge v1.

## Context

Issue #255 created and validated the local SpecBridge v2 MVP. Issue #256 created the private remote repository and pushed the MVP to `yagooyarzabaldev-ops/specbridge-v2`. The remaining v2 gaps recorded in issue #256 are CI, collaborator/protection policy, and v1 evidence not yet merged.

The user has now requested: `Termina con todo lo faltante en v2`.

This contract authorizes only the bounded v2 operational hardening needed to remove the known v2 gaps. It does not authorize production deployment, dependency installation, secrets, billing, authentication, authorization, database changes, hosted runtimes, external AI integrations, or destructive repository operations.

## Source References

- `README.md` - SpecBridge operating model and CI/review role.
- `SPECBRIDGE.md` - execution contracts, policy gates, high-risk CI boundaries, and final report requirements.
- `AGENTS.md` - active repository working method and protected boundaries.
- `.specbridge/policy.yaml` - active protected paths and stop conditions.
- `.specbridge/contracts/issue-255-serious-product-build-pilot.execution.md` - v2 local build boundary.
- `.specbridge/contracts/issue-256-create-upload-specbridge-v2.execution.md` - v2 remote creation boundary.
- `.specbridge/reports/issue-256-create-upload-specbridge-v2.final-report.json` - unresolved v2 risks.
- `D:\Antigravity\Infinite Process\specbridge-v2` - v2 repository to harden.
- `https://github.com/yagooyarzabaldev-ops/specbridge-v2` - authorized v2 remote.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

High. This task authorizes a minimal CI/CD workflow addition in the separate v2 repository and a normal push to the private v2 remote. Risk is bounded by requiring no secrets, no write-token workflow permissions, no dependency installation, no deployment, no production configuration, no auth/billing/database changes, no force push, and auditable v1 evidence.

## Allowed Scope

```text
.specbridge/contracts/issue-257-finish-specbridge-v2-hardening.execution.md
.specbridge/scopes/issue-257-finish-specbridge-v2-hardening.scope.json
.specbridge/github-evidence/issue-257-finish-specbridge-v2-hardening.issue.json
.specbridge/github-evidence/issue-257-finish-specbridge-v2-hardening.repo.json
.specbridge/github-evidence/issue-257-finish-specbridge-v2-hardening.ci.json
.specbridge/reports/issue-257-finish-specbridge-v2-hardening.final-report.json
.specbridge/audit-packets/issue-257-finish-specbridge-v2-hardening.audit-packet.json
.specbridge/audits/issue-257-finish-specbridge-v2-hardening.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v2\.github\workflows\ci.yml
D:\Antigravity\Infinite Process\specbridge-v2\README.md
D:\Antigravity\Infinite Process\specbridge-v2\AGENTS.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\CURRENT_GOAL.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\DO_NOT_TOUCH.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\context\STYLE_GUIDE.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\contracts\operational-hardening.execution.md
D:\Antigravity\Infinite Process\specbridge-v2\.specbridge\scopes\operational-hardening.scope.json
D:\Antigravity\Infinite Process\specbridge-v2\docs\operations.md
D:\Antigravity\Infinite Process\specbridge-v2\tests\bootstrap.tests.ps1
```

The only authorized remote repository target is:

```text
https://github.com/yagooyarzabaldev-ops/specbridge-v2
```

## Blocked Scope

```text
public repository visibility
creating any repository other than yagooyarzabaldev-ops/specbridge-v2
force push
branch deletion
remote deletion
destructive cleanup
dependency installation
package manager execution
secrets
.env
.env.*
private keys
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
workflow steps that require repository write permissions
workflow steps that publish artifacts externally
workflow steps that use secrets
workflow steps that run package installation
```

## Acceptance Criteria

1. `specbridge-v2` contains a minimal GitHub Actions workflow that runs the existing PowerShell 5.1 test suite on push and pull request for `master`.
2. The v2 workflow uses read-only repository permissions and does not require secrets, package installation, deployment, hosted runtime setup, or external AI provider credentials.
3. v2 README, AGENTS instructions, current goal, and protected-file context clearly describe the remote/CI operational boundary.
4. v2 includes a dedicated operational-hardening contract and scope manifest for this phase.
5. v2 tests include additive coverage for the new operational artifacts and pass locally through `scripts/test.ps1`.
6. v2 changes are committed and pushed to `yagooyarzabaldev-ops/specbridge-v2` without force push.
7. A GitHub Actions run for the pushed v2 commit is observed when GitHub schedules it; if unavailable, the exact blocker is recorded.
8. Branch protection or ruleset status is queried or attempted only when it can be done without secrets, paid-feature assumptions, production changes, or CI weakening; success or blocker is recorded.
9. SpecBridge v1 records issue evidence, repository evidence, CI/protection evidence, final report, audit packet, and ChatGPT/Codex audit.
10. Required v1 validations pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v2\scripts\test.ps1
gh run list --repo yagooyarzabaldev-ops/specbridge-v2 --limit 5 --json databaseId,status,conclusion,workflowName,headSha,createdAt,url
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, dependency installation, production configuration, billing, provider account configuration, authentication, authorization, database changes, deployment automation, workflow write permissions, external artifact publishing, public visibility, repository mutation outside `yagooyarzabaldev-ops/specbridge-v2` and the current v1 evidence branch, force push, branch deletion, destructive cleanup, hosted MCP/runtime work, mutation-capable MCP tools, cleanup enforcement, retention enforcement, Qwen-AgentWorld integration, contradictory acceptance criteria, impossible validation, or writes outside the declared v1 artifacts and v2 files.

## Merge Policy

No autonomous merge into v1 `main` is performed by this contract. V1 evidence merge requires a pull request, GitHub CI, review gate, no protected file changes, and explicit operator merge authority.

The v2 `master` branch may receive the normal non-force push authorized by this contract because the repository was created specifically for this v2 pilot and has no branch protection yet. Any future protected branch policy must be recorded as separate evidence and must not weaken CI.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-257-finish-specbridge-v2-hardening.final-report.json`, `.specbridge/audit-packets/issue-257-finish-specbridge-v2-hardening.audit-packet.json`, and `.specbridge/audits/issue-257-finish-specbridge-v2-hardening.chatgpt-audit.json`. The report must include summary, changed files, remote repository URL, v2 pushed commit, CI/protection evidence, validations, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v2 CI and operational docs/policy are pushed, local v2 validation passes, GitHub CI/protection evidence is recorded when available, v1 evidence is recorded, and required local validations pass or exact blockers are documented.
