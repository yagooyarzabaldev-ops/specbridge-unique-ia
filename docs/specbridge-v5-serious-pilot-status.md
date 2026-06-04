# SpecBridge V5 Serious Pilot Status

## Purpose

`v5-serious-pilot-status` is a deterministic local CLI status command that reports
the standards, baseline, and policy boundary for the V5 serious live pilot.

It makes the next pilot explicit: three live Claude Code slices (`status`, `tests`,
`docs`) must each complete through bounded live execution without coordinator
remediation. It does not launch Claude Code, read runtime evidence, call GitHub,
install dependencies, access secrets, touch production, or modify any environment.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-serious-pilot-status
```

## Output Fields

The command returns a JSON object with the following fields:

| Field | Type | Description |
|---|---|---|
| `command` | string | Always `"v5-serious-pilot-status"`. Identifies the command that produced the output. |
| `ok` | boolean | `true` when the pilot standard is active and coordinator remediation is not allowed. |
| `branch` | string | The current git branch at the time the command ran. |
| `head` | string | The current git commit SHA at the time the command ran. |
| `pilot_standard` | string | The label identifying the active pilot standard. Always `"serious_live_multi_slice_no_remediation"`. |
| `runner_baseline` | string | The runtime runner baseline in effect. Always `"v5_hardened_runtime_runner"`. |
| `required_slices` | array of strings | The slice identifiers that must each complete via live Claude Code execution. Always `["status","tests","docs"]`. |
| `default_runtime_budget_usd` | string | The default USD budget cap for each live slice launch. Always `"2.00"`. |
| `diagnostic_preview_policy` | string | The preview redaction and normalization policy for failure diagnostics. Always `"ascii_stable_bounded_240_chars"`. |
| `target_completion_status` | string | The required completion status for this pilot. Always `"completed_without_coordinator_remediation"`. |
| `coordinator_remediation_allowed` | boolean | `false`. The coordinator must not author product changes to any live slice after execution starts. |
| `policy_boundary` | string | A fixed statement confirming the policy boundary in effect. See below. |

### Policy Boundary Field

The `policy_boundary` field always contains:

```text
no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment
```

This confirms that `v5-serious-pilot-status` only reports the pilot standard. It
does not trigger any launch, deployment, secret access, production configuration
change, authentication change, authorization change, billing change, database
change, dependency installation, or CI/CD security change.

### Example Output

```json
{
  "command": "v5-serious-pilot-status",
  "ok": true,
  "branch": "codex/issue087-budget-aware-v5-status",
  "head": "cc26aef",
  "pilot_standard": "serious_live_multi_slice_no_remediation",
  "runner_baseline": "v5_hardened_runtime_runner",
  "required_slices": ["status", "tests", "docs"],
  "default_runtime_budget_usd": "2.00",
  "diagnostic_preview_policy": "ascii_stable_bounded_240_chars",
  "target_completion_status": "completed_without_coordinator_remediation",
  "coordinator_remediation_allowed": false,
  "policy_boundary": "no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment"
}
```

## Required Slices

This pilot requires three product slices, each executed as an independent bounded
live Claude Code session:

| Slice | Primary Write Paths | Purpose |
|---|---|---|
| `status` | `scripts/specbridge.ps1` | Add the `v5-serious-pilot-status` command to the CLI |
| `tests` | `scripts/test-specbridge-cli.ps1` | Add CLI tests covering `v5-serious-pilot-status` and timeout exit-code normalization |
| `docs` | `README.md`, `docs/specbridge-v5-serious-pilot-status.md` | Document the command and update the README |

Each slice must:

- run through `execute-runtime-launch -Force` with a runtime launch plan using
  `allowed_tools: ["Edit","Read","Write"]` and `max_budget_usd: "2.00"`
- write its declared exclusive paths and executor evidence
- produce a runtime-run, runtime-result, and runtime-summary artifact
- reach `ready_for_policy_gates` in its runtime summary

All three slices must complete before the autonomy metrics report
`summary_count: 3`, `ready_count: 3`, `blocked_count: 0`, and
`policy_gate_ready_rate: 1`.

## Hardened Runner Baseline

The `runner_baseline` field reports `v5_hardened_runtime_runner`. This baseline
includes the following hardening measures added during issue 082 and the second
V5 live autonomy pilot closure:

- **Default live budget cap of `2.00` USD.** Runtime launch plans for live
  slices use `max_budget_usd: "2.00"` as the default. This matches the proven
  tool baseline from issue 080 and prevents runaway spend.
- **ASCII-stable diagnostic previews.** The `execute-runtime-launch` runner
  normalizes all non-ASCII and multibyte characters in stdout and stderr to `?`
  before truncating to 240 characters. This ensures validators and shells agree
  on byte length and that previews do not contain characters that break JSON
  serialization or terminal output.
- **Timeout artifact normalization.** When a live Claude Code child process is
  killed after the timeout deadline, the runner normalizes the OS exit code to
  `255` if the raw value falls outside the validator-compatible range `[0, 255]`.
  This prevents runtime-execution artifacts from recording `exit_code: -1`, which
  fails schema validation.
- **Local-only agent settings ignore rules.** The `.gitignore` excludes
  `.claude/settings.local.json` so that local Antigravity permission overrides
  are not committed to the repository.

## Timeout Artifact Normalization

Issue 086 exposed that a killed Claude process can return `exit_code: -1`. The
runtime-execution schema validator requires exit codes in the range `[0, 255]`,
so a `-1` artifact would fail validation.

The hardened runner adds this guard at lines 2883-2885 of `scripts/specbridge.ps1`:

```powershell
if ($timedOut -and ($exitCode -lt 0 -or $exitCode -gt 255)) {
  $exitCode = 255
}
```

This normalization runs only when `$timedOut` is `true`, so successful and
normally-failing runs are not affected. The normalized exit code `255` is
preserved in the runtime-execution artifact and in the `failure_diagnostics`
object, which also records `timed_out: true` and `reason: "timeout"` so the
cause remains auditable.

## No-Coordinator-Remediation Target

The no-coordinator-remediation target requires:

- All three required slices (`status`, `tests`, `docs`) complete via live Claude
  Code execution.
- At most one live retry is allowed per slice.
- Any retry is a live executor retry, not coordinator-authored product code.
- The coordinator must not author changes to `scripts/specbridge.ps1`,
  `scripts/test-specbridge-cli.ps1`, `README.md`, or
  `docs/specbridge-v5-serious-pilot-status.md` after live execution starts.
- If a slice fails twice, the pilot is blocked; it does not become a coordinator
  remediation opportunity.

The `coordinator_remediation_allowed: false` output field records this target as
machine-readable evidence in every `v5-serious-pilot-status` response.

## Policy Boundary

`v5-serious-pilot-status` operates entirely within the following policy boundary:

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

## Integration with the V5 Serious Pilot

`v5-serious-pilot-status` is the autonomy-standard gate for the V5 serious live
pilot. It follows `v5-autonomy-status` and extends it with the hardened runner
baseline and the `status`, `tests`, `docs` slice set.

The standard sequence is:

1. `runtime-capability-status` confirms Claude Code CLI and Antigravity are
   discoverable.
2. `v5-serious-pilot-status` confirms `ok: true`,
   `runner_baseline: v5_hardened_runtime_runner`, and
   `coordinator_remediation_allowed: false`.
3. Each required slice runs through `execute-runtime-launch -Force` with
   `allowed_tools: ["Edit","Read","Write"]` and `max_budget_usd: "2.00"`.
4. Runtime-run, runtime-result, and runtime-summary artifacts are recorded.
5. Autonomy metrics are produced and validated.
6. Final report, audit packet, and ChatGPT/Codex audit are completed.
7. Policy-gated merge proceeds after all local validations and GitHub CI pass.

## Related Documentation

- `docs/specbridge-v5-autonomy-status.md` - `v5-autonomy-status` command and second pilot autonomy standard.
- `docs/specbridge-v5-live-status.md` - `v5-live-status` command and first pilot result.
- `docs/specbridge-runtime-capability-status.md` - `runtime-capability-status` pre-flight check.
- `docs/specbridge-runtime-runner.md` - How `execute-runtime-launch` works and what it produces.
- `docs/specbridge-v5-live-parallel-pilot-boundary.md` - V5 boundary, prerequisites, and completion criteria.
- `docs/specbridge-autonomy-metrics.md` - Autonomy metrics format and fields.
- `docs/specbridge-runtime-summaries.md` - Runtime summary format and merge readiness.
- `docs/specbridge-standard-loop-v1.md` - The canonical Standard Loop that V5 extends.
