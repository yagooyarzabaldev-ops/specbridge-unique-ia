param(
  [Parameter(Position = 0)]
  [ValidateSet("status", "validate", "create-contract", "create-report", "audit-packet", "detect-conflicts", "decompose-task", "prepare-executors", "prepare-runtime-launch", "run-runtime-launch", "record-runtime-result", "summarize-runtime", "summarize-autonomy-metrics", "plan-executor-branches", "record-github-evidence", "coordinate-executors", "review-gate")]
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
  [string[]] $WrittenFile = @(),
  [ValidateSet("simulation", "github")]
  [string] $EvidenceMode = "simulation",
  [string] $RepositoryUrl = "https://github.com/yagooyarzabaldev-ops/specbridge",
  [string] $BaseBranch = "main",
  [switch] $IncludeLatestArtifacts,
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
  "run-runtime-launch" { Invoke-RunRuntimeLaunchCommand }
  "record-runtime-result" { Invoke-RecordRuntimeResultCommand }
  "summarize-runtime" { Invoke-SummarizeRuntimeCommand }
  "summarize-autonomy-metrics" { Invoke-SummarizeAutonomyMetricsCommand }
  "plan-executor-branches" { Invoke-PlanExecutorBranchesCommand }
  "record-github-evidence" { Invoke-RecordGithubEvidenceCommand }
  "coordinate-executors" { Invoke-CoordinateExecutorsCommand }
  "review-gate" { Invoke-ReviewGateCommand }
  default { Fail "Unsupported command: $Command" }
}
