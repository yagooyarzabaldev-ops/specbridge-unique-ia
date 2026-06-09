# SpecBridge CLI library: common
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

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

function Write-LedgerEntry {
  param(
    [string] $TaskId,
    [string] $Operation,
    [string] $Status,
    [string] $Detail = "",
    [string] $RunId  = ""
  )
  $ledgerDir = Join-Path $repoRoot ".specbridge/ledger"
  if (-not (Test-Path $ledgerDir)) { New-Item -ItemType Directory -Force -Path $ledgerDir | Out-Null }
  $entryObj = [ordered]@{
    task_id   = $TaskId
    operation = $Operation
    status    = $Status
    detail    = $Detail
    timestamp = (Get-Date -Format "o")
  }
  if (-not [string]::IsNullOrWhiteSpace($RunId)) { $entryObj["run_id"] = $RunId }
  $entry = $entryObj | ConvertTo-Json -Compress
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $ledgerPath = Join-Path $ledgerDir "operations.ndjson"
  $sw = New-Object System.IO.StreamWriter($ledgerPath, $true, $utf8NoBom)
  try { $sw.WriteLine($entry) } finally { $sw.Close() }
}

function Write-LockFile {
  param([string] $TaskId, [string] $Branch)
  $lockDir = Join-Path $repoRoot ".specbridge/locks"
  if (-not (Test-Path $lockDir)) { New-Item -ItemType Directory -Force -Path $lockDir | Out-Null }
  $lock = [ordered]@{
    task_id     = $TaskId
    branch      = $Branch
    started_at  = (Get-Date -Format "o")
    owner       = "specbridge"
  } | ConvertTo-Json
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Join-Path $lockDir "$TaskId.lock.json"), $lock, $utf8NoBom)
}

function Remove-LockFile {
  param([string] $TaskId)
  $lockPath = Join-Path $repoRoot ".specbridge/locks/$TaskId.lock.json"
  if (Test-Path $lockPath) { Remove-Item $lockPath -Force }
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
    "./scripts/validate-runtime-preflights.ps1",
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
      $execution = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
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

function Get-MarkdownSectionText {
  param(
    [string] $Path,
    [string] $Heading
  )

  $normalizedPath = Normalize-RepoPath -Path $Path -FieldName "MarkdownPath"

  if (-not (Test-Path -LiteralPath $normalizedPath -PathType Leaf)) {
    return ""
  }

  $target = "## $Heading"
  $capturing = $false
  $lines = @()

  foreach ($line in (Get-Content -LiteralPath $normalizedPath -Encoding UTF8)) {
    if ($line.Trim() -eq $target) {
      $capturing = $true
      continue
    }

    if ($capturing -and $line -match "^##\s+") {
      break
    }

    if ($capturing) {
      $lines += $line
    }
  }

  return (($lines -join "`n").Trim())
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

function Get-JsonObjectFromFile {
  param(
    [string] $Path,
    [string] $Description
  )

  try {
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  }
  catch {
    Fail "$Description must contain valid JSON: $Path"
  }
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
  # Keep diagnostic previews ASCII-stable so validators and shells agree on length.
  $redacted = [regex]::Replace($redacted, "[^\x09\x0A\x20-\x7E]", "?")

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

