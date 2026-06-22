# SpecBridge CLI library: project-starter
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-RequiredCliString {
  param(
    [string] $Value,
    [string] $FieldName
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    Fail "$FieldName is required"
  }

  return $Value.Trim()
}

function Get-RequiredCliStringArray {
  param(
    [string[]] $Value,
    [string] $FieldName
  )

  if ($null -eq $Value -or @($Value).Count -le 0) {
    Fail "$FieldName must include at least one value"
  }

  $items = @()

  foreach ($rawItem in @($Value)) {
    if ([string]::IsNullOrWhiteSpace($rawItem)) {
      Fail "$FieldName must contain only non-empty values"
    }

    foreach ($item in ($rawItem -split ",")) {
      if ([string]::IsNullOrWhiteSpace($item)) {
        Fail "$FieldName must contain only non-empty values"
      }

      $items += $item.Trim()
    }
  }

  return @($items)
}

function New-ProjectStarterArtifact {
  $taskIdValue = Get-RequiredCliString -Value $TaskId -FieldName "TaskId"
  $safeTaskId = Convert-ToSafeName -Value $taskIdValue -FieldName "TaskId"
  $titleValue = Get-RequiredCliString -Value $Title -FieldName "Title"
  $goalValue = Get-RequiredCliString -Value $Goal -FieldName "Goal"

  if ($null -eq $TargetUser -or @($TargetUser).Count -le 0) {
    Fail "TargetUser must include at least one value"
  }

  if ($null -eq $MvpScope -or @($MvpScope).Count -le 0) {
    Fail "MvpScope must include at least one value"
  }

  if ($null -eq $NonGoal -or @($NonGoal).Count -le 0) {
    Fail "NonGoal must include at least one value"
  }

  $targetUsers = @(Get-RequiredCliStringArray -Value $TargetUser -FieldName "TargetUser")
  $mvpScopeItems = @(Get-RequiredCliStringArray -Value $MvpScope -FieldName "MvpScope")
  $nonGoalItems = @(Get-RequiredCliStringArray -Value $NonGoal -FieldName "NonGoal")

  return [ordered]@{
    schema_version = "1"
    command = "specbridge-project-starter"
    starter_id = $safeTaskId
    title = $titleValue
    goal = $goalValue
    target_users = @($targetUsers)
    mvp_scope = @($mvpScopeItems)
    non_goals = @($nonGoalItems)
    blocked_scope = @(
      "external_repository_creation",
      "external_repository_mutation",
      "network_calls",
      "dependency_installation",
      "secret_or_private_key_access",
      "billing_or_payment_configuration",
      "provider_account_configuration",
      "authentication_or_authorization_implementation",
      "database_changes",
      "ci_cd_security_changes",
      "deployment_or_production_configuration",
      "mutation_capable_mcp_tools",
      "artifact_or_branch_cleanup_enforcement"
    )
    future_spec_package = [ordered]@{
      required_specs = @(
        "product-vision",
        "mvp-acceptance-criteria",
        "security-boundaries",
        "data-and-integration-map",
        "agent-execution-contracts",
        "validation-and-audit-plan"
      )
      recommended_repository_files = @(
        ".specbridge/context/CODEX_CONTEXT.md",
        ".specbridge/context/ACCEPTANCE_CRITERIA.md",
        ".specbridge/context/DO_NOT_TOUCH.md",
        ".specbridge/contracts/<task>.execution.md",
        ".specbridge/scopes/<task>.scope.json",
        ".specbridge/reports/<task>.final-report.json"
      )
    }
    agent_architecture = [ordered]@{
      coordinator = "SpecBridge converts the starter into contracts, scopes, handoffs, and validation evidence."
      suggested_roles = @(
        "planner",
        "product-spec",
        "implementer",
        "tester",
        "security-reviewer",
        "docs",
        "closure"
      )
      parallelization_rule = "Split implementation only after each executor has a non-overlapping write scope and explicit acceptance criteria."
    }
    validation_plan = @(
      "Create execution contract and scope manifest before implementation.",
      "Run local validators before PR creation.",
      "Run GitHub CI before merge.",
      "Run Codex/ChatGPT audit against final report and audit packet.",
      "Record post-merge closure evidence before selecting the next task."
    )
    security_boundaries = [ordered]@{
      secrets = "blocked_until_dedicated_contract"
      production = "blocked_until_dedicated_contract"
      billing = "blocked_until_dedicated_contract"
      authentication = "blocked_until_dedicated_contract"
      authorization = "blocked_until_dedicated_contract"
      database_destructive_changes = "blocked"
      dependency_installation = "blocked_until_dedicated_contract"
      deployment = "blocked_until_dedicated_contract"
    }
    security_review_prompts = @(
      "Does the starter require secrets, wallets, private keys, tokens, provider credentials, or payment accounts?",
      "Does any MVP item imply authentication, authorization, billing, production, deployment, or database mutation?",
      "Can the first implementation be proven locally with deterministic tests before external integrations are enabled?",
      "Are future agent scopes non-overlapping and small enough for independent validation and audit?"
    )
    next_steps = @(
      "Review this starter package with the user.",
      "Convert the approved starter into a GitHub issue.",
      "Create a dedicated execution contract and scope manifest.",
      "Use SpecBridge intake and validation gates before implementation.",
      "Delegate implementation to Claude Code only inside the active contract."
    )
    standard_boundaries = [ordered]@{
      creates_external_repository = $false
      installs_dependencies = $false
      calls_network = $false
      reads_secrets = $false
      changes_billing = $false
      deploys = $false
      mutates_mcp_tools = $false
      cleanup_enforcement = "none"
    }
  }
}

function Invoke-ProjectStarterCommand {
  $artifact = New-ProjectStarterArtifact

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/project-starters/$($artifact.starter_id).project-starter.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"

    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }

    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }

    Write-Utf8JsonFile -Path $normalized -Value $artifact -Depth 12
    Write-CliJson ([ordered]@{
      command = "specbridge-project-starter"
      ok = $true
      output_path = $normalized
      starter = $artifact
    }) -Depth 12
    return
  }

  Write-CliJson ([ordered]@{
    command = "specbridge-project-starter"
    ok = $true
    starter = $artifact
  }) -Depth 12
}
