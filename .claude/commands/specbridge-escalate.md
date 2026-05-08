# /specbridge-escalate

Create a structured escalation for ChatGPT review.

## Procedure

1. Identify the issue number.
2. Identify the contract id.
3. Explain why execution cannot continue inside current scope.
4. List affected files.
5. Identify whether approval required is ChatGPT or human.
6. Provide options and recommendation.
7. Write escalation under `.specbridge/escalations/`.
8. Stop execution.

## Rule

Do not continue dependent implementation after escalation.
