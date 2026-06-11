# SpecBridge CLI library: status
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Invoke-StatusCommand {
  $policyMode = ""

  if (Test-Path ".specbridge/policy.yaml") {
    $policyModeLine = Select-String -Path ".specbridge/policy.yaml" -Pattern "default_mode:" | Select-Object -First 1

    if ($policyModeLine) {
      $policyMode = (($policyModeLine.Line -split ":", 2)[1]).Trim()
    }
  }

  $status = [ordered]@{
    command = "status"
    ok = $true
    repository = "specbridge"
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    default_mode = $policyMode
    counts = [ordered]@{
      contracts = Get-FileCount -Path ".specbridge/contracts" -Filter "*.execution.md"
      scopes = Get-FileCount -Path ".specbridge/scopes" -Filter "*.scope.json"
      reports = Get-FileCount -Path ".specbridge/reports" -Filter "*.final-report.json"
      audit_packets = Get-FileCount -Path ".specbridge/audit-packets" -Filter "*.audit-packet.json"
      chatgpt_audits = Get-FileCount -Path ".specbridge/audits" -Filter "*.chatgpt-audit.json"
      runtime_launches = Get-FileCount -Path ".specbridge/runtime-launches" -Filter "*.runtime-launch.json"
      runtime_preflights = Get-FileCount -Path ".specbridge/preflights" -Filter "*.runtime-preflight.json"
      runtime_results = Get-FileCount -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summaries = Get-FileCount -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
      runtime_runs = Get-FileCount -Path ".specbridge/runtime-runs" -Filter "*.runtime-run.json"
      runtime_executions = Get-FileCount -Path ".specbridge/runtime-executions" -Filter "*.runtime-execution.json"
    }
    current_goal_path = ".specbridge/context/CURRENT_GOAL.md"
  }

  if ($IncludeLatestArtifacts) {
    $status["latest_artifacts"] = [ordered]@{
      contract = Get-LatestArtifactPath -Path ".specbridge/contracts" -Filter "*.execution.md"
      scope = Get-LatestArtifactPath -Path ".specbridge/scopes" -Filter "*.scope.json"
      final_report = Get-LatestArtifactPath -Path ".specbridge/reports" -Filter "*.final-report.json"
      audit_packet = Get-LatestArtifactPath -Path ".specbridge/audit-packets" -Filter "*.audit-packet.json"
      chatgpt_audit = Get-LatestArtifactPath -Path ".specbridge/audits" -Filter "*.chatgpt-audit.json"
      runtime_launch = Get-LatestArtifactPath -Path ".specbridge/runtime-launches" -Filter "*.runtime-launch.json"
      runtime_preflight = Get-LatestArtifactPath -Path ".specbridge/preflights" -Filter "*.runtime-preflight.json"
      runtime_result = Get-LatestArtifactPath -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summary = Get-LatestArtifactPath -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
      runtime_run = Get-LatestArtifactPath -Path ".specbridge/runtime-runs" -Filter "*.runtime-run.json"
      runtime_execution = Get-LatestArtifactPath -Path ".specbridge/runtime-executions" -Filter "*.runtime-execution.json"
    }
  }

  Write-CliJson $status
  exit 0
}

function Get-ClaudeCapability {
  $claudeCommand = Get-Command claude -ErrorAction SilentlyContinue
  $claudePath = $null
  $claudeVersion = $null

  if ($null -ne $claudeCommand) {
    $claudePath = $claudeCommand.Source
  }

  if (-not [string]::IsNullOrWhiteSpace($claudePath)) {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
      $versionOutput = & $claudePath --version 2>$null

      if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($versionOutput | Out-String))) {
        $claudeVersion = (($versionOutput | Select-Object -First 1) | Out-String).Trim()
      }
    }
    catch {
      $claudeVersion = $null
    }
    finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
  }

  return [ordered]@{
    available = (-not [string]::IsNullOrWhiteSpace($claudePath))
    path = $claudePath
    version = $claudeVersion
  }
}

function Get-AntigravityCapability {
  $candidatePaths = @()
  $command = Get-Command antigravity -ErrorAction SilentlyContinue

  if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
    $candidatePaths += $command.Source
  }

  if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $candidatePaths += (Join-Path $env:LOCALAPPDATA "Programs/Antigravity/Antigravity.exe")
  }

  if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $candidatePaths += (Join-Path $env:ProgramFiles "Antigravity/Antigravity.exe")
  }

  $candidatePaths += "D:/Antigravity"

  $resolvedPath = $null

  foreach ($candidate in @($candidatePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
    $resolvedPath = Get-ResolvedPathOrNull -Path $candidate

    if (-not [string]::IsNullOrWhiteSpace($resolvedPath)) {
      break
    }
  }

  return [ordered]@{
    available = (-not [string]::IsNullOrWhiteSpace($resolvedPath))
    path = $resolvedPath
  }
}

function Invoke-RuntimeCapabilityStatusCommand {
  $claude = Get-ClaudeCapability
  $antigravity = Get-AntigravityCapability

  Write-CliJson ([ordered]@{
    command = "runtime-capability-status"
    ok = ([bool] $claude.available -and [bool] $antigravity.available)
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    claude = $claude
    antigravity = $antigravity
    policy_boundary = "no-launch no-deploy no-secret-access"
  })

  exit 0
}

function Get-StandardLoopPathStatus {
  param(
    [string[]] $Paths
  )

  $items = @()

  foreach ($path in $Paths) {
    $normalizedPath = Normalize-RepoPath -Path $path -FieldName "standard_loop_path"
    $items += [ordered]@{
      path = $normalizedPath
      exists = (Test-Path -LiteralPath $normalizedPath)
    }
  }

  return @($items)
}

