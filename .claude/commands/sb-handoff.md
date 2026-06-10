# /sb-handoff

Record an agent handoff in the active orchestration.

## Arguments

`$ARGUMENTS` = `<task-id> <agent> "<summary>"`

Agents hand off strictly in order: planner, implementer, reviewer, tester, security, docs, closure.

## Rules

- The summary must state what the agent actually verified or produced, not boilerplate. The artifact is audit evidence.
- The reviewer handoff is hard-gated: it fails unless `.specbridge/agent-reviews/<task-id>.review-agent-report.json` exists with verdict `approve` and no blocker findings. Use `/sb-review` first.
- Hand off `tester` only after the CLI suite and full smoke pass locally.
- Hand off `closure` only during post-merge closure (it completes the orchestration).

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-handoff -TaskId <task-id> -Agent <agent> -Summary "<summary>"
```

## Output Requirement

Report the JSON output: `next_agent` and `orchestration_status`. If the command fails, report the error verbatim and do not retry with a weaker summary.
