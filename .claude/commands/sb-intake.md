# /sb-intake

Start a new governed task through the SpecBridge intake bridge.

## Arguments

`$ARGUMENTS` = `<task-id> "<title>" "<goal>"`

Task id is kebab-case (convention: `issue-<n>-<slug>` using the next number from CURRENT_GOAL.md, accepting that the real GitHub issue number may drift).

## Steps

1. Confirm `current-goal.json` status is `ready_for_next_task`; if not, stop and report the open task.
2. Trigger the intake workflow:

```powershell
gh workflow run specbridge-intake.yml -f task_id=<task-id> -f title="<title>" -f goal="<goal>"
```

3. Watch the run until it completes (`gh run watch <run-id> --exit-status`).
4. `git fetch origin` and check out the generated `codex/<task-id>` branch.
5. Read the generated contract and scope; expand `exclusive_write` with the implementation files before touching them.
6. Create the orchestration manifest:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-orchestrate -TaskId <task-id>
```

## Output Requirement

Report the GitHub issue number created, the branch name, the run_id, and the expanded scope file list.
