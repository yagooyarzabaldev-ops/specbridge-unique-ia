param(
  [Parameter(Position = 0)]
  [ValidateSet("status", "validate", "create-contract", "create-report", "audit-packet", "detect-conflicts", "decompose-task", "prepare-executors", "prepare-runtime-launch", "execute-runtime-launch", "run-runtime-launch", "record-runtime-result", "summarize-runtime", "summarize-autonomy-metrics", "standard-loop-status", "v5-pilot-status", "v5-live-status", "v5-autonomy-status", "runtime-capability-status", "plan-executor-branches", "record-github-evidence", "coordinate-executors", "review-gate")]
  [string] $Command = "status",

  [string] $TaskId = "",
  [string] $Title = "",
  [string] $Goal = "",
  [string] $RelatedIssue = "",
  [string] $OutputPath = "",
  [string] $InputPath = "",
  [string] $ContractPath = "",
  [string] $ReportPath = "",
  [string] $OutputDirectory = "",
  [string] $OutputFileName = "",
  [string] $EvidencePath = "",
  [string] $CiStatus = "not_collected",
  [string] $Summary = "",
  [string[]] $ChangedFile = @(),
  [string[]] $Validation = @(),
  [string] $PolicyResult = "",
  [string] $RiskResult = "",
  [string] $CompletionStatus = "draft",
  [string] $Profile = "standard",
  [string] $BranchPrefix = "claude",
  [string[]] $AllowedTool = @("Read", "Write"),
  [ValidateSet("acceptEdits", "auto", "default", "dontAsk", "plan")]
  [string] $PermissionMode = "acceptEdits",
  [string] $MaxBudgetUsd = "0.25",
  [int] $RuntimeExitCode = 0,
  [int] $TimeoutSeconds = 300,
  [string[]] $WrittenFile = @(),
  [ValidateSet("simulation", "github")]
  [string] $EvidenceMode = "simulation",
  [string] $RepositoryUrl = "https://github.com/yagooyarzabaldev-ops/specbridge",
  [string] $BaseBranch = "main",
  [switch] $IncludeLatestArtifacts,
  [switch] $DryRun,
  [switch] $Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Write-CliJson {
  param(
    [object] $Value,
    [int] $Depth = 8
  )

  $Value | ConvertTo-Json -Depth $Depth
}

function Fail {
  param(
    [string] $Message,
    [int] $Code = 1
  )

  Write-CliJson ([ordered]@{
    command = $Command
    ok = $false
    error = $Message
  })

  exit $Code
}

function Normalize-RepoPath {
  param(
    [string] $Path,
    [string] $FieldName
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    Fail "$FieldName is required"
  }

  $normalized = $Path.Trim().Replace("\", "/")

  while ($normalized.StartsWith("./")) {
    $normalized = $normalized.Substring(2)
  }

  if ([System.IO.Path]::IsPathRooted($normalized)) {
    Fail "$FieldName must be repository-relative: $Path"
  }

  if ($normalized -match "(^|/)\.\.(/|$)") {
    Fail "$FieldName must not traverse parent directories: $Path"
  }

  if ([string]::IsNullOrWhiteSpace($normalized)) {
    Fail "$FieldName must not normalize to an empty path"
  }

  return $normalized
}

function Assert-OutputPath {
  param(
    [string] $Path,
    [string] $Pattern,
    [string] $Description
  )

  $normalized = Normalize-RepoPath -Path $Path -FieldName "OutputPath"

  if ($normalized -notmatch $Pattern) {
    Fail "OutputPath must point to $Description`: $normalized"
  }

  if ((Test-Path -LiteralPath $normalized) -and -not $Force) {
    Fail "OutputPath already exists; use -Force to replace it: $normalized"
  }

  return $normalized
}

function New-ParentDirectory {
  param(
    [string] $Path
  )

  $parent = Split-Path -Parent $Path

  if (-not [string]::IsNullOrWhiteSpace($parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
}

function Write-Utf8JsonFile {
  param(
    [string] $Path,
    [object] $Value,
    [int] $Depth = 8
  )

  New-ParentDirectory -Path $Path
  $json = $Value | ConvertTo-Json -Depth $Depth
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Join-Path $repoRoot $Path), $json, $utf8NoBom)
}

function Write-Utf8TextFile {
  param(
    [string] $Path,
    [string] $Value
  )

  New-ParentDirectory -Path $Path
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Join-Path $repoRoot $Path), $Value, $utf8NoBom)
}

function Invoke-ScriptGate {
  param(
    [string] $ScriptPath
  )

  if (-not (Test-Path -LiteralPath $ScriptPath)) {
    return [ordered]@{
      command = $ScriptPath
      result = "missing"
      exit_code = 1
    }
  }

  $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1
  $exitCode = $LASTEXITCODE

  if ($null -eq $exitCode) {
    $exitCode = 0
  }

  $result = "passed"

  if ($exitCode -ne 0) {
    $result = "failed"
  }

  return [ordered]@{
    command = $ScriptPath
    result = $result
    exit_code = $exitCode
    output = @($output | ForEach-Object { $_.ToString() })
  }
}

function Invoke-ValidationProfile {
  param(
    [string] $SelectedProfile
  )

  $standardScripts = @(
    "./scripts/validate-foundation.ps1",
    "./scripts/validate-contracts.ps1",
    "./scripts/validate-contract-scopes.ps1",
    "./scripts/validate-schemas.ps1",
    "./scripts/validate-final-reports.ps1",
    "./scripts/validate-audit-packets.ps1",
    "./scripts/validate-chatgpt-audits.ps1",
    "./scripts/validate-executor-packets.ps1",
    "./scripts/validate-runtime-launches.ps1",
    "./scripts/validate-runtime-runs.ps1",
    "./scripts/validate-runtime-results.ps1",
    "./scripts/validate-runtime-summaries.ps1",
    "./scripts/validate-autonomy-metrics.ps1",
    "./scripts/validate-runtime-executions.ps1",
    "./scripts/validate-standard-templates.ps1",
    "./scripts/validate-standard-ci-authority.ps1",
    "./scripts/validate-branch-orchestrations.ps1",
    "./scripts/validate-security-gates.ps1",
    "./scripts/validate-pr-review-reports.ps1",
    "./scripts/validate-claude-review-workflow.ps1",
    "./scripts/validate-autonomous-execution-protocol.ps1",
    "./scripts/validate-review-gate.ps1"
  )

  if ($SelectedProfile -eq "standard") {
    return @($standardScripts)
  }

  if ($SelectedProfile -eq "full") {
    return @($standardScripts + "./scripts/test-specbridge-negative-validations.ps1")
  }

  if ($SelectedProfile -eq "smoke") {
    return @("./scripts/specbridge-smoke.ps1")
  }

  Fail "Profile must be one of: standard, full, smoke"
}

function Get-FileCount {
  param(
    [string] $Path,
    [string] $Filter
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return 0
  }

  return @(Get-ChildItem -LiteralPath $Path -Filter $Filter -File).Count
}

function Get-LatestArtifactPath {
  param(
    [string] $Path,
    [string] $Filter
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  $file = Get-ChildItem -LiteralPath $Path -Filter $Filter -File |
    ForEach-Object {
      $issueNumber = -1

      if ($_.Name -match "^issue-(\d+)") {
        $issueNumber = [int] $Matches[1]
      }

      [pscustomobject]@{
        File = $_
        IssueNumber = $issueNumber
        Name = $_.Name
      }
    } |
    Sort-Object `
      @{ Expression = "IssueNumber"; Descending = $true },
      @{ Expression = "Name"; Descending = $true } |
    Select-Object -First 1 -ExpandProperty File

  if ($null -eq $file) {
    return $null
  }

  return Normalize-RepoPath -Path (Join-Path $Path $file.Name) -FieldName "latest_artifact"
}

function Get-LatestRuntimeDryRunPath {
  $path = ".specbridge/runtime-executions"

  if (-not (Test-Path -LiteralPath $path)) {
    return $null
  }

  $candidates = @()

  foreach ($file in @(Get-ChildItem -LiteralPath $path -Filter "*.runtime-execution.json" -File)) {
    $repoPath = Normalize-RepoPath -Path (Join-Path $path $file.Name) -FieldName "runtime_execution"

    try {
      $execution = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    }
    catch {
      continue
    }

    if (-not ($execution.PSObject.Properties.Name.Contains("dry_run") -and $execution.PSObject.Properties.Name.Contains("execution_status"))) {
      continue
    }

    if (-not ([bool] $execution.dry_run) -or $execution.execution_status -ne "dry_run") {
      continue
    }

    $issueNumber = -1

    if ($file.Name -match "^issue-(\d+)") {
      $issueNumber = [int] $Matches[1]
    }

    $candidates += [pscustomobject]@{
      Path = $repoPath
      IssueNumber = $issueNumber
      Name = $file.Name
    }
  }

  $latest = $candidates |
    Sort-Object `
      @{ Expression = "IssueNumber"; Descending = $true },
      @{ Expression = "Name"; Descending = $true } |
    Select-Object -First 1

  if ($null -eq $latest) {
    return $null
  }

  return $latest.Path
}

function Get-GitValue {
  param(
    [string[]] $Arguments,
    [string] $Fallback = ""
  )

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  try {
    $value = & git @Arguments 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($value | Out-String))) {
      return $Fallback
    }

    return (($value | Select-Object -First 1) | Out-String).Trim()
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
}

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
      runtime_results = Get-FileCount -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summaries = Get-FileCount -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
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
      runtime_result = Get-LatestArtifactPath -Path ".specbridge/runtime-results" -Filter "*.runtime-result.json"
      runtime_summary = Get-LatestArtifactPath -Path ".specbridge/runtime-summaries" -Filter "*.runtime-summary.json"
    }
  }

  Write-CliJson $status
  exit 0
}

