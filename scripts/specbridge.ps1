param(
  [Parameter(Position = 0)]
  [ValidateSet("status", "validate", "create-contract", "create-report", "audit-packet", "detect-conflicts", "decompose-task", "review-gate")]
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
  "review-gate" { Invoke-ReviewGateCommand }
  default { Fail "Unsupported command: $Command" }
}
