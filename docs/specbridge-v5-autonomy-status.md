# SpecBridge V5 Autonomy Status

## Purpose

`v5-autonomy-status` is a deterministic local CLI status command that reports the
target autonomy standard for live V5 execution.

It makes the next standard explicit: all implementation, tests, and documentation
slices must complete through live Claude Code execution without coordinator
remediation. It does not launch Claude Code, read runtime evidence, call GitHub,
install dependencies, access secrets, touch production, or modify any environment.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-autonomy-status
```

## Output Fields

The command returns a JSON object with the following fields:

| Field | Type | Description |
|---|---|---|
| `command` | string | Always `"v5-autonomy-status"`. Identifies the command that produced the output. |
| `ok` | boolean | `true` when the autonomy standard is active and coordinator remediation is not allowed for product slices. |
| `branch` | string | The current git branch at the time the command ran. |
| `head` | string | The current git commit SHA at the time the command ran. |
| `autonomy_standard` | string | The label identifying the active autonomy standard. Always `"v5_live_no_coordinator_remediation"`. |
| `prior_live_pilot_status` | string | The completion status of the first V5 live pilot. Always `"completed_with_coordinator_remediation"`. |
| `target_live_pilot_status` | string | The required completion status for the second live pilot. Always `"completed_without_coordinator_remediation"`. |
| `required_slices` | array of strings | The slice identifiers that must each complete via live Claude Code execution. Always `["implementation", "tests", "docs"]`. |
| `coordinator_remediation_allowed` | boolean | `false`. The coordinator must not author product changes to implementation, tests, documentation, or README after live execution starts. |
| `policy_boundary` | string | A fixed statement confirming the policy boundary in effect. See below. |

### Policy Boundary Field

The `policy_boundary` field always contains:

```text
no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment
```

This confirms that `v5-autonomy-status` only reports the autonomy standard. It
does not trigger any launch, deployment, secret access, production configuration
change, authentication change, authorization change, billing change, database
change, dependency installation, or CI/CD security change.

### Example Output

```json
{
  "command": "v5-autonomy-status",
  "ok": true,
  "branch": "codex/second-v5-live-pilot",
  "head": "1d35e54",
  "autonomy_standard": "v5_live_no_coordinator_remediation",
  "prior_live_pilot_status": "completed_with_coordinator_remediation",
  "target_live_pilot_status": "completed_without_coordinator_remediation",
  "required_slices": ["implementation", "tests", "docs"],
  "coordinator_remediation_allowed": false,
  "policy_boundary": "no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment"
}
```

## Required Slices

The second V5 live pilot requires three product slices, each executed as an
independent bounded live Claude Code session:

| Slice | Primary Write Paths | Purpose |
|---|---|---|
| `implementation` | `scripts/specbridge.ps1` | Add the `v5-autonomy-status` command to the CLI |
| `tests` | `scripts/test-specbridge-cli.ps1` | Add CLI tests covering `v5-autonomy-status` |
| `docs` | `README.md`, `docs/specbridge-v5-autonomy-status.md` | Document the command and update the README See list |

Each slice must:

- run through `execute-runtime-launch -Force` with a runtime launch plan
- write its declared exclusive paths and executor evidence
- produce a runtime-run, runtime-result, and runtime-summary artifact
- reach `ready_for_policy_gates` in its runtime summary

All three slices must complete before the autonomy metrics report
`summary_count: 3`, `ready_count: 3`, `blocked_count: 0`, and
`policy_gate_ready_rate: 1`.

## No-Coordinator-Remediation Target

The first V5 live pilot completed, but the CLI implementation slice failed twice
and required coordinator remediation. The coordinator authored the product change
inside declared scope. This is a valid completion for the first pilot, but it is
not the target autonomy standard.

The no-coordinator-remediation target requires:

- All three required slices complete via live Claude Code execution.
- At most one live retry is allowed per slice.
- Any retry is a live executor retry, not coordinator-authored product code.
- The coordinator must not author changes to `scripts/specbridge.ps1`,
  `scripts/test-specbridge-cli.ps1`, `README.md`, or
  `docs/specbridge-v5-autonomy-status.md` after live execution starts.
- If a slice fails twice, the pilot is blocked; it does not become a coordinator
  remediation opportunity.

The `coordinator_remediation_allowed: false` output field records this target as
machine-readable evidence in every `v5-autonomy-status` response.

## Policy Boundary

`v5-autonomy-status` operates entirely within the following policy boundary:

- No launch. The command does not start Claude Code, Antigravity, or any
  subprocess other than reading git state.
- No deploy. The command does not trigger any deployment.
- No secret access. The command does not read `.env`, tokens, credentials,
  production configuration, or any protected file.
- No production changes. The command does not modify any production or staging
  environment.
- No billing changes. The command does not interact with any billing or payment
  provider.
- No authentication or authorization changes. The command does not modify any
  auth configuration.
- No database changes. The command does not touch any database.
- No CI/CD changes. The command does not alter any CI/CD workflow or security
  control.
- No dependency installation. The command does not install packages or modify
  lockfiles.

The `policy_boundary` output field in every response records this boundary as
machine-readable evidence.

## Integration with the Second V5 Live Pilot

`v5-autonomy-status` is the autonomy-standard gate for the second V5 live pilot.

The standard sequence is:

1. `runtime-capability-status` confirms Claude Code CLI and Antigravity are
   discoverable.
2. `v5-live-status` confirms `readiness_status: ready_for_second_live_pilot`.
3. `v5-autonomy-status` confirms `ok: true` and
   `coordinator_remediation_allowed: false`.
4. Each required slice runs through `execute-runtime-launch -Force`.
5. Runtime-run, runtime-result, and runtime-summary artifacts are recorded.
6. Autonomy metrics are produced and validated.
7. Final report, audit packet, and ChatGPT/Codex audit are completed.
8. Policy-gated merge proceeds after all local validations and GitHub CI pass.

## Related Documentation

- `docs/specbridge-v5-live-status.md` - `v5-live-status` command and first pilot result.
- `docs/specbridge-runtime-capability-status.md` - `runtime-capability-status` pre-flight check.
- `docs/specbridge-runtime-runner.md` - How `execute-runtime-launch` works and what it produces.
- `docs/specbridge-v5-live-parallel-pilot-boundary.md` - V5 boundary, prerequisites, and completion criteria.
- `docs/specbridge-autonomy-metrics.md` - Autonomy metrics format and fields.
- `docs/specbridge-runtime-summaries.md` - Runtime summary format and merge readiness.
- `docs/specbridge-standard-loop-v1.md` - The canonical Standard Loop that V5 extends.
