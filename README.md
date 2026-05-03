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

The default workflow is Vibe Autopilot:

1. The user defines the goal.
2. ChatGPT/Codex creates the executable context.
3. SpecBridge creates the execution contract.
4. Claude Code implements without step-by-step permission requests.
5. CI validates the result.
6. Codex reviews the implementation.
7. SpecBridge reports the final outcome.

## Core Principle

SpecBridge does not remove control.

SpecBridge moves control from constant human interruption to explicit policy, context, tests, review, and auditability.

The system should not ask the user for permission during normal implementation work. It should stop only when a defined policy boundary is reached.

## Main Roles

### ChatGPT / Codex

Responsible for intent, context, specs, acceptance criteria, and review.

### SpecBridge

Responsible for execution contracts, policy enforcement, GitHub orchestration, and final reports.

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