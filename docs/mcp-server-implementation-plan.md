# MCP Server Implementation Plan

## Purpose

This document defines the future implementation plan for SpecBridge MCP servers.

No MCP server is implemented by this document.

## Proposed MCP Servers

```text
specbridge-github
specbridge-contracts
```

## specbridge-github

Purpose:

Expose controlled GitHub operations to agents.

Candidate tools:

- get_issue
- create_issue
- get_pull_request
- create_pull_request
- comment_on_pull_request
- list_changed_files
- read_workflow_status

Candidate resources:

- repository summary
- branch protection status
- open SpecBridge tasks
- recent validation results

## specbridge-contracts

Purpose:

Expose execution contracts and policy resources.

Candidate tools:

- validate_contract
- classify_risk
- generate_final_report_draft

Candidate resources:

- contract catalog
- policy summary
- autonomy profiles
- risk rules

## Implementation Rules

MCP implementation must not start until:

- tool contracts exist
- resource contracts exist
- structured error model exists
- credential handling is documented
- validation strategy exists

## Security Rules

MCP servers must not expose secrets.

All credentials must be passed through environment variables.

Tools with side effects must be explicitly marked and auditable.

## Current Status

A bounded local read-only MCP-style runtime is implemented as `specbridge-mcp-runtime` (issue #234). It supports `resources/list` and `resources/read` for the three existing operator-state resources only. All mutation-capable methods and network transport remain blocked. Full MCP server runtime (network, tools, GitHub resources) remains future-planned and requires a dedicated contract.
