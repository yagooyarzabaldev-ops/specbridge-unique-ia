param(
  [Parameter(Position = 0)]
  [ValidateSet("status", "validate", "create-contract", "create-report", "audit-packet", "detect-conflicts", "decompose-task", "prepare-executors", "plan-executor-branches", "coordinate-executors", "review-gate")]
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
  [string] $CiStatus = "not_collected",
  [string] $Summary = "",
  [string[]] $ChangedFile = @(),
  [string[]] $Validation = @(),
  [string] $PolicyResult = "",
  [string] $RiskResult = "",
  [string] $CompletionStatus = "draft",
  [string] $Profile = "standard",
  [string] $BranchPrefix = "claude",
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
  "plan-executor-branches" { Invoke-PlanExecutorBranchesCommand }
  "coordinate-executors" { Invoke-CoordinateExecutorsCommand }
  "review-gate" { Invoke-ReviewGateCommand }
  default { Fail "Unsupported command: $Command" }
}
