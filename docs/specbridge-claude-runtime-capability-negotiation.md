# SpecBridge Claude Runtime Capability Negotiation

## Overview

SpecBridge uses bounded Claude Code runtime launches only through governed runtime launch plans and `execute-runtime-launch -Force`.

Some Claude CLI flags are conditional across installed versions. `--max-turns` is one of those flags: SpecBridge policy wants it when available, but older local Claude CLI builds may not expose it.

This standard makes that decision explicit.

## Runtime Capability Status

`runtime-capability-status` now reports:

- Claude CLI availability
- Claude CLI path
- Claude CLI version when available
- `help_probe_status`
- `supports_max_turns`
- conditional flag metadata for `--max-turns`

The command probes `claude --help` with a short timeout and does not store raw help output.

## Launch Planning

`prepare-runtime-launch` records the desired turn limit:

```json
"max_turns": 8
```

It also records conditional metadata:

```json
"conditional_flags": {
  "max_turns": {
    "flag": "--max-turns",
    "desired_value": 8,
    "apply_when": "claude_help_exposes_flag"
  }
}
```

This is planning metadata. It does not launch Claude Code and it does not spend provider tokens.

## Runtime Execution

`execute-runtime-launch` behaves differently for dry runs and live runs:

- Dry run: does not probe Claude, does not launch Claude, and records `applied=false`.
- Live run: probes `claude --help` with a short timeout, applies `--max-turns <value>` only when the help output exposes the flag, and records the decision.

Runtime execution artifacts include:

```json
"claude_capabilities": {
  "max_turns": {
    "flag": "--max-turns",
    "desired_value": 8,
    "supported": true,
    "applied": true,
    "probe_source": "claude --help",
    "probe_status": "completed",
    "reason": "supported_by_claude_help"
  }
}
```

When unsupported, `supported=false`, `applied=false`, and the effective `command_summary` omits `--max-turns`.

## Token And Budget Boundary

This negotiation does not authorize unbounded token spending.

The runtime still requires:

- `--max-budget-usd`
- `--no-session-persistence`
- bounded timeout
- declared allowed tools
- repository-scoped runtime launch plan
- `-Force` for live execution
- redacted bounded diagnostics

If `--max-turns` is unavailable, SpecBridge relies on `max_budget_usd` plus `TimeoutSeconds` and records the unsupported capability as evidence.

## Validation

The CLI regression suite uses fake Claude binaries to prove both cases without spending provider tokens:

- fake Claude supports `--max-turns`: command includes the flag and evidence records `applied=true`.
- fake Claude omits `--max-turns`: command omits the flag and evidence records `applied=false`.

Validators accept the new optional runtime fields while keeping historical runtime artifacts valid.
