# 002 - Architecture

## Architecture Principle

SpecBridge must separate intent, policy, execution, validation, review, and reporting.

No single agent should be trusted as the only source of truth.

## Logical Components

### 1. Context Package

Structured repository files created from ChatGPT/Codex context.

Expected files:

- .specbridge/context/CODEX_CONTEXT.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md
- .specbridge/context/DO_NOT_TOUCH.md
- .specbridge/context/STYLE_GUIDE.md

### 2. Policy Engine

Reads policy, autonomy profiles, risk rules, and execution contracts.

Determines:

- whether execution may start
- whether Claude Code may continue
- whether a task must stop
- whether autonomous merge is allowed
- whether deployment is allowed

### 3. Claude Code Executor

Executes the implementation task inside the allowed scope.

Claude Code should not ask for ordinary implementation permissions.

Claude Code must stop for policy boundaries.

### 4. GitHub Orchestration

Coordinates issues, branches, pull requests, CI, review, and audit trail.

### 5. Codex Review

Reviews implementation against specs, acceptance criteria, policy, and risk.

### 6. Final Reporter

Produces concise final reports for the user.

## MVP Architecture

The MVP may be repository-first and file-based.

It does not require a SaaS dashboard.

It should prove the workflow using specs, policy files, GitHub, Claude Code, CI, and Codex review.

## Future Architecture

Future versions may include:

- MCP server
- GitHub App
- dashboard
- hosted policy engine
- multi-repository support
- provider abstraction for multiple coding agents
