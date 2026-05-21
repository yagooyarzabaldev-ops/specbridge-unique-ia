# SpecBridge

SpecBridge is a standard connector for turning ChatGPT/Codex context into autonomous Claude Code execution.

## Core Idea

Think and define in ChatGPT.
Structure and govern with Codex.
Execute autonomously with Claude Code.
Validate with CI.
Review with Codex.
Report the final result to the user.

## Product Vision

SpecBridge allows a user to delegate software development work from ChatGPT/Codex to Claude Code without approving every individual step.

SpecBridge also supports a multi-agent product direction: one governed goal may be decomposed into multiple execution contracts so several Claude Code executors can work in parallel inside Antigravity without losing scope control, validation, review, or auditability.

The default workflow is Vibe Autopilot:

1. The user defines the goal.
2. ChatGPT/Codex creates the executable context.
3. SpecBridge creates the execution contract.
4. Claude Code implements without step-by-step permission requests.
5. CI validates the result.
6. Codex reviews the implementation.
7. SpecBridge reports the final outcome.

The default autonomy profile is now Full Autopilot:

- ordinary implementation proceeds without step-by-step approval
- validation failures are fixed automatically when inside scope
- pull requests may be updated automatically
- merge may happen automatically only when all required gates pass
- production deployment remains manual unless a future policy explicitly enables it

## Core Principle

SpecBridge does not remove control.

SpecBridge moves control from constant human interruption to explicit policy, context, tests, review, and auditability.

The system should not ask the user for permission during normal implementation work. It should stop only when a defined policy boundary is reached.

## Main Roles

### ChatGPT / Codex

Responsible for intent, context, specs, acceptance criteria, and review.

### SpecBridge

Responsible for execution contracts, policy enforcement, multi-agent coordination, GitHub orchestration, and final reports.

### Claude Code

Responsible for implementation, tests, fixes, pull requests, and autonomous execution inside the allowed scope.

### GitHub

Responsible for repository state, issues, branches, pull requests, CI, and audit trail.

## Non-Goals

SpecBridge is not:

- an unrestricted remote shell
- a random chat-to-terminal executor
- a replacement for tests
- a system that sends raw ChatGPT conversations to Claude Code
- a system that touches secrets, production, billing, or destructive infrastructure without policy authorization

## MVP Goal

The first MVP must prove this flow:

1. Store context as repository files.
2. Create an executable task.
3. Let Claude Code implement autonomously.
4. Run CI validation.
5. Let Codex review.
6. Merge only if policy allows it.
7. Produce a final report.

## Current Status

SpecBridge currently has three governed status layers:

- V1 foundation: complete and validated locally.
- Repository-first MVP: complete as a controlled loop using context files, execution contracts, validation scripts, PR gates, review artifacts, and final reports.
- V3 essential product scope: defined for the next runtime phase, with implementation still blocked until a dedicated execution contract authorizes source paths, test strategy, lint, typecheck, and build gates.
- V4 product contract: defined for local CLI, MCP, GitHub evidence integration, dashboard boundaries, data model boundaries, runtime gates, completion criteria, and Version 5 candidates.
- Branch-per-executor orchestration: implemented as deterministic branch plans, coordinator simulation evidence, and a controlled GitHub evidence run with real child PR URLs, passed child CI, and ChatGPT/Codex audit status.
- Operational autonomy cleanup: evidence-only child PRs are closed without merge, issue 42 is closed as completed, and stale GitHub evidence is resolved.
- Controlled Antigravity/Claude Code runtime launch: implemented as a bounded non-interactive Claude Code run from the Antigravity workspace, with SpecBridge executor packet evidence, one executor-written runtime artifact, validation evidence, and ChatGPT/Codex audit.
- Default automation: Full Autopilot is enabled for autonomous merge after required gates pass; production deployment remains disabled.

See:

- `docs/specbridge-phase-completion.md`
- `docs/specbridge-mvp-operating-runbook.md`
- `docs/specbridge-v3-essential-product-scope.md`
- `docs/specbridge-v4-product-contract.md`
- `docs/specbridge-multi-agent-antigravity-architecture.md`
- `docs/specbridge-branch-per-executor-orchestration.md`
- `docs/specbridge-controlled-github-evidence-run.md`
- `docs/specbridge-operational-autonomy-policy-closure.md`
- `docs/specbridge-controlled-antigravity-runtime-launch.md`
- `docs/specbridge-autonomy-backlog.md`
