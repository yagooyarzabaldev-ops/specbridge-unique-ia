$ErrorActionPreference = "Stop"

Write-Output "SpecBridge negative validation tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-negative-tests-" + [guid]::NewGuid().ToString("N"))
$failed = $false

function Copy-RepoFixture {
  param(
    [string] $Destination
  )

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null

  Get-ChildItem -LiteralPath $sourceRoot -Force |
    Where-Object {
      $_.Name -ne ".git" -and
      $_.Name -ne ".agents"
    } |
    ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Invoke-ExpectedFailure {
  param(
    [string] $Name,
    [scriptblock] $Arrange,
    [string] $Command,
    [string] $ExpectedPattern,
    [bool] $RequiresGit = $false
  )

  $caseDir = Join-Path $tempRoot $Name
  Copy-RepoFixture -Destination $caseDir

  if ($RequiresGit) {
    Push-Location $caseDir
    try {
      git init | Out-Null
      git config user.email "specbridge-tests@example.invalid"
      git config user.name "SpecBridge Tests"
      git config core.autocrlf false
      git commit --allow-empty -m "baseline" | Out-Null
    }
    finally {
      Pop-Location
    }
  }

  Push-Location $caseDir
  try {
    & $Arrange

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousHeadRef = $env:GITHUB_HEAD_REF
    $env:GITHUB_BASE_REF = $null
    $env:GITHUB_HEAD_REF = $null

    try {
      $output = & powershell -ExecutionPolicy Bypass -Command $Command 2>&1
      $exitCode = $LASTEXITCODE
      $outputText = ($output | Out-String)
    }
    finally {
      $env:GITHUB_BASE_REF = $previousBaseRef
      $env:GITHUB_HEAD_REF = $previousHeadRef
    }

    if ($exitCode -eq 0) {
      Write-Output "FAIL negative test did not fail: $Name"
      $script:failed = $true
      return
    }

    if ($outputText -notmatch $ExpectedPattern) {
      Write-Output "FAIL negative test failed for unexpected reason: $Name"
      Write-Output "Expected pattern: $ExpectedPattern"
      Write-Output $outputText
      $script:failed = $true
      return
    }

    Write-Output "PASS negative test: $Name"
  }
  finally {
    Pop-Location
  }
}

function Invoke-ExpectedSuccess {
  param(
    [string] $Name,
    [scriptblock] $Arrange,
    [string] $Command
  )

  $caseDir = Join-Path $tempRoot $Name
  Copy-RepoFixture -Destination $caseDir

  Push-Location $caseDir
  try {
    & $Arrange

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousHeadRef = $env:GITHUB_HEAD_REF
    $env:GITHUB_BASE_REF = $null
    $env:GITHUB_HEAD_REF = $null

    try {
      $output = & powershell -ExecutionPolicy Bypass -Command $Command 2>&1
      $exitCode = $LASTEXITCODE
      $outputText = ($output | Out-String)
    }
    finally {
      $env:GITHUB_BASE_REF = $previousBaseRef
      $env:GITHUB_HEAD_REF = $previousHeadRef
    }

    if ($exitCode -ne 0) {
      Write-Output "FAIL positive fixture failed unexpectedly: $Name"
      Write-Output $outputText
      $script:failed = $true
      return
    }

    Write-Output "PASS positive fixture: $Name"
  }
  finally {
    Pop-Location
  }
}

function Write-ScopeManifest {
  param(
    [string] $Path,
    [string] $ContractId,
    [string] $Status,
    [string[]] $ExclusiveWrite,
    [string[]] $ReadOnly,
    [string[]] $CoordinatorOwned,
    [string[]] $Dependencies,
    [string] $FinalReport
  )

  $manifest = [ordered]@{
    contract_id = $ContractId
    status = $Status
    exclusive_write = @($ExclusiveWrite)
    read_only = @($ReadOnly)
    coordinator_owned = @($CoordinatorOwned)
    dependencies = @($Dependencies)
    final_report = $FinalReport
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
  Set-Content -LiteralPath $Path -Value ($manifest | ConvertTo-Json -Depth 4) -NoNewline
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  Invoke-ExpectedFailure `
    -Name "foundation-missing-readme" `
    -Arrange {
      Remove-Item -LiteralPath "README.md" -Force
    } `
    -Command "./scripts/validate-foundation.ps1" `
    -ExpectedPattern "missing required file: README\.md"

  Invoke-ExpectedFailure `
    -Name "contract-missing-section" `
    -Arrange {
      $contract = @"
# Execution Contract: Negative Test

## Contract Metadata

- contract_id: negative-test
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/999
- created_by: SpecBridge Tests
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Context

This contract intentionally omits the Goal section.
"@

      Set-Content -LiteralPath ".specbridge/contracts/negative-test.execution.md" -Value $contract -NoNewline
    } `
    -Command "./scripts/validate-contracts.ps1" `
    -ExpectedPattern "missing required section.*Goal"

  Invoke-ExpectedSuccess `
    -Name "contract-scope-disjoint-manifests" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/disjoint-a.scope.json" `
        -ContractId "disjoint-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/disjoint-a.md") `
        -ReadOnly @("README.md") `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/disjoint-a.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/disjoint-b.scope.json" `
        -ContractId "disjoint-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/disjoint-b.md") `
        -ReadOnly @("README.md") `
        -CoordinatorOwned @() `
        -Dependencies @("disjoint-a") `
        -FinalReport ".specbridge/reports/disjoint-b.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1"

  Invoke-ExpectedFailure `
    -Name "contract-scope-missing-exclusive-write" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      $manifest = [ordered]@{
        contract_id = "missing-exclusive-write"
        status = "active"
        read_only = @("README.md")
        coordinator_owned = @()
        dependencies = @()
        final_report = ".specbridge/reports/missing-exclusive-write.final-report.json"
      }

      New-Item -ItemType Directory -Force -Path ".specbridge/scopes" | Out-Null
      Set-Content -LiteralPath ".specbridge/scopes/missing-exclusive-write.scope.json" -Value ($manifest | ConvertTo-Json -Depth 4) -NoNewline
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "missing required property.*exclusive_write"

  Invoke-ExpectedFailure `
    -Name "contract-scope-conflicting-write-path" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/conflict-a.scope.json" `
        -ContractId "conflict-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/shared.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/conflict-a.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/conflict-b.scope.json" `
        -ContractId "conflict-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/shared.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/conflict-b.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "exclusive_write conflict path=docs/shared\.md contracts=conflict-a, conflict-b"

  Invoke-ExpectedFailure `
    -Name "contract-scope-duplicate-final-report" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/report-a.scope.json" `
        -ContractId "report-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/report-a.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/shared.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/report-b.scope.json" `
        -ContractId "report-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/report-b.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/shared.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "duplicate final_report path=.specbridge/reports/shared\.final-report\.json contracts=report-a, report-b"

  Invoke-ExpectedFailure `
    -Name "final-report-missing-property" `
    -Arrange {
      $report = @{
        summary = "Invalid report fixture"
      } | ConvertTo-Json

      Set-Content -LiteralPath ".specbridge/reports/negative-test.final-report.json" -Value $report -NoNewline
    } `
    -Command "./scripts/validate-final-reports.ps1" `
    -ExpectedPattern "missing required property.*changed_files"

  Invoke-ExpectedFailure `
    -Name "review-gate-blocked-path" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "src" | Out-Null
      Set-Content -LiteralPath "src/blocked.txt" -Value "blocked path fixture" -NoNewline
      git add src/blocked.txt 2>$null
      git commit -m "add blocked path fixture" | Out-Null
    } `
    -Command "./scripts/validate-review-gate.ps1" `
    -ExpectedPattern "blocked path changed: src/blocked\.txt"
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failed) {
  Write-Output "SpecBridge negative validation tests failed."
  exit 1
}

Write-Output "SpecBridge negative validation tests passed."
exit 0
