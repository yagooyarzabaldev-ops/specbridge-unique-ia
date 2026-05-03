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

This repository is currently in foundation phase.

No product implementation code should be added until the following are defined:

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.specbridge/policy.yaml`
- `.specbridge/autonomy.yaml`
- `.specbridge/risk-rules.yaml`
- initial specs under `specs/`

During foundation phase, agents should focus on product contract, policy, architecture, and execution model.
