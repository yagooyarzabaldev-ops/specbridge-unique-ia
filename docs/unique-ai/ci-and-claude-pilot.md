# CI and Claude Pilot — SpecBridge Unique IA

## Overview

This document describes the CI architecture established in issue #1, Claude's
first-pass implementation role, the deterministic authority model, branch
protection targets, rollback procedure, and completion status.

## Architecture

SpecBridge Unique IA uses provider-neutral deterministic CI. No active GitHub
Actions workflow depends on an AI provider API key, a provider-specific action,
or any network call to an AI service.

```
pull_request to main
       |
       +-- unique-ai-ci          (new, stable check, windows-latest)
       |      test.ps1
       |      validate-contracts.ps1
       |      validate-contract-scopes.ps1
       |      validate-final-reports.ps1
       |      validate-audit-packets.ps1
       |      validate-chatgpt-audits.ps1
       |      validate-standard-ci-authority.ps1
       |      validate-security-gates.ps1
       |      git diff --check
       |
       +-- Foundation Validation  (retained, provider-neutral entrypoint)
       |      validate-foundation.ps1
       |      validate-contracts.ps1
       |      validate-contract-scopes.ps1
       |      validate-schemas.ps1
       |      validate-final-reports.ps1
       |      validate-audit-packets.ps1
       |      validate-chatgpt-audits.ps1
       |      validate-standard-ci-authority.ps1
       |      validate-orchestrations.ps1
       |      validate-agent-review-reports.ps1
       |      validate-security-gates.ps1
       |      test.ps1
       |
       +-- SpecBridge Review Gate (unchanged deterministic gate)
       |
       +-- SpecBridge PR Review Report (unchanged deterministic report)
```

The new Unique IA and Foundation jobs run on `windows-latest` with
`permissions: contents: read`. Neither installs dependencies, downloads
scripts over the network, nor invokes a provider action. Other retained
workflows keep their pre-existing least privileges for deterministic PR
reporting.

## Claude First-Pass Role

Claude Code (claude-sonnet-4-6) acted as the bounded first implementation
worker for issue #1 under the `assisted` autonomy profile. Claude's role is
explicitly limited to local file changes within the declared scope. Claude does
not push, merge, configure secrets, or access GitHub beyond what the operating
environment already provides.

The review label for Claude's own output in this cycle is
`fresh_session_self_review` per SPECBRIDGE.md invariant 3. Codex audits
Claude's diff independently before merge.

## Deterministic Authority

CI is the merge authority. No merge is authorized while any required check is
pending or failing. The stable check name that branch protection must require
is `unique-ai-ci`.

Workflow changes are blocked by default. Each change requires:
1. An unexpired entry in `.specbridge/policies/workflow-change-authorizations.json`
2. A dedicated execution contract with `risk_level: high`
3. Explicit human operator authorization

The current authorization is `wf-auth-20260720-unique-ai-ci-pilot`, valid
2026-07-20 through 2026-07-27, granted by the repository owner through explicit
operator chat instruction.

## Branch Protection Target

After merge, `main` must be protected with:

- Required status checks: `unique-ai-ci`
- Strict status checks: enabled
- Enforce admins: enabled
- Force pushes: blocked
- Deletions: blocked

This protection is a post-merge step performed by the human operator or
authorized automation, not by Claude or this contract.

## Deleted Workflows

The following inherited workflows were deleted in issue #1 because they
depend on provider-specific secrets or actions:

| File | Reason |
|------|--------|
| `claude-review-non-blocking.yml` | Uses `anthropics/claude-code-action@v1` and `ANTHROPIC_API_KEY` |
| `codex-review.example.yml` | Codex/OpenAI provider-specific example |
| `claude-code-review.example.yml` | Claude-specific example |
| `claude-code-execute.example.yml` | Claude-specific example |

## Rollback

To revert this change:

1. Restore the deleted workflow files from git history:
   `git show HEAD~1:.github/workflows/claude-review-non-blocking.yml > .github/workflows/claude-review-non-blocking.yml`
   (repeat for each deleted file)
2. Revert `foundation-validation.yml` to call `specbridge-smoke.ps1`
3. Delete `.github/workflows/unique-ai-ci.yml`
4. Revert `scripts/validate-standard-ci-authority.ps1` to require `claude-review-non-blocking.yml`
5. Revert `docs/specbridge-ci-authority-standard.md`
6. Remove the `wf-auth-20260720-unique-ai-ci-pilot` entry from the authorization registry
7. Open a new PR; previous CI gates will apply once the files are restored

## Status

| Item | Status |
|------|--------|
| unique-ai-ci.yml created | Completed |
| foundation-validation.yml aligned | Completed |
| Provider-specific workflows deleted | Completed |
| Workflow authorization updated | Completed |
| CI authority validator updated | Completed |
| CI authority documentation updated | Completed |
| test-ci.ps1 deterministic tests | Completed |
| Branch protection update (main) | Completed — strict unique-ai-ci, admins enforced, force-push and deletion blocked |
| Codex audit of Claude diff | Completed — security gate restored and deleted-workflow review handling fixed |
| PR open and checks passing | Completed — PR #2 merged as 0d6e47f |
| Issue #1 closure | Completed |
