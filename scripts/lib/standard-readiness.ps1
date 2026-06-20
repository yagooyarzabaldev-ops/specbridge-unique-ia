# SpecBridge CLI library: standard readiness
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-StandardReadinessNextTaskSnapshot {
  $decisions = Get-OperatorTaskDecisions
  $excludedTaskIds = @($decisions | ForEach-Object { $_.task_id })

  $currentGoalStatus = "unknown"
  $currentTaskId = "unknown"
  $cgPath = Join-Path $repoRoot ".specbridge/state/current-goal.json"
  if (Test-Path -LiteralPath $cgPath) {
    try {
      $cg = Get-Content -LiteralPath $cgPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($cg.status) { $currentGoalStatus = [string] $cg.status }
      if ($cg.current_task_id) { $currentTaskId = [string] $cg.current_task_id }
    } catch {}
  }

  $eligible = @()
  $scopeDir = Join-Path $repoRoot ".specbridge/scopes"
  if (Test-Path $scopeDir) {
    foreach ($sf in (Get-ChildItem $scopeDir -Filter "*.scope.json" -File -ErrorAction SilentlyContinue)) {
      try {
        $sc = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($sc.status -ne "active") { continue }
        if ($excludedTaskIds -contains $sc.contract_id) { continue }
        if ($currentGoalStatus -eq "active" -and $sc.contract_id -eq $currentTaskId) { continue }
        $eligible += [ordered]@{
          task_id = $sc.contract_id
          run_id  = $sc.run_id
        }
      } catch {}
    }
  }

  $excluded = @($decisions | ForEach-Object {
    [ordered]@{
      issue   = $_.github_issue
      task_id = $_.task_id
      reason  = $_.decision
    }
  })

  $recommended = if ($currentGoalStatus -eq "active") {
    "continue_current_goal"
  } elseif (@($eligible).Count -gt 0) {
    "execute_eligible_task"
  } else {
    "create_new_operator_task"
  }

  return [ordered]@{
    current_goal_status = $currentGoalStatus
    current_task_id     = $currentTaskId
    eligible_tasks      = @($eligible)
    excluded_issues     = @($excluded)
    recommended_action  = $recommended
  }
}

function Get-StandardReadinessValue {
  param(
    [object] $Doctor,
    [object] $NextTask,
    [object] $RepositoryHealth,
    [object] $TokenGovernance,
    [object] $McpCatalog
  )

  if ($Doctor.health -eq "blocked") {
    return "blocked"
  }

  if ($TokenGovernance.ok -ne $true) {
    return "blocked"
  }

  if ($McpCatalog.read_only_policy -ne $true) {
    return "blocked"
  }

  if ($RepositoryHealth.cleanup_permission -ne "none" -or $RepositoryHealth.enforcement_status -ne "none") {
    return "blocked"
  }

  if ($NextTask.recommended_action -eq "continue_current_goal") {
    return "continue_current_goal"
  }

  if ($NextTask.recommended_action -eq "execute_eligible_task") {
    return "execute_eligible_task"
  }

  if ($Doctor.health -eq "healthy" -and $NextTask.recommended_action -eq "create_new_operator_task") {
    return "ready_for_governed_task_intake"
  }

  return "review_recommended"
}

function Build-StandardReadinessStatus {
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

  return [ordered]@{
    command = "specbridge-standard-readiness"
    ok = ($readiness -ne "blocked")
    schema_version = "1"
    readiness = $readiness
    recommended_next_action = $nextTask.recommended_action
    task_selection = [ordered]@{
      current_goal_status = $nextTask.current_goal_status
      current_task_id = $nextTask.current_task_id
      eligible_task_count = @($nextTask.eligible_tasks).Count
      excluded_issue_count = @($nextTask.excluded_issues).Count
      recommended_action = $nextTask.recommended_action
    }
    doctor = [ordered]@{
      health = [string] $doctorSnapshot.health
      mode = [string] $doctorSnapshot.mode
      action_count = [int] $doctorSnapshot.action_count
      blocker_count = @($doctorSnapshot.blockers).Count
      warning_count = @($doctorSnapshot.warnings).Count
      online_checks_enabled = [bool] $doctorSnapshot.online_checks.enabled
      online_checks_available = [bool] $doctorSnapshot.online_checks.available
    }
    repository_health = [ordered]@{
      overall_health_posture = [string] $repositoryHealth.overall_health_posture
      cleanup_permission = [string] $repositoryHealth.cleanup_permission
      enforcement_status = [string] $repositoryHealth.enforcement_status
      branch_cleanup_blocked = [int] $repositoryHealth.blocked_action_counts.branch_cleanup_blocked
      artifact_retention_blocked = [int] $repositoryHealth.blocked_action_counts.artifact_retention_blocked
      total_blocked_actions = [int] $repositoryHealth.blocked_action_counts.total_blocked
    }
    token_context_governance = [ordered]@{
      governance_id = [string] $tokenStatus.governance_id
      status = [string] $tokenStatus.status
      provider_source_count = @($tokenStatus.provider_sources).Count
      max_budget_usd_default = [string] $tokenStatus.claude_code_runtime_governance.max_budget_usd_default
      max_budget_usd_ceiling = [string] $tokenStatus.claude_code_runtime_governance.max_budget_usd_ceiling
      max_turns_default = [int] $tokenStatus.claude_code_runtime_governance.max_turns_default
      blocked_disclosure_count = @($tokenStatus.blocked_disclosures).Count
    }
    mcp_resource_surface = [ordered]@{
      mcp_server_status = [string] $mcpCatalog.mcp_server_status
      read_only_policy = [bool] $mcpCatalog.read_only_policy
      resource_count = @($mcpCatalog.resources).Count
      resource_uris = @($mcpCatalog.resources | ForEach-Object { $_.uri })
    }
    standard_boundaries = [ordered]@{
      launches_claude = $false
      launches_codex = $false
      calls_network = $false
      mutates_github = $false
      reads_secrets = $false
      changes_billing = $false
      changes_ci_cd_security = $false
      deploys = $false
      cleanup_permission = [string] $repositoryHealth.cleanup_permission
      retention_enforcement = [string] $repositoryHealth.artifact_posture.retention_enforcement
      writes_output_artifact = $WritesOutputArtifact
    }
    evidence_sources = @(
      "scripts/lib/intake-doctor.ps1",
      "scripts/lib/repository-health-summary.ps1",
      "scripts/lib/token-governance.ps1",
      "scripts/lib/mcp-resources.ps1",
      ".specbridge/state/current-goal.json",
      ".specbridge/policies/operator-task-decisions.json",
      ".specbridge/policies/token-context-governance.json"
    )
    notes = @(
      "This command is a read-only operator readiness snapshot when OutputPath is omitted.",
      "Repository branch cleanup and artifact retention remain disabled even when debt is visible.",
      "A blocked readiness value means an existing policy or health gate must be resolved before new governed execution."
    )
  }
}

function Invoke-StandardReadinessCommand {
  $output = $null
  $writesOutputArtifact = $false

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/standard-readiness/current.status.json"
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

  $status = Build-StandardReadinessStatus -WritesOutputArtifact:$writesOutputArtifact

  if ($writesOutputArtifact) {
    Write-Utf8JsonFile -Path $output -Value $status -Depth 12
  }

  Write-CliJson $status -Depth 12
}
