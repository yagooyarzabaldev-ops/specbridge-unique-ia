$ErrorActionPreference = "Stop"

Write-Output "SpecBridge standard CI authority validation started."

$failed = $false

$requiredDocs = @(
  "docs/specbridge-ci-authority-standard.md",
  "docs/specbridge-standard-loop-v1.md"
)

$requiredWorkflows = @(
  ".github/workflows/foundation-validation.yml",
  ".github/workflows/specbridge-review-gate.yml",
  ".github/workflows/specbridge-pr-review-report.yml",
  ".github/workflows/unique-ai-ci.yml"
)

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

foreach ($doc in $requiredDocs) {
  if (-not (Test-Path -LiteralPath $doc -PathType Leaf)) {
    Write-Failure "missing CI authority standard document: $doc"
    continue
  }

  $content = Get-Content -LiteralPath $doc -Raw

  foreach ($requiredText in @("CI authority", "GitHub CI", "security gate", "review gate")) {
    if ($content -notmatch [regex]::Escape($requiredText)) {
      Write-Failure "CI authority document must mention '$requiredText': $doc"
    }
  }
}

foreach ($workflow in $requiredWorkflows) {
  if (-not (Test-Path -LiteralPath $workflow -PathType Leaf)) {
    Write-Failure "missing required existing workflow: $workflow"
  }
}

if (Test-Path -LiteralPath ".github/workflows" -PathType Container) {
  $changedWorkflowFiles = @()
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  try {
    [void] (git rev-parse --is-inside-work-tree 2>$null)
    $isGitRepository = ($LASTEXITCODE -eq 0)

    if ($isGitRepository) {
      [void] (git rev-parse --verify HEAD~1 2>$null)
      $hasPreviousCommit = ($LASTEXITCODE -eq 0)

      if ($hasPreviousCommit) {
        $changedWorkflowFiles = @(
          git diff --name-only HEAD~1..HEAD 2>$null |
            Where-Object { $_ -match "^\.github/workflows/" }
        )
      }
    }
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($changedWorkflowFiles.Count -gt 0) {
    # Default: workflow changes are blocked. A change passes only when an
    # unexpired entry in the workflow-change authorization registry covers
    # that exact file. The registry records who authorized it and why.
    $authorizedFiles = @()
    $registryPath = ".specbridge/policies/workflow-change-authorizations.json"
    if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
      try {
        $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $today = (Get-Date).Date
        foreach ($auth in @($registry.authorizations)) {
          if ($null -eq $auth) { continue }
          if ([string]::IsNullOrWhiteSpace($auth.authorized_by) -or [string]::IsNullOrWhiteSpace($auth.reason)) { continue }
          $expires = $null
          try { $expires = [datetime]::ParseExact($auth.expires_at, "yyyy-MM-dd", $null) } catch { continue }
          if ($expires.Date -lt $today) { continue }
          $authorizedFiles += @($auth.files)
        }
      } catch {
        Write-Failure "workflow-change authorization registry is not valid JSON: $registryPath"
      }
    }

    foreach ($workflow in $changedWorkflowFiles) {
      if ($authorizedFiles -contains $workflow) {
        Write-Output "Workflow change authorized by registry entry: $workflow"
      } else {
        Write-Failure "standardization package must not modify workflow security controls: $workflow (no unexpired authorization in $registryPath)"
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge standard CI authority validation failed."
  exit 1
}

Write-Output "SpecBridge standard CI authority validation passed."
exit 0