function Get-ResolvedPathOrNull {
  param(
    [string] $Path
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return $null
  }

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  try {
    return (Resolve-Path -LiteralPath $Path).Path
  }
  catch {
    return $Path
  }
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
    ".specbridge/schemas/runtime-run.schema.json",
    ".specbridge/schemas/runtime-result.schema.json",
    ".specbridge/schemas/runtime-summary.schema.json",
    ".specbridge/schemas/autonomy-metrics.schema.json",
    ".specbridge/schemas/runtime-execution.schema.json"
  )

  $validatorPaths = @(
    "scripts/validate-standard-templates.ps1",
    "scripts/validate-standard-ci-authority.ps1",
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
    -Passed ((Test-Path -LiteralPath $currentGoalPath) -and ((Get-Content -LiteralPath $currentGoalPath -Raw) -match "V5 live parallel pilot")) `
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
    $reportText = Get-Content -LiteralPath $liveReportPath -Raw
  }

  if (Test-Path -LiteralPath $currentGoalPath -PathType Leaf) {
    $currentGoalText = Get-Content -LiteralPath $currentGoalPath -Raw
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

function Invoke-ValidateCommand {
  $scripts = Invoke-ValidationProfile -SelectedProfile $Profile
  $results = @()
  $failed = $false

  foreach ($script in $scripts) {
    $result = Invoke-ScriptGate -ScriptPath $script
    $results += $result

    if ($result.exit_code -ne 0) {
      $failed = $true
      break
    }
  }

  Write-CliJson ([ordered]@{
    command = "validate"
    ok = (-not $failed)
    profile = $Profile
    results = $results
  })

  if ($failed) {
    exit 1
  }

  exit 0
}

function Invoke-CreateContractCommand {
  if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Fail "TaskId is required"
  }

  if ([string]::IsNullOrWhiteSpace($Title)) {
    Fail "Title is required"
  }

  if ([string]::IsNullOrWhiteSpace($Goal)) {
    Fail "Goal is required"
  }

  if ([string]::IsNullOrWhiteSpace($RelatedIssue)) {
    Fail "RelatedIssue is required"
  }

  $path = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/contracts/.+\.execution\.md$" `
    -Description "a .specbridge/contracts/*.execution.md contract"

  $contract = @"
# Execution Contract: $Title

## Contract Metadata

- contract_id: $TaskId
- related_issue: $RelatedIssue
- created_by: SpecBridge CLI
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: low
- status: draft

## Goal

$Goal

## Context

Generated by the local SpecBridge CLI from declared command inputs.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

## Allowed Scope

```text
To be filled before execution.
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
runtime product code unless explicitly authorized
production deployment
billing
authentication security changes
authorization security changes
CI/CD security weakening
```

## Acceptance Criteria

- The contract is completed before execution.
- Required validations are declared before execution.
- Scope remains repository-relative and auditable.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Stop Conditions

Stop on policy conflict, missing required context, impossible acceptance criteria, secrets, production configuration, billing, authentication security, authorization security, or CI/CD security weakening.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete only when the declared validations pass and the final report records evidence.
"@

  Write-Utf8TextFile -Path $path -Value $contract

  Write-CliJson ([ordered]@{
    command = "create-contract"
    ok = $true
    output_path = $path
  })

  exit 0
}

function Invoke-CreateReportCommand {
  if ([string]::IsNullOrWhiteSpace($Summary)) {
    Fail "Summary is required"
  }

  if ($ChangedFile.Count -le 0) {
    Fail "ChangedFile requires at least one path"
  }

  if ($Validation.Count -le 0) {
    Fail "Validation requires at least one record"
  }

  if ([string]::IsNullOrWhiteSpace($PolicyResult)) {
    Fail "PolicyResult is required"
  }

  if ([string]::IsNullOrWhiteSpace($RiskResult)) {
    Fail "RiskResult is required"
  }

  $path = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/reports/.+\.final-report\.json$" `
    -Description "a .specbridge/reports/*.final-report.json final report"

  $normalizedChangedFiles = @($ChangedFile | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "ChangedFile" })

  $report = [ordered]@{
    summary = $Summary
    changed_files = @($normalizedChangedFiles)
    validations = @($Validation)
    policy_result = $PolicyResult
    risk_result = $RiskResult
    unresolved_risks = @()
    merge_status = "Not applicable."
    deployment_status = "Not applicable."
    completion_status = $CompletionStatus
  }

  Write-Utf8JsonFile -Path $path -Value $report -Depth 6

  Write-CliJson ([ordered]@{
    command = "create-report"
    ok = $true
    output_path = $path
  })

  exit 0
}

function Invoke-AuditPacketCommand {
  if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Fail "TaskId is required"
  }

  $contract = Normalize-RepoPath -Path $ContractPath -FieldName "ContractPath"
  $report = Normalize-RepoPath -Path $ReportPath -FieldName "ReportPath"
  $outputDir = ".specbridge/audit-packets"

  if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $outputDir = Normalize-RepoPath -Path $OutputDirectory -FieldName "OutputDirectory"
  }

  $generatorArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    "./scripts/generate-audit-packet.ps1",
    "-TaskId",
    $TaskId,
    "-ExecutionContractPath",
    $contract,
    "-FinalReportPath",
    $report,
    "-CiStatus",
    $CiStatus,
    "-OutputDirectory",
    $outputDir
  )

  if (-not [string]::IsNullOrWhiteSpace($OutputFileName)) {
    $generatorArgs += @("-OutputFileName", $OutputFileName)
  }

  & powershell @generatorArgs
  $exitCode = $LASTEXITCODE

  if ($exitCode -ne 0) {
    Fail "audit packet generation failed" $exitCode
  }

  $packetName = $OutputFileName

  if ([string]::IsNullOrWhiteSpace($packetName)) {
    $packetName = "$TaskId.audit-packet.json"
  }

  Write-CliJson ([ordered]@{
    command = "audit-packet"
    ok = $true
    output_path = (Normalize-RepoPath -Path (Join-Path $outputDir $packetName) -FieldName "output_path")
  })

  exit 0
}

function Invoke-DetectConflictsCommand {
  $result = Invoke-ScriptGate -ScriptPath "./scripts/validate-contract-scopes.ps1"

  Write-CliJson ([ordered]@{
    command = "detect-conflicts"
    ok = ($result.exit_code -eq 0)
    result = $result
  })

  exit $result.exit_code
}

function Invoke-DecomposeTaskCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/decompositions/.+\.decomposition\.json$" `
    -Description "a .specbridge/decompositions/*.decomposition.json decomposition"

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  try {
    $source = Get-Content -LiteralPath $input -Raw | ConvertFrom-Json
  }
  catch {
    Fail "InputPath must contain valid JSON: $input"
  }

  if (-not $source.PSObject.Properties.Name.Contains("task_id") -or [string]::IsNullOrWhiteSpace($source.task_id)) {
    Fail "InputPath JSON must include task_id"
  }

  if (-not $source.PSObject.Properties.Name.Contains("slices") -or -not ($source.slices -is [System.Array]) -or @($source.slices).Count -le 0) {
    Fail "InputPath JSON must include a non-empty slices array"
  }

  $seenWritePaths = @{}
  $slices = @()

  foreach ($slice in @($source.slices)) {
    foreach ($field in @("id", "goal", "exclusive_write")) {
      if (-not $slice.PSObject.Properties.Name.Contains($field)) {
        Fail "Each slice must include $field"
      }
    }

    $sliceWrites = @($slice.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "slice.exclusive_write" })

    foreach ($writePath in $sliceWrites) {
      if ($seenWritePaths.ContainsKey($writePath)) {
        Fail "Duplicate exclusive_write path in decomposition: $writePath"
      }

      $seenWritePaths[$writePath] = $slice.id
    }

    $slices += [ordered]@{
      id = $slice.id
      goal = $slice.goal
      exclusive_write = @($sliceWrites)
      status = "planned"
    }
  }

  $decomposition = [ordered]@{
    schema_version = "1"
    task_id = $source.task_id
    generated_by = "specbridge-cli"
    slices = @($slices)
  }

  Write-Utf8JsonFile -Path $output -Value $decomposition -Depth 8

  Write-CliJson ([ordered]@{
    command = "decompose-task"
    ok = $true
    output_path = $output
    slices = @($slices).Count
  })

  exit 0
}

function Get-RequiredJsonString {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $Context
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    Fail "$Context must include $FieldName"
  }

  $value = $Object.$FieldName

  if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
    Fail "$Context.$FieldName must be a non-empty string"
  }

  return $value.Trim()
}

function Get-RequiredJsonStringArray {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $Context
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    Fail "$Context must include $FieldName"
  }

  $value = $Object.$FieldName

  if ($null -eq $value -or -not ($value -is [System.Array]) -or @($value).Count -le 0) {
    Fail "$Context.$FieldName must be a non-empty array"
  }

  $items = @()

  foreach ($item in @($value)) {
    if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
      Fail "$Context.$FieldName must contain only non-empty strings"
    }

    $items += $item.Trim()
  }

  return @($items)
}

function Get-OptionalJsonStringArray {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $Context
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    return @()
  }

  $value = $Object.$FieldName

  if ($null -eq $value) {
    return @()
  }

  if (-not ($value -is [System.Array])) {
    Fail "$Context.$FieldName must be an array when provided"
  }

  $items = @()

  foreach ($item in @($value)) {
    if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
      Fail "$Context.$FieldName must contain only non-empty strings"
    }

    $items += $item.Trim()
  }

  return @($items)
}

