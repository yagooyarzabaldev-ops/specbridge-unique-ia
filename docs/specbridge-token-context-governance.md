# SpecBridge Token And Context Governance

## Purpose

This document defines how SpecBridge governs Codex and Claude Code context, token, budget, and evidence behavior.

The goal is not to minimize tokens at any cost. The goal is to spend context intentionally, keep autonomous execution bounded, and preserve enough evidence for Codex to audit Claude Code without exposing secrets or raw conversation noise.

## Source Standard

This standard is backed by `.specbridge/policies/token-context-governance.json`, retrieved from current public provider documentation on 2026-06-16.

The policy records source URLs for:

- Claude Code CLI flags, including print mode, budget, session persistence, and turn-limit support.
- Claude Code cost guidance, including context size, prompt caching, and compaction.
- Claude Code settings, permissions, and filesystem boundaries.
- Claude Code MCP tool-search guidance for context-efficient tool discovery.
- Claude API context-window and prompt-caching behavior.
- Claude Code GitHub Actions security guidance for API key handling and least privilege.
- The OpenAI Codex manual for explicit task context, `AGENTS.md`, compaction, and token-count telemetry.

Provider docs may change. SpecBridge records the retrieval date and keeps the repository policy deterministic; future updates must be made through a new governed contract.

## Codex Context Rules

Codex must work from structured repository context:

- `README.md`
- `SPECBRIDGE.md`
- `AGENTS.md`
- `.specbridge/policy.yaml`
- `.specbridge/context/CURRENT_GOAL.md`
- the active execution contract
- the active scope manifest
- validation evidence and final reports

Codex must not pass raw ChatGPT conversations directly to Claude Code. User intent is converted into contract, scope, acceptance criteria, validations, stop conditions, and reporting requirements.

When context gets large, summaries may preserve:

- task goal
- allowed and blocked scope
- policy boundaries
- acceptance criteria
- changed files
- validations
- blockers
- unresolved risks

Summaries must not preserve secrets, provider tokens, raw hidden prompts, irrelevant chat history, or unbounded tool output.

## Claude Code Runtime Rules

SpecBridge live Claude Code launches must stay bounded.

Required runtime shape:

```text
claude -p --no-session-persistence --max-budget-usd <budget> --permission-mode <mode> --tools <tools> --allowedTools <tools> --input-format text
```

`--max-turns` is part of the current provider standard for bounded print-mode launches, but it must only be used by SpecBridge live execution after the installed Claude Code CLI exposes the flag. Until then, SpecBridge records the max-turns policy and relies on `--max-budget-usd` plus `TimeoutSeconds`.

Current SpecBridge limits:

- default `max_budget_usd`: `2.00`
- maximum `max_budget_usd`: `10.00`
- default max-turns policy target: `8`
- default timeout: `300` seconds
- timeout ceiling: `3600` seconds
- allowed tools: `Read`, `Write`, `Edit`
- dangerous permission bypass: blocked

Budget or usage-limit failures are runtime evidence. They are not proof that a spec is wrong. A retry is allowed only when the execution contract declares a bounded retry.

## MCP And Tool Context

Tool context must be treated as part of the budget.

SpecBridge should prefer deferred tool discovery and read-only MCP resources over loading every tool schema into every executor prompt. MCP instructions should be concise, task-specific, and front-load critical boundaries.

SpecBridge MCP resources remain read-only unless a future dedicated contract authorizes mutation.

## Agent SDK Loop Lightweight Practices

Issue #246 adopts the Agent SDK loop practices that fit the current local runtime without adding a hosted SDK app:

- bounded MCP tools declare `annotations.readOnlyHint: true` so SDK-style consumers can identify read-only tools for safe parallel read execution
- `CLAUDE.md` contains compaction and summary preservation instructions so long-running executor context keeps objective, contract, scope, acceptance criteria, files, validations, decisions, evidence pointers, risks, and rollback notes
- result handling expectations are recorded as future evidence fields: result subtype, stop reason, total cost, usage, turn count, and session id
- budget and turn limits remain governed by existing SpecBridge runtime policy, with `--max-turns` used only when the installed Claude CLI advertises support

Still blocked until a dedicated contract authorizes them:

- dependency installation or importing `claude_agent_sdk`
- hosted Agent SDK runtime or external storage
- Agent SDK hooks implementation
- SDK session resume, fork, or persistence implementation
- mutation-capable MCP tools
- network MCP transport or hosted MCP server deployment
- OpenTelemetry, deployment, production, billing, auth, database, cleanup, or CI/CD security changes

## Multi-Agent Slice Rules

Each Claude Code executor slice receives only:

- its task goal
- its execution contract
- its scope manifest
- exclusive write paths
- read-only context paths
- required validations
- stop conditions
- final report requirements

Parallel executors require non-overlapping `exclusive_write` scopes and a preflight budget check before launch.

No executor may widen its tools, budget, branch scope, write scope, or policy boundary after live execution starts unless the active contract explicitly allows it.

## Blocked Disclosures

SpecBridge must not reveal, record, or forward:

- provider API keys
- OAuth tokens
- private keys
- secrets
- raw hidden prompts
- raw ChatGPT transcripts
- raw unbounded stdout
- raw unbounded stderr
- billing account identifiers
- production credentials

Audit packets and runtime diagnostics must continue using bounded summaries, hashes, counts, paths, and redacted previews.

## Status Command

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command specbridge-token-governance-status
```

Optional file-backed evidence:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command specbridge-token-governance-status -OutputPath .specbridge/token-governance/current.status.json -Force
```

The command reads local repository policy only. It does not launch Claude Code, launch Codex, call the network, mutate GitHub, inspect secrets, change billing, change CI/CD security, enforce cleanup, or deploy.

## Completion Boundary

This standard governs how future token/context work should be evaluated. It does not enable new provider billing, new API keys, new deployment automation, CI/CD security changes, cleanup enforcement, artifact retention enforcement, or production use.
