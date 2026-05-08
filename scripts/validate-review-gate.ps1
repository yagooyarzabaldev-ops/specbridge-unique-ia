$ErrorActionPreference = "Stop"

Write-Output "SpecBridge PR review gate started."

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$blockedPathPatterns = @(
  "^\.env$",
  "^\.env\.",
  "^secrets/",
  "^infra/prod/",
  "^src/",
  "^app/",
  "^pages/",
  "^packages/",
  "^apps/",
  "^lib/",
  "^server/",
  "^database/",
  "^migrations/"
)

$blockedWorkflowActivationPatterns = @(
  "claude-code-execute",
  "codex-review",
  "claude-code-review.example",
  "claude-code-execute.example",
  "codex-review.example"
)

function Get-ChangedFiles {
  $candidates = @()

  if ($env:GITHUB_BASE_REF) {
    $baseRef = "origin/$($env:GITHUB_BASE_REF)"
    git fetch origin $env:GITHUB_BASE_REF --depth=1 | Out-Null
    $candidates = git diff --name-only "$baseRef...HEAD"
  }

  if (-not $candidates -or $candidates.Count -eq 0) {
    $candidates = git diff --name-only "HEAD~1..HEAD" 2>$null
  }

  if (-not $candidates -or $candidates.Count -eq 0) {
    $candidates = git diff --name-only --cached
  }

  return @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$changedFiles = Get-ChangedFiles
$failed = $false

if ($changedFiles.Count -eq 0) {
  Write-Output "No changed files detected. Review gate passes."
  exit 0
}

Write-Output "Changed files:"
foreach ($changedFile in $changedFiles) {
  Write-Output "- $changedFile"
}

foreach ($changedFile in $changedFiles) {
  $normalizedPath = $changedFile.Replace("\", "/")

  foreach ($pattern in $blockedPathPatterns) {
    if ($normalizedPath -match $pattern) {
      Write-Output "FAIL blocked path changed: $normalizedPath"
      $failed = $true
    }
  }

  if ($normalizedPath -match "^\.github/workflows/.+\.ya?ml$") {
    $workflowContent = Get-Content $normalizedPath -Raw

    foreach ($pattern in $blockedWorkflowActivationPatterns) {
      if ($workflowContent -match $pattern) {
        Write-Output "FAIL blocked workflow activation pattern in $($normalizedPath): $pattern"
        $failed = $true
      }
    }

    if ($workflowContent -match "\$\{\{\s*secrets\.") {
      Write-Output "FAIL workflow uses secrets in review-gated phase: $normalizedPath"
      $failed = $true
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge PR review gate failed."
  exit 1
}

Write-Output "SpecBridge PR review gate passed."
exit 0

