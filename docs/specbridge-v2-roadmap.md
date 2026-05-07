# SpecBridge V2 Roadmap

## Purpose

This document captures the SpecBridge V2 direction informed by the Claude Certified Architect foundations guide.

The purpose is not to implement V2 immediately. The purpose is to preserve the architecture decisions that should guide the next phase of SpecBridge.

## Current V1 Foundation

SpecBridge V1 foundation now includes:

- repository contract files
- Spec Driven Development specs
- agent instructions
- Claude Code instructions
- policy files
- autonomy profiles
- risk rules
- execution contract template
- execution contract examples
- context package
- issue template
- pull request template
- foundation validation script
- required GitHub Actions validation
- branch protection on `main`

This foundation is intentionally repository-first.

## V2 Thesis

SpecBridge V2 should evolve from repository governance into a Claude-native execution bridge.

The next version should connect:

```text
ChatGPT / Codex context
SpecBridge contracts
Claude Code configuration
MCP tool/resource interfaces
CI validation
Independent review
Final reporting
```

The architecture must preserve policy, auditability, and validation before introducing autonomous execution.

## V2 Scope

### 1. Claude Code Project Configuration Standard

SpecBridge should define a Claude-native project layout.

Target files and directories:

```text
.claude/rules/
.claude/commands/
.claude/skills/
docs/claude-code-configuration.md
```

Required decisions:

- which rules are always loaded
- which rules are path-scoped
- which slash commands are project-scoped
- which skills use `context: fork`
- which skills restrict tools with `allowed-tools`
- when Claude Code should use plan mode
- when Claude Code may use direct execution
- when Claude Code must stop

Rationale:

Claude Code should not depend only on a monolithic `CLAUDE.md`. V2 should use project-scoped commands, path-specific rules, and skills to reduce context noise and improve deterministic behavior.

### 2. MCP Integration Contract Standard

SpecBridge should define how MCP servers, tools, and resources are introduced.

Target files:

```text
.mcp.example.json
.specbridge/mcp-tool-contract-template.md
.specbridge/mcp-resource-contract-template.md
docs/mcp-integration-contract.md
```

Required decisions:

- project-scoped versus user-scoped MCP servers
- environment variable expansion for credentials
- MCP resources for exposing catalogs and summaries
- MCP tools for actions and state-changing operations
- tool description quality standards
- structured error response format
- retryability metadata
- permission error handling

Required structured MCP error shape:

```text
isError: true
errorCategory: transient | validation | permission | business
isRetryable: true | false
message: human-readable summary
attemptedAction: optional action description
partialResult: optional partial data
recoveryHint: optional next step
```

Rationale:

SpecBridge should not expose vague tools. Claude tool selection quality depends on clear descriptions, boundaries, inputs, outputs, and error semantics.

### 3. Claude Code CI Review Workflow Standard

SpecBridge should define how Claude Code may participate in CI and PR review.

Target files:

```text
docs/claude-code-ci-workflow.md
.specbridge/schemas/claude-review-output.schema.json
.specbridge/contracts/claude-code-review-contract-template.md
```

Required decisions:

- non-interactive Claude Code execution using `-p` or `--print`
- structured JSON output expectations
- JSON schema for review findings
- independent review instance pattern
- review categories allowed in CI
- false-positive reduction criteria
- severity classification rules
- how findings become PR comments
- how duplicate findings are avoided on reruns

Rationale:

Claude Code in CI must not hang waiting for interactive input. It must produce machine-readable output and should be isolated from the same session that generated the code.

### 4. Contract Validation Hardening

SpecBridge should validate execution contracts before any agent consumes them.

Target file:

```text
scripts/validate-contracts.ps1
```

Every file matching:

```text
.specbridge/contracts/*.execution.md
```

must include these sections:

- Contract Metadata
- Goal
- Context
- Source References
- Autonomy Profile
- Risk Level
- Allowed Scope
- Blocked Scope
- Acceptance Criteria
- Required Validations
- Stop Conditions
- Merge Policy
- Deployment Policy
- Final Report Requirements
- Completion Rule

Rationale:

Claude Code should not execute vague or incomplete contracts. Missing sections must fail validation before execution.

### 5. Context Management and Reliability Patterns

SpecBridge should define context lifecycle rules for long-running agentic workflows.

Target files:

```text
docs/context-management.md
.specbridge/context/CASE_FACTS.md
.specbridge/context/SOURCE_MANIFEST.md
.specbridge/context/EXECUTION_STATE.md
```

Required decisions:

- explicit context passing between agents
- source/provenance preservation
- scratchpad files for durable findings
- structured state files for recovery
- avoiding stale resumed sessions
- using fresh sessions with structured summaries when tool results are stale
- preserving dates, IDs, amounts, filenames, and source references exactly

Rationale:

Long sessions degrade. SpecBridge should persist critical facts and source mappings outside conversational memory.

### 6. Agentic Orchestration Patterns

SpecBridge should later support coordinator-subagent workflows, but not before contracts and validators are stable.

Future orchestration concepts:

- coordinator controls delegation
- subagents receive explicit context
- all subagent communication routes through coordinator
- parallel subagents may be used for independent work
- synthesis preserves attribution
- structured errors propagate upward
- deterministic gates block unsafe downstream actions

Rationale:

Multi-agent systems require controlled context passing, explicit tool scopes, and structured error propagation. Prompt-only enforcement is not enough for critical operations.

## V2 Non-Goals

V2 should not immediately add:

- production deployment automation
- billing
- unrestricted shell execution
- real MCP server implementation before contracts exist
- Agent SDK runtime before workflow contracts exist
- autonomous production changes
- secret handling
- destructive database operations

## Recommended Implementation Order

1. Add contract validation script.
2. Add Claude Code project configuration standard.
3. Add MCP integration contract standard.
4. Define Claude Code CI review workflow.
5. Add structured review output schema.
6. Add context management docs and state files.
7. Add Claude Code execution workflow.
8. Add independent Codex review workflow.
9. Add MCP server implementation only after tool contracts stabilize.
10. Add Agent SDK orchestration only after single-agent execution is reliable.

## Source Mapping

This roadmap is based on concepts from the Claude Certified Architect foundations guide, especially:

- Claude Code configuration hierarchy
- `.claude/rules/` path-specific rules
- `.claude/commands/` project-scoped slash commands
- `.claude/skills/` with `context: fork` and `allowed-tools`
- plan mode versus direct execution
- Claude Code CI usage with `-p` / `--print`
- structured JSON output for CI
- MCP tool and resource interface design
- structured MCP error responses
- explicit context passing between agents
- scratchpad/state files for long-running work
- independent review instances
- multi-pass review architecture
- provenance preservation

## Decision

SpecBridge should absorb these concepts as V2 specifications first.

Implementation should remain blocked until validators and execution contracts are strong enough to prevent vague or unsafe agent execution.