function Convert-ToSafeName {
  param(
    [string] $Value,
    [string] $FieldName
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    Fail "$FieldName is required"
  }

  $safe = $Value.Trim().ToLowerInvariant() -replace "[^a-z0-9._-]+", "-"
  $safe = $safe.Trim("-")

  if ([string]::IsNullOrWhiteSpace($safe)) {
    Fail "$FieldName must contain at least one safe character"
  }

  return $safe
}

function Invoke-PrepareExecutorsCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $outputDir = ".specbridge/executor-packets"

  if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $outputDir = Normalize-RepoPath -Path $OutputDirectory -FieldName "OutputDirectory"
  }

  if ($outputDir -notmatch "^\.specbridge/executor-packets(/.*)?$") {
    Fail "OutputDirectory must be under .specbridge/executor-packets: $outputDir"
  }

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  try {
    $source = Get-Content -LiteralPath $input -Raw | ConvertFrom-Json
  }
  catch {
    Fail "InputPath must contain valid JSON: $input"
  }

  $taskId = Get-RequiredJsonString -Object $source -FieldName "task_id" -Context "InputPath JSON"

  if (-not $source.PSObject.Properties.Name.Contains("slices") -or -not ($source.slices -is [System.Array]) -or @($source.slices).Count -le 0) {
    Fail "InputPath JSON must include a non-empty slices array"
  }

  $safeTaskId = Convert-ToSafeName -Value $taskId -FieldName "task_id"
  $safeBranchPrefix = Convert-ToSafeName -Value $BranchPrefix -FieldName "BranchPrefix"
  $seenPacketPaths = @{}
  $seenBranchNames = @{}
  $packets = @()

  foreach ($slice in @($source.slices)) {
    $context = "slice"
    $sliceId = Get-RequiredJsonString -Object $slice -FieldName "id" -Context $context
    $goal = Get-RequiredJsonString -Object $slice -FieldName "goal" -Context $context
    $role = Get-RequiredJsonString -Object $slice -FieldName "role" -Context $context
    $contractPath = Normalize-RepoPath -Path (Get-RequiredJsonString -Object $slice -FieldName "contract_path" -Context $context) -FieldName "slice.contract_path"
    $finalReportPath = Normalize-RepoPath -Path (Get-RequiredJsonString -Object $slice -FieldName "final_report_path" -Context $context) -FieldName "slice.final_report_path"
    $exclusiveWrite = @(
      Get-RequiredJsonStringArray -Object $slice -FieldName "exclusive_write" -Context $context |
        ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "slice.exclusive_write" }
    )
    $readOnly = @(
      Get-OptionalJsonStringArray -Object $slice -FieldName "read_only" -Context $context |
        ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "slice.read_only" }
    )
    $validations = @(
      Get-RequiredJsonStringArray -Object $slice -FieldName "required_validations" -Context $context
    )

    if ($contractPath -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
      Fail "slice.contract_path must point to a SpecBridge execution contract: $contractPath"
    }

    if (-not (Test-Path -LiteralPath $contractPath)) {
      Fail "slice.contract_path does not exist: $contractPath"
    }

    if ($finalReportPath -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Fail "slice.final_report_path must point to a SpecBridge final report path: $finalReportPath"
    }

    $safeSliceId = Convert-ToSafeName -Value $sliceId -FieldName "slice.id"
    $branchName = "$safeBranchPrefix/$safeTaskId-$safeSliceId"

    if ($slice.PSObject.Properties.Name.Contains("branch_name") -and -not [string]::IsNullOrWhiteSpace($slice.branch_name)) {
      $branchName = $slice.branch_name.Trim()
    }

    if ($branchName -notmatch "^[A-Za-z0-9._/-]+$" -or $branchName -match "(^|/)\.\.(/|$)") {
      Fail "slice.branch_name contains unsupported characters: $branchName"
    }

    if ($seenBranchNames.ContainsKey($branchName)) {
      Fail "Duplicate branch_name in executor handoff input: $branchName"
    }

    $seenBranchNames[$branchName] = $sliceId
    $packetFileName = "$safeTaskId-$safeSliceId.executor-packet.json"
    $packetPath = Normalize-RepoPath -Path (Join-Path $outputDir $packetFileName) -FieldName "executor_packet_path"

    if ($seenPacketPaths.ContainsKey($packetPath)) {
      Fail "Duplicate executor packet path: $packetPath"
    }

    if ((Test-Path -LiteralPath $packetPath) -and -not $Force) {
      Fail "Executor packet already exists; use -Force to replace it: $packetPath"
    }

    $seenPacketPaths[$packetPath] = $sliceId

    $packet = [ordered]@{
      schema_version = "1"
      packet_id = "$safeTaskId-$safeSliceId"
      task_id = $taskId
      slice_id = $sliceId
      agent_role = $role
      goal = $goal
      launch_mode = "manual_antigravity"
      branch_name = $branchName
      execution_contract_path = $contractPath
      final_report_path = $finalReportPath
      exclusive_write = @($exclusiveWrite)
      read_only = @($readOnly)
      required_validations = @($validations)
      stop_conditions = @(
        "policy_conflict",
        "scope_conflict",
        "missing_required_context",
        "impossible_acceptance_criteria",
        "protected_resource_required"
      )
      status = "ready_for_handoff"
      source_files = @(
        $input,
        $contractPath
      )
      generated_by = "specbridge-cli"
    }

    Write-Utf8JsonFile -Path $packetPath -Value $packet -Depth 8
    $packets += $packetPath
  }

  Write-CliJson ([ordered]@{
    command = "prepare-executors"
    ok = $true
    output_directory = $outputDir
    packets = @($packets)
    packet_count = @($packets).Count
  })

  exit 0
}

function Invoke-PrepareRuntimeLaunchCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$" `
    -Description "a .specbridge/runtime-launches/*.runtime-launch.json runtime launch plan"

  if ($input -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$") {
    Fail "InputPath must be a .specbridge/executor-packets/*.executor-packet.json file: $input"
  }

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  $packet = Get-JsonObjectFromFile -Path $input -Description "executor packet"
  $context = "executor packet $input"

  foreach ($field in @("packet_id", "task_id", "slice_id", "agent_role", "goal", "branch_name", "execution_contract_path", "final_report_path", "exclusive_write", "read_only", "required_validations", "stop_conditions", "status")) {
    if (-not $packet.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($packet.status -ne "ready_for_handoff") {
    Fail "executor packet status must be ready_for_handoff: $input"
  }

  $contractPath = Normalize-RepoPath -Path $packet.execution_contract_path -FieldName "execution_contract_path"
  $finalReportPath = Normalize-RepoPath -Path $packet.final_report_path -FieldName "final_report_path"
  $exclusiveWrite = @($packet.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })
  $readOnly = @($packet.read_only | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "read_only" })
  $validations = @($packet.required_validations | ForEach-Object {
    if ($null -eq $_ -or $_.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($_)) {
      Fail "required_validations must contain only non-empty strings"
    }

    $_.Trim()
  })
  $stopConditions = @($packet.stop_conditions | ForEach-Object {
    if ($null -eq $_ -or $_.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($_)) {
      Fail "stop_conditions must contain only non-empty strings"
    }

    $_.Trim()
  })

  if ($contractPath -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
    Fail "execution_contract_path must point to a SpecBridge execution contract: $contractPath"
  }

  if (-not (Test-Path -LiteralPath $contractPath)) {
    Fail "execution_contract_path does not exist: $contractPath"
  }

  if ($finalReportPath -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
    Fail "final_report_path must point to a SpecBridge final report path: $finalReportPath"
  }

  if ($exclusiveWrite.Count -le 0) {
    Fail "executor packet exclusive_write must not be empty"
  }

  if ($readOnly.Count -le 0) {
    Fail "executor packet read_only must not be empty"
  }

  if ($validations.Count -le 0) {
    Fail "executor packet required_validations must not be empty"
  }

  $approvedTools = @("Read", "Write", "Edit")
  $normalizedAllowedTools = @()

  foreach ($toolEntry in @($AllowedTool)) {
    if ($null -eq $toolEntry -or $toolEntry.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($toolEntry)) {
      Fail "AllowedTool must contain only non-empty strings"
    }

    foreach ($tool in @($toolEntry -split ",")) {
      $trimmedTool = $tool.Trim()

      if ([string]::IsNullOrWhiteSpace($trimmedTool)) {
        Fail "AllowedTool must contain only non-empty strings"
      }

      if ($approvedTools -notcontains $trimmedTool) {
        Fail "AllowedTool is not approved for runtime launch planning: $trimmedTool"
      }

      $normalizedAllowedTools += $trimmedTool
    }
  }

  $normalizedAllowedTools = @($normalizedAllowedTools | Sort-Object -Unique)

  if ($normalizedAllowedTools.Count -le 0) {
    Fail "AllowedTool must include at least one approved tool"
  }

  foreach ($requiredTool in @("Read", "Write")) {
    if ($normalizedAllowedTools -notcontains $requiredTool) {
      Fail "AllowedTool must include $requiredTool for runtime launch planning"
    }
  }

  if ($MaxBudgetUsd -notmatch "^[0-9]+(\.[0-9]{1,2})?$") {
    Fail "MaxBudgetUsd must be a positive decimal string with up to two fractional digits"
  }

  $budget = [decimal]::Parse($MaxBudgetUsd, [System.Globalization.CultureInfo]::InvariantCulture)

  if ($budget -le 0 -or $budget -gt 10) {
    Fail "MaxBudgetUsd must be greater than 0 and no more than 10"
  }

  $safeLaunchId = Convert-ToSafeName -Value ($packet.packet_id + "-runtime-launch") -FieldName "launch_id"
  $allowedToolsText = ($normalizedAllowedTools -join ",")

  $promptSections = @(
    "Read README.md, SPECBRIDGE.md, AGENTS.md, CLAUDE.md, .specbridge/policy.yaml, the execution contract, and the executor packet before writing.",
    "Modify only paths declared in exclusive_write.",
    "Treat read_only paths as context only.",
    "Run only required validations that are explicitly allowed by the runtime operator.",
    "Stop on policy conflict, scope conflict, missing required context, impossible acceptance criteria, protected resource requirement, secrets, production configuration, billing, authentication security, authorization security, dependency installation, database change, CI/CD security change, or deployment automation.",
    "Report changed files, validation evidence, policy result, unresolved risks, and completion status."
  )

  $launch = [ordered]@{
    schema_version = "1"
    launch_id = $safeLaunchId
    generated_by = "specbridge-cli"
    source_executor_packet_path = $input
    task_id = $packet.task_id
    packet_id = $packet.packet_id
    slice_id = $packet.slice_id
    agent_role = $packet.agent_role
    goal = $packet.goal
    branch_name = $packet.branch_name
    execution_contract_path = $contractPath
    final_report_path = $finalReportPath
    exclusive_write = @($exclusiveWrite)
    read_only = @($readOnly)
    required_validations = @($validations)
    allowed_tools = @($normalizedAllowedTools)
    permission_mode = $PermissionMode
    max_budget_usd = $MaxBudgetUsd
    command_summary = "claude -p --no-session-persistence --max-budget-usd $MaxBudgetUsd --permission-mode $PermissionMode --tools `"$allowedToolsText`" --allowedTools `"$allowedToolsText`" <bounded prompt>"
    prompt_sections = @($promptSections)
    stop_conditions = @($stopConditions)
    launch_status = "ready_for_operator_launch"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($input, $contractPath)
  }

  Write-Utf8JsonFile -Path $output -Value $launch -Depth 10

  Write-CliJson ([ordered]@{
    command = "prepare-runtime-launch"
    ok = $true
    output_path = $output
    source_executor_packet_path = $input
    launch_status = "ready_for_operator_launch"
  })

  exit 0
}

