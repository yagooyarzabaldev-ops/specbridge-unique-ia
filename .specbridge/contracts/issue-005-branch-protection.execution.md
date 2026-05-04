# Execution Contract: Issue 005

## Contract Metadata

- contract_id: issue-005-branch-protection
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/5
- created_by: ChatGPT/Codex
- created_at: 2026-05-03
- autonomy_profile: vibe_autopilot
- risk_level: medium
- status: draft

## Goal

Require CI to pass before any pull request can be merged into `main`.

## Context

SpecBridge already has a working GitHub Actions workflow named:

```text
Foundation Validation
```

The workflow runs:

```text
scripts/validate-foundation.ps1
```

During the previous PR cycle, a PR was mergeable while its check was still pending. This means the repository has CI, but `main` is not protected yet.

SpecBridge requires GitHub-level enforcement so validation is a hard gate, not a suggestion.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml
- .specbridge/risk-rules.yaml
- .specbridge/execution-contract-template.md
- .github/workflows/foundation-validation.yml
- docs/branch-protection.md
- GitHub issue #5

## Autonomy Profile

```text
vibe_autopilot
```

Claude Code may update foundation documentation and governance files without step-by-step permission requests.

## Risk Level

```text
medium
```

Reason:

- branch protection affects repository governance
- no product implementation code
- no secrets
- no production configuration
- no runtime infrastructure change
- no database change

## Allowed Scope

```text
docs/**
.github/**
.specbridge/**
specs/**
README.md
SPECBRIDGE.md
AGENTS.md
CLAUDE.md
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
application source code
runtime framework setup
package installation
deployment automation
database schema implementation
```

## Acceptance Criteria

- `docs/branch-protection.md` exists.
- The document defines required protection for `main`.
- The document identifies the required check: `Foundation Validation / validate-foundation`.
- The document states that force pushes and branch deletion must be disabled for `main`.
- The document explains that CI must be a hard merge gate.
- Foundation validation passes.
- No product implementation code is added.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
```

```powershell
gh api repos/yagooyarzabaldev-ops/specbridge/branches/main/protection
```

## Stop Conditions

Execution must stop if any of the following occurs:

- GitHub API requires permissions not available to the current user
- branch protection cannot be configured safely
- the required status check name is ambiguous
- repository policy conflicts with this contract
- blocked scope must be modified
- validation fails and cannot be resolved safely

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.
- CI passed.
- Branch protection documentation exists.
- No protected files changed.
- No product implementation code added.
- PR references and closes GitHub issue #5.

## Deployment Policy

No deployment is allowed for this task.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include:

- summary
- changed files
- branch protection status
- required checks
- validation result
- policy result
- risk result
- unresolved risks
- completion status

## Completion Rule

This task is complete only when branch protection is documented, validation passes, CI passes, branch protection is applied or explicitly blocked by GitHub permissions, and the PR is merged into `main`.
