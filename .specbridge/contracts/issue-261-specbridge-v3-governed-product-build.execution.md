# Execution Contract: Issue 261 SpecBridge v3 Governed Product Build

## Contract Metadata

- contract_id: issue-261-specbridge-v3-governed-product-build
- run_id: sb-20260625-0261feed
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/261
- created_by: ChatGPT/Codex
- created_at: 2026-06-25
- autonomy_profile: full_autopilot
- risk_level: high
- status: completed

## Goal

Build SpecBridge v3 as a separate governed product repository that keeps what
adds real value from the Ponytail pattern: minimalism, reuse-first execution,
and anti-overbuild review. V3 must remain local-first, auditable, dependency-free
for the MVP, and useful as the next product-build pilot after v2.

## Context

SpecBridge v2 is a release-ready static MVP. It validates contracts and scopes,
has local tests, GitHub CI, release-readiness evidence, rollback docs, and
governed v1 evidence. The next user request is to create a v3 with everything
that actually adds value.

Ponytail's useful contribution is not a runtime dependency. Its useful
contribution is a decision discipline: avoid unnecessary code, reuse existing
code, prefer standard/native capabilities, avoid speculative abstractions, and
preserve safety, validation, security, and accessibility. SpecBridge v3 should
turn that discipline into repository-native contract fields, validation, tests,
docs, and review evidence.

## Source References

- `README.md` - SpecBridge operating model and current status.
- `SPECBRIDGE.md` - execution contracts, quality gates, and final report requirements.
- `AGENTS.md` - repository operating rules and non-interruption principle.
- `.specbridge/policy.yaml` - protected paths, stop conditions, quality gates, and merge policy.
- `.specbridge/context/CURRENT_GOAL.md` - recommends the serious product-build pilot.
- `.specbridge/reports/issue-260-specbridge-v2-release-readiness-hardening.final-report.json` - v2 static MVP readiness evidence.
- `https://github.com/DietrichGebert/ponytail` - public reference for the reuse-first/minimal-change discipline; do not copy code or install it.
- `D:\Antigravity\Infinite Process\specbridge-v2` - completed v2 repository baseline.
- `D:\Antigravity\Infinite Process\specbridge-v3` - v3 repository to create.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

High. This task creates a new repository, may create a v3 GitHub Actions
workflow inside that new repository, and may create/push a new private GitHub
repository. The contract explicitly authorizes only the v3 repository and its
read-only test CI workflow. It does not authorize secrets, production,
billing, authentication, authorization, databases, dependency installation,
deployment automation, hosted runtimes, mutation-capable MCP tools, branch
deletion, force push, repository visibility changes to public, or CI workflow
changes outside the v3 repository.

## Allowed Scope

```text
.specbridge/contracts/issue-261-specbridge-v3-governed-product-build.execution.md
.specbridge/scopes/issue-261-specbridge-v3-governed-product-build.scope.json
.specbridge/github-evidence/issue-261-specbridge-v3-governed-product-build.issue.json
.specbridge/github-evidence/issue-261-specbridge-v3-governed-product-build.repo.json
.specbridge/github-evidence/issue-261-specbridge-v3-governed-product-build.ci.json
.specbridge/runtime-evidence/issue-261-specbridge-v3-claude-output.md
.specbridge/reports/issue-261-specbridge-v3-governed-product-build.final-report.json
.specbridge/audit-packets/issue-261-specbridge-v3-governed-product-build.audit-packet.json
.specbridge/audits/issue-261-specbridge-v3-governed-product-build.chatgpt-audit.json
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
mutation-capable MCP tools
external AI provider integration
Ponytail plugin installation
Ponytail MCP installation
copying third-party Ponytail source code
public repository visibility
force push
branch deletion
remote deletion outside specbridge-v3 creation
destructive cleanup
CI workflow security changes outside D:\Antigravity\Infinite Process\specbridge-v3\.github\workflows\ci.yml
changing SpecBridge v1 policy
merging into SpecBridge v1 main
```

## Acceptance Criteria

1. A separate local repository exists at `D:\Antigravity\Infinite Process\specbridge-v3`.
2. A private GitHub repository exists at `https://github.com/yagooyarzabaldev-ops/specbridge-v3`.
3. v3 is local-first and dependency-free for the MVP: PowerShell 5.1, no npm/pip/NuGet/package manager installation, and no external runtime dependency.
4. v3 contains `README.md`, `AGENTS.md`, `VERSION`, `src/specbridge_v3.ps1`, `scripts/test.ps1`, `tests/bootstrap.tests.ps1`, docs, context, contracts, scopes, readiness evidence, and rollback documentation.
5. v3 validates execution contracts and scope manifests at least as strongly as v2 for required sections, required fields, array shape, nonblank entries, path traversal/rooting, operation conflicts, report schema, and exit code behavior.
6. v3 adds a minimalism/anti-overbuild review gate inspired by Ponytail but implemented as local repository-native validation, not as a dependency. The gate must validate explicit reuse/minimal-change evidence such as `minimal_change_rationale`, `reuse_inventory`, `new_files_justification`, `dependency_policy`, and `validation_plan`.
7. v3 includes tests that prove valid bootstrap inputs pass and malformed contract, scope, and minimalism-review evidence fails deterministically.
8. v3 includes a read-only GitHub Actions workflow that runs the local test suite on push and pull request to `master`, with `permissions: contents: read`.
9. v3 includes machine-readable readiness evidence documenting version, validation commands, CI boundary, minimalism gate status, blocked boundaries, and rollback reference.
10. v3 local tests pass with exit code 0 before any push.
11. v3 is committed and pushed normally to `origin/master`; no force push, branch deletion, or public visibility change is performed.
12. GitHub Actions CI for v3 passes on the pushed commit.
13. SpecBridge v1 records issue evidence, Claude output evidence, repo/CI evidence, final report, audit packet, and ChatGPT/Codex audit.
14. Required v1 validators pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v3\scripts\test.ps1
git diff --check
gh repo view yagooyarzabaldev-ops/specbridge-v3 --json nameWithOwner,url,visibility,defaultBranchRef,pushedAt,updatedAt
gh run view <run-id> --repo yagooyarzabaldev-ops/specbridge-v3 --json databaseId,headSha,status,conclusion,url,createdAt,updatedAt,name,displayTitle,event,jobs
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, dependency installation, package manager
execution, production configuration, billing, authentication, authorization,
database changes, deployment automation, public repository visibility, hosted
runtime work, mutation-capable MCP tools, external AI provider integration,
Ponytail plugin/MCP installation, copying third-party Ponytail source code,
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

Write `.specbridge/reports/issue-261-specbridge-v3-governed-product-build.final-report.json`, `.specbridge/audit-packets/issue-261-specbridge-v3-governed-product-build.audit-packet.json`, and `.specbridge/audits/issue-261-specbridge-v3-governed-product-build.chatgpt-audit.json`. The report must include summary, changed files, v3 repository URL, v3 pushed commit, validations, CI status, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when v3 exists as a local and private GitHub repository,
implements the governed minimalism/anti-overbuild product build, passes local
tests, is pushed normally to `origin/master`, passes GitHub Actions CI, is
reviewed by Codex, and v1 evidence passes required validators or exact blockers
are documented.
