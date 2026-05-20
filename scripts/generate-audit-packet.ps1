param(
  [Parameter(Mandatory = $true)]
  [string] $TaskId,

  [Parameter(Mandatory = $true)]
  [string] $ExecutionContractPath,

  [Parameter(Mandatory = $true)]
  [string] $FinalReportPath,

  [string] $PrReviewReportPath = "",
  [string] $CiStatus = "not_collected",
  [string] $OutputDirectory = ".specbridge/audit-packets",
  [string] $OutputFileName = "",
  [string] $BaseRef = "",
  [string] $HeadRef = "HEAD"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge audit packet generation started."

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Fail {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  exit 1
}

function Normalize-RepoPath {
  param(
    [string] $Path,
    [string] $FieldName
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    Fail "$FieldName must be a non-empty repository-relative path"
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

function Read-JsonFile {
  param(
    [string] $Path,
    [string] $Description
  )

  if (-not (Test-Path $Path)) {
    Fail "missing $Description`: $Path"
  }

  try {
    return (Get-Content $Path -Raw | ConvertFrom-Json)
  }
  catch {
    Fail "invalid JSON in $Description`: $Path error=$($_.Exception.Message)"
  }
}

function Get-StringArray {
  param(
    [object] $Value,
    [string] $FieldName
  )

  if ($null -eq $Value) {
    return @()
  }

  $items = @($Value)
  $results = @()

  foreach ($item in $items) {
    if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
      Fail "$FieldName must contain only non-empty strings"
    }

    $results += $item.Trim()
  }

  return @($results)
}

function Get-GitNumstat {
  param(
    [string] $BaseRef,
    [string] $HeadRef
  )

  $lines = @()
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  try {
    if (-not [string]::IsNullOrWhiteSpace($BaseRef)) {
      $lines = git diff --numstat $BaseRef $HeadRef 2>$null
    }

    if (-not $lines -or $lines.Count -eq 0) {
      $lines = git diff --numstat 2>$null
    }

    if (-not $lines -or $lines.Count -eq 0) {
      $lines = git diff --numstat --cached 2>$null
    }

    if (-not $lines -or $lines.Count -eq 0) {
      $lines = git diff --numstat HEAD~1..HEAD 2>$null
    }
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  $stats = @{}

  foreach ($line in @($lines)) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }

    $parts = $line -split "`t"

    if ($parts.Count -lt 3) {
      continue
    }

    $added = $null
    $deleted = $null

    if ($parts[0] -match "^[0-9]+$") {
      $added = [int] $parts[0]
    }

    if ($parts[1] -match "^[0-9]+$") {
      $deleted = [int] $parts[1]
    }

    $path = Normalize-RepoPath -Path $parts[2] -FieldName "diff_summary.file"
    $stats[$path] = [ordered]@{
      file = $path
      added_lines = $added
      deleted_lines = $deleted
    }
  }

  return $stats
}

function Split-ValidationRecord {
  param(
    [string] $Record
  )

  $trimmed = $Record.Trim()
  $separatorIndex = $trimmed.LastIndexOf(": ")

  if ($separatorIndex -gt 0) {
    return [ordered]@{
      command = $trimmed.Substring(0, $separatorIndex).Trim()
      result = $trimmed.Substring($separatorIndex + 2).Trim()
    }
  }

  return [ordered]@{
    command = $trimmed
    result = "recorded"
  }
}

if ([string]::IsNullOrWhiteSpace($TaskId)) {
  Fail "TaskId must not be empty"
}

$contractPath = Normalize-RepoPath -Path $ExecutionContractPath -FieldName "ExecutionContractPath"
$reportPath = Normalize-RepoPath -Path $FinalReportPath -FieldName "FinalReportPath"
$outputDir = Normalize-RepoPath -Path $OutputDirectory -FieldName "OutputDirectory"

if ($contractPath -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
  Fail "ExecutionContractPath must be under .specbridge/contracts and end with .execution.md: $contractPath"
}

if ($reportPath -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
  Fail "FinalReportPath must be under .specbridge/reports and end with .final-report.json: $reportPath"
}

if (-not (Test-Path $contractPath)) {
  Fail "missing execution contract: $contractPath"
}

$finalReport = Read-JsonFile -Path $reportPath -Description "final report"

$reviewReportPath = $null

if (-not [string]::IsNullOrWhiteSpace($PrReviewReportPath)) {
  $reviewReportPath = Normalize-RepoPath -Path $PrReviewReportPath -FieldName "PrReviewReportPath"

  if ($reviewReportPath -notmatch "^\.specbridge/review-reports/.+\.review-report\.json$") {
    Fail "PrReviewReportPath must be under .specbridge/review-reports and end with .review-report.json: $reviewReportPath"
  }

  if (-not (Test-Path $reviewReportPath)) {
    Fail "missing PR review report: $reviewReportPath"
  }
}

$changedFiles = Get-StringArray -Value $finalReport.changed_files -FieldName "final_report.changed_files" |
  ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "changed_files" } |
  Sort-Object -Unique

