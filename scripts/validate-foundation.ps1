$ErrorActionPreference = "Stop"

Write-Output "SpecBridge foundation validation started."

$requiredFiles = @(
  ".gitattributes",
  "README.md",
  "SPECBRIDGE.md",
  "AGENTS.md",
  "CLAUDE.md",
  ".specbridge/policy.yaml",
  ".specbridge/autonomy.yaml",
  ".specbridge/risk-rules.yaml",
  ".specbridge/report-template.md",
  ".specbridge/context/CODEX_CONTEXT.md",
  ".specbridge/context/CURRENT_GOAL.md",
  ".specbridge/context/ACCEPTANCE_CRITERIA.md",
  ".specbridge/context/DO_NOT_TOUCH.md",
  ".specbridge/context/STYLE_GUIDE.md",
  "specs/000-project-context.md",
  "specs/001-product-requirements.md",
  "specs/002-architecture.md",
  "specs/003-mvp-plan.md",
  "specs/004-acceptance-tests.md"
)

$failed = $false

foreach ($file in $requiredFiles) {
  if (-not (Test-Path $file)) {
    Write-Output "FAIL missing required file: $file"
    $failed = $true
    continue
  }

  $item = Get-Item $file
  if ($item.Length -le 0) {
    Write-Output "FAIL empty required file: $file"
    $failed = $true
  }
}

$mdFiles = Get-ChildItem -Recurse -Filter *.md

foreach ($file in $mdFiles) {
  $count = (Select-String -Path $file.FullName -Pattern '^```').Count
  if ($count % 2 -ne 0) {
    Write-Output "FAIL unbalanced markdown fences: $($file.FullName) fences=$count"
    $failed = $true
  }
}

$blockedImplementationPaths = @(
  "src",
  "app",
  "apps",
  "packages",
  "lib",
  "server",
  "client"
)

foreach ($path in $blockedImplementationPaths) {
  if (Test-Path $path) {
    Write-Output "FAIL implementation path exists during foundation phase: $path"
    $failed = $true
  }
}

$blockedImplementationFiles = Get-ChildItem -Recurse -File -Include *.ts,*.tsx,*.js,*.mjs,*.cjs,*.py,*.go,*.rs,*.java,*.cs,*.sql -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch "\\.git\\" -and
    $_.FullName -notmatch "\\scripts\\" 
  }

foreach ($file in $blockedImplementationFiles) {
  Write-Output "FAIL implementation file exists during foundation phase: $($file.FullName)"
  $failed = $true
}

if ($failed) {
  Write-Output "SpecBridge foundation validation failed."
  exit 1
}

Write-Output "SpecBridge foundation validation passed."
exit 0