function Convert-ValidationRecords {
  param(
    [string[]] $Records
  )

  if ($Records.Count -le 0) {
    Fail "Validation must include at least one runtime validation result"
  }

  $results = @()

  foreach ($recordEntry in @($Records)) {
    if ($null -eq $recordEntry -or $recordEntry.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($recordEntry)) {
      Fail "Validation must contain only non-empty strings"
    }

    foreach ($record in @($recordEntry -split ",")) {
      $trimmed = $record.Trim()

      if ([string]::IsNullOrWhiteSpace($trimmed)) {
        Fail "Validation must contain only non-empty strings"
      }

      $separatorIndex = $trimmed.LastIndexOf(": ")

      if ($separatorIndex -gt 0) {
        $commandText = $trimmed.Substring(0, $separatorIndex).Trim()
        $resultText = $trimmed.Substring($separatorIndex + 2).Trim()
      }
      else {
        $commandText = $trimmed
        $resultText = "recorded"
      }

      if ([string]::IsNullOrWhiteSpace($commandText) -or [string]::IsNullOrWhiteSpace($resultText)) {
        Fail "Validation records must contain non-empty command and result text"
      }

      $results += [ordered]@{
        command = $commandText
        result = $resultText
      }
    }
  }

  return @($results)
}

function Invoke-RecordRuntimeResultCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidence = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-results/.+\.runtime-result\.json$" `
    -Description "a .specbridge/runtime-results/*.runtime-result.json runtime result"

  if ($input -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $input"
  }

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
    Fail "EvidencePath must reference an existing executor evidence file: $evidence"
  }

  $launch = Get-JsonObjectFromFile -Path $input -Description "runtime launch plan"
  $context = "runtime launch plan $input"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "exclusive_write", "required_validations", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch plan status must be ready_for_operator_launch: $input"
  }

  $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })

  if ($exclusiveWrite.Count -le 0) {
    Fail "runtime launch plan exclusive_write must not be empty"
  }

  if ($exclusiveWrite -notcontains $evidence) {
    Fail "EvidencePath must be declared in runtime launch exclusive_write: $evidence"
  }

  if ($RuntimeExitCode -lt 0 -or $RuntimeExitCode -gt 255) {
    Fail "RuntimeExitCode must be between 0 and 255"
  }

  $allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")

  if ($allowedCompletionStatuses -notcontains $CompletionStatus) {
    Fail "CompletionStatus must be one of: $($allowedCompletionStatuses -join ', ')"
  }

  if ([string]::IsNullOrWhiteSpace($PolicyResult)) {
    Fail "PolicyResult is required"
  }

  $filesWritten = @()

  if ($WrittenFile.Count -le 0) {
    $filesWritten += $evidence
  }
  else {
    foreach ($path in @($WrittenFile)) {
      $filesWritten += Normalize-RepoPath -Path $path -FieldName "WrittenFile"
    }
  }

  $filesWritten = @($filesWritten | Sort-Object -Unique)

  foreach ($path in $filesWritten) {
    if ($exclusiveWrite -notcontains $path) {
      Fail "WrittenFile must be declared in runtime launch exclusive_write: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "WrittenFile must reference an existing file: $path"
    }
  }

  if ($filesWritten -notcontains $evidence) {
    Fail "WrittenFile must include EvidencePath: $evidence"
  }

  $validationResults = Convert-ValidationRecords -Records $Validation
  $runtimeStatus = "succeeded"

  if ($RuntimeExitCode -ne 0) {
    $runtimeStatus = "failed"
  }

  $safeResultId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-result") -FieldName "result_id"

  $result = [ordered]@{
    schema_version = "1"
    result_id = $safeResultId
    generated_by = "specbridge-cli"
    source_runtime_launch_path = $input
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    executor_evidence_path = $evidence
    exit_code = $RuntimeExitCode
    files_written = @($filesWritten)
    validation_results = @($validationResults)
    policy_result = $PolicyResult.Trim()
    stop_conditions = @($launch.stop_conditions)
    completion_status = $CompletionStatus
    runtime_status = $runtimeStatus
    result_status = "recorded"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($input, $evidence)
  }

  Write-Utf8JsonFile -Path $output -Value $result -Depth 10

  Write-CliJson ([ordered]@{
    command = "record-runtime-result"
    ok = $true
    output_path = $output
    source_runtime_launch_path = $input
    executor_evidence_path = $evidence
    runtime_status = $runtimeStatus
    result_status = "recorded"
  })

  exit 0
}

function Get-JsonObjectFromFile {
  param(
    [string] $Path,
    [string] $Description
  )

  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  }
  catch {
    Fail "$Description must contain valid JSON: $Path"
  }
}

function Invoke-RunRuntimeLaunchCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidence = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-runs/.+\.runtime-run\.json$" `
    -Description "a .specbridge/runtime-runs/*.runtime-run.json runtime run"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
    Fail "EvidencePath must reference an existing executor evidence file: $evidence"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $context = "runtime launch $launchPath"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "exclusive_write", "allowed_tools", "permission_mode", "max_budget_usd", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch status must be ready_for_operator_launch: $launchPath"
  }

  $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })

  if ($exclusiveWrite -notcontains $evidence) {
    Fail "EvidencePath must be declared in runtime launch exclusive_write: $evidence"
  }

  if ($RuntimeExitCode -lt 0 -or $RuntimeExitCode -gt 255) {
    Fail "RuntimeExitCode must be between 0 and 255"
  }

  $allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")

  if ($allowedCompletionStatuses -notcontains $CompletionStatus) {
    Fail "CompletionStatus must be one of: $($allowedCompletionStatuses -join ', ')"
  }

  if ([string]::IsNullOrWhiteSpace($PolicyResult)) {
    Fail "PolicyResult is required"
  }

  $filesWritten = @()

  if ($WrittenFile.Count -le 0) {
    $filesWritten += $evidence
  }
  else {
    foreach ($path in @($WrittenFile)) {
      $filesWritten += Normalize-RepoPath -Path $path -FieldName "WrittenFile"
    }
  }

  $filesWritten = @($filesWritten | Sort-Object -Unique)

  foreach ($path in $filesWritten) {
    if ($exclusiveWrite -notcontains $path) {
      Fail "WrittenFile must be declared in runtime launch exclusive_write: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "WrittenFile must reference an existing file: $path"
    }
  }

  if ($filesWritten -notcontains $evidence) {
    Fail "WrittenFile must include EvidencePath: $evidence"
  }

  $validationRecords = @($Validation)

  if ($validationRecords.Count -le 0) {
    $validationRecords = @("runtime launch evidence capture: recorded")
  }

  $validationResults = Convert-ValidationRecords -Records $validationRecords
  $runtimeStatus = "succeeded"

  if ($RuntimeExitCode -ne 0) {
    $runtimeStatus = "failed"
  }

  $safeRunId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-run") -FieldName "run_id"

  $run = [ordered]@{
    schema_version = "1"
    run_id = $safeRunId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    executor_evidence_path = $evidence
    exit_code = $RuntimeExitCode
    files_written = @($filesWritten)
    validation_results = @($validationResults)
    tool_restriction = @($launch.allowed_tools)
    permission_mode = $launch.permission_mode
    max_budget_usd = $launch.max_budget_usd
    policy_result = $PolicyResult.Trim()
    stop_conditions = @($launch.stop_conditions)
    completion_status = $CompletionStatus
    runtime_status = $runtimeStatus
    run_status = "recorded"
    runner_mode = "evidence_capture"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($launchPath, $evidence)
  }

  Write-Utf8JsonFile -Path $output -Value $run -Depth 10

  Write-CliJson ([ordered]@{
    command = "run-runtime-launch"
    ok = $true
    output_path = $output
    runtime_launch_path = $launchPath
    executor_evidence_path = $evidence
    runtime_status = $runtimeStatus
    run_status = "recorded"
  })

  exit 0
}

