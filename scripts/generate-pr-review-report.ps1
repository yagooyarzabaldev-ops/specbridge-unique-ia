param(
  [string] $OutputDirectory = ".specbridge/generated-review-reports",
  [string] $OutputFileName = "generated-pr-review.review-report.json"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge deterministic PR review report generation started."

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Get-ChangedFiles {
  $changedFiles = @()

  if ($env:GITHUB_BASE_REF) {
    git fetch origin $env:GITHUB_BASE_REF --depth=1 | Out-Null
    $baseRef = "origin/$($env:GITHUB_BASE_REF)"
    $changedFiles = git diff --name-only "$baseRef...HEAD"
  }

  if (-not $changedFiles -or $changedFiles.Count -eq 0) {
    $changedFiles = git diff --name-only "HEAD~1..HEAD" 2>$null
  }

  if (-not $changedFiles -or $changedFiles.Count -eq 0) {
    $changedFiles = git diff --name-only --cached
  }

  return @($changedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$changedFiles = Get-ChangedFiles

$findings = @()

if ($changedFiles.Count -eq 0) {
  $findings += [ordered]@{
    severity = "info"
    category = "change_detection"
    file = "repository"
    line = $null
    evidence = "No changed files were detected by the deterministic generator."
    recommendation = "Verify that the workflow has enough git history when this runs on pull requests."
    blocking = $false
  }
} else {
  foreach ($changedFile in $changedFiles) {
    $normalizedPath = $changedFile.Replace("\", "/")
    $findings += [ordered]@{
      severity = "info"
      category = "changed_file"
      file = $normalizedPath
      line = $null
      evidence = "Changed file detected by deterministic PR review report generator."
      recommendation = "Review this file according to the execution contract and active validation gates."
      blocking = $false
    }
  }
}

$report = [ordered]@{
  schema_version = "1"
  reviewer = "specbridge-deterministic-review-generator"
  summary = "Deterministic PR review report generated without live Claude, Codex, MCP, secrets, deployment automation, or runtime application execution."
  findings = $findings
  result = "pass"
}

$outputPath = Join-Path $OutputDirectory $OutputFileName
$report | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

Write-Output "Generated PR review report: $outputPath"
Write-Output "SpecBridge deterministic PR review report generation passed."
exit 0