function Invoke-StandardLoopStatusCommand {
  $templatePaths = @(
    "templates/specbridge/execution-contract.template.md",
    "templates/specbridge/scope-manifest.template.json",
    "templates/specbridge/executor-handoff.template.json",
    "templates/specbridge/runtime-launch.template.json",
    "templates/specbridge/final-report.template.json",
    "templates/specbridge/audit-packet.template.json",
    "templates/specbridge/chatgpt-audit.template.json"
  )

  $schemaPaths = @(
    ".specbridge/schemas/executor-packet.schema.json",
    ".specbridge/schemas/runtime-launch.schema.json",
    ".specbridge/schemas/runtime-preflight.schema.json",
    ".specbridge/schemas/runtime-run.schema.json",
    ".specbridge/schemas/runtime-result.schema.json",
    ".specbridge/schemas/runtime-summary.schema.json",
    ".specbridge/schemas/autonomy-metrics.schema.json",
    ".specbridge/schemas/runtime-execution.schema.json"
  )

  $validatorPaths = @(
    "scripts/validate-standard-templates.ps1",
    "scripts/validate-standard-ci-authority.ps1",
    "scripts/validate-runtime-preflights.ps1",
    "scripts/validate-runtime-executions.ps1"
  )

  $workflowPaths = @(
    ".github/workflows/foundation-validation.yml",
    ".github/workflows/specbridge-review-gate.yml",
    ".github/workflows/specbridge-pr-review-report.yml",
    ".github/workflows/claude-review-non-blocking.yml"
  )

  $templateStatus = Get-StandardLoopPathStatus -Paths $templatePaths
  $schemaStatus = Get-StandardLoopPathStatus -Paths $schemaPaths
  $validatorStatus = Get-StandardLoopPathStatus -Paths $validatorPaths
  $workflowStatus = Get-StandardLoopPathStatus -Paths $workflowPaths

  $allRequired = @($templateStatus + $schemaStatus + $validatorStatus + $workflowStatus)
  $missing = @($allRequired | Where-Object { -not $_.exists } | ForEach-Object { $_.path })

  $status = [ordered]@{
    command = "standard-loop-status"
    ok = ($missing.Count -eq 0)
    standard = "SpecBridge Standard Loop v1"
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    template_count = @($templateStatus | Where-Object { $_.exists }).Count
    schema_count = @($schemaStatus | Where-Object { $_.exists }).Count
    validator_count = @($validatorStatus | Where-Object { $_.exists }).Count
    ci_workflow_count = @($workflowStatus | Where-Object { $_.exists }).Count
    latest_artifacts = [ordered]@{
      contract = Get-LatestArtifactPath -Path ".specbridge/contracts" -Filter "*.execution.md"
      scope = Get-LatestArtifactPath -Path ".specbridge/scopes" -Filter "*.scope.json"
      runtime_launch = Get-LatestArtifactPath -Path ".specbridge/runtime-launches" -Filter "*.runtime-launch.json"
      runtime_preflight = Get-LatestArtifactPath -Path ".specbridge/preflights" -Filter "*.runtime-preflight.json"
      runtime_run = Get-LatestArtifactPath -Path ".specbridge/runtime-runs" -Filter "*.runtime-run.json"
      runtime_result = Get-LatestArtifactPath -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summary = Get-LatestArtifactPath -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
      runtime_execution = Get-LatestArtifactPath -Path ".specbridge/runtime-executions" -Filter "*.runtime-execution.json"
      autonomy_metrics = Get-LatestArtifactPath -Path ".specbridge/metrics" -Filter "*.autonomy-metrics.json"
      audit_packet = Get-LatestArtifactPath -Path ".specbridge/audit-packets" -Filter "*.audit-packet.json"
      chatgpt_audit = Get-LatestArtifactPath -Path ".specbridge/audits" -Filter "*.chatgpt-audit.json"
    }
    required_paths = [ordered]@{
      templates = @($templateStatus)
      schemas = @($schemaStatus)
      validators = @($validatorStatus)
      ci_workflows = @($workflowStatus)
    }
    missing_required_paths = @($missing)
    ci_security_boundary = "workflow files are read-only in this standardization package"
  }

  Write-CliJson $status -Depth 10

  if ($missing.Count -gt 0) {
    exit 1
  }

  exit 0
}

function New-StandardLoopContractSeed {
  param(
    [string] $TaskIdentifier
  )

  $safeTaskId = Convert-ToSafeName -Value $TaskIdentifier -FieldName "task_id"
  $contractPath = ".specbridge/contracts/$safeTaskId.execution.md"
  $scopePath = ".specbridge/scopes/$safeTaskId.scope.json"
  $finalReportPath = ".specbridge/reports/$safeTaskId.final-report.json"
  $auditPacketPath = ".specbridge/audit-packets/$safeTaskId.audit-packet.json"
  $chatGptAuditPath = ".specbridge/audits/$safeTaskId.chatgpt-audit.json"
  $standardLoopRunPath = ".specbridge/standard-loop-runs/$safeTaskId.standard-loop-run.json"

  $issueReference = "not_declared"
  if ($safeTaskId -match "^issue-0*([0-9]+)") {
    $issueReference = "$RepositoryUrl/issues/$($Matches[1])"
  }

  return [ordered]@{
    task_id = $safeTaskId
    issue_reference = $issueReference
    recommended_branch = "codex/$safeTaskId"
    contract_path = $contractPath
    scope_path = $scopePath
    final_report_path = $finalReportPath
    audit_packet_path = $auditPacketPath
    chatgpt_audit_path = $chatGptAuditPath
    standard_loop_run_path = $standardLoopRunPath
    required_evidence_paths = @(
      $contractPath,
      $scopePath,
      $finalReportPath,
      $auditPacketPath,
      $chatGptAuditPath,
      $standardLoopRunPath
    )
    suggested_commands = [ordered]@{
      write_orchestration_artifact = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId $safeTaskId -OutputPath $standardLoopRunPath -Force"
      validate_standard = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard"
      test_cli = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1"
      smoke = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1"
      security_gate = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1"
      review_gate = "powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1"
    }
    completion_gates = [ordered]@{
      local = @(
        "contract validates",
        "scope validates",
        "final report validates",
        "audit packet validates",
        "ChatGPT/Codex audit validates",
        "runtime preflight validates",
        "security gate passes",
        "review gate passes",
        "CLI tests pass",
        "smoke validation passes",
        "git diff --check passes"
      )
      github = @(
        "Foundation Validation",
        "SpecBridge Review Gate",
        "SpecBridge PR Review Report",
        "Claude Review Non Blocking"
      )
    }
    policy_boundary = "seed-only no-launch no-github-call no-dependency-install no-deploy"
  }
}

