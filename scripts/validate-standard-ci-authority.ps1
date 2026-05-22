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
  ".github/workflows/claude-review-non-blocking.yml"
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
    foreach ($workflow in $changedWorkflowFiles) {
      Write-Failure "standardization package must not modify workflow security controls: $workflow"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge standard CI authority validation failed."
  exit 1
}

Write-Output "SpecBridge standard CI authority validation passed."
exit 0