function Invoke-SummarizeRuntimeCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $resultPath = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-summaries/.+\.runtime-summary\.json$" `
    -Description "a .specbridge/runtime-summaries/*.runtime-summary.json runtime summary"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if ($resultPath -notmatch "^\.specbridge/runtime-results/.+\.runtime-result\.json$") {
    Fail "EvidencePath must be a .specbridge/runtime-results/*.runtime-result.json file: $resultPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
    Fail "EvidencePath does not exist: $resultPath"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $result = Get-JsonObjectFromFile -Path $resultPath -Description "runtime result"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "execution_policy", "source_files")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "runtime launch must include $field"
    }
  }

  foreach ($field in @("source_runtime_launch_path", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "validation_results", "policy_result", "completion_status", "runtime_status", "result_status", "execution_policy", "source_files")) {
    if (-not $result.PSObject.Properties.Name.Contains($field)) {
      Fail "runtime result must include $field"
    }
  }

  if ((Normalize-RepoPath -Path $result.source_runtime_launch_path -FieldName "source_runtime_launch_path") -ne $launchPath) {
    Fail "Runtime result source_runtime_launch_path must match InputPath"
  }

  foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name")) {
    if ($launch.$matchingField -ne $result.$matchingField) {
      Fail "$matchingField must match between runtime launch and runtime result"
    }
  }

  if ($result.validation_results -isnot [System.Array] -or @($result.validation_results).Count -le 0) {
    Fail "runtime result validation_results must be a non-empty array"
  }

  $validationTotal = @($result.validation_results).Count
  $validationPassed = @($result.validation_results | Where-Object { $_.result -eq "passed" }).Count
  $validationFailed = @($result.validation_results | Where-Object { $_.result -eq "failed" }).Count
  $validationOther = $validationTotal - $validationPassed - $validationFailed
  $blockers = @()

  if ($result.runtime_status -ne "succeeded") {
    $blockers += "runtime_status is not succeeded"
  }

  if ($result.result_status -ne "recorded") {
    $blockers += "result_status is not recorded"
  }

  if ($result.completion_status -ne "complete") {
    $blockers += "completion_status is not complete"
  }

  if ($validationFailed -gt 0 -or $validationOther -gt 0) {
    $blockers += "validation_results are not all passed"
  }

  if ([string]::IsNullOrWhiteSpace($result.policy_result)) {
    $blockers += "policy_result is empty"
  }

  $mergeReadiness = "ready_for_policy_gates"

  if ($blockers.Count -gt 0) {
    $mergeReadiness = "blocked"
  }

  $sourceFiles = @()
  $sourceFiles += $launchPath
  $sourceFiles += $resultPath
  $sourceFiles += @($launch.source_files)
  $sourceFiles += @($result.source_files)
  $sourceFiles = @($sourceFiles | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "source_files" } | Sort-Object -Unique)
  $summaryId = Convert-ToSafeName -Value ($result.task_id + "-runtime-summary") -FieldName "summary_id"

  $summary = [ordered]@{
    schema_version = "1"
    summary_id = $summaryId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    runtime_result_path = $resultPath
    launch_id = $result.launch_id
    task_id = $result.task_id
    packet_id = $result.packet_id
    slice_id = $result.slice_id
    branch_name = $result.branch_name
    completion_status = $result.completion_status
    runtime_status = $result.runtime_status
    result_status = $result.result_status
    validation_totals = [ordered]@{
      total = $validationTotal
      passed = $validationPassed
      failed = $validationFailed
      other = $validationOther
    }
    policy_result = $result.policy_result
    merge_readiness = $mergeReadiness
    blockers = @($blockers)
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($sourceFiles)
  }

  Write-Utf8JsonFile -Path $output -Value $summary -Depth 10

  Write-CliJson ([ordered]@{
    command = "summarize-runtime"
    ok = $true
    output_path = $output
    runtime_launch_path = $launchPath
    runtime_result_path = $resultPath
    merge_readiness = $mergeReadiness
    blocker_count = @($blockers).Count
  })

  exit 0
}

function Add-Count {
  param(
    [hashtable] $Table,
    [string] $Key
  )

  $safeKey = $Key

  if ([string]::IsNullOrWhiteSpace($safeKey)) {
    $safeKey = "unknown"
  }

  if (-not $Table.ContainsKey($safeKey)) {
    $Table[$safeKey] = 0
  }

  $Table[$safeKey] = [int] $Table[$safeKey] + 1
}

function Convert-HashtableToOrderedObject {
  param(
    [hashtable] $Table
  )

  $result = [ordered]@{}

  foreach ($key in @($Table.Keys | Sort-Object)) {
    $result[$key] = $Table[$key]
  }

  return $result
}

function Invoke-SummarizeAutonomyMetricsCommand {
  $summaryRoot = ".specbridge/runtime-summaries"
  $resultRoot = ".specbridge/runtime-results"

  if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    $summaryRoot = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  }

  if (-not [string]::IsNullOrWhiteSpace($EvidencePath)) {
    $resultRoot = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  }

  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/metrics/.+\.autonomy-metrics\.json$" `
    -Description "a .specbridge/metrics/*.autonomy-metrics.json autonomy metrics artifact"

  if (-not (Test-Path -LiteralPath $summaryRoot -PathType Container)) {
    Fail "InputPath must reference an existing runtime summaries directory: $summaryRoot"
  }

  if (-not (Test-Path -LiteralPath $resultRoot -PathType Container)) {
    Fail "EvidencePath must reference an existing runtime results directory: $resultRoot"
  }

  $taskFilter = $null

  if (-not [string]::IsNullOrWhiteSpace($TaskId)) {
    $taskFilter = $TaskId.Trim()
  }

  $summaryRecords = @()

  foreach ($file in @(Get-ChildItem -LiteralPath $summaryRoot -Filter "*.runtime-summary.json" -File | Sort-Object Name)) {
    $summaryPath = Normalize-RepoPath -Path (Join-Path $summaryRoot $file.Name) -FieldName "runtime_summary"
    $summary = Get-JsonObjectFromFile -Path $summaryPath -Description "runtime summary"

    if ($null -ne $taskFilter -and $summary.task_id -ne $taskFilter) {
      continue
    }

    $summaryRecords += [ordered]@{
      path = $summaryPath
      value = $summary
    }
  }

  if ($summaryRecords.Count -le 0) {
    if ($null -eq $taskFilter) {
      Fail "No runtime summaries found for autonomy metrics"
    }

    Fail "No runtime summaries found for TaskId: $taskFilter"
  }

  $resultRecords = @()

  foreach ($file in @(Get-ChildItem -LiteralPath $resultRoot -Filter "*.runtime-result.json" -File | Sort-Object Name)) {
    $resultPath = Normalize-RepoPath -Path (Join-Path $resultRoot $file.Name) -FieldName "runtime_result"
    $result = Get-JsonObjectFromFile -Path $resultPath -Description "runtime result"

    if ($null -ne $taskFilter -and $result.task_id -ne $taskFilter) {
      continue
    }

    $resultRecords += [ordered]@{
      path = $resultPath
      value = $result
    }
  }

  $runtimeStatusCounts = @{}
  $resultStatusCounts = @{}
  $completionStatusCounts = @{}
  $mergeReadinessCounts = @{}
  $sliceIds = @{}
  $validationTotal = 0
  $validationPassed = 0
  $validationFailed = 0
  $validationOther = 0
  $readyCount = 0
  $blockedCount = 0

  foreach ($record in $summaryRecords) {
    $summary = $record.value
    Add-Count -Table $runtimeStatusCounts -Key $summary.runtime_status
    Add-Count -Table $resultStatusCounts -Key $summary.result_status
    Add-Count -Table $completionStatusCounts -Key $summary.completion_status
    Add-Count -Table $mergeReadinessCounts -Key $summary.merge_readiness
    $sliceIds[$summary.slice_id] = $true

    if ($summary.merge_readiness -eq "ready_for_policy_gates") {
      $readyCount++
    }

    if ($summary.merge_readiness -eq "blocked") {
      $blockedCount++
    }

    if ($summary.PSObject.Properties.Name.Contains("validation_totals")) {
      $validationTotal += [int] $summary.validation_totals.total
      $validationPassed += [int] $summary.validation_totals.passed
      $validationFailed += [int] $summary.validation_totals.failed
      $validationOther += [int] $summary.validation_totals.other
    }
  }

  $readyRate = [math]::Round(($readyCount / $summaryRecords.Count), 4)
  $metricsIdBase = "all-runtime"

  if ($null -ne $taskFilter) {
    $metricsIdBase = $taskFilter
  }

  $metricsId = Convert-ToSafeName -Value ($metricsIdBase + "-autonomy-metrics") -FieldName "metrics_id"
  $sourceSummaries = @($summaryRecords | ForEach-Object { $_.path })
  $sourceResults = @($resultRecords | ForEach-Object { $_.path })
  $sourceFiles = @($sourceSummaries + $sourceResults | Sort-Object -Unique)

  $metrics = [ordered]@{
    schema_version = "1"
    metrics_id = $metricsId
    generated_by = "specbridge-cli"
    task_filter = $taskFilter
    summary_count = @($summaryRecords).Count
    ready_count = $readyCount
    blocked_count = $blockedCount
    executor_count = @($sliceIds.Keys).Count
    validation_totals = [ordered]@{
      total = $validationTotal
      passed = $validationPassed
      failed = $validationFailed
      other = $validationOther
    }
    runtime_status_counts = Convert-HashtableToOrderedObject -Table $runtimeStatusCounts
    result_status_counts = Convert-HashtableToOrderedObject -Table $resultStatusCounts
    completion_status_counts = Convert-HashtableToOrderedObject -Table $completionStatusCounts
    merge_readiness_counts = Convert-HashtableToOrderedObject -Table $mergeReadinessCounts
    policy_gate_ready_rate = $readyRate
    source_summaries = @($sourceSummaries)
    source_results = @($sourceResults)
    source_files = @($sourceFiles)
  }

  Write-Utf8JsonFile -Path $output -Value $metrics -Depth 10

  Write-CliJson ([ordered]@{
    command = "summarize-autonomy-metrics"
    ok = $true
    output_path = $output
    summary_count = @($summaryRecords).Count
    ready_count = $readyCount
    blocked_count = $blockedCount
    policy_gate_ready_rate = $readyRate
  })

  exit 0
}

