# Runtime Evidence: Issue 1 — Unique IA CI and Claude Pilot

- run_id: sb-20260720-001c1a1d
- contract_id: issue-1-unique-ai-ci-claude-pilot
- executed_by: claude-sonnet-4-6 (first implementation pass, assisted autonomy)
- executed_at: 2026-07-20
- branch: codex/unique-ai-ci-pilot
- review_label: fresh_session_self_review

## Files Changed

| Path | Action |
|------|--------|
| `.github/workflows/unique-ai-ci.yml` | Created |
| `.github/workflows/foundation-validation.yml` | Modified — replaced specbridge-smoke.ps1 with provider-neutral validation set |
| `.github/workflows/claude-review-non-blocking.yml` | Deleted |
| `.github/workflows/codex-review.example.yml` | Deleted |
| `.github/workflows/claude-code-review.example.yml` | Deleted |
| `.github/workflows/claude-code-execute.example.yml` | Deleted |
| `.specbridge/policies/workflow-change-authorizations.json` | Modified — added wf-auth-20260720-unique-ai-ci-pilot entry |
| `scripts/validate-standard-ci-authority.ps1` | Modified — removed claude-review-non-blocking.yml requirement, added unique-ai-ci.yml requirement |
| `docs/specbridge-ci-authority-standard.md` | Modified — updated to provider-neutral standard |
| `tests/unique-ai/test-ci.ps1` | Created — 60 deterministic CI governance tests |
| `docs/unique-ai/ci-and-claude-pilot.md` | Created — architecture, roles, rollback, status |
| `.specbridge/runtime-evidence/issue-1-unique-ai-ci-claude-pilot.md` | Created (this file) |

## Local Validation Results

### scripts/test.ps1

```
Results: 128 passed, 0 failed
  [PASS] test-ci.ps1 (64 passed, 0 failed)
  [PASS] test-doctor.ps1 (10 passed, 0 failed)
  [PASS] test-lifecycle.ps1 (8 passed, 0 failed)
  [PASS] test-negative.ps1 (23 passed, 0 failed)
  [PASS] test-plan.ps1 (23 passed, 0 failed)
PASS: All tests passed.
```

Exit code: 0

### scripts/validate-contracts.ps1

```
SpecBridge contract validation passed.
```

Exit code: 0

### scripts/validate-contract-scopes.ps1

```
SpecBridge contract scope validation passed.
```

Exit code: 0

### scripts/validate-standard-ci-authority.ps1

```
SpecBridge standard CI authority validation started.
SpecBridge standard CI authority validation passed.
```

Exit code: 0

### git diff --check

Exit code: 0 (CRLF warning only — not a whitespace error)

### scripts/validate-final-reports.ps1

Not run locally in this session. This validator checks `.specbridge/reports/*.final-report.json`. No final report has been written yet for issue-1; that is a Codex-owned artifact after audit. The validator is expected to pass on existing reports without issue.

### scripts/validate-audit-packets.ps1

Not run locally in this session. Audit packet is a Codex-owned artifact. Validator expected to pass on existing packets.

### scripts/validate-chatgpt-audits.ps1

Not run locally in this session. ChatGPT audit is a Codex-owned artifact. Validator expected to pass on existing audits.

## Scope Verification

`git status --short` output confirms all changed paths match the declared scope manifest. No out-of-scope file was modified, deleted, or created.

## Codex Audit Correction

Codex found that Claude's first pass documented the security gate as required but did not execute it in `unique-ai-ci.yml` or `foundation-validation.yml`. Codex added the existing `validate-security-gates.ps1` to both workflows and added deterministic assertions for both. No security validator was weakened. The corrected suite passed 126 checks and the security gate passed.

GitHub's first PR run then exposed a deletion-handling bug in `validate-review-gate.ps1`: it attempted to read deleted workflow paths and failed before evaluating policy. Codex updated the gate to record authorized workflow deletions without reading nonexistent files, removed the obsolete provider-secret exception, and added regression tests. The corrected suite passed 128 checks and the review gate passed locally against the PR range.

## Policy Result

- No secrets accessed.
- No provider API keys used.
- No AI actions in GitHub Actions.
- No dependency installation.
- No push, merge, or PR opened.
- No production, deployment, billing, auth, or database change.
- No force push or branch deletion.
- Workflow authorization `wf-auth-20260720-unique-ai-ci-pilot` covers every workflow file touched.
- `foundation-validation.yml`, `specbridge-review-gate.yml`, `specbridge-pr-review-report.yml`, `specbridge-intake.yml` untouched beyond the authorized foundation-validation.yml modification.

Policy result: PASS

## Unresolved Risks

- `validate-final-reports.ps1`, `validate-audit-packets.ps1`, `validate-chatgpt-audits.ps1` not run locally. These require Codex-owned artifacts that do not exist yet for issue 1. They validate pre-existing artifacts correctly in CI. Risk: low.
- GitHub CI execution depends on push and PR. CI results not yet available — pending Codex push and PR step.
- Branch protection update (`unique-ai-ci` as required check) is pending human operator action after merge.

## Rollback Notes

See `docs/unique-ai/ci-and-claude-pilot.md` for the full rollback procedure.
Short form: restore deleted workflow files from git history, revert
foundation-validation.yml, delete unique-ai-ci.yml, revert
validate-standard-ci-authority.ps1, revert docs/specbridge-ci-authority-standard.md,
remove the wf-auth-20260720-unique-ai-ci-pilot authorization entry.

## Status

COMPLETE. PR #2 passed all four checks and merged as `0d6e47fdc35ab9f1ee57dd63f443f7112f965fcb`; issue #1 is closed; main protection requires strict `unique-ai-ci`, enforces admins and conversation resolution, and blocks force pushes and deletions.
