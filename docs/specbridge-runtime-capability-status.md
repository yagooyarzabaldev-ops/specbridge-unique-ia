# SpecBridge Runtime Capability Status

## Purpose

`runtime-capability-status` is a local CLI command that reports whether the Claude Code CLI and Antigravity application are discoverable before live runtime work starts.

It is a pre-flight check. It does not launch Claude Code. It does not start Antigravity. It does not access secrets, production, billing, authentication, or deployment configuration.

## Usage

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
```

## Output Fields

The command returns a JSON object with the following fields:

| Field | Type | Description |
|---|---|---|
| `command` | string | Always `"runtime-capability-status"`. Identifies the command that produced the output. |
| `ok` | boolean | `true` when both `claude.available` and `antigravity.available` are `true`. `false` when either is not discoverable. |
| `branch` | string | The current git branch at the time the command ran. |
| `head` | string | The current git commit SHA at the time the command ran. |
| `claude.available` | boolean | `true` when the Claude Code CLI binary is found on the system path or at the resolved path. |
| `claude.path` | string or null | The resolved path to the Claude Code CLI binary, or `null` when not found. |
| `claude.version` | string or null | The version string reported by the Claude Code CLI binary, or `null` when not found or not executable. |
| `antigravity.available` | boolean | `true` when the Antigravity application directory or executable is discoverable at its expected local path. |
| `antigravity.path` | string or null | The resolved path to the Antigravity application, or `null` when not found. |
| `policy_boundary` | string | A fixed statement confirming the policy boundary in effect. See below. |

### Policy Boundary Field

The `policy_boundary` field always contains:

```text
no-launch no-deploy no-secret-access
```

This confirms that `runtime-capability-status` only checks local path discoverability. It does not trigger any launch, deployment, secret access, production configuration change, authentication change, authorization change, billing change, database change, or CI/CD change.

### Example Output: Both Available

```json
{
  "command": "runtime-capability-status",
  "ok": true,
  "branch": "codex/v5-live-parallel-pilot",
  "head": "5ce5549",
  "claude": {
    "available": true,
    "path": "C:\\Users\\oyarz\\AppData\\Roaming\\npm\\claude.cmd",
    "version": "1.x.x"
  },
  "antigravity": {
    "available": true,
    "path": "D:\\Antigravity"
  },
  "policy_boundary": "no-launch no-deploy no-secret-access"
}
```

### Example Output: Claude Code Not Found

```json
{
  "command": "runtime-capability-status",
  "ok": false,
  "branch": "codex/v5-live-parallel-pilot",
  "head": "5ce5549",
  "claude": {
    "available": false,
    "path": null,
    "version": null
  },
  "antigravity": {
    "available": true,
    "path": "D:\\Antigravity"
  },
  "policy_boundary": "no-launch no-deploy no-secret-access"
}
```

## Antigravity Availability vs. Claude Code Runner Execution

These are two distinct checks that must not be conflated.

### Antigravity Availability

`antigravity.available` reports whether the Antigravity application is discoverable at its expected local path.

A positive result means:

- The Antigravity directory or executable exists at the expected location.
- The local machine has Antigravity installed.

A positive result does not mean:

- Antigravity is currently running.
- Antigravity is ready to accept a new session.
- A live Claude Code executor has been launched inside Antigravity.
- Any runtime work has started.

### Claude Code Runner Execution

Live Claude Code execution happens through `execute-runtime-launch`, not through `runtime-capability-status`.

`execute-runtime-launch` takes a runtime launch plan, applies allowed tools, budget, and timeout constraints, and starts a bounded non-interactive Claude Code session.

`runtime-capability-status` does not call `execute-runtime-launch`. It only verifies that the Claude Code CLI binary is discoverable and reports its version. This is a path check, not a launch.

### Summary of the Distinction

| Capability | What It Means | What It Does Not Mean |
|---|---|---|
| `antigravity.available: true` | Antigravity app is found at its local path | Antigravity is running or accepting sessions |
| `claude.available: true` | Claude Code CLI binary is discoverable | Claude Code has been launched or is executing |
| `ok: true` | Both binaries are discoverable | Any live runtime session has started |
| `execute-runtime-launch` | Starts a bounded live Claude Code session | Only runs when a runtime launch plan authorizes it |

This distinction is intentional. `runtime-capability-status` is a safe, read-only pre-flight check that can run at any time without side effects.

## Policy Boundary

`runtime-capability-status` operates entirely within the following policy boundary:

- No launch. The command does not start Claude Code, Antigravity, or any subprocess other than reading path and version information.
- No deploy. The command does not trigger any deployment.
- No secret access. The command does not read `.env`, tokens, credentials, production configuration, or any protected file.
- No production changes. The command does not modify any production or staging environment.
- No billing changes. The command does not interact with any billing or payment provider.
- No authentication or authorization changes. The command does not modify any auth configuration.
- No database changes. The command does not touch any database.
- No CI/CD changes. The command does not alter any CI/CD workflow or security control.
- No dependency installation. The command does not install packages or modify lockfiles.

The `policy_boundary` output field in every response records this boundary as machine-readable evidence.

## Integration with V5 Live Parallel Pilot

`runtime-capability-status` is the pre-flight readiness check for the V5 live parallel pilot.

Before any live `execute-runtime-launch -Force` execution runs, `runtime-capability-status` must report `ok: true`. This confirms that:

- The Claude Code CLI is available to be launched by the controlled runner.
- The Antigravity application is present on the machine.

After `runtime-capability-status` passes, the standard runner proceeds to launch bounded executor sessions through `execute-runtime-launch -Force` with explicit allowed tools, budget, and timeout. Those sessions produce runtime evidence, which is separate from the `runtime-capability-status` output.

## Related Documentation

- `docs/specbridge-v5-live-parallel-pilot-boundary.md` - V5 boundary, prerequisites, and completion criteria.
- `docs/specbridge-runtime-runner.md` - How `execute-runtime-launch` works and what it produces.
- `docs/specbridge-standard-loop-v1.md` - The canonical Standard Loop that V5 extends.
- `docs/specbridge-runtime-launch-plans.md` - Runtime launch plan format and fields.
- `docs/specbridge-runtime-results.md` - Runtime result format and fields.
- `docs/specbridge-runtime-summaries.md` - Runtime summary format and merge readiness.