function Get-TextSha256 {
  param(
    [AllowNull()]
    [string] $Text
  )

  if ($null -eq $Text) {
    return $null
  }

  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $hashBytes = $sha.ComputeHash($bytes)
  return ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").ToLowerInvariant()
}

function Get-TextLineCount {
  param(
    [AllowNull()]
    [string] $Text
  )

  if ([string]::IsNullOrEmpty($Text)) {
    return 0
  }

  return @($Text -split "\r?\n").Count
}

function Get-RedactedPreview {
  param(
    [AllowNull()]
    [string] $Text,
    [int] $MaxLength = 240
  )

  if ($MaxLength -lt 1) {
    Fail "MaxLength must be greater than zero for redacted previews"
  }

  if ($null -eq $Text) {
    $Text = ""
  }

  $originalLength = $Text.Length
  $redacted = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
  $redacted = [regex]::Replace($redacted, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "?")
  $redacted = [regex]::Replace($redacted, "(?i)(authorization\s*[:=]\s*bearer\s+)[^\s,;]+", '$1[REDACTED]')
  $redacted = [regex]::Replace($redacted, "(?i)((api[_-]?key|token|secret|password)\s*[:=]\s*)['""]?[^'""\s,;}]+", '$1[REDACTED]')
  $redacted = [regex]::Replace($redacted, "sk-[A-Za-z0-9_-]{16,}", "sk-[REDACTED]")
  $redacted = [regex]::Replace($redacted, "gh[pousr]_[A-Za-z0-9_]{16,}", "gh_[REDACTED]")
  $redacted = [regex]::Replace($redacted, "xox[baprs]-[A-Za-z0-9-]{16,}", "xox-[REDACTED]")

  $truncated = $redacted.Length -gt $MaxLength

  if ($truncated) {
    $redacted = $redacted.Substring(0, $MaxLength)
  }

  return [ordered]@{
    text = $redacted
    original_length = $originalLength
    preview_length = $redacted.Length
    max_length = $MaxLength
    truncated = $truncated
  }
}

function New-FailureDiagnostics {
  param(
    [bool] $DryRun,
    [string] $ExecutionStatus,
    [AllowNull()]
    [object] $ExitCode,
    [bool] $TimedOut,
    [AllowNull()]
    [string] $Stdout,
    [AllowNull()]
    [string] $Stderr
  )

  $status = "not_applicable"
  $reason = "execution_succeeded"

  if ($DryRun) {
    $reason = "dry_run"
  }
  elseif ($ExecutionStatus -in @("failed", "timed_out") -or $TimedOut) {
    $status = "recorded"

    if ($TimedOut -or $ExecutionStatus -eq "timed_out") {
      $reason = "timeout"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Stderr)) {
      $reason = "stderr_nonempty"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Stdout)) {
      $reason = "stdout_only_failure"
    }
    else {
      $reason = "process_exit_without_output"
    }
  }

  return [ordered]@{
    status = $status
    reason = $reason
    exit_code = $ExitCode
    timed_out = $TimedOut
    redaction_policy = "bounded_preview_240_chars_with_secret_token_patterns_redacted"
    stdout_preview = Get-RedactedPreview -Text $Stdout -MaxLength 240
    stderr_preview = Get-RedactedPreview -Text $Stderr -MaxLength 240
  }
}

function New-RuntimeExecutionPrompt {
  param(
    [object] $Launch
  )

  $lines = @()
  $lines += "SpecBridge controlled runtime execution."
  $lines += ""
  $lines += "Task ID: $($Launch.task_id)"
  $lines += "Packet ID: $($Launch.packet_id)"
  $lines += "Slice ID: $($Launch.slice_id)"
  $lines += "Goal: $($Launch.goal)"
  $lines += ""
  $lines += "Execution contract: $($Launch.execution_contract_path)"
  $lines += "Final report path: $($Launch.final_report_path)"
  $lines += ""
  $lines += "Exclusive write paths:"
  foreach ($path in @($Launch.exclusive_write)) {
    $lines += "- $path"
  }
  $lines += ""
  $lines += "Read-only context paths:"
  foreach ($path in @($Launch.read_only)) {
    $lines += "- $path"
  }
  $lines += ""
  $lines += "Required prompt sections:"
  foreach ($section in @($Launch.prompt_sections)) {
    $lines += "- $section"
  }
  $lines += ""
  $lines += "Stop conditions:"
  foreach ($condition in @($Launch.stop_conditions)) {
    $lines += "- $condition"
  }
  $lines += ""
  $lines += "Report evidence, not confidence. Stop on any policy or scope conflict."

  return ($lines -join "`n")
}

function Invoke-ExecuteRuntimeLaunchCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-executions/.+\.runtime-execution\.json$" `
    -Description "a .specbridge/runtime-executions/*.runtime-execution.json runtime execution artifact"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if ($TimeoutSeconds -lt 30 -or $TimeoutSeconds -gt 3600) {
    Fail "TimeoutSeconds must be between 30 and 3600"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $context = "runtime launch $launchPath"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "goal", "exclusive_write", "read_only", "allowed_tools", "permission_mode", "max_budget_usd", "prompt_sections", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch status must be ready_for_operator_launch: $launchPath"
  }

  $allowedTools = @($launch.allowed_tools | ForEach-Object { $_.ToString().Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  foreach ($tool in $allowedTools) {
    if (@("Read", "Write", "Edit") -notcontains $tool) {
      Fail "runtime launch contains an unapproved tool for controlled execution: $tool"
    }
  }

  if ($allowedTools -notcontains "Read" -or $allowedTools -notcontains "Write") {
    Fail "runtime launch must include Read and Write tools for controlled execution"
  }

  if (-not $DryRun -and -not $Force) {
    Fail "Live execute-runtime-launch requires -Force; use -DryRun for planning evidence"
  }

  $prompt = New-RuntimeExecutionPrompt -Launch $launch
  $toolCsv = ($allowedTools -join ",")
  $commandParts = @(
    "claude",
    "-p",
    "--no-session-persistence",
    "--max-budget-usd",
    $launch.max_budget_usd,
    "--permission-mode",
    $launch.permission_mode,
    "--tools",
    $toolCsv,
    "--allowedTools",
    $toolCsv,
    "--input-format",
    "text"
  )

  $executionStatus = "dry_run"
  $exitCode = $null
  $timedOut = $false
  $stdoutLength = 0
  $stderrLength = 0
  $stdoutLineCount = 0
  $stderrLineCount = 0
  $stdoutSha256 = $null
  $stderrSha256 = $null
  $stdout = ""
  $stderr = ""

  if (-not $DryRun) {
    $claudeCommand = Get-Command claude -ErrorAction SilentlyContinue

    if ($null -eq $claudeCommand) {
      Fail "Claude Code CLI is not available on PATH"
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "claude"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $arguments = @(
      "-p",
      "--no-session-persistence",
      "--max-budget-usd",
      $launch.max_budget_usd,
      "--permission-mode",
      $launch.permission_mode,
      "--tools",
      $toolCsv,
      "--allowedTools",
      $toolCsv,
      "--input-format",
      "text"
    )

    $psi.Arguments = (($arguments | ForEach-Object { '"' + ($_.ToString().Replace('"', '\"')) + '"' }) -join " ")
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($prompt)
    $process.StandardInput.Close()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
      $timedOut = $true
      $executionStatus = "timed_out"
      $process.Kill()
      $process.WaitForExit()
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $exitCode = $process.ExitCode
    $stdoutLength = $stdout.Length
    $stderrLength = $stderr.Length
    $stdoutLineCount = Get-TextLineCount -Text $stdout
    $stderrLineCount = Get-TextLineCount -Text $stderr
    $stdoutSha256 = Get-TextSha256 -Text $stdout
    $stderrSha256 = Get-TextSha256 -Text $stderr

    if (-not $timedOut) {
      if ($exitCode -eq 0) {
        $executionStatus = "succeeded"
      }
      else {
        $executionStatus = "failed"
      }
    }
  }

  $safeExecutionId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-execution") -FieldName "execution_id"
  $policyResult = "Dry run only. Claude Code was not launched."

  if (-not $DryRun) {
    $policyResult = "Controlled Claude Code launch executed with bounded tools, budget, timeout, and repository-scoped launch plan."
  }

  $execution = [ordered]@{
    schema_version = "1"
    execution_id = $safeExecutionId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    dry_run = [bool] $DryRun
    timeout_seconds = $TimeoutSeconds
    allowed_tools = @($allowedTools)
    permission_mode = $launch.permission_mode
    max_budget_usd = $launch.max_budget_usd
    command_summary = ($commandParts -join " ")
    prompt_sections = @($launch.prompt_sections)
    execution_status = $executionStatus
    exit_code = $exitCode
    timed_out = $timedOut
    stdout = [ordered]@{
      captured = (-not $DryRun)
      length = $stdoutLength
      line_count = $stdoutLineCount
      sha256 = $stdoutSha256
    }
    stderr = [ordered]@{
      captured = (-not $DryRun)
      length = $stderrLength
      line_count = $stderrLineCount
      sha256 = $stderrSha256
    }
    failure_diagnostics = New-FailureDiagnostics `
      -DryRun ([bool] $DryRun) `
      -ExecutionStatus $executionStatus `
      -ExitCode $exitCode `
      -TimedOut $timedOut `
      -Stdout $stdout `
      -Stderr $stderr
    policy_result = $policyResult
    execution_policy = [ordered]@{
      launches_claude = (-not [bool] $DryRun)
      launches_antigravity = $false
      executes_shell = $false
      requires_network = (-not [bool] $DryRun)
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($launchPath)
  }

  Write-Utf8JsonFile -Path $output -Value $execution -Depth 10

  Write-CliJson ([ordered]@{
    command = "execute-runtime-launch"
    ok = ($executionStatus -in @("dry_run", "succeeded"))
    output_path = $output
    runtime_launch_path = $launchPath
    execution_status = $executionStatus
    dry_run = [bool] $DryRun
  })

  if ($executionStatus -notin @("dry_run", "succeeded")) {
    exit 1
  }

  exit 0
}

function Get-ExecutorPacketFiles {
  param(
    [string] $Path
  )

  $normalizedInput = Normalize-RepoPath -Path $Path -FieldName "InputPath"

  if (-not (Test-Path -LiteralPath $normalizedInput)) {
    Fail "InputPath does not exist: $normalizedInput"
  }

  $item = Get-Item -LiteralPath $normalizedInput

  if ($item.PSIsContainer) {
    if ($normalizedInput -notmatch "^\.specbridge/executor-packets(/.*)?$") {
      Fail "InputPath directory must be under .specbridge/executor-packets: $normalizedInput"
    }

    $files = @(
      Get-ChildItem -LiteralPath $normalizedInput -Filter "*.executor-packet.json" -File |
        Sort-Object Name
    )

    if ($files.Count -le 0) {
      Fail "InputPath directory contains no executor packets: $normalizedInput"
    }

    return @(
      $files |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path $normalizedInput $_.Name) -FieldName "executor_packet" }
    )
  }

  if ($normalizedInput -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$") {
    Fail "InputPath file must be a .specbridge/executor-packets/*.executor-packet.json file: $normalizedInput"
  }

  return @($normalizedInput)
}

function Invoke-PlanExecutorBranchesCommand {
  $packetPaths = Get-ExecutorPacketFiles -Path $InputPath
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/branch-plans/.+\.branch-plan\.json$" `
    -Description "a .specbridge/branch-plans/*.branch-plan.json branch plan"

  $packets = @()
  $packetIds = @{}
  $branchNames = @{}
  $packetTaskIdentifier = ""

  foreach ($packetPath in $packetPaths) {
    $packet = Get-JsonObjectFromFile -Path $packetPath -Description "executor packet"
    $context = "executor packet $packetPath"

    foreach ($field in @("packet_id", "task_id", "slice_id", "agent_role", "goal", "branch_name", "execution_contract_path", "final_report_path", "exclusive_write", "required_validations")) {
      if (-not $packet.PSObject.Properties.Name.Contains($field)) {
        Fail "$context must include $field"
      }
    }

    if ([string]::IsNullOrWhiteSpace($packetTaskIdentifier)) {
      $packetTaskIdentifier = $packet.task_id
    }
    elseif ($packetTaskIdentifier -ne $packet.task_id) {
      Fail "All executor packets in a branch plan must share one task_id"
    }

    if ($packetIds.ContainsKey($packet.packet_id)) {
      Fail "Duplicate packet_id in branch plan input: $($packet.packet_id)"
    }

    if ($branchNames.ContainsKey($packet.branch_name)) {
      Fail "Duplicate branch_name in branch plan input: $($packet.branch_name)"
    }

    $packetIds[$packet.packet_id] = $packetPath
    $branchNames[$packet.branch_name] = $packetPath

    $packets += [pscustomobject]@{
      Path = $packetPath
      Packet = $packet
    }
  }

  $executorBranches = @()
  $sourceTaskId = $packetTaskIdentifier
  $planTaskId = $sourceTaskId

  if (-not [string]::IsNullOrWhiteSpace($TaskId)) {
    $planTaskId = $TaskId.Trim()
  }

  foreach ($entry in @($packets | Sort-Object { $_.Packet.packet_id })) {
    $packet = $entry.Packet
    $rollbackNotes = @(
      "Close the executor PR if it exists.",
      "Delete or abandon branch $($packet.branch_name) after coordinator review.",
      "Re-run the coordinator plan before retrying this packet."
    )

    $executorBranches += [ordered]@{
      packet_id = $packet.packet_id
      slice_id = $packet.slice_id
      agent_role = $packet.agent_role
      branch_name = $packet.branch_name
      base_branch = $BaseBranch
      execution_contract_path = $packet.execution_contract_path
      final_report_path = $packet.final_report_path
      exclusive_write = @($packet.exclusive_write)
      required_validations = @($packet.required_validations)
      pr_title = "Executor $($packet.slice_id): $($packet.goal)"
      pr_url = $null
      pr_status = "not_created"
      ci_status = "not_collected"
      chatgpt_audit_status = "not_collected"
      merge_status = "not_ready"
      rollback_notes = @($rollbackNotes)
    }
  }

  $branchPlan = [ordered]@{
    schema_version = "1"
    plan_id = $planTaskId
    task_id = $planTaskId
    source_task_id = $sourceTaskId
    generated_by = "specbridge-cli"
    repository_url = $RepositoryUrl
    base_branch = $BaseBranch
    source_packet_count = @($executorBranches).Count
    executor_branches = @($executorBranches)
    coordinator_gates = [ordered]@{
      one_branch_per_packet = $true
      one_pr_per_branch_required = $true
      ci_status_required = "passed"
      chatgpt_audit_required = "approved"
      integration_waits_for_all_children = $true
      simulation_cannot_authorize_merge = $true
    }
    status = "planned"
    source_files = @($packetPaths)
  }

  Write-Utf8JsonFile -Path $output -Value $branchPlan -Depth 10

  Write-CliJson ([ordered]@{
    command = "plan-executor-branches"
    ok = $true
    output_path = $output
    branch_count = @($executorBranches).Count
  })

  exit 0
}

function Invoke-RecordGithubEvidenceCommand {
  $branchPlanPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidencePath = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/branch-plans/.+\.branch-plan\.json$" `
    -Description "a .specbridge/branch-plans/*.branch-plan.json branch plan"

  if ($branchPlanPath -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$") {
    Fail "InputPath must be a .specbridge/branch-plans/*.branch-plan.json file: $branchPlanPath"
  }

  if ($evidencePath -notmatch "^\.specbridge/github-evidence/.+\.json$") {
    Fail "EvidencePath must be under .specbridge/github-evidence and end with .json: $evidencePath"
  }

  if (-not (Test-Path -LiteralPath $branchPlanPath)) {
    Fail "InputPath does not exist: $branchPlanPath"
  }

  if (-not (Test-Path -LiteralPath $evidencePath)) {
    Fail "EvidencePath does not exist: $evidencePath"
  }

  $branchPlan = Get-JsonObjectFromFile -Path $branchPlanPath -Description "branch plan"
  $evidence = Get-JsonObjectFromFile -Path $evidencePath -Description "GitHub evidence"

  foreach ($field in @("task_id", "executor_branches", "source_files")) {
    if (-not $branchPlan.PSObject.Properties.Name.Contains($field)) {
      Fail "branch plan must include $field"
    }
  }

  foreach ($field in @("task_id", "child_prs")) {
    if (-not $evidence.PSObject.Properties.Name.Contains($field)) {
      Fail "GitHub evidence must include $field"
    }
  }

  if (-not ($evidence.child_prs -is [System.Array]) -or @($evidence.child_prs).Count -le 0) {
    Fail "GitHub evidence child_prs must be a non-empty array"
  }

  $evidenceByPacketId = @{}

  foreach ($child in @($evidence.child_prs)) {
    foreach ($field in @("packet_id", "branch_name", "pr_url", "pr_status", "ci_status", "chatgpt_audit_status")) {
      if (-not $child.PSObject.Properties.Name.Contains($field)) {
        Fail "GitHub evidence child_prs entries must include $field"
      }

      $value = $child.$field

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Fail "GitHub evidence child_prs.$field must be a non-empty string"
      }
    }

    if ($child.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
      Fail "GitHub evidence pr_url must use a GitHub pull request URL: $($child.pr_url)"
    }

    if ($evidenceByPacketId.ContainsKey($child.packet_id)) {
      Fail "Duplicate packet_id in GitHub evidence: $($child.packet_id)"
    }

    $evidenceByPacketId[$child.packet_id] = $child
  }

  $updatedBranches = @()

  foreach ($executor in @($branchPlan.executor_branches | Sort-Object packet_id)) {
    if (-not $evidenceByPacketId.ContainsKey($executor.packet_id)) {
      Fail "Missing GitHub evidence for packet_id: $($executor.packet_id)"
    }

    $child = $evidenceByPacketId[$executor.packet_id]

    if ($child.branch_name -ne $executor.branch_name) {
      Fail "GitHub evidence branch_name mismatch for packet_id $($executor.packet_id): expected=$($executor.branch_name) actual=$($child.branch_name)"
    }

    $mergeStatus = "not_ready"

    if ($child.ci_status -eq "passed" -and $child.chatgpt_audit_status -eq "approved") {
      $mergeStatus = "ready_for_integration"
    }
    elseif ($child.ci_status -eq "failed" -or $child.chatgpt_audit_status -in @("changes_requested", "blocked")) {
      $mergeStatus = "blocked"
    }

    $updatedBranches += [ordered]@{
      packet_id = $executor.packet_id
      slice_id = $executor.slice_id
      agent_role = $executor.agent_role
      branch_name = $executor.branch_name
      base_branch = $executor.base_branch
      execution_contract_path = $executor.execution_contract_path
      final_report_path = $executor.final_report_path
      exclusive_write = @($executor.exclusive_write)
      required_validations = @($executor.required_validations)
      pr_title = $executor.pr_title
      pr_url = $child.pr_url
      pr_status = $child.pr_status
      ci_status = $child.ci_status
      chatgpt_audit_status = $child.chatgpt_audit_status
      merge_status = $mergeStatus
      rollback_notes = @($executor.rollback_notes)
    }
  }

  $sourceFiles = @($branchPlan.source_files)
  $sourceFiles += $branchPlanPath
  $sourceFiles += $evidencePath

  $updatedPlan = [ordered]@{
    schema_version = $branchPlan.schema_version
    plan_id = $evidence.task_id
    task_id = $evidence.task_id
    source_task_id = $branchPlan.source_task_id
    generated_by = "specbridge-cli"
    repository_url = $branchPlan.repository_url
    base_branch = $branchPlan.base_branch
    source_packet_count = @($updatedBranches).Count
    executor_branches = @($updatedBranches)
    coordinator_gates = $branchPlan.coordinator_gates
    status = "evidence_recorded"
    source_files = @($sourceFiles | Sort-Object -Unique)
  }

  Write-Utf8JsonFile -Path $output -Value $updatedPlan -Depth 10

  Write-CliJson ([ordered]@{
    command = "record-github-evidence"
    ok = $true
    output_path = $output
    evidence_path = $evidencePath
    child_count = @($updatedBranches).Count
  })

  exit 0
}

