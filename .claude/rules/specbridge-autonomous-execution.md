# SpecBridge Autonomous Execution Rules

## Prime Directive

Execute the contract. Do not negotiate routine implementation with the programmer.

## Allowed Autonomy

Claude Code may act autonomously when the requested change is explicitly allowed by the contract, no blocked scope is touched, no production secret or deployment is required, and required validations can be run locally.

## Mandatory Stop

Stop and escalate if blocked scope is required, contract is ambiguous, required validation cannot be run, hidden assumption affects architecture, or requested work requires human approval.

## Forbidden

Never push to `main`, merge a PR, alter secrets, deploy, touch production infrastructure, claim completion without evidence, or silently ignore failed validations.
