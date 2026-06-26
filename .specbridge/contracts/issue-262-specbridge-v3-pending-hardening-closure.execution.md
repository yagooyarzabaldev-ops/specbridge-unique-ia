# Execution Contract: Issue 262 SpecBridge v3 Pending Hardening Closure

## Contract Metadata

- contract_id: issue-262-specbridge-v3-pending-hardening-closure
- run_id: sb-20260626-0262feed
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/262
- created_by: ChatGPT/Codex
- created_at: 2026-06-26
- autonomy_profile: full_autopilot
- risk_level: high
- status: completed

## Goal

Close the v3 pending hardening items that can be finished safely under policy:
CI action pinning, branch protection attempt/evidence, and dependency-free local
operation-plan enforcement. Preserve v3 as a local-first static validator; do not
add hosted runtime, package dependencies, external providers, or mutation-capable
MCP tools.

## Context

Issue #261 created the private `specbridge-v3` repository and implemented a
local PowerShell 5.1 MVP with contract, scope, and structured minimalism-review
validation. Its final report left several residual risks: branch protection was
not configured, `actions/checkout@v4` was not SHA-pinned, runtime operation
enforcement remained future scope, and v1 evidence was not merged into main.

This contract authorizes only the v3 hardening work that can be completed
without crossing protected boundaries. For runtime enforcement, the authorized
scope is local operation-plan validation against scope `allowed_operations`,
`forbidden_operations`, and path boundaries. It does not authorize executing
those operations or mutating files from an operation plan.

## Source References

- `README.md` - SpecBridge operating model and current status.
- `SPECBRIDGE.md` - execution contracts, quality gates, and final report requirements.
- `AGENTS.md` - repository operating rules and non-interruption principle.
- `.specbridge/policy.yaml` - protected paths, stop conditions, quality gates, and merge policy.
- `.specbridge/context/CURRENT_GOAL.md` - current repository phase.
- `.specbridge/reports/issue-261-specbridge-v3-governed-product-build.final-report.json` - v3 residual risks.
- `D:\Antigravity\Infinite Process\specbridge-v3` - v3 repository to harden.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

High. This task changes the v3 GitHub Actions workflow, attempts GitHub branch
protection on the v3 repository, and updates a separate repository. The contract
explicitly authorizes only the v3 repository, the read-only v3 CI workflow, and
v1 evidence artifacts listed below.

## Allowed Scope

```text
.specbridge/contracts/issue-262-specbridge-v3-pending-hardening-closure.execution.md
.specbridge/scopes/issue-262-specbridge-v3-pending-hardening-closure.scope.json
.specbridge/github-evidence/issue-262-specbridge-v3-pending-hardening-closure.issue.json
.specbridge/github-evidence/issue-262-specbridge-v3-pending-hardening-closure.repo.json
.specbridge/github-evidence/issue-262-specbridge-v3-pending-hardening-closure.ci.json
.specbridge/github-evidence/issue-262-specbridge-v3-pending-hardening-closure.branch-protection.json
.specbridge/runtime-evidence/issue-262-specbridge-v3-hardening-output.md
.specbridge/reports/issue-262-specbridge-v3-pending-hardening-closure.final-report.json
.specbridge/audit-packets/issue-262-specbridge-v3-pending-hardening-closure.audit-packet.json
.specbridge/audits/issue-262-specbridge-v3-pending-hardening-closure.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v3
```

The only authorized external repository target is:

```text
https://github.com/yagooyarzabaldev-ops/specbridge-v3
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
external AI provider integration
mutation-capable MCP tools
public repository visibility
force push
branch deletion
remote deletion
destructive cleanup
CI workflow changes outside D:\Antigravity\Infinite Process\specbridge-v3\.github\workflows\ci.yml
changing SpecBridge v1 policy
merging into SpecBridge v1 main
executing operations from an operation plan
```

## Acceptance Criteria

1. v3 pins `actions/checkout` in `.github/workflows/ci.yml` to an immutable commit SHA, or exact blocker evidence is recorded.
2. v3 adds dependency-free local operation-plan validation that checks requested operations against scope `allowed_operations`, `forbidden_operations`, and repository-relative path boundaries without executing the operations.
3. v3 tests prove a valid operation plan passes and malformed/forbidden operation plans fail deterministically.
4. v3 readiness/docs record CI pinning, operation-plan enforcement, remaining blocked boundaries, and rollback notes.
5. v3 local tests pass with exit code 0.
6. v3 is committed and pushed normally to `origin/master`; no force push or branch deletion is performed.
7. GitHub Actions CI for v3 passes on the pushed commit.
8. Branch protection for v3 `master` is applied if supported by the repository permissions/plan, or exact blocker evidence is recorded.
9. SpecBridge v1 records issue, repo, CI, branch-protection, runtime, final report, audit packet, and ChatGPT/Codex audit evidence.
10. Required v1 validators pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v3\scripts\test.ps1
git diff --check
gh repo view yagooyarzabaldev-ops/specbridge-v3 --json nameWithOwner,url,visibility,defaultBranchRef,pushedAt,updatedAt
gh run view <run-id> --repo yagooyarzabaldev-ops/specbridge-v3 --json databaseId,headSha,status,conclusion,url,createdAt,updatedAt,name,displayTitle,event,jobs
gh api repos/yagooyarzabaldev-ops/specbridge-v3/branches/master/protection
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
```

## Stop Conditions

Stop if the work requires secrets, dependency installation, package manager
execution, production configuration, billing, authentication, authorization,
database changes, deployment automation, public repository visibility, hosted
runtime work, external provider integration, mutation-capable MCP tools,
force push, branch deletion, destructive cleanup, CI workflow mutation outside
the new v3 repository, repository mutation outside `yagooyarzabaldev-ops/specbridge-v3`
and the current v1 evidence branch, contradictory acceptance criteria,
impossible validation, or writes outside the declared v1 artifacts and v3 repo.

## Merge Policy

No autonomous merge into SpecBridge v1 `main` is performed by this contract.
V1 evidence merge requires a pull request, GitHub CI, review gate, no protected
file changes, and explicit operator merge authority.

The v3 `master` branch may receive a normal non-force push after local v3 tests
pass. No force push, branch deletion, remote deletion, public visibility change,
or deployment is allowed.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-262-specbridge-v3-pending-hardening-closure.final-report.json`, `.specbridge/audit-packets/issue-262-specbridge-v3-pending-hardening-closure.audit-packet.json`, and `.specbridge/audits/issue-262-specbridge-v3-pending-hardening-closure.chatgpt-audit.json`. The report must include summary, changed files, validations, CI status, branch protection result, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v3 operation-plan validation is implemented and
tested, the workflow action pinning is applied or blocker evidence is recorded,
branch protection is applied or blocker evidence is recorded, v3 local tests and
CI pass, and v1 evidence passes required validators or exact blockers are
documented.
