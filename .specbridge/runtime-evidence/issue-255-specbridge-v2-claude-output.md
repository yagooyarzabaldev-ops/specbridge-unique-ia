# Issue 255 SpecBridge v2 Claude Code Evidence

## Runtime Boundary

- task_id: issue-255-serious-product-build-pilot
- run_id: sb-20260624-0255c0de
- v1 issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/255
- v2 local workspace: `D:\Antigravity\Infinite Process\specbridge-v2`
- executor: Claude Code 2.1.170
- mode: `claude -p`
- budget: `--max-budget-usd 2.00`
- session persistence: disabled
- permission mode: `acceptEdits`
- allowed tools: `Read,Write,Bash`

## Prompt Boundary

Claude Code was instructed to create only a local SpecBridge v2 MVP under the current working directory and to avoid:

- network calls
- GitHub repository creation
- external repository mutation
- dependency installation
- secrets
- CI/CD workflow changes
- deployment
- authentication
- authorization
- billing
- provider configuration
- databases
- hosted runtime
- mutation-capable MCP
- Qwen integration

## Claude Code Result

Claude Code exited successfully and reported:

```text
Files created: 13 tracked MVP files
Test result: 33 passed, 0 failed
Exit code: 0
Local git repository initialized with 2 commits.
```

Claude Code also reported fixing three local implementation issues during the run:

- path-with-spaces handling for PowerShell subprocess calls
- preserving validator exit code 2 when `$ErrorActionPreference = 'Stop'`
- handling already-absolute report paths

## Codex Verification

Codex independently verified the v2 workspace after the Claude Code run.

```text
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1
Result: passed
Output summary: 33 passed, 0 failed, ALL TESTS PASSED
Exit code: 0
```

The test suite intentionally runs a negative missing-contract case. That case writes an expected `ERROR: Cannot read contract...` line while still asserting exit code 2 and keeping the overall suite exit code 0.

Additional verification:

```text
non-ASCII scan: passed, no non-ASCII files reported
git status --short --branch: clean on master
git log --oneline:
  f224ff1 fix: handle spaces-in-path and exit-code bugs in validator and launchers
  91d636d feat: initial SpecBridge v2 local MVP scaffold
```

Tracked v2 files:

```text
.gitignore
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/context/CODEX_CONTEXT.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/DO_NOT_TOUCH.md
.specbridge/contracts/bootstrap.execution.md
.specbridge/reports/bootstrap.final-report.json
.specbridge/scopes/bootstrap.scope.json
AGENTS.md
README.md
scripts/test.ps1
src/specbridge_v2.ps1
tests/bootstrap.tests.ps1
```

## Policy Result

Passed locally. The v2 workspace was created as a separate local repository. No v2 GitHub repository was created, no remote was configured or pushed, no dependencies were installed, no network service was added, no secrets were read, no production, billing, authentication, authorization, database, CI/CD workflow, deployment, hosted runtime, MCP mutation, or Qwen integration work occurred.
