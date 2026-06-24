# Execution Contract: Issue 256 Create and Upload SpecBridge v2 Repository

## Contract Metadata

- contract_id: issue-256-create-upload-specbridge-v2
- run_id: sb-20260624-0256c0de
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/256
- created_by: ChatGPT/Codex
- created_at: 2026-06-24
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Create a private GitHub repository for the existing local SpecBridge v2 MVP and push the local repository contents.

## Context

Issue #255 created and validated a separate local `specbridge-v2` repository at `D:\Antigravity\Infinite Process\specbridge-v2`. That contract deliberately blocked external repository creation. The user has now explicitly authorized creating the remote repository and uploading the local v2 repo.

This contract authorizes a bounded GitHub mutation for `yagooyarzabaldev-ops/specbridge-v2` only.

## Source References

- `README.md` - SpecBridge operating model and GitHub audit role.
- `SPECBRIDGE.md` - execution contracts, policy gates, and final report requirements.
- `AGENTS.md` - active repository working method and protected boundaries.
- `.specbridge/policy.yaml` - active protected paths and stop conditions.
- `.specbridge/contracts/issue-255-serious-product-build-pilot.execution.md` - local v2 pilot boundary.
- `.specbridge/runtime-evidence/issue-255-specbridge-v2-claude-output.md` - v2 local MVP verification evidence.
- `D:\Antigravity\Infinite Process\specbridge-v2` - local v2 repository to publish.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task creates a new GitHub repository and pushes source files. Risk is bounded by private visibility, no dependency installation, no secrets, no production configuration, no billing, no authentication or authorization changes, no database changes, no CI/CD workflow changes, no deployment, no force push, and no destructive cleanup.

## Allowed Scope

```text
.specbridge/contracts/issue-256-create-upload-specbridge-v2.execution.md
.specbridge/scopes/issue-256-create-upload-specbridge-v2.scope.json
.specbridge/github-evidence/issue-256-create-upload-specbridge-v2.issue.json
.specbridge/github-evidence/issue-256-create-upload-specbridge-v2.repo.json
.specbridge/reports/issue-256-create-upload-specbridge-v2.final-report.json
.specbridge/audit-packets/issue-256-create-upload-specbridge-v2.audit-packet.json
.specbridge/audits/issue-256-create-upload-specbridge-v2.chatgpt-audit.json
D:\Antigravity\Infinite Process\specbridge-v2
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
CI/CD workflow changes
.github/workflows/**
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
```

## Acceptance Criteria

1. A private GitHub repository exists at `https://github.com/yagooyarzabaldev-ops/specbridge-v2`.
2. The local `D:\Antigravity\Infinite Process\specbridge-v2` repository has `origin` configured to that remote.
3. The local v2 `master` branch is pushed to the remote without force push.
4. The remote contains the v2 MVP files from the local repository.
5. The v2 local test script passes before or after push.
6. SpecBridge v1 records issue evidence, repository creation/push evidence, final report, audit packet, and ChatGPT/Codex audit.
7. Required validations pass locally, or exact blockers are recorded.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\Antigravity\Infinite Process\specbridge-v2\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
```

## Stop Conditions

Stop if GitHub authentication is unavailable, repository creation is denied, the target repository already exists with conflicting content, push would require force, secrets are detected, dependency installation is required, visibility would be public, CI/CD workflow changes are required, deployment is requested, production or billing configuration is touched, or any command would mutate a repository other than `yagooyarzabaldev-ops/specbridge-v2` and the current v1 evidence branch.

## Merge Policy

No autonomous merge is performed by this contract. V1 evidence merge requires a pull request, GitHub CI, review gate, no protected file changes, and explicit operator merge authority.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-256-create-upload-specbridge-v2.final-report.json`, `.specbridge/audit-packets/issue-256-create-upload-specbridge-v2.audit-packet.json`, and `.specbridge/audits/issue-256-create-upload-specbridge-v2.chatgpt-audit.json`. The report must include summary, changed files, remote repository URL, validations, policy result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the private remote repository is created, v2 local contents are pushed, evidence is recorded in v1, and required local validations pass or exact blockers are documented.
