# 001 - Product Requirements

## Objective

Build SpecBridge as a connector and orchestration layer that allows users to delegate software development work from ChatGPT/Codex to Claude Code.

## Primary User Problem

Users design, reason, and decide inside ChatGPT/Codex, but implementation context gets lost when work moves to Claude Code, IDEs, terminals, or GitHub.

Without a structured bridge, agents either ask for too many permissions, lose context, touch unrelated files, or generate ungoverned code.

## Primary Product Promise

Think in ChatGPT. Execute with Claude Code. Receive the final result.

## Required Capabilities

SpecBridge must be able to:

- convert ChatGPT/Codex context into structured repository files
- define execution contracts
- decompose a product goal into multiple agent-specific execution contracts
- coordinate multiple Claude Code executors working in parallel inside Antigravity
- assign non-overlapping write scopes
- aggregate evidence from parallel agent tasks
- enforce autonomy profiles
- classify task risk
- trigger Claude Code execution
- run or read validation gates
- request or read Codex review
- decide whether autonomous merge is allowed
- generate final reports

## Autonomy Requirements

The product must support at least three autonomy profiles:

1. assisted: human approval before implementation and merge.
2. vibe_autopilot: autonomous ordinary implementation, no autonomous merge unless selected by policy.
3. full_autopilot: autonomous implementation and merge when all gates pass.

Default profile:

SpecBridge uses `full_autopilot` by default once the repository policy enables autonomous merge and required gates are configured.

## Safety Requirements

SpecBridge must block or escalate:

- secret access
- destructive database changes
- production configuration changes
- billing changes
- critical authentication or authorization changes
- CI/CD security changes
- impossible acceptance criteria
- policy conflicts

## Non-Goals

SpecBridge is not:

- an unrestricted remote shell
- a raw ChatGPT conversation dumper
- a replacement for tests
- a replacement for GitHub governance
- a system that allows silent policy bypass

## MVP Requirement

The MVP must prove the complete loop from structured context to autonomous Claude Code execution, validation, review, policy decision, and final report.

## Multi-Agent Requirement

SpecBridge must treat multi-agent orchestration as a first-class product capability.

The product must support a future mode where multiple Claude Code executors work at the same time inside Antigravity, each with its own execution contract, write scope, validation commands, branch, final report, and escalation route.