if ($changedFiles.Count -le 0) {
  Fail "final report must provide at least one changed file for audit packet generation"
}

$validationRecords = Get-StringArray -Value $finalReport.validations -FieldName "final_report.validations"

if ($validationRecords.Count -le 0) {
  Fail "final report must provide at least one validation record"
}

$validationResults = @($validationRecords | ForEach-Object { Split-ValidationRecord -Record $_ })
$validationCommands = @($validationResults | ForEach-Object { $_.command } | Sort-Object -Unique)
$gitStats = Get-GitNumstat -BaseRef $BaseRef -HeadRef $HeadRef
$diffSummary = @()

foreach ($changedFile in $changedFiles) {
  if ($gitStats.ContainsKey($changedFile)) {
    $diffSummary += $gitStats[$changedFile]
    continue
  }

  if (Test-Path $changedFile) {
    $lineCount = @((Get-Content $changedFile -ErrorAction SilentlyContinue)).Count
    $diffSummary += [ordered]@{
      file = $changedFile
      added_lines = $lineCount
      deleted_lines = 0
    }
    continue
  }

  $diffSummary += [ordered]@{
    file = $changedFile
    added_lines = $null
    deleted_lines = $null
  }
}

$sourceFiles = @(
  $contractPath,
  $reportPath
)

if ($reviewReportPath) {
  $sourceFiles += $reviewReportPath
}

$unresolvedRisks = Get-StringArray -Value $finalReport.unresolved_risks -FieldName "final_report.unresolved_risks"

$packet = [ordered]@{
  schema_version = "1"
  task_id = $TaskId.Trim()
  generated_by = "specbridge-audit-packet-generator"
  execution_contract_path = $contractPath
  changed_files = @($changedFiles)
  diff_summary = @($diffSummary)
  validation_commands = @($validationCommands)
  validation_results = @($validationResults)
  final_report_path = $reportPath
  ci_status = $CiStatus.Trim()
  pr_review_report_path = $reviewReportPath
  policy_result = $finalReport.policy_result
  unresolved_risks = @($unresolvedRisks)
  completion_status = $finalReport.completion_status
  source_files = @($sourceFiles | Sort-Object -Unique)
  secret_omission = "This packet contains repository-relative paths, line-count summaries, validation summaries, policy result, risks, and status only. It does not embed raw diffs, file contents, secrets, tokens, private keys, or credential values."
}

if ([string]::IsNullOrWhiteSpace($packet.ci_status)) {
  Fail "CiStatus must not be empty"
}

foreach ($requiredStringField in @("policy_result", "completion_status")) {
  if ($null -eq $packet[$requiredStringField] -or $packet[$requiredStringField].GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($packet[$requiredStringField])) {
    Fail "final report must provide a non-empty $requiredStringField"
  }
}

if ([string]::IsNullOrWhiteSpace($OutputFileName)) {
  $OutputFileName = "$($packet.task_id).audit-packet.json"
}

if ($OutputFileName -notmatch "^[A-Za-z0-9._-]+\.audit-packet\.json$") {
  Fail "OutputFileName must end with .audit-packet.json and contain only safe filename characters: $OutputFileName"
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$outputPath = Join-Path $outputDir $OutputFileName
$packet | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

Write-Output "Generated audit packet: $outputPath"
Write-Output "SpecBridge audit packet generation passed."
exit 0
