# SpecBridge Runtime Runner Evidence

## Purpose

Runtime-run artifacts capture the operator-observed result of a bounded executor
launch before the broader runtime result and summary layers are produced.

A runtime launch plan says how an executor may run. A runtime-run artifact records
which launch plan was used, which executor evidence file was produced, which files
were written, which tools were allowed, and whether the bounded invocation
completed inside policy.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 run-runtime-launch `
  -InputPath .specbridge/runtime-launches/<task>.runtime-launch.json `
  -EvidencePath .specbridge/runtime-evidence/<executor-output>.md `
  -OutputPath .specbridge/runtime-runs/<task>.runtime-run.json `
  -RuntimeExitCode 0 `
  -WrittenFile docs/<executor-output>.md `
  -WrittenFile .specbridge/runtime-evidence/<executor-output>.md `
  -Validation "executor invocation: passed" `
  -PolicyResult "Passed." `
  -CompletionStatus complete
```

The command is evidence capture only. It does not launch Claude Code, launch
Antigravity, run shell commands inside the executor, call GitHub, install
dependencies, touch secrets, touch production, or deploy.

## Controlled Runtime Execution Diagnostics

`execute-runtime-launch` produces runtime execution artifacts under:

```text
.specbridge/runtime-executions/*.runtime-execution.json
```

New runtime execution artifacts include `failure_diagnostics`.

They also include Claude capability negotiation evidence for conditional runtime
flags. `execute-runtime-launch` records the desired `max_turns` value and a
`claude_capabilities.max_turns` object showing whether `--max-turns` was
supported by `claude --help`, whether it was applied, the probe status, and the
reason for the decision.

Dry runs do not probe or launch Claude. Live runs probe `claude --help` with a
short timeout and include `--max-turns <value>` only when the installed CLI
reports support for that flag. If unsupported, the runner omits the flag and
continues to rely on `max_budget_usd` plus `TimeoutSeconds`.

The diagnostics object records:

- status
- reason
- exit code
- timeout state
- redaction policy
- bounded stdout preview
- bounded stderr preview

The previews are capped at 240 characters, redact common token and bearer
credential patterns, normalize non-ASCII or multibyte characters to `?` before
truncation, and do not store raw unbounded stdout or stderr.

For dry runs, diagnostics are recorded as:

```text
status: not_applicable
reason: dry_run
```

For successful live runs, diagnostics are recorded as:

```text
status: not_applicable
reason: execution_succeeded
```

For failed or timed-out live runs, diagnostics are recorded as:

```text
status: recorded
reason: timeout | stderr_nonempty | stdout_only_failure | process_exit_without_output
```

Historical runtime execution artifacts remain valid when they do not have this
field. New artifacts created by `execute-runtime-launch` include it.

## Artifact

Runtime runs live under:

```text
.specbridge/runtime-runs/*.runtime-run.json
```

Each artifact records:

- runtime launch path
- launch id
- task id
- packet id
- slice id
- branch name
- executor evidence path
- exit code
- files written
- validation results
- tool restriction
- permission mode
- max budget
- max turns, when present
- policy result
- stop conditions
- completion status
- runtime status
- run status
- runner mode
- execution policy
- source files

## Validation

Runtime runs are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1
```

The validator requires:

- repository-relative paths
- a source launch plan under `.specbridge/runtime-launches/`
- an existing executor evidence file
- every written file to exist
- every written file to be declared in the source launch plan `exclusive_write`
- executor evidence included in `files_written`
- `tool_restriction` limited to `Read`, `Write`, or `Edit`
- `run_status` set to `recorded`
- `runner_mode` set to `evidence_capture`
- execution policy booleans set to false

## Issue 071 Evidence

The serious autonomous test loop records two runtime-run artifacts:

```text
.specbridge/runtime-runs/issue-071-claude-implementation.runtime-run.json
.specbridge/runtime-runs/issue-071-claude-audit.runtime-run.json
```

Both are produced from issue 071 launch plans and executor evidence files. Both
must pass runtime-run validation before runtime results, runtime summaries,
autonomy metrics, final report, audit packet, and ChatGPT/Codex audit can be used
for merge gates.
