# SpecBridge V5 Live Parallel Pilot Boundary

## Purpose

V5 is the first candidate phase for live parallel Antigravity execution.

Standard Loop v1 must be stable before V5 begins. V5 should not start from broad
automation. It should start from one small feature with multiple bounded executor
slices and a coordinator that waits for every slice before merge.

## Required Prerequisites

Before V5:

- Standard Loop v1 is merged.
- `standard-loop-status` reports `ok: true`.
- `execute-runtime-launch -DryRun` is validated.
- Runtime-run, runtime-result, runtime-summary, and autonomy metrics validators pass.
- Templates and schemas are present.
- CI authority is explicit and validated.
- ChatGPT/Codex audit validation is strict enough to reject contradictory evidence.
- `v5-pilot-status` reports `ok: true` from repository evidence.

## Readiness Gate

`v5-pilot-status` is the local readiness gate for the first live V5 pilot.

It checks:

- Standard Loop v1 required paths.
- Runtime evidence validators.
- Controlled runner dry-run evidence.
- V5 boundary documentation.
- Current goal memory pointing to V5.
- V5 readiness contract and scope.
- V5 executor handoff.
- At least two executor packets.
- At least two runtime launch plans.
- At least two dry-run runtime execution artifacts.
- At least two runtime summaries ready for policy gates.
- V5 autonomy metrics.

This readiness gate does not authorize live execution by itself. Live execution still requires a dedicated live pilot contract.

## V5 Pilot Shape

Recommended first V5 pilot:

```text
ChatGPT/Codex
  defines a small feature and acceptance criteria

SpecBridge Coordinator
  creates contract, scope, executor packets, runtime launches

Claude Code Executor A
  implements the feature

Claude Code Executor B
  writes or updates tests

Claude Code Executor C
  updates docs or audit support evidence

SpecBridge Coordinator
  records runtime evidence, summaries, metrics, audit packet, and final report

ChatGPT/Codex
  audits spec, security, scope, validation, CI, and report honesty
```

## Boundary

V5 may launch live parallel Antigravity sessions only when the active contract
explicitly authorizes:

- simultaneous executor sessions
- branch ownership
- exclusive write scopes
- allowed tools
- timeout and budget
- retry policy
- stop conditions
- coordinator merge gate

V5 must not touch secrets, production, billing, auth security, destructive
database changes, CI/CD weakening, or deployment automation.

## Completion Criteria

The V5 pilot is complete only when every executor summary is ready for policy
gates, autonomy metrics show no blocked slices, GitHub CI passes, ChatGPT/Codex
audit approves, and policy allows merge.