function Invoke-CoordinateExecutorsCommand {
  $branchPlanPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"

  if ($branchPlanPath -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$") {
    Fail "InputPath must be a .specbridge/branch-plans/*.branch-plan.json file: $branchPlanPath"
  }

  if (-not (Test-Path -LiteralPath $branchPlanPath)) {
    Fail "InputPath does not exist: $branchPlanPath"
  }

  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/orchestrations/.+\.executor-orchestration\.json$" `
    -Description "a .specbridge/orchestrations/*.executor-orchestration.json orchestration"

  $branchPlan = Get-JsonObjectFromFile -Path $branchPlanPath -Description "branch plan"

  foreach ($field in @("task_id", "repository_url", "base_branch", "executor_branches")) {
    if (-not $branchPlan.PSObject.Properties.Name.Contains($field)) {
      Fail "branch plan must include $field"
    }
  }

  $children = @()
  $allGithubEvidencePassed = $true

  foreach ($executor in @($branchPlan.executor_branches | Sort-Object packet_id)) {
    foreach ($field in @("packet_id", "slice_id", "agent_role", "branch_name", "pr_url", "ci_status", "chatgpt_audit_status", "rollback_notes")) {
      if (-not $executor.PSObject.Properties.Name.Contains($field)) {
        Fail "executor branch entry must include $field"
      }
    }

    if ($EvidenceMode -eq "simulation") {
      $children += [ordered]@{
        packet_id = $executor.packet_id
        slice_id = $executor.slice_id
        agent_role = $executor.agent_role
        branch_name = $executor.branch_name
        pr_url = "simulation://pull-requests/$($executor.packet_id)"
        pr_status = "simulated_open"
        ci_status = "simulated_passed"
        chatgpt_audit_status = "simulated_approved"
        merge_allowed = $false
        merge_blocker = "Simulation evidence cannot authorize merge."
        rollback_notes = @($executor.rollback_notes)
      }

      continue
    }

    if ($null -eq $executor.pr_url -or $executor.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
      $allGithubEvidencePassed = $false
    }

    if ($executor.ci_status -ne "passed" -or $executor.chatgpt_audit_status -ne "approved") {
      $allGithubEvidencePassed = $false
    }

    $children += [ordered]@{
      packet_id = $executor.packet_id
      slice_id = $executor.slice_id
      agent_role = $executor.agent_role
      branch_name = $executor.branch_name
      pr_url = $executor.pr_url
      pr_status = $executor.pr_status
      ci_status = $executor.ci_status
      chatgpt_audit_status = $executor.chatgpt_audit_status
      merge_allowed = ($executor.ci_status -eq "passed" -and $executor.chatgpt_audit_status -eq "approved")
      merge_blocker = ""
      rollback_notes = @($executor.rollback_notes)
    }
  }

  $integrationDecision = "simulation_only_no_merge"
  $coordinatorStatus = "simulated"
  $requiredNextEvidence = @(
    "Create real executor branches from the branch plan.",
    "Open one GitHub PR per executor branch.",
    "Collect real CI status for every child PR.",
    "Collect a ChatGPT/Codex audit for every child PR.",
    "Regenerate coordination in github evidence mode before integration merge."
  )

  if ($EvidenceMode -eq "github") {
    if ($allGithubEvidencePassed) {
      $integrationDecision = "ready_for_integration"
      $coordinatorStatus = "ready_for_integration"
      $requiredNextEvidence = @()
    }
    else {
      $integrationDecision = "blocked"
      $coordinatorStatus = "blocked"
      $requiredNextEvidence = @(
        "Every executor branch must have a GitHub pull request URL.",
        "Every executor PR must have CI status passed.",
        "Every executor PR must have ChatGPT/Codex audit status approved."
      )
    }
  }

  $orchestration = [ordered]@{
    schema_version = "1"
    orchestration_id = $branchPlan.task_id
    task_id = $branchPlan.task_id
    generated_by = "specbridge-cli"
    evidence_mode = $EvidenceMode
    branch_plan_path = $branchPlanPath
    repository_url = $branchPlan.repository_url
    base_branch = $branchPlan.base_branch
    child_results = @($children)
    integration_decision = $integrationDecision
    coordinator_status = $coordinatorStatus
    required_next_evidence = @($requiredNextEvidence)
    source_files = @($branchPlanPath)
  }

  Write-Utf8JsonFile -Path $output -Value $orchestration -Depth 10

  Write-CliJson ([ordered]@{
    command = "coordinate-executors"
    ok = $true
    evidence_mode = $EvidenceMode
    output_path = $output
    child_count = @($children).Count
    integration_decision = $integrationDecision
  })

  exit 0
}

function Invoke-ReviewGateCommand {
  $security = Invoke-ScriptGate -ScriptPath "./scripts/validate-security-gates.ps1"
  $review = $null

  if ($security.exit_code -eq 0) {
    $review = Invoke-ScriptGate -ScriptPath "./scripts/validate-review-gate.ps1"
  }

  $failed = ($security.exit_code -ne 0 -or ($null -ne $review -and $review.exit_code -ne 0))
  $results = @($security)

  if ($null -ne $review) {
    $results += $review
  }

  Write-CliJson ([ordered]@{
    command = "review-gate"
    ok = (-not $failed)
    results = $results
  })

  if ($failed) {
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

switch ($Command) {
  "status" { Invoke-StatusCommand }
  "validate" { Invoke-ValidateCommand }
  "create-contract" { Invoke-CreateContractCommand }
  "create-report" { Invoke-CreateReportCommand }
  "audit-packet" { Invoke-AuditPacketCommand }
  "detect-conflicts" { Invoke-DetectConflictsCommand }
  "decompose-task" { Invoke-DecomposeTaskCommand }
  "prepare-executors" { Invoke-PrepareExecutorsCommand }
  "prepare-runtime-launch" { Invoke-PrepareRuntimeLaunchCommand }
  "execute-runtime-launch" { Invoke-ExecuteRuntimeLaunchCommand }
  "run-runtime-launch" { Invoke-RunRuntimeLaunchCommand }
  "record-runtime-result" { Invoke-RecordRuntimeResultCommand }
  "summarize-runtime" { Invoke-SummarizeRuntimeCommand }
  "summarize-autonomy-metrics" { Invoke-SummarizeAutonomyMetricsCommand }
  "standard-loop-status" { Invoke-StandardLoopStatusCommand }
  "v5-pilot-status" { Invoke-V5PilotStatusCommand }
  "v5-live-status" { Invoke-V5LiveStatusCommand }
  "v5-autonomy-status" { Invoke-V5AutonomyStatusCommand }
  "runtime-capability-status" { Invoke-RuntimeCapabilityStatusCommand }
  "plan-executor-branches" { Invoke-PlanExecutorBranchesCommand }
  "record-github-evidence" { Invoke-RecordGithubEvidenceCommand }
  "coordinate-executors" { Invoke-CoordinateExecutorsCommand }
  "review-gate" { Invoke-ReviewGateCommand }
  default { Fail "Unsupported command: $Command" }
}
