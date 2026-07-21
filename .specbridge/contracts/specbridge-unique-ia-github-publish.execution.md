# Execution Contract: Publish SpecBridge Unique IA to GitHub

## Contract Metadata

- contract_id: specbridge-unique-ia-github-publish
- run_id: sb-20260720-270b1c2d
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/270
- created_by: ChatGPT/Codex
- created_at: 2026-07-20
- autonomy_profile: assisted
- risk_level: medium
- status: ready_for_execution

## Goal

Create the public GitHub repository `yagooyarzabaldev-ops/specbridge-unique-ia`, publish the complete committed SpecBridge Unique IA MVP on `main`, and preserve auditable local evidence.

## Context

The user explicitly authorized creating the GitHub repository and uploading all product content. Existing sibling repositories `specbridge-v2` and `specbridge-v3` are public, so this publication uses the same visibility. The local MVP is committed and validated, has no remote, and excludes `.unique-ai/runs/`.

## Source References

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `.specbridge/policy.yaml`
- `.specbridge/contracts/specbridge-unique-ia-single-agent-build.execution.md`
- `.unique-ai/evidence/claude-build-report.md`
- `docs/unique-ai/milestones.md`

## Autonomy Profile

```text
assisted
```

## Risk Level

Medium. This creates a public remote and uploads repository history. Risk is bounded by explicit user authority, pre-push secret scanning, a dedicated repository name, no force push, no workflow changes, and no deployment.

## Allowed Scope

```text
.specbridge/contracts/specbridge-unique-ia-github-publish.execution.md
.specbridge/scopes/specbridge-unique-ia-github-publish.scope.json
.specbridge/reports/specbridge-unique-ia-github-publish.final-report.json
.specbridge/audit-packets/specbridge-unique-ia-github-publish.audit-packet.json
.specbridge/audits/specbridge-unique-ia-github-publish.chatgpt-audit.json
local branch main
GitHub repository yagooyarzabaldev-ops/specbridge-unique-ia
git remote origin for that repository
non-force push of main
```

## Blocked Scope

```text
secrets or credentials
.env
.env.*
GitHub Actions workflow changes
branch protection changes
autonomous merge
force push
branch deletion
release publication
deployment
production configuration
billing
authentication or authorization changes
database changes
dependency installation
issue 267 source-worktree content
```

## Acceptance Criteria

1. Pre-push checks find no tracked secret or environment files.
2. Local product tests, contract validation, scope validation, and `git diff --check` pass.
3. Governance publication artifacts are committed locally.
4. A public repository exists at `https://github.com/yagooyarzabaldev-ops/specbridge-unique-ia`.
5. `origin` points exactly to the new repository.
6. The complete committed MVP and governance evidence are present on remote `main`.
7. Local `main` tracks `origin/main` and the worktree is clean.
8. No force push, merge, release, workflow mutation, dependency, secret, production, or deployment action occurs.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contract-scopes.ps1
git diff --check
git status --short
gh repo view yagooyarzabaldev-ops/specbridge-unique-ia --json nameWithOwner,visibility,defaultBranchRef,url
git ls-remote --heads origin main
```

## Stop Conditions

Stop if authentication fails, the target repository already exists unexpectedly, a tracked secret or environment file is found, validations fail, the remote URL differs, a force push would be required, or publication requires any blocked operation.

## Merge Policy

No merge is needed: this is the initial publication of a new repository. Future changes require normal branch and review policy.

## Deployment Policy

No deployment is authorized.

## Final Report Requirements

Record repository URL, visibility, branch, commit, changed files, validations, policy result, remote verification, merge status, deployment status, unresolved risks, and rollback.

## Completion Rule

Complete only when the public repository and remote `main` are verified, local `main` tracks it, the worktree is clean, and final governance evidence is committed and pushed.
