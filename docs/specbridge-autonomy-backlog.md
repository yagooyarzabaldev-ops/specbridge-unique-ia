# SpecBridge Autonomy Backlog

## Purpose

This document is the operational memory for the next SpecBridge build phase.

It records the remaining work required to test SpecBridge as a real ChatGPT-governed, Claude Code-implemented, ChatGPT-audited autonomous development system.

## Product Direction

SpecBridge must prove this loop:

```text
ChatGPT / Codex
  governs intent, specs, acceptance criteria, security standards, and audit

SpecBridge
  converts intent into contracts, scopes, validations, PR gates, and final reports

Claude Code
  implements inside Antigravity according to the active execution contract

GitHub
  validates with CI, preserves evidence, and controls merge gates

ChatGPT / Codex
  audits Claude Code output against spec, policy, security, and evidence
```

## Closed Foundation

Already complete:

- Spec Driven Development foundation
- repository-first MVP
- Full Autopilot policy
- auto-merge after gates
- positive validation suite
- negative validation suite
- multi-agent Antigravity architecture
- final report artifacts
- PR review report artifacts
- GitHub CI validation
- security review gate expansion
- local SpecBridge CLI
- live Antigravity executor handoff packets
- branch-per-executor planning and coordinator simulation evidence
- controlled GitHub evidence run with real child executor PRs and passed child CI
- operational autonomy issue closure and evidence-only child PR cleanup
- controlled Antigravity/Claude Code runtime launch with one bounded non-interactive executor artifact
- runtime launch plans generated from executor packets without executing Claude Code
- runtime result records generated from launch plans and declared executor evidence without executing Claude Code
- runtime summaries generated from launch plans and runtime results as the first source-backed runtime CLI slice

## Remaining Work

### 1. Local SpecBridge CLI

Goal:

Implement the first file-backed runtime surface.

Status:

Implemented as `scripts/specbridge.ps1` with command coverage in `scripts/test-specbridge-cli.ps1` and smoke validation coverage.

Required commands:

- `specbridge status`
- `specbridge validate`
- `specbridge create-contract`
- `specbridge create-report`
- `specbridge audit-packet`
- `specbridge detect-conflicts`
- `specbridge decompose-task`
- `specbridge prepare-executors`
- `specbridge plan-executor-branches`
- `specbridge record-github-evidence`
- `specbridge coordinate-executors`
- `specbridge review-gate`

Acceptance:

- commands have deterministic exit codes
- commands use declared input and output paths
- commands do not require secrets
- commands are covered by tests
- CI runs the CLI validation suite

### 2. Contract Scope Validator

Goal:

Prevent unsafe or overlapping agent work before Claude Code starts.

Status:

Implemented as `scripts/validate-contract-scopes.ps1` with `.specbridge/scopes/*.scope.json` manifests, smoke validation coverage, and positive/negative fixture coverage.

Required validation:

- each contract declares `exclusive_write`
- each contract declares `read_only`
- each contract declares `coordinator_owned` when shared files are involved
- no two active contracts own the same write path
- dependency order is explicit
- final report path is unique

Acceptance:

- conflicting contracts fail validation
- disjoint contracts pass validation
- failures report the conflicting contract ids and paths

### 3. Audit Packet Generator

Goal:

Create the evidence bundle ChatGPT/Codex uses to audit Claude Code output.

Status:

Implemented as `scripts/generate-audit-packet.ps1` and `scripts/validate-audit-packets.ps1`, with committed packet evidence under `.specbridge/audit-packets/`.

Required packet fields:

- issue or task id
- execution contract path
- changed files
- diff summary
- validation commands
- validation results
- final report path
- CI status
- PR review report path
- policy result
- unresolved risks

Acceptance:

- packet generation is deterministic
- packet omits secrets
- packet references source files by path
- packet is suitable for independent review

### 4. ChatGPT Audit Standard

Goal:

Define the audit result format used when ChatGPT/Codex reviews Claude Code output.

Status:

Implemented as `.specbridge/schemas/chatgpt-audit.schema.json` and `scripts/validate-chatgpt-audits.ps1`, with committed audit evidence under `.specbridge/audits/`.

Allowed outcomes:

- `approved`
- `changes_requested`
- `blocked`
- `needs_human_decision`

Audit must check:

- spec compliance
- acceptance criteria
- policy boundaries
- security rules
- changed file scope
- test evidence
- CI evidence
- final report honesty

Acceptance:

- audit output has a schema
- audit findings include severity and file references
- blocking findings prevent merge

### 5. Controlled Implementation Pilot

Goal:

Run a real small implementation through the intended product loop.