function Invoke-StandardLoopOrchestrateCommand {
  $templatePaths = @(
    "templates/specbridge/execution-contract.template.md",
    "templates/specbridge/scope-manifest.template.json",
    "templates/specbridge/executor-handoff.template.json",
    "templates/specbridge/runtime-launch.template.json",
    "templates/specbridge/final-report.template.json",
    "templates/specbridge/audit-packet.template.json",
    "templates/specbridge/chatgpt-audit.template.json"
  )

  $schemaPaths = @(
    ".specbridge/schemas/executor-packet.schema.json",
    ".specbridge/schemas/runtime-launch.schema.json",
    ".specbridge/schemas/runtime-preflight.schema.json",
    ".specbridge/schemas/runtime-run.schema.json",
    ".specbridge/schemas/runtime-result.schema.json",
    ".specbridge/schemas/runtime-summary.schema.json",
    ".specbridge/schemas/autonomy-metrics.schema.json",
    ".specbridge/schemas/runtime-execution.schema.json"
  )

  $validatorPaths = @(
    "scripts/validate-foundation.ps1",
    "scripts/validate-contracts.ps1",
    "scripts/validate-contract-scopes.ps1",
    "scripts/validate-final-reports.ps1",
    "scripts/validate-audit-packets.ps1",
    "scripts/validate-chatgpt-audits.ps1",
    "scripts/validate-runtime-preflights.ps1",
    "scripts/validate-security-gates.ps1",
    "scripts/validate-review-gate.ps1",
    "scripts/specbridge-smoke.ps1",
    "scripts/test-specbridge-cli.ps1"
  )

  $workflowPaths = @(
    ".github/workflows/foundation-validation.yml",
    ".github/workflows/specbridge-review-gate.yml",
    ".github/workflows/specbridge-pr-review-report.yml",
    ".github/workflows/claude-review-non-blocking.yml"
  )

  $docPaths = @(
    "README.md",
    "SPECBRIDGE.md",
    "AGENTS.md",
    "docs/specbridge-standard-loop-v1.md",
    "docs/specbridge-ci-authority-standard.md"
  )

  $templateStatus = Get-StandardLoopPathStatus -Paths $templatePaths
  $schemaStatus = Get-StandardLoopPathStatus -Paths $schemaPaths
  $validatorStatus = Get-StandardLoopPathStatus -Paths $validatorPaths
  $workflowStatus = Get-StandardLoopPathStatus -Paths $workflowPaths
  $docStatus = Get-StandardLoopPathStatus -Paths $docPaths

  $allRequired = @($templateStatus + $schemaStatus + $validatorStatus + $workflowStatus + $docStatus)
  $missing = @($allRequired | Where-Object { -not $_.exists } | ForEach-Object { $_.path })

  $currentPhase = Get-MarkdownSectionText -Path ".specbridge/context/CURRENT_GOAL.md" -Heading "Current Phase"
  $nextRecommendedAction = Get-MarkdownSectionText -Path ".specbridge/context/CURRENT_GOAL.md" -Heading "Next Recommended Task"

  if ([string]::IsNullOrWhiteSpace($currentPhase)) {
    $currentPhase = "not_declared"
  }

  if ([string]::IsNullOrWhiteSpace($nextRecommendedAction)) {
    $nextRecommendedAction = "not_declared"
  }

  $resolvedTaskId = $TaskId
  if ([string]::IsNullOrWhiteSpace($resolvedTaskId)) {
    $resolvedTaskId = "current-goal"
  }

  $contractSeed = New-StandardLoopContractSeed -TaskIdentifier $resolvedTaskId

  $phases = @(
    [ordered]@{
      order = 1
      id = "goal_intake"
      name = "Goal, acceptance criteria, and risk boundary"
      required_evidence = @(".specbridge/context/CURRENT_GOAL.md", "GitHub issue")
      gate = "goal_is_explicit"
    },
    [ordered]@{
      order = 2
      id = "contract_scope"
      name = "Execution contract and scope manifest"
      required_evidence = @(".specbridge/contracts/*.execution.md", ".specbridge/scopes/*.scope.json")
      gate = "contract_and_scope_validate"
    },
    [ordered]@{
      order = 3
      id = "executor_preparation"
      name = "Executor handoff, decomposition, and packets"
      required_evidence = @(".specbridge/executor-handoffs/*.json", ".specbridge/executor-packets/*.executor-packet.json")
      gate = "executor_scopes_do_not_overlap"
    },
    [ordered]@{
      order = 4
      id = "runtime_planning"
      name = "Runtime launch planning"
      required_evidence = @(".specbridge/runtime-launches/*.runtime-launch.json")
      gate = "launch_plan_validates"
    },
    [ordered]@{
      order = 5
      id = "controlled_execution"
      name = "Controlled execution and evidence capture"
      required_evidence = @(".specbridge/runtime-executions/*.runtime-execution.json", ".specbridge/runtime-runs/*.runtime-run.json")
      gate = "execution_is_bounded_and_recorded"
    },
    [ordered]@{
      order = 6
      id = "result_summary"
      name = "Runtime result, summary, and autonomy metrics"
      required_evidence = @(".specbridge/runtime-results/*.runtime-result.json", ".specbridge/runtime-summaries/*.runtime-summary.json", ".specbridge/metrics/*.autonomy-metrics.json")
      gate = "summaries_ready_for_policy_gates"
    },
    [ordered]@{
      order = 7
      id = "report_audit"
      name = "Final report, audit packet, and ChatGPT/Codex audit"
      required_evidence = @(".specbridge/reports/*.final-report.json", ".specbridge/audit-packets/*.audit-packet.json", ".specbridge/audits/*.chatgpt-audit.json")
      gate = "audit_approved"
    },
    [ordered]@{
      order = 8
      id = "pull_request_ci"
      name = "Pull request, security gate, review gate, and GitHub CI"
      required_evidence = @("GitHub pull request", "Foundation Validation", "SpecBridge Review Gate", "SpecBridge PR Review Report")
      gate = "ci_and_review_pass"
    },
    [ordered]@{
      order = 9
      id = "merge_closure"
      name = "Policy-gated merge and repository memory closure"
      required_evidence = @("merged pull request", ".specbridge/context/CURRENT_GOAL.md")
      gate = "merge_allowed_by_policy"
    }
  )

  $orchestration = [ordered]@{
    schema_version = "1"
    command = "standard-loop-orchestrate"
    ok = ($missing.Count -eq 0)
    mode = "plan_only"
    task_id = $resolvedTaskId
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    standard = "SpecBridge Standard Loop v1"
    current_repository_phase = $currentPhase
    next_recommended_action = $nextRecommendedAction
    next_contract_seed = $contractSeed
    phases = @($phases)
    required_gates = [ordered]@{
      local = @(
        "validate-contracts",
        "validate-contract-scopes",
        "validate-final-reports",
                                         "validate-audit-packets",
                                         "validate-chatgpt-audits",
                                         "validate-runtime-preflights",
                                         "validate-security-gates",
        "validate-review-gate",
        "specbridge-smoke",
        "test-specbridge-cli",
        "git diff --check"
      )
      github = @(
        "Foundation Validation",
        "SpecBridge Review Gate",
        "SpecBridge PR Review Report",
        "Claude Review Non Blocking"
      )
    }
    latest_artifacts = [ordered]@{
      contract = Get-LatestArtifactPath -Path ".specbridge/contracts" -Filter "*.execution.md"
      scope = Get-LatestArtifactPath -Path ".specbridge/scopes" -Filter "*.scope.json"
      runtime_launch = Get-LatestArtifactPath -Path ".specbridge/runtime-launches" -Filter "*.runtime-launch.json"
      runtime_preflight = Get-LatestArtifactPath -Path ".specbridge/preflights" -Filter "*.runtime-preflight.json"
      runtime_execution = Get-LatestArtifactPath -Path ".specbridge/runtime-executions" -Filter "*.runtime-execution.json"
      runtime_run = Get-LatestArtifactPath -Path ".specbridge/runtime-runs" -Filter "*.runtime-run.json"
      runtime_result = Get-LatestArtifactPath -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summary = Get-LatestArtifactPath -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
      autonomy_metrics = Get-LatestArtifactPath -Path ".specbridge/metrics" -Filter "*.autonomy-metrics.json"
      final_report = Get-LatestArtifactPath -Path ".specbridge/reports" -Filter "*.final-report.json"
      audit_packet = Get-LatestArtifactPath -Path ".specbridge/audit-packets" -Filter "*.audit-packet.json"
      chatgpt_audit = Get-LatestArtifactPath -Path ".specbridge/audits" -Filter "*.chatgpt-audit.json"
    }
    required_paths = [ordered]@{
      docs = @($docStatus)
      templates = @($templateStatus)
      schemas = @($schemaStatus)
      validators = @($validatorStatus)
      ci_workflows = @($workflowStatus)
    }
    missing_required_paths = @($missing)
    policy_boundaries = @(
      "no-secrets",
      "no-production",
      "no-billing",
      "no-auth-security-change",
      "no-authorization-security-change",
      "no-database-change",
      "no-dependency-installation",
      "no-ci-cd-security-change",
      "no-deployment"
    )
    command_boundary = "does-not-launch-claude-code does-not-launch-antigravity does-not-call-github does-not-install-dependencies does-not-deploy"
    output_path = $null
  }

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = Assert-OutputPath `
      -Path $OutputPath `
      -Pattern "^\.specbridge/standard-loop-runs/.+\.standard-loop-run\.json$" `
      -Description "a .specbridge/standard-loop-runs/*.standard-loop-run.json orchestration artifact"

    $orchestration["output_path"] = $output
    Write-Utf8JsonFile -Path $output -Value $orchestration -Depth 12
  }

  Write-CliJson $orchestration -Depth 12

  if ($missing.Count -gt 0) {
    exit 1
  }

  exit 0
}

function New-V5Prerequisite {
  param(
    [string] $Name,
    [bool] $Passed,
    [string] $Evidence,
    [string[]] $Details = @()
  )

  if ($null -eq $Details) {
    $Details = @()
  }

  return [ordered]@{
    name = $Name
    passed = $Passed
    evidence = $Evidence
    details = @($Details)
  }
}

function Invoke-V5PilotStatusCommand {
  $standardRequiredPaths = @(
    "templates/specbridge/execution-contract.template.md",
    "templates/specbridge/scope-manifest.template.json",
    "templates/specbridge/executor-handoff.template.json",
    "templates/specbridge/runtime-launch.template.json",
    "templates/specbridge/final-report.template.json",
    "templates/specbridge/audit-packet.template.json",
    "templates/specbridge/chatgpt-audit.template.json",
    ".specbridge/schemas/executor-packet.schema.json",
    ".specbridge/schemas/runtime-launch.schema.json",
    ".specbridge/schemas/runtime-run.schema.json",
    ".specbridge/schemas/runtime-result.schema.json",
    ".specbridge/schemas/runtime-summary.schema.json",
    ".specbridge/schemas/autonomy-metrics.schema.json",
    ".specbridge/schemas/runtime-execution.schema.json",
    "scripts/validate-standard-templates.ps1",
    "scripts/validate-standard-ci-authority.ps1",
    "scripts/validate-runtime-executions.ps1",
    ".github/workflows/foundation-validation.yml",
    ".github/workflows/specbridge-review-gate.yml",
    ".github/workflows/specbridge-pr-review-report.yml",
    ".github/workflows/claude-review-non-blocking.yml"
  )

  $standardPathStatus = Get-StandardLoopPathStatus -Paths $standardRequiredPaths
  $missingStandardPaths = @($standardPathStatus | Where-Object { -not $_.exists } | ForEach-Object { $_.path })

  $runtimeValidatorPaths = @(
    "scripts/validate-runtime-runs.ps1",
    "scripts/validate-runtime-results.ps1",
    "scripts/validate-runtime-summaries.ps1",
    "scripts/validate-autonomy-metrics.ps1",
    "scripts/validate-runtime-executions.ps1"
  )

  $runtimeValidatorStatus = Get-StandardLoopPathStatus -Paths $runtimeValidatorPaths
  $missingRuntimeValidators = @($runtimeValidatorStatus | Where-Object { -not $_.exists } | ForEach-Object { $_.path })

  $v5BoundaryPath = "docs/specbridge-v5-live-parallel-pilot-boundary.md"
  $currentGoalPath = ".specbridge/context/CURRENT_GOAL.md"
  $contractPath = ".specbridge/contracts/v5-pilot-readiness.execution.md"
  $scopePath = ".specbridge/scopes/v5-pilot-readiness.scope.json"
  $handoffPath = ".specbridge/executor-handoffs/v5-pilot-readiness.input.json"
  $metricsPath = ".specbridge/metrics/v5-pilot-readiness.autonomy-metrics.json"
  $packetPaths = @()
  $runtimeLaunchPaths = @()
  $runtimeExecutionPaths = @()
  $runtimeSummaryPaths = @()

  if (Test-Path -LiteralPath ".specbridge/executor-packets") {
    $packetPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/executor-packets" -Filter "v5-pilot-readiness-*.executor-packet.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/executor-packets" $_.Name) -FieldName "v5_executor_packet" }
    )
  }

  if (Test-Path -LiteralPath ".specbridge/runtime-launches") {
    $runtimeLaunchPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/runtime-launches" -Filter "v5-pilot-readiness-*.runtime-launch.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/runtime-launches" $_.Name) -FieldName "v5_runtime_launch" }
    )
  }

  if (Test-Path -LiteralPath ".specbridge/runtime-executions") {
    $runtimeExecutionPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/runtime-executions" -Filter "v5-pilot-readiness-*.runtime-execution.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/runtime-executions" $_.Name) -FieldName "v5_runtime_execution" }
    )
  }

  if (Test-Path -LiteralPath ".specbridge/runtime-summaries") {
    $runtimeSummaryPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/runtime-summaries" -Filter "v5-pilot-readiness-*.runtime-summary.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/runtime-summaries" $_.Name) -FieldName "v5_runtime_summary" }
    )
  }

  $runtimeExecutionEvidenceReady = ($runtimeExecutionPaths.Count -ge 2)
  $runtimeExecutionEvidenceDetails = @()

  foreach ($executionPath in $runtimeExecutionPaths) {
    $executionArtifact = Get-JsonObjectFromFile -Path $executionPath -Description "V5 runtime execution"

    if (-not ($executionArtifact.PSObject.Properties.Name.Contains("dry_run") -and [bool] $executionArtifact.dry_run -and $executionArtifact.execution_status -eq "dry_run")) {
      $runtimeExecutionEvidenceReady = $false
      $runtimeExecutionEvidenceDetails += "$executionPath is not dry_run evidence."
    }
  }

  if ($runtimeExecutionPaths.Count -lt 2) {
    $runtimeExecutionEvidenceDetails += "At least two V5 runtime dry-run execution artifacts are required."
  }

  $runtimeSummaryReady = ($runtimeSummaryPaths.Count -ge 2)
  $runtimeSummaryDetails = @()

  foreach ($summaryPath in $runtimeSummaryPaths) {
    $summaryArtifact = Get-JsonObjectFromFile -Path $summaryPath -Description "V5 runtime summary"

    if ($summaryArtifact.merge_readiness -ne "ready_for_policy_gates") {
      $runtimeSummaryReady = $false
      $runtimeSummaryDetails += "$summaryPath is not ready_for_policy_gates."
    }
  }

  if ($runtimeSummaryPaths.Count -lt 2) {
    $runtimeSummaryDetails += "At least two V5 runtime summaries are required."
  }

  $latestRuntimeExecution = Get-LatestArtifactPath -Path ".specbridge/runtime-executions" -Filter "*.runtime-execution.json"
  $latestRuntimeDryRunExecution = Get-LatestRuntimeDryRunPath
  $runtimeExecutionDryRunReady = $false
  $runtimeExecutionDetails = @()

  if ($null -eq $latestRuntimeDryRunExecution) {
    $runtimeExecutionDetails += "No dry-run runtime execution artifact was found."
  }
  else {
    $execution = Get-JsonObjectFromFile -Path $latestRuntimeDryRunExecution -Description "runtime execution"

    if ($execution.PSObject.Properties.Name.Contains("dry_run") -and $execution.PSObject.Properties.Name.Contains("execution_status")) {
      $runtimeExecutionDryRunReady = ([bool] $execution.dry_run -and $execution.execution_status -eq "dry_run")
    }

    if (-not $runtimeExecutionDryRunReady) {
      $runtimeExecutionDetails += "Latest runtime execution is not a dry_run evidence artifact."
    }
  }

  $runtimeExecutionEvidence = "missing"

  if ($null -ne $latestRuntimeDryRunExecution) {
    $runtimeExecutionEvidence = $latestRuntimeDryRunExecution
  }

  $prerequisites = @()
  $prerequisites += New-V5Prerequisite `
    -Name "standard_loop_v1_paths" `
    -Passed ($missingStandardPaths.Count -eq 0) `
    -Evidence "standard-loop-status required path set" `
    -Details $missingStandardPaths
  $prerequisites += New-V5Prerequisite `
    -Name "runtime_evidence_validators" `
    -Passed ($missingRuntimeValidators.Count -eq 0) `
    -Evidence ($runtimeValidatorPaths -join ", ") `
    -Details $missingRuntimeValidators
  $prerequisites += New-V5Prerequisite `
    -Name "controlled_runner_dry_run_evidence" `
    -Passed $runtimeExecutionDryRunReady `
    -Evidence $runtimeExecutionEvidence `
    -Details $runtimeExecutionDetails
  $prerequisites += New-V5Prerequisite `
    -Name "v5_boundary_documented" `
    -Passed (Test-Path -LiteralPath $v5BoundaryPath) `
    -Evidence $v5BoundaryPath
  $prerequisites += New-V5Prerequisite `
    -Name "current_goal_points_to_v5" `
    -Passed ((Test-Path -LiteralPath $currentGoalPath) -and ((Get-Content -LiteralPath $currentGoalPath -Raw -Encoding UTF8) -match "V5 live parallel pilot")) `
    -Evidence $currentGoalPath
  $prerequisites += New-V5Prerequisite `
    -Name "v5_readiness_contract_present" `
    -Passed (Test-Path -LiteralPath $contractPath) `
    -Evidence $contractPath
  $prerequisites += New-V5Prerequisite `
    -Name "v5_readiness_scope_present" `
    -Passed (Test-Path -LiteralPath $scopePath) `
    -Evidence $scopePath
  $prerequisites += New-V5Prerequisite `
    -Name "v5_executor_handoff_present" `
    -Passed (Test-Path -LiteralPath $handoffPath) `
    -Evidence $handoffPath
  $prerequisites += New-V5Prerequisite `
    -Name "v5_executor_packets_prepared" `
    -Passed ($packetPaths.Count -ge 2) `
    -Evidence ($packetPaths -join ", ") `
    -Details $(if ($packetPaths.Count -ge 2) { @() } else { @("At least two V5 executor packets are required.") })
  $prerequisites += New-V5Prerequisite `
    -Name "v5_runtime_launches_prepared" `
    -Passed ($runtimeLaunchPaths.Count -ge 2) `
    -Evidence ($runtimeLaunchPaths -join ", ") `
    -Details $(if ($runtimeLaunchPaths.Count -ge 2) { @() } else { @("At least two V5 runtime launch plans are required.") })
  $prerequisites += New-V5Prerequisite `
    -Name "v5_runtime_dry_runs_recorded" `
    -Passed $runtimeExecutionEvidenceReady `
    -Evidence ($runtimeExecutionPaths -join ", ") `
    -Details $runtimeExecutionEvidenceDetails
  $prerequisites += New-V5Prerequisite `
    -Name "v5_runtime_summaries_ready" `
    -Passed $runtimeSummaryReady `
    -Evidence ($runtimeSummaryPaths -join ", ") `
    -Details $runtimeSummaryDetails
  $prerequisites += New-V5Prerequisite `
    -Name "v5_autonomy_metrics_present" `
    -Passed (Test-Path -LiteralPath $metricsPath) `
    -Evidence $metricsPath

  $failedPrerequisites = @($prerequisites | Where-Object { -not $_.passed })
  $readinessStatus = "ready_for_v5_live_contract"

  if ($failedPrerequisites.Count -gt 0) {
    $readinessStatus = "blocked"
  }

  Write-CliJson ([ordered]@{
    command = "v5-pilot-status"
    ok = ($failedPrerequisites.Count -eq 0)
    phase = "V5 live parallel Antigravity pilot readiness"
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    readiness_status = $readinessStatus
    prerequisite_count = @($prerequisites).Count
    failed_prerequisite_count = @($failedPrerequisites).Count
    prerequisites = @($prerequisites)
    latest_artifacts = [ordered]@{
      contract = Get-LatestArtifactPath -Path ".specbridge/contracts" -Filter "*.execution.md"
      scope = Get-LatestArtifactPath -Path ".specbridge/scopes" -Filter "*.scope.json"
      runtime_execution = $latestRuntimeExecution
      runtime_run = Get-LatestArtifactPath -Path ".specbridge/runtime-runs" -Filter "*.runtime-run.json"
      runtime_result = Get-LatestArtifactPath -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summary = Get-LatestArtifactPath -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
      autonomy_metrics = Get-LatestArtifactPath -Path ".specbridge/metrics" -Filter "*.autonomy-metrics.json"
      audit_packet = Get-LatestArtifactPath -Path ".specbridge/audit-packets" -Filter "*.audit-packet.json"
      chatgpt_audit = Get-LatestArtifactPath -Path ".specbridge/audits" -Filter "*.chatgpt-audit.json"
    }
    v5_artifacts = [ordered]@{
      readiness_contract = $contractPath
      readiness_scope = $scopePath
      executor_handoff = $handoffPath
      executor_packets = @($packetPaths)
      runtime_launches = @($runtimeLaunchPaths)
      runtime_executions = @($runtimeExecutionPaths)
      runtime_summaries = @($runtimeSummaryPaths)
      autonomy_metrics = $metricsPath
    }
    live_execution_boundary = [ordered]@{
      requires_dedicated_execution_contract = $true
      requires_non_overlapping_executor_scopes = $true
      requires_runtime_launch_plan_per_executor = $true
      requires_runtime_result_and_summary_per_executor = $true
      requires_chatgpt_codex_audit = $true
      production_deployment_allowed = $false
      secrets_allowed = $false
      billing_allowed = $false
      auth_security_changes_allowed = $false
      ci_cd_security_changes_allowed = $false
    }
    next_required_evidence = @(
      "Create the live V5 pilot execution contract with one small behavior change.",
      "Generate one executor packet and runtime launch plan per live executor.",
      "Run live Antigravity/Claude Code sessions only inside declared exclusive_write scopes.",
      "Record runtime-run, runtime-result, runtime-summary, autonomy metrics, final report, audit packet, ChatGPT/Codex audit, and GitHub CI evidence before integration."
    )
  }) -Depth 10

  if ($failedPrerequisites.Count -gt 0) {
    exit 1
  }

  exit 0
}

function Invoke-V5LiveStatusCommand {
  $liveContractPath = ".specbridge/contracts/issue-076-v5-live-parallel-pilot.execution.md"
  $liveReportPath = ".specbridge/reports/issue-076-v5-live-parallel-pilot.final-report.json"
  $liveAuditPath = ".specbridge/audits/issue-076-v5-live-parallel-pilot.chatgpt-audit.json"
  $liveMetricsPath = ".specbridge/metrics/issue-076-v5-live-parallel-pilot.autonomy-metrics.json"
  $currentGoalPath = ".specbridge/context/CURRENT_GOAL.md"

  $requiredArtifactPaths = @(
    $liveContractPath,
    $liveReportPath,
    $liveAuditPath,
    $liveMetricsPath,
    $currentGoalPath
  )

  $artifactStatus = @()

  foreach ($path in $requiredArtifactPaths) {
    $artifactStatus += [ordered]@{
      path = $path
      exists = (Test-Path -LiteralPath $path -PathType Leaf)
    }
  }

  $runtimeExecutionPaths = @()
  $runtimeSummaryPaths = @()

  if (Test-Path -LiteralPath ".specbridge/runtime-executions" -PathType Container) {
    $runtimeExecutionPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/runtime-executions" -Filter "issue-076-*.runtime-execution.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/runtime-executions" $_.Name) -FieldName "v5_live_runtime_execution" }
    )
  }

  if (Test-Path -LiteralPath ".specbridge/runtime-summaries" -PathType Container) {
    $runtimeSummaryPaths = @(
      Get-ChildItem -LiteralPath ".specbridge/runtime-summaries" -Filter "issue-076-*.runtime-summary.json" -File |
        Sort-Object Name |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path ".specbridge/runtime-summaries" $_.Name) -FieldName "v5_live_runtime_summary" }
    )
  }

  $executionRecords = @()
  $executionStatusCounts = @{}
  $executionDiagnosticsCount = 0

  foreach ($executionPath in $runtimeExecutionPaths) {
    $execution = Get-JsonObjectFromFile -Path $executionPath -Description "V5 live runtime execution"
    $status = $execution.execution_status

    if ([string]::IsNullOrWhiteSpace($status)) {
      $status = "unknown"
    }

    if (-not $executionStatusCounts.ContainsKey($status)) {
      $executionStatusCounts[$status] = 0
    }

    $executionStatusCounts[$status] += 1

    $hasFailureDiagnostics = $execution.PSObject.Properties.Name.Contains("failure_diagnostics")

    if ($hasFailureDiagnostics) {
      $executionDiagnosticsCount += 1
    }

    $diagnosticReason = $null

    if ($hasFailureDiagnostics -and $execution.failure_diagnostics.PSObject.Properties.Name.Contains("reason")) {
      $diagnosticReason = $execution.failure_diagnostics.reason
    }

    $executionRecords += [ordered]@{
      slice_id = $execution.slice_id
      execution_status = $execution.execution_status
      exit_code = $execution.exit_code
      timed_out = $execution.timed_out
      dry_run = $execution.dry_run
      has_failure_diagnostics = $hasFailureDiagnostics
      failure_reason = $diagnosticReason
      source_execution_path = $executionPath
    }
  }

  $summaryRecords = @()
  $summaryReady = ($runtimeSummaryPaths.Count -ge 3)

  foreach ($summaryPath in $runtimeSummaryPaths) {
    $summary = Get-JsonObjectFromFile -Path $summaryPath -Description "V5 live runtime summary"
    $blockerCount = @($summary.blockers).Count

    if ($summary.merge_readiness -ne "ready_for_policy_gates" -or $summary.completion_status -ne "complete") {
      $summaryReady = $false
    }

    $summaryRecords += [ordered]@{
      slice_id = $summary.slice_id
      runtime_status = $summary.runtime_status
      completion_status = $summary.completion_status
      merge_readiness = $summary.merge_readiness
      blocker_count = $blockerCount
      policy_result = $summary.policy_result
      source_summary_path = $summaryPath
    }
  }

  $auditApproved = $false
  $auditMergeAllowed = $false

  if (Test-Path -LiteralPath $liveAuditPath -PathType Leaf) {
    $audit = Get-JsonObjectFromFile -Path $liveAuditPath -Description "V5 live ChatGPT audit"
    $auditApproved = ($audit.outcome -eq "approved")
    $auditMergeAllowed = ([bool] $audit.merge_allowed)
  }

  $metricsReady = $false
  $metricsSummary = [ordered]@{
    ready_count = 0
    blocked_count = $null
    policy_gate_ready_rate = $null
  }

  if (Test-Path -LiteralPath $liveMetricsPath -PathType Leaf) {
    $metrics = Get-JsonObjectFromFile -Path $liveMetricsPath -Description "V5 live autonomy metrics"
    $metricsReady = (($metrics.ready_count -ge 3) -and ($metrics.blocked_count -eq 0))
    $metricsSummary = [ordered]@{
      ready_count = $metrics.ready_count
      blocked_count = $metrics.blocked_count
      policy_gate_ready_rate = $metrics.policy_gate_ready_rate
    }
  }

  $reportText = ""
  $currentGoalText = ""

  if (Test-Path -LiteralPath $liveReportPath -PathType Leaf) {
    $reportText = Get-Content -LiteralPath $liveReportPath -Raw -Encoding UTF8
  }

  if (Test-Path -LiteralPath $currentGoalPath -PathType Leaf) {
    $currentGoalText = Get-Content -LiteralPath $currentGoalPath -Raw -Encoding UTF8
  }

  $coordinatorRemediationRecorded = (
    $reportText -match "coordinator remediation" -or
    $reportText -match "coordinator remediated" -or
    $currentGoalText -match "coordinator remediation"
  )

  $failedLiveExecutions = @($executionRecords | Where-Object { $_.dry_run -eq $false -and $_.execution_status -eq "failed" })
  $timedOutLiveExecutions = @($executionRecords | Where-Object { $_.dry_run -eq $false -and $_.execution_status -eq "timed_out" })
  $liveExecutionRecords = @($executionRecords | Where-Object { $_.dry_run -eq $false })
  $requiredArtifactsPresent = (@($artifactStatus | Where-Object { -not $_.exists }).Count -eq 0)
  $livePilotComplete = (
    $requiredArtifactsPresent -and
    $runtimeExecutionPaths.Count -ge 4 -and
    $runtimeSummaryPaths.Count -ge 3 -and
    $summaryReady -and
    $metricsReady -and
    $auditApproved -and
    $auditMergeAllowed -and
    $coordinatorRemediationRecorded
  )

  $liveStatus = "blocked_or_incomplete"
  $readinessStatus = "blocked"

  if ($livePilotComplete) {
    $liveStatus = "completed_with_coordinator_remediation"
    $readinessStatus = "ready_for_second_live_pilot"
  }

  Write-CliJson ([ordered]@{
    command = "v5-live-status"
    ok = $livePilotComplete
    phase = "V5 live parallel pilot completion status"
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    live_status = $liveStatus
    readiness_status = $readinessStatus
    live_pilot_artifacts = [ordered]@{
      contract = $liveContractPath
      final_report = $liveReportPath
      chatgpt_audit = $liveAuditPath
      autonomy_metrics = $liveMetricsPath
      current_goal = $currentGoalPath
      required_artifacts = @($artifactStatus)
    }
    runtime_execution_counts = [ordered]@{
      total = @($executionRecords).Count
      live = @($liveExecutionRecords).Count
      failed_live = @($failedLiveExecutions).Count
      timed_out_live = @($timedOutLiveExecutions).Count
      with_failure_diagnostics = $executionDiagnosticsCount
      by_status = Convert-HashtableToOrderedObject -Table $executionStatusCounts
    }
    live_execution_outcomes = @($executionRecords)
    slice_outcomes = @($summaryRecords)
    coordinator_remediation = [ordered]@{
      recorded = $coordinatorRemediationRecorded
      required_for_completion = $true
      cli_failed_live_attempts = @($failedLiveExecutions).Count
      note = "The first V5 live pilot completed only after coordinator remediation of the CLI slice."
    }
    readiness_evidence = [ordered]@{
      summaries_ready = $summaryReady
      audit_approved = $auditApproved
      audit_merge_allowed = $auditMergeAllowed
      metrics = $metricsSummary
    }
    diagnostics = [ordered]@{
      current_runner_records_failure_diagnostics = $true
      historical_issue_076_execution_count = @($executionRecords).Count
      historical_issue_076_diagnostics_count = $executionDiagnosticsCount
      historical_issue_076_failed_execution_count = @($failedLiveExecutions).Count
      note = "Historical issue 076 execution artifacts predate failure_diagnostics; new execute-runtime-launch artifacts include bounded redacted diagnostics."
    }
    remaining_risks = @(
      "Live CLI executor reliability remains unproven because the first implementation slice failed twice before coordinator remediation.",
      "The next live pilot should require implementation, tests, and docs slices to complete without coordinator remediation."
    )
    next_recommended_action = "Run a second serious live pilot with diagnostics enabled and no coordinator remediation target."
  }) -Depth 12

  if (-not $livePilotComplete) {
    exit 1
  }

  exit 0
}

function Invoke-V5AutonomyStatusCommand {
  Write-CliJson ([ordered]@{
    command = "v5-autonomy-status"
    ok = $true
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    autonomy_standard = "v5_live_no_coordinator_remediation"
    prior_live_pilot_status = "completed_with_coordinator_remediation"
    target_live_pilot_status = "completed_without_coordinator_remediation"
    required_slices = @("implementation", "tests", "docs")
    coordinator_remediation_allowed = $false
    policy_boundary = "no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment"
  })

  exit 0
}

function Invoke-V5SeriousPilotStatusCommand {
  Write-CliJson ([ordered]@{
    command = "v5-serious-pilot-status"
    ok = $true
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    pilot_standard = "serious_live_multi_slice_no_remediation"
    runner_baseline = "v5_hardened_runtime_runner"
    required_slices = @("status", "tests", "docs")
    default_runtime_budget_usd = "2.00"
    diagnostic_preview_policy = "ascii_stable_bounded_240_chars"
    target_completion_status = "completed_without_coordinator_remediation"
    coordinator_remediation_allowed = $false
    max_live_retry_per_slice = 1
    pilot_block_rule = "two_failures_per_slice_block_the_pilot"
    policy_boundary = "no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment"
  })

  exit 0
}

function Invoke-BoundedLivePilotStatusCommand {
  $pilotSlices = @("docs", "status", "tests")
  $launchPlans = [ordered]@{}
  $executorEvidence = [ordered]@{}

  foreach ($slice in $pilotSlices) {
    $launchPath = ".specbridge/runtime-launches/issue-097-$slice.runtime-launch.json"
    $evidencePath = ".specbridge/runtime-evidence/issue-097-$slice.executor-output.md"

    $launchPlans[$slice] = [ordered]@{
      path = $launchPath
      exists = (Test-Path -LiteralPath $launchPath)
    }

    $executorEvidence[$slice] = [ordered]@{
      path = $evidencePath
      exists = (Test-Path -LiteralPath $evidencePath)
    }
  }

  $allPlansExist = (@($launchPlans.Values | Where-Object { -not $_.exists }).Count -eq 0)
  $evidenceCount = @($executorEvidence.Values | Where-Object { $_.exists }).Count

  Write-CliJson ([ordered]@{
    command = "bounded-live-pilot-status"
    ok = $allPlansExist
    branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    pilot_id = "issue-097-multi-slice-live-pilot"
    pilot_slices = @($pilotSlices)
    prepared_launch_plans = $launchPlans
    executor_evidence = $executorEvidence
    executor_evidence_count = $evidenceCount
    policy_boundary = "no-production no-secrets no-billing no-auth no-authorization no-database no-dependency-installation no-ci-cd-security no-deployment"
  })

  exit 0
}
