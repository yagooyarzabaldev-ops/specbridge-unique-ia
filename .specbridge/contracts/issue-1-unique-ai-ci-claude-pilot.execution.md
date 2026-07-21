# Execution Contract: Issue 1 Unique IA CI and Claude Pilot

## Contract Metadata

- contract_id: issue-1-unique-ai-ci-claude-pilot
- run_id: sb-20260720-001c1a1d
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge-unique-ia/issues/1
- created_by: ChatGPT/Codex
- created_at: 2026-07-20
- autonomy_profile: assisted
- risk_level: high
- status: ready_for_execution

## Goal

Use Claude Code as the first implementation worker to establish provider-neutral deterministic CI for SpecBridge Unique IA, remove inherited active multi-provider review workflows, validate the change through a pull request, merge only after required checks pass, and protect `main` with the new required check.

## Context

The user explicitly instructed Codex to proceed and put Claude to work after publication. The public repository inherited the original SpecBridge workflows, including active Claude- and Codex-specific review jobs. Unique IA must rely on one configured AI for reasoning while CI remains deterministic and provider-independent.

This contract explicitly authorizes the bounded CI/CD security changes listed below. It does not authorize secrets, external AI actions in GitHub Actions, production, deployment, billing, auth, databases, dependency installation, force push, or branch deletion.

## Source References

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `.specbridge/policy.yaml`
- `.specbridge/policies/workflow-change-authorizations.json`
- `.github/workflows/foundation-validation.yml`
- `.github/workflows/specbridge-review-gate.yml`
- `.github/workflows/claude-review-non-blocking.yml`
- `.github/workflows/codex-review.example.yml`
- `scripts/test.ps1`
- `.specbridge/contracts/specbridge-unique-ia-single-agent-build.execution.md`

## Autonomy Profile

```text
assisted
```

## Risk Level

High. The task changes CI workflows and branch protection on a public repository. Risk is bounded by exact workflow paths, explicit human authority in this chat, deterministic tests without provider secrets, a PR review gate, no force push, and no deployment.

## Allowed Scope

```text
.github/workflows/unique-ai-ci.yml
.github/workflows/claude-review-non-blocking.yml (delete only)
.github/workflows/codex-review.example.yml (delete only)
.github/workflows/claude-code-review.example.yml (delete only)
.github/workflows/claude-code-execute.example.yml (delete only)
.specbridge/policies/workflow-change-authorizations.json
.specbridge/contracts/issue-1-unique-ai-ci-claude-pilot.execution.md
.specbridge/scopes/issue-1-unique-ai-ci-claude-pilot.scope.json
.specbridge/runtime-evidence/issue-1-unique-ai-ci-claude-pilot.md
.specbridge/reports/issue-1-unique-ai-ci-claude-pilot.final-report.json
.specbridge/audit-packets/issue-1-unique-ai-ci-claude-pilot.audit-packet.json
.specbridge/audits/issue-1-unique-ai-ci-claude-pilot.chatgpt-audit.json
docs/unique-ai/ci-and-claude-pilot.md
docs/specbridge-ci-authority-standard.md
scripts/validate-standard-ci-authority.ps1
tests/unique-ai/test-ci.ps1
branch codex/unique-ai-ci-pilot
pull request to main
non-force branch push
merge after all required checks and Codex review pass
main branch protection requiring unique-ai-ci
issue 1 status and closure after verified merge
```

## Blocked Scope

```text
secrets or GitHub secret configuration
provider API keys
AI-provider actions in GitHub Actions
production or deployment
billing
authentication or authorization product changes
database changes
dependency installation
force push
branch deletion
workflow files not explicitly listed
weakening or bypassing deterministic tests
disabling GitHub Actions
removing foundation-validation.yml
removing specbridge-review-gate.yml
autonomous changes beyond issue 1
```

## Acceptance Criteria

1. Claude Code performs the first bounded implementation pass on the issue branch.
2. `.github/workflows/unique-ai-ci.yml` runs on pull requests and pushes to `main` using no provider secret and exposes a stable `unique-ai-ci` job/check.
3. The new CI runs `scripts/test.ps1`, contract validation, scope validation, final-report validation, audit-packet validation, ChatGPT audit validation, and `git diff --check` or equivalent deterministic checks.
4. Inherited active Claude/Codex review workflow files listed in scope are deleted so CI no longer depends on a second AI provider.
5. Workflow authorization policy contains a current, bounded human authorization for exactly the listed workflow changes.
6. The CI authority validator and documentation require the provider-neutral Unique IA workflow and no longer require a Claude-specific workflow.
7. Deterministic tests reject active workflow dependencies on Claude, Codex, Anthropic/OpenAI actions, or provider API-key secrets.
8. Codex audits Claude's diff and records any corrections.
9. A pull request is opened; GitHub checks pass.
10. The PR is merged only after CI and review gates pass under this explicit user authorization.
11. `main` protection requires the stable `unique-ai-ci` status check, enforces admins, strict checks, and blocks force pushes and deletions.
12. Remote `main`, PR state, issue state, and protection are verified live.
13. No secret, dependency, production, deployment, billing, auth, database, or force-push action occurs.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-standard-ci-authority.ps1
git diff --check
gh pr checks
gh pr view
gh api repos/yagooyarzabaldev-ops/specbridge-unique-ia/branches/main/protection
```

## Stop Conditions

Stop if Claude requests secrets or expands scope, local validation fails without an in-scope fix, workflow authorization cannot be made exact, CI fails for a protected or out-of-scope reason, branch protection would require bypassing checks, merge would require force, or any blocked boundary is reached.

## Merge Policy

The user's current instruction explicitly authorizes merge for issue 1 after local validations, GitHub required checks, and Codex review pass. Squash merge is preferred. No merge is allowed while any required check is pending or failing.

## Deployment Policy

No deployment is authorized.

## Final Report Requirements

Record Claude execution evidence, changed and deleted files, validations, PR and check URLs, merge commit, branch protection response, issue closure, policy result, review result, deployment status, unresolved risks, and rollback.

## Completion Rule

Complete only when Claude has implemented first, Codex has audited, the PR is merged with passing checks, issue 1 is closed, `main` protection is verified, final evidence is pushed, and no blocked boundary was crossed.
