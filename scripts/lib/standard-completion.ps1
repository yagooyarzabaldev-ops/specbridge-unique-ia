# SpecBridge CLI library: standard completion
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Build-FinalStandardizationStatus {
  param(
    [bool] $WritesOutputArtifact
  )

  $doctorSnapshot = Get-McpDoctorFixPlanSnapshot
  $nextTask = Get-StandardReadinessNextTaskSnapshot
  $repositoryHealth = Build-RepositoryHealthSummary
  $tokenPolicy = Get-TokenGovernancePolicy
  $tokenStatus = New-TokenGovernanceStatus -Policy $tokenPolicy -WritesOutputArtifact:$false
  $mcpCatalog = Build-McpResourceCatalog

  $readiness = Get-StandardReadinessValue `
    -Doctor $doctorSnapshot `
    -NextTask $nextTask `
    -RepositoryHealth $repositoryHealth `
    -TokenGovernance $tokenStatus `
    -McpCatalog $mcpCatalog

  $standardizationCompletionPct = 95
  $remainingStandardizationPct = 100 - $standardizationCompletionPct

  $remainingGaps = @(
    [ordered]@{
      category = "serious_pilot"
      gap      = "Next serious product-build pilot has not run against the final standardization status surface."
      status   = "ready_for_contract"
      gate     = "dedicated_governed_project_pilot_contract"
    },
    [ordered]@{
      category = "repository_hygiene"
      gap      = "Branch cleanup enforcement remains disabled after the one-time issue #249 cleanup."
      status   = "policy_gated"
      gate     = "dedicated_cleanup_activation_contract"
    },
    [ordered]@{
      category = "artifact_hygiene"
      gap      = "Artifact retention enforcement remains disabled; inventory and policy evaluation are read-only."
      status   = "policy_gated"
      gate     = "dedicated_retention_activation_contract"
    },
    [ordered]@{
      category = "mcp_runtime"
      gap      = "Mutation-capable MCP tools are not enabled; current MCP tool surface remains read-only local runtime."
      status   = "blocked_by_default"
      gate     = "dedicated_mutation_capability_contract"
    },
    [ordered]@{
      category = "hosted_runtime"
      gap      = "Network MCP transport and hosted server deployment are not implemented."
      status   = "product_decision_required"
      gate     = "dedicated_hosted_runtime_contract"
    }
  )

  $blockedBoundaries = @(
    "branch_cleanup_apply",
    "artifact_retention_apply",
    "network_mcp_transport",
    "hosted_mcp_server",
    "claude_launch_inside_command",
    "codex_launch_inside_command",
    "github_mutation_inside_command",
    "dependency_installation",
    "deployment_automation",
    "production_deployment"
  )

  $recommendedNextContracts = @(
    [ordered]@{
      contract_slug = "serious-product-build-pilot"
      description   = "Run a real bounded product-build pilot from project starter to contracts, execution evidence, validations, and audit."
      gate          = "ready_after_issue_252_merge"
    },
    [ordered]@{
      contract_slug = "pr-state-aware-branch-cleanup-maintenance"
      description   = "Create a new exact-list cleanup contract for post-merge issue branches, preserving unmerged and closed-without-merge branches."
      gate          = "dedicated_cleanup_authorization_required"
    },
    [ordered]@{
      contract_slug = "artifact-retention-activation"
      description   = "Move artifact retention from read-only policy to governed enforcement only after exact retention rules and rollback evidence exist."
      gate          = "operator_activation_required"
    },
    [ordered]@{
      contract_slug = "mutation-capable-mcp-tools"
      description   = "Design and pilot mutation-capable MCP tools with explicit allowlists, dry-run mode, audit logs, and policy gates."
      gate          = "security_review_and_dedicated_contract_required"
    },
    [ordered]@{
      contract_slug = "hosted-network-mcp-runtime"
      description   = "Define hosted/network MCP runtime requirements before any transport, deployment, secret, or production boundary is changed."
      gate          = "product_decision_required"
    }
  )

  $validationExpectations = @(
    "validate-contracts.ps1",
    "validate-contract-scopes.ps1",
    "validate-final-reports.ps1",
    "validate-audit-packets.ps1",
    "validate-chatgpt-audits.ps1",
    "test-specbridge-cli.ps1",
    "specbridge-smoke.ps1",
    "specbridge-doctor -FixPlan -Offline",
    "specbridge-standard-readiness",
    "specbridge-final-standardization-status"
  )

  return [ordered]@{
    command                        = "specbridge-final-standardization-status"
    ok                             = $true
    schema_version                 = "1"
    standardization_completion_pct = $standardizationCompletionPct
    remaining_standardization_pct  = $remainingStandardizationPct
    readiness                      = $readiness
    recommended_next_action        = $nextTask.recommended_action
    remaining_gaps                 = @($remainingGaps)
    blocked_boundaries             = @($blockedBoundaries)
    recommended_next_contracts     = @($recommendedNextContracts)
    validation_expectations        = @($validationExpectations)
    task_selection = [ordered]@{
      current_goal_status    = $nextTask.current_goal_status
      current_task_id        = $nextTask.current_task_id
      eligible_task_count    = @($nextTask.eligible_tasks).Count
      excluded_issue_count   = @($nextTask.excluded_issues).Count
      recommended_action     = $nextTask.recommended_action
    }
    doctor = [ordered]@{
      health                   = [string] $doctorSnapshot.health
      mode                     = [string] $doctorSnapshot.mode
      action_count             = [int] $doctorSnapshot.action_count
      blocker_count            = @($doctorSnapshot.blockers).Count
      warning_count            = @($doctorSnapshot.warnings).Count
      online_checks_enabled    = [bool] $doctorSnapshot.online_checks.enabled
      online_checks_available  = [bool] $doctorSnapshot.online_checks.available
    }
    repository_health = [ordered]@{
      overall_health_posture     = [string] $repositoryHealth.overall_health_posture
      cleanup_permission         = [string] $repositoryHealth.cleanup_permission
      enforcement_status         = [string] $repositoryHealth.enforcement_status
      branch_cleanup_blocked     = [int] $repositoryHealth.blocked_action_counts.branch_cleanup_blocked
      artifact_retention_blocked = [int] $repositoryHealth.blocked_action_counts.artifact_retention_blocked
      total_blocked_actions      = [int] $repositoryHealth.blocked_action_counts.total_blocked
    }
    token_context_governance = [ordered]@{
      governance_id            = [string] $tokenStatus.governance_id
      status                   = [string] $tokenStatus.status
      provider_source_count    = @($tokenStatus.provider_sources).Count
      max_budget_usd_default   = [string] $tokenStatus.claude_code_runtime_governance.max_budget_usd_default
      max_budget_usd_ceiling   = [string] $tokenStatus.claude_code_runtime_governance.max_budget_usd_ceiling
      max_turns_default        = [int] $tokenStatus.claude_code_runtime_governance.max_turns_default
      blocked_disclosure_count = @($tokenStatus.blocked_disclosures).Count
    }
    mcp_resource_surface = [ordered]@{
      mcp_server_status = [string] $mcpCatalog.mcp_server_status
      read_only_policy  = [bool] $mcpCatalog.read_only_policy
      resource_count    = @($mcpCatalog.resources).Count
      resource_uris     = @($mcpCatalog.resources | ForEach-Object { $_.uri })
    }
    standard_boundaries = [ordered]@{
      launches_claude          = $false
      launches_codex           = $false
      calls_network            = $false
      mutates_github           = $false
      reads_secrets            = $false
      changes_billing          = $false
      changes_ci_cd_security   = $false
      deploys                  = $false
      cleanup_permission       = [string] $repositoryHealth.cleanup_permission
      retention_enforcement    = [string] $repositoryHealth.artifact_posture.retention_enforcement
      writes_output_artifact   = $WritesOutputArtifact
    }
    evidence_sources = @(
      "scripts/lib/intake-doctor.ps1",
      "scripts/lib/standard-readiness.ps1",
      "scripts/lib/repository-health-summary.ps1",
      "scripts/lib/token-governance.ps1",
      "scripts/lib/mcp-resources.ps1",
      ".specbridge/state/current-goal.json",
      ".specbridge/policies/operator-task-decisions.json",
      ".specbridge/policies/token-context-governance.json",
      ".specbridge/context/CURRENT_GOAL.md"
    )
    notes = @(
      "This command is a deterministic read-only final standardization status snapshot.",
      "standardization_completion_pct=$standardizationCompletionPct reflects governed infrastructure completeness; remaining $remainingStandardizationPct% is policy-gated or pilot-gated, not an untracked gap.",
      "blocked_boundaries are permanent per current policy and require explicit operator authorization to activate.",
      "recommended_next_contracts are advisory; each requires standard governed task intake before execution.",
      "Run this command before a serious product-build pilot to confirm repository readiness posture."
    )
  }
}

function Invoke-FinalStandardizationStatusCommand {
  $output = $null
  $writesOutputArtifact = $false

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/standard-readiness/final-standardization.status.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    $output = $normalized
    $writesOutputArtifact = $true
  }

  $status = Build-FinalStandardizationStatus -WritesOutputArtifact:$writesOutputArtifact

  if ($writesOutputArtifact) {
    Write-Utf8JsonFile -Path $output -Value $status -Depth 12
  }

  Write-CliJson $status -Depth 12
}
