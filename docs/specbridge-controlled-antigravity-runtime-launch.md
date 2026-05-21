# SpecBridge Controlled Antigravity Runtime Launch

## Purpose

This document records the first controlled SpecBridge runtime launch where ChatGPT/Codex created the execution contract, SpecBridge prepared an executor packet, Claude Code ran non-interactively from the Antigravity workspace, and the result stayed inside a declared evidence-only write scope.

The launch proves the smallest safe version of the intended loop:

```text
ChatGPT / Codex contract
SpecBridge executor packet
Claude Code runtime executor
SpecBridge validation and audit
GitHub pull request and CI
```

## Controlled Scope

The active issue is:

```text
https://github.com/yagooyarzabaldev-ops/specbridge/issues/61
```

The execution contract is:

```text
.specbridge/contracts/issue-061-controlled-antigravity-runtime-launch.execution.md
```

The executor handoff input is:

```text
.specbridge/executor-handoffs/issue-061-controlled-antigravity-runtime-launch.input.json
```

SpecBridge generated the executor packet:

```text
.specbridge/executor-packets/issue-061-controlled-antigravity-runtime-launch-claude-runtime.executor-packet.json
```

Claude Code was allowed to write only:

```text
.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md
```

## Runtime Invocation

The runtime was launched from the repository workspace under `D:\Antigravity\Infinite Process\specbridge`.

Runtime availability checks:

- `claude --version`: `2.1.126 (Claude Code)`
- `antigravity --help`: `Antigravity 1.107.0`
- Claude readiness probe: `SPECBRIDGE_CLAUDE_READY`

The executor run used non-interactive Claude Code print mode with a bounded prompt and constrained tools:

```text
claude -p --no-session-persistence --max-budget-usd 0.25 --permission-mode acceptEdits --tools "Read,Write" --allowedTools "Read,Write"
```

Claude Code did not receive shell access for this first runtime launch. Local validation remained the coordinator responsibility after the executor wrote its evidence artifact.

## Evidence Files

Runtime evidence is recorded in:

```text
.specbridge/runtime-evidence/issue-061-controlled-antigravity-runtime-launch.claude-run.json
.specbridge/runtime-evidence/issue-061-claude-runtime-executor-output.md
```

The evidence records:

- Claude Code availability
- Antigravity CLI availability
- executor packet generation
- bounded runtime invocation
- exclusive executor write scope
- delegated validation responsibility
- policy boundary results

## Runtime Boundary

This launch does not add product runtime code.

It does not install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, modify CI/CD security controls, touch production, access protected credentials, modify auth or billing surfaces, change database schema, or deploy anything.

## Next Runtime Step

After this launch is merged, the next product step should be a dedicated controlled runtime implementation slice.

That later contract may authorize a small source-backed feature only if it declares exact source paths, tests, lint, typecheck, build gates, security gates, executor branch rules, and ChatGPT/Codex audit requirements.
