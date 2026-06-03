# SpecBridge Standard Loop V1

## Purpose

SpecBridge Standard Loop v1 is the canonical repository path for ChatGPT-governed,
Claude Code-implemented, ChatGPT-audited development.

It turns the issue 071 proof into an operating standard:

```text
goal -> contract -> scope -> executor handoff -> executor packet ->
runtime launch -> controlled execution -> runtime evidence -> metrics ->
audit packet -> ChatGPT/Codex audit -> PR -> GitHub CI -> merge
```

## Required Order

Every standard task follows this order:

1. ChatGPT/Codex defines the goal, acceptance criteria, and risk boundary.
2. SpecBridge creates an execution contract and scope manifest.
3. SpecBridge prepares executor handoff input and executor packets.
4. SpecBridge prepares runtime launch plans.
5. Claude Code executes only inside declared scope.
6. SpecBridge records runtime execution, runtime run, runtime result, and runtime summary evidence.
7. SpecBridge generates autonomy metrics when more than one executor or runtime slice is involved.
8. SpecBridge creates the final report and audit packet.
9. ChatGPT/Codex audits the result against the spec, policy, security rules, changed scope, tests, CI, and report honesty.
10. GitHub CI, review gate, and security gate pass.
11. Merge happens only when policy allows it.

## Standard CLI Surface

The local standard surface includes:

- `status`
- `standard-loop-status`
- `v5-pilot-status`
- `validate`
- `create-contract`
- `create-report`
- `audit-packet`
- `detect-conflicts`
- `decompose-task`
- `prepare-executors`
- `prepare-runtime-launch`
- `execute-runtime-launch`
- `run-runtime-launch`
- `record-runtime-result`
- `summarize-runtime`
- `summarize-autonomy-metrics`
- `plan-executor-branches`
- `record-github-evidence`
- `coordinate-executors`
- `review-gate`

`standard-loop-status` is the first real feature pilot for this standard. It reads
repository files and reports whether the templates, schemas, validators, CI
authority docs, and latest evidence are present.

`v5-pilot-status` is the readiness gate for the next live parallel pilot. It
reports whether the repository has V5 boundary docs, a readiness contract and
scope, two executor packets, runtime launch plans, dry-run execution artifacts,
runtime summaries, and autonomy metrics before live execution is attempted.

## Controlled Execution

`execute-runtime-launch` is the controlled runner surface.

Default safe use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 execute-runtime-launch `
  -InputPath .specbridge/runtime-launches/<task>.runtime-launch.json `
  -OutputPath .specbridge/runtime-executions/<task>.runtime-execution.json `
  -DryRun `
  -Force
```

Dry run records command shape, prompt sections, tool limits, timeout, budget, and
policy evidence without launching Claude Code.

Live execution is intentionally gated:

- it requires `-Force`
- it uses the launch plan's allowed tools
- it uses the launch plan's permission mode and budget
- it records timeout and process outcome
- it does not store raw stdout or stderr content, only length, line count, and hash

## Evidence Standard

Required evidence for a completed standard task:

- execution contract
- scope manifest
- executor handoff input when executor work is needed
- executor packet
- runtime launch plan
- runtime execution artifact when the runner is used
- runtime run artifact when executor output is observed
- runtime result
- runtime summary
- autonomy metrics for multi-slice work
- final report
- audit packet
- ChatGPT/Codex audit
- GitHub PR and CI evidence

## Merge Standard

Merge is allowed only when:

- local required validations pass
- GitHub CI passes
- security gate passes
- review gate passes
- audit packet validates
- ChatGPT/Codex audit is approved
- no protected files changed
- no policy violation is recorded
- deployment remains disabled unless a future contract authorizes it

## CI Boundary

The CI authority for this standard is the existing GitHub CI workflow set. It
does not modify workflow security controls. Any future workflow change requires
its own contract because `.github/workflows/**` is a CI/CD security boundary.

## Next Standard Task

The next standard task should be a small real product behavior change implemented
through bounded executor slices, not a larger architecture expansion.
