# Agent Instructions

This repository follows Spec Driven Development.

All agents working in this repository must treat specifications, policies, tests, and repository evidence as the source of truth.

Agents must not improvise beyond the active execution contract.

## Repository Purpose

SpecBridge is a connector and orchestration layer that converts ChatGPT/Codex context into autonomous Claude Code execution.

The product exists to support Vibe Autopilot development:

- the user defines goals in ChatGPT/Codex
- context is converted into structured repository files
- Claude Code executes implementation autonomously
- CI validates the result
- Codex reviews the implementation
- SpecBridge reports the final outcome

## Global Agent Rules

Every agent must:

- read `README.md` before acting
- read `SPECBRIDGE.md` before acting
- respect `.specbridge/policy.yaml` when it exists
- prefer explicit specs over inference
- keep changes inside the declared task scope
- add or update tests when behavior changes
- avoid unrelated refactors
- avoid large unrequested rewrites
- preserve auditability
- report evidence, not confidence

Every agent must stop when:

- the spec is contradictory
- acceptance criteria are impossible
- required context is missing for a risky decision
- a policy boundary is reached
- secrets, production, billing, or destructive infrastructure are involved
- the requested change would require touching blocked files or commands

## Non-Interruption Principle

SpecBridge is designed for autonomous execution.

Agents should not ask for permission for ordinary development work when the task is inside the active contract.

Allowed without interruption:

- creating normal source files
- modifying normal source files
- adding tests
- fixing tests
- fixing lint
- fixing type errors
- updating related documentation
- opening or updating pull requests
- retrying after failed validation

Required stop or escalation:

- secret access
- destructive database change
- production configuration change
- billing change
- critical authentication or authorization change
- CI/CD security change
- policy conflict
- task scope conflict
- impossible acceptance criteria

## Control Hierarchy

When instructions conflict, apply this hierarchy:

1. Security policy
2. Repository policy
3. Current execution contract
4. Acceptance criteria
5. Product specification
6. Agent-specific instructions
7. Model inference

Model inference is never allowed to override explicit policy.

## Required Working Method

Before changing files, an agent must identify:

- the active task
- the allowed scope
- the blocked scope
- the acceptance criteria
- the required validation commands
- the expected final report format

After changing files, an agent must report:

- what changed
- why it changed
- which files changed
- which validations were run
- which validations passed or failed
- what risks remain
- whether the task is complete

## Code Change Rules

Agents must not:

- touch unrelated files
- remove tests to make validation pass
- weaken security checks
- hide errors
- fake CI results
- fake test results
- claim completion without evidence
- introduce secrets into the repository
- create generated noise unless explicitly required
- change public contracts without spec support

Agents should:

- keep diffs small and task-focused
- prefer deterministic behavior
- write clear tests
- update documentation when contracts change
- preserve existing style unless the spec says otherwise
- use complete files when replacing small project documents
- avoid speculative abstractions

## Documentation Rules

Documentation must be:

- direct
- operational
- auditable
- free of vague promises
- aligned with `SPECBRIDGE.md`

Do not document features that do not exist unless they are explicitly marked as planned or MVP scope.

## Security Rules

Agents must treat the following as protected by default:

- `.env`
- `.env.*`
- secrets
- tokens
- private keys
- production configuration
- billing configuration
- authentication security
- authorization security
- CI/CD security controls
- destructive database operations

Protected areas require explicit policy authorization.

## Git Rules

Agents must prefer branch-based work.

Agents must not merge unless the active policy explicitly allows autonomous merge.

A merge requires evidence:

- CI passed
- tests passed
- lint passed when configured
- typecheck passed when configured
- no policy violation
- review passed when configured

## Execution Environment Rules

This repository runs PowerShell in two different editions, and the difference has caused real bugs:

- Local development and the inner loop of `specbridge-smoke.ps1` use Windows PowerShell 5.1 (`powershell.exe`).
- GitHub Actions workflow steps use PowerShell Core 7+ (`shell: pwsh`) on `windows-latest`, but smoke and CLI tests still spawn `powershell.exe` internally, so PS 5.1 semantics are exercised in CI too.

Known divergence traps agents must respect:

- PS 5.1 reads files without a BOM as Windows-1252, not UTF-8. Always pass `-Encoding UTF8` to `Get-Content` and write files through the UTF-8 helpers in `scripts/lib/common.ps1` (`Write-Utf8JsonFile`, `Write-Utf8TextFile`). Never embed text read without explicit encoding into JSON output.
- Em dashes and arrows in repository markdown are multi-byte UTF-8; reading them as Windows-1252 produces a stray right-double-quote byte that breaks JSON strings in PS 5.1.
- `Where-Object` returning a single item yields a bare object in PS 5.1; wrap in `@()` before using `.Count`.
- `[ordered]@{}` exposes `.Contains()`, not `.ContainsKey()`; prefer plain hashtables when key checks are needed.
- The operations ledger and other evidence files are tracked in git; code must still handle their absence gracefully in fresh clones.

Validation parity rule: a change is not CI-safe until `./scripts/specbridge-smoke.ps1` passes locally, because CI runs the same scripts.

## Final Report Standard

Every completed task must end with a concise final report containing:

- summary
- changed files
- validations
- policy result
- review result, if applicable
- merge status
- deployment status, if applicable
- unresolved risks
- rollback notes, if applicable

The user should receive results, not step-by-step noise.

## Current Repository Stage

This repository is no longer foundation-only.

Foundation, repository-first MVP, Standard Loop v1, V5 readiness, V5 live pilot evidence, V5 runner hardening, and V5 serious pilot status are complete as recorded in `README.md`, `SPECBRIDGE.md`, `.specbridge/context/CURRENT_GOAL.md`, specs, contracts, reports, audit packets, ChatGPT/Codex audits, and GitHub PR history.

The current stage is governed standardization and runtime expansion.

Agents may work on product, runtime, documentation, policy, tests, and evidence only when an active execution contract explicitly authorizes the task scope.

Every new implementation task still requires:

- an execution contract under `.specbridge/contracts/`
- a scope manifest under `.specbridge/scopes/`
- declared allowed and blocked scope
- acceptance criteria
- required validation commands
- security, review, and CI gates
- final report, audit packet, and ChatGPT/Codex audit evidence

Agents must not treat this stage as permission for open-ended implementation.

The following remain blocked unless a dedicated policy and execution contract explicitly authorize them:

- secrets or private keys
- production configuration
- billing or payment-provider configuration
- authentication security changes
- authorization security changes
- destructive database changes
- CI/CD security changes
- dependency installation
- deployment automation
- production deployment

When deciding what to do next, agents must read `.specbridge/context/CURRENT_GOAL.md` and prefer the next task recorded in repository evidence over chat-memory inference.