Status:

Implemented as the first small CLI feature pilot. `scripts/specbridge.ps1 status -IncludeLatestArtifacts` now reports the newest known contract, scope, final report, audit packet, and ChatGPT audit paths, with test coverage and audit evidence.

Flow:

1. ChatGPT defines spec and acceptance criteria.
2. SpecBridge creates an execution contract.
3. Claude Code implements a small feature.
4. CI validates tests and gates.
5. ChatGPT/Codex audits the result.
6. SpecBridge creates final report.
7. Auto-merge occurs only after gates pass.

Acceptance:

- feature code is intentionally small
- tests are included
- security review is included
- final report records evidence
- PR auto-merges after gates

### 6. Multi-Agent Pilot

Goal:

Prove that several Claude Code executor sessions can work in parallel under SpecBridge governance.

Status:

Implemented as a file-backed pilot with three executor contracts, non-overlapping scope manifests, per-agent final reports, coordinator integration evidence, and deterministic decomposition tests. Live parallel Antigravity sessions remain future runtime work.

Pilot shape:

- Agent A: implementation slice
- Agent B: test slice
- Agent C: documentation or integration slice

Acceptance:

- each agent has its own contract
- write scopes do not overlap
- conflicts are detected before work starts
- each agent produces a final report
- coordinator produces an integration report
- GitHub validates all PRs

### 7. Security Review Gate Expansion

Goal:

Strengthen deterministic security checks before runtime autonomy expands.

Status:

Implemented as `scripts/validate-security-gates.ps1` with smoke validation coverage and positive/negative fixture coverage in `scripts/test-specbridge-negative-validations.ps1`.

Add checks for:

- secret-like content
- auth-sensitive files
- authorization-sensitive files
- CI/CD permission escalation
- dependency additions
- unsafe shell commands
- protected path changes
- production configuration

Acceptance:

- safe fixture passes
- unsafe fixtures fail for expected reason
- failures name the security category

## Recommended Execution Order

1. Contract scope validator
2. Audit packet generator
3. ChatGPT audit standard
4. Security review gate expansion
5. Local CLI wrapper
6. Controlled implementation pilot
7. Multi-agent pilot
8. Controlled GitHub evidence run
9. Operational autonomy cleanup

## Current Next Task

After Runtime Summary is merged, start a controlled fresh executor source run.

Reason:

The repository will have launch plans, runtime results, and runtime summaries as deterministic evidence layers. The next product proof should create fresh executor output from a bounded source implementation task, then record and summarize that result before broader runtime automation.

## Next Runtime Expansion

### 8. Live Antigravity Executor Handoff

Goal:

Prepare repository-backed handoff packets for separate Antigravity Claude Code executor sessions.

Status:

Implemented as `specbridge prepare-executors`, `scripts/validate-executor-packets.ps1`, `scripts/test-specbridge-executor-handoff.ps1`, and `.specbridge/executor-packets/*.executor-packet.json`.

Acceptance:

- each executor packet references one contract
- each executor packet declares branch name, launch mode, write scope, read-only scope, validations, stop conditions, and final report path
- duplicate branch names fail before handoff
- packets validate locally and in smoke
- live sessions are not launched until a later runtime contract authorizes that boundary

### 9. Real Branch-Per-Executor Orchestration

Goal:

Run separate executor branches and PRs from the handoff packets.

Status:

Implemented as deterministic branch plans and coordinator orchestration artifacts. Real child branch and PR creation is now covered by the controlled GitHub evidence run.

Acceptance:

- one branch per executor packet
- one PR record per independently mergeable executor branch
- coordinator tracks PR URLs, CI status, and ChatGPT audit status
- integration waits for all child evidence
- rollback notes are recorded per executor branch
- simulation evidence cannot authorize merge

### 10. Controlled GitHub Evidence Run

Goal:

Create real executor branches and child PRs from a branch plan, then coordinate them in GitHub evidence mode.

Status:

Implemented as `specbridge record-github-evidence`, real child executor branches, child PRs #56, #57, and #58, committed GitHub evidence input, an evidence-recorded branch plan, and GitHub-mode coordinator orchestration.

Acceptance:

- one real GitHub branch exists for each executor branch record
- one real GitHub PR exists for each executor branch
- each child PR records CI status from GitHub
- each child PR records ChatGPT/Codex audit status
- the coordinator marks integration ready only when every child PR has passed CI and approved audit evidence
- simulation URLs are not accepted in GitHub evidence mode

### 11. Operational Autonomy Cleanup

Goal:

Close stale autonomy bookkeeping after the controlled GitHub evidence run.

Status:

Implemented by closing issue 42 as completed, closing child evidence PRs #56, #57, and #58 without merge, and recording the cleanup decision in repository evidence.

Acceptance:

- child evidence PRs are closed without merge
- issue 42 is closed as completed
- cleanup decision is recorded in `.specbridge/github-evidence/`
- repository memory points to the next controlled runtime launch

### 12. Controlled Antigravity Runtime Launch

Goal:

Run one bounded Claude Code executor task inside Antigravity using a SpecBridge contract, then validate and audit the resulting PR through GitHub.

Status:

Implemented as issue 061 with a bounded non-interactive Claude Code executor run. Claude Code wrote only `.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md`; SpecBridge records CLI availability, executor packet evidence, runtime launch evidence, validation evidence, final report, audit packet, and ChatGPT/Codex audit evidence.

Acceptance:

- one low-risk runtime task has a dedicated execution contract
- SpecBridge prepares the executor packet
- Antigravity/Claude Code runs against only the assigned contract
- the executor PR is created and validated by CI
- ChatGPT/Codex audits the result against spec, policy, security, and evidence
- merge happens only after required gates pass
- no secrets, production configuration, billing, auth security, dependency installation, or deployment automation are involved

### 13. Controlled Runtime Implementation Slice

Goal:

Authorize the first source-backed SpecBridge runtime implementation slice after the controlled runtime launch.

Status:

Implemented as runtime launch plan preparation. `specbridge prepare-runtime-launch` converts one executor packet into a bounded `.specbridge/runtime-launches/*.runtime-launch.json` artifact without launching Claude Code, Antigravity, shell commands, GitHub operations, dependency installation, or deployment.

Acceptance:

- one small feature has a dedicated execution contract
- exact source, test, and documentation paths are declared
- Claude Code executes in a bounded branch or executor session
- lint, typecheck, tests, build, security gate, review gate, audit packet validation, and ChatGPT/Codex audit are required
- GitHub CI passes before merge
- the slice avoids secrets, production configuration, billing, auth security, dependency installation unless explicitly authorized, database changes, CI/CD weakening, and deployment automation

### 14. Controlled Runtime Result Recording

Goal:

Record the result of a bounded Claude Code runtime execution from a declared launch plan.

Status:

Implemented as `specbridge record-runtime-result`, `scripts/validate-runtime-results.ps1`, CLI test coverage, negative validation coverage, and `.specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json`.

Acceptance:

- one runtime result recorder has a dedicated execution contract
- the recorder reads one runtime launch plan and declared executor output evidence
- the recorder writes one `.specbridge/runtime-results/*.runtime-result.json` artifact
- the result records exit code, files written, validations, policy result, stop conditions, and completion status
- validation covers successful and invalid runtime result artifacts
- no secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, live launch expansion, or deployment automation are involved

### 15. Controlled Source-Backed Runtime Slice

Goal:

Use the launch plan and runtime result layers for one small source-backed implementation slice.

Status:

Implemented as `specbridge summarize-runtime`, `scripts/validate-runtime-summaries.ps1`, CLI test coverage, negative validation coverage, and `.specbridge/runtime-summaries/issue-067-source-backed-runtime-slice.runtime-summary.json`.

Acceptance:

- one source-backed runtime task has a dedicated execution contract
- source paths, tests, docs, final report, audit packet, and ChatGPT/Codex audit are declared up front
- SpecBridge links one declared runtime launch plan and one declared runtime result artifact
- SpecBridge writes one validated runtime summary artifact
- GitHub CI, security gate, review gate, runtime result validation, runtime summary validation, audit packet validation, and ChatGPT/Codex audit pass before merge
- no secrets, production configuration, billing, auth security, dependency installation unless explicitly authorized, database changes, CI/CD weakening, or deployment automation are involved

### 16. Controlled Fresh Executor Source Run

Goal:

Create fresh executor output from a bounded source implementation task, then record and summarize that result through the launch, result, audit, CI, and merge gates.

Status:

Planned.

Acceptance:

- one fresh source implementation task has a dedicated execution contract
- exact source, test, docs, final report, audit packet, and ChatGPT/Codex audit paths are declared before execution
- the executor writes only inside the assigned scope
- SpecBridge records the runtime result from fresh declared executor evidence
- SpecBridge writes a runtime summary for the fresh result
- GitHub CI, security gate, review gate, runtime result validation, runtime summary validation, audit packet validation, and ChatGPT/Codex audit pass before merge
- no secrets, production configuration, billing, auth security, dependency installation unless explicitly authorized, database changes, CI/CD weakening, or deployment automation are involved
