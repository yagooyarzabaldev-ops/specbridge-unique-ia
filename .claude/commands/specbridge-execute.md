# /specbridge-execute

Execute a SpecBridge issue autonomously within contract.

## Procedure

1. Read `CLAUDE.md`.
2. Read `.specbridge/context/*.md`.
3. Read the GitHub issue.
4. Read the matching execution contract.
5. Extract allowed scope and blocked scope.
6. Plan implementation only inside allowed scope.
7. Execute without asking the programmer when inside allowed scope.
8. Stop and create escalation if blocked scope or missing critical information appears.
9. Run required validations from the contract.
10. Generate or update the final report artifact.
11. Summarize changed files and validation results.
12. Do not push to `main`.
13. Do not merge pull requests.
