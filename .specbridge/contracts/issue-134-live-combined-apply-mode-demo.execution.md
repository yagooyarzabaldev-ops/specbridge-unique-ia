# Execution Contract: Issue 134 Live Combined Apply-Mode Demonstration

## Contract Metadata

- contract_id: issue-134-live-combined-apply-mode-demo
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/134
- created_by: ChatGPT / SpecBridge coordinator
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run a governed live combined apply-mode demonstration for the currently supported GitHub mutation operations: `pr_open`, `merge`, and `issue_close`.

## Context

Issue 119 proved apply-mode `issue_close`.
Issue 123 proved apply-mode `pr_open`.
Issue 126 proved apply-mode `merge` with `gh pr merge --squash --auto`.
Issue 133 closed the stale evidence and memory gap after PR 129 merged.

The next proof is a bounded combined demonstration. It must not expand the apply-mode operation catalog. It must demonstrate only the already supported operations in one governed call when all evidence gates are satisfied.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-126-apply-mode-merge.execution.md
- .specbridge/reports/issue-126-apply-mode-merge.final-report.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/134

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- This task prepares and governs a live GitHub mutation demonstration.
- The allowed operation set is limited to `pr_open`, `merge`, and `issue_close`.
- Production, secrets, billing, auth, database, CI/CD security, and deployment remain blocked.

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-134-live-combined-apply-mode-demo.execution.md
.specbridge/scopes/issue-134-live-combined-apply-mode-demo.scope.json
.specbridge/reports/issue-134-live-combined-apply-mode-demo.final-report.json
.specbridge/audit-packets/issue-134-live-combined-apply-mode-demo.audit-packet.json
.specbridge/audits/issue-134-live-combined-apply-mode-demo.chatgpt-audit.json
.specbridge/github-evidence/issue-134-live-combined-apply-mode-demo.github-mutation-evidence.json
.specbridge/issue-to-merge-runs/issue-134-live-combined-apply-mode-demo.github-mutation-run.json
GitHub pull request for this branch
GitHub issue 134 lifecycle comments/status updates
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
database changes
authentication implementation
authorization implementation
billing implementation
CI/CD security changes
deployment automation
production deployment
unsupported apply-mode operations
broad refactor
```

## Acceptance Criteria

- Create governance artifacts for issue 134.
- Record a combined apply-mode run envelope for exactly `pr_open`, `merge`, and `issue_close`.
- Do not claim local `gh` execution unless the repository-local `issue-to-merge-github` command actually executed it.
- Record current evidence state honestly: prepared, blocked, partially executed, or completed.
- Keep `ci_wait` and `post_merge_memory` out of apply-mode unless a separate policy expansion is created.
- Record final report, audit packet, and ChatGPT/Codex audit.
- Update CURRENT_GOAL.md and README.md with the issue 134 active phase.
- GitHub CI must pass before merge.

## Required Local Command for Live Execution

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-github `
  -TaskId issue-134-live-combined-apply-mode-demo `
  -Title "Live combined apply-mode demonstration: pr_open + merge + issue_close" `
  -RelatedIssue "https://github.com/yagooyarzabaldev-ops/specbridge/issues/134" `
  -MutationMode apply `
  -GithubOperation pr_open,merge,issue_close `
  -EvidencePath .specbridge/github-evidence/issue-134-live-combined-apply-mode-demo.github-mutation-evidence.json `
  -Force `
  -ConfirmGithubMutation
```

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires unsupported apply-mode operations, protected credential access, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or production deployment.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete only when the combined operation is either honestly recorded as policy-blocked/prepared, or actually executed by the repository-local apply-mode command and verified with PR/issue evidence. A connector-created PR alone does not count as repository-local `gh` execution.
