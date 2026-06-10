# /sb-close

Run the post-merge closure cycle for a merged task.

## Arguments

`$ARGUMENTS` = `<task-id> <pr-number> <issue-number>`

## Preconditions

The primary PR is merged (verify with `gh pr view <pr-number> --json state,mergeCommit`). Never run closure before the merge.

## Steps

1. `git checkout main && git pull`, then create branch `chore/<task-id>-closure`.
2. Set the scope file status to `completed` (note: serialized JSON uses two spaces after the colon; match with `"status":\s*"active"`).
3. Close the GitHub issue with a note referencing the merged PR and the closure evidence path.
4. Write `.specbridge/github-evidence/<task-id>.closure.json` with the real merge commit, primary_pr, related_issue and run_id.
5. Complete the orchestration:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-handoff -TaskId <task-id> -Agent closure -Summary "<merge commit, issue closed, evidence written>"
```

6. Update `.specbridge/state/current-goal.json`: status `ready_for_next_task`, primary_pr set.
7. Update `.specbridge/context/CURRENT_GOAL.md`: completion-history row and next recommended task.
8. Regenerate both dashboards (`generate-dashboard`, `generate-studio-dashboard`).
9. Run full smoke; commit; push; open the closure PR; merge after CI passes (merge requires human authorization).
10. Delete the merged work branches local and remote.

## Output Requirement

Report: orchestration status (must be `completed`), dashboard counts, smoke result, closure PR number.
