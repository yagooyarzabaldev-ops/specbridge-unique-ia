$ErrorActionPreference = "Stop"

Write-Output "SpecBridge CLI tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-cli-tests-" + [guid]::NewGuid().ToString("N"))
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

  $localClaudeSettings = Join-Path $Destination ".claude/settings.local.json"

  if (Test-Path -LiteralPath $localClaudeSettings) {
    Remove-Item -LiteralPath $localClaudeSettings -Force
  }
}

function Invoke-Cli {
  param(
    [string[]] $Arguments
  )

  $previousBaseRef = $env:GITHUB_BASE_REF
  $previousHeadRef = $env:GITHUB_HEAD_REF
  $env:GITHUB_BASE_REF = $null
  $env:GITHUB_HEAD_REF = $null

  try {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 @Arguments 2>&1
    $exitCode = $LASTEXITCODE
  }
  finally {
    $env:GITHUB_BASE_REF = $previousBaseRef
    $env:GITHUB_HEAD_REF = $previousHeadRef
  }

  if ($null -eq $exitCode) {
    $exitCode = 0
  }

  return [pscustomobject]@{
    ExitCode = $exitCode
    Text = ($output | Out-String)
  }
}

function Assert-Success {
  param(
    [string] $Name,
    [object] $Result,
    [string] $ExpectedPattern = ""
  )

  if ($Result.ExitCode -ne 0) {
    Write-Output "FAIL CLI command failed unexpectedly: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if (-not [string]::IsNullOrWhiteSpace($ExpectedPattern) -and $Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL CLI command output did not match expected pattern: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS CLI command: $Name"
}

function Assert-Failure {
  param(
    [string] $Name,
    [object] $Result,
    [string] $ExpectedPattern
  )

  if ($Result.ExitCode -eq 0) {
    Write-Output "FAIL CLI command did not fail: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if ($Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL CLI command failed for unexpected reason: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS CLI failure: $Name"
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $caseDir = Join-Path $tempRoot "cli"
  Copy-RepoFixture -Destination $caseDir

  Push-Location $caseDir
  try {
    git init | Out-Null
    git config user.email "specbridge-tests@example.invalid"
    git config user.name "SpecBridge Tests"
    git config core.autocrlf false

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
      git add . 2>$null | Out-Null
      git commit -m "baseline" 2>$null | Out-Null
      git commit --allow-empty -m "validation baseline" 2>$null | Out-Null
    }
    finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }

    Assert-Success `
      -Name "status" `
      -Result (Invoke-Cli -Arguments @("status")) `
      -ExpectedPattern '"command"\s*:\s*"status"'

    Assert-Success `
      -Name "status-latest-artifacts" `
      -Result (Invoke-Cli -Arguments @("status", "-IncludeLatestArtifacts")) `
      -ExpectedPattern '"latest_artifacts"'

    Assert-Success `
      -Name "validate-standard" `
      -Result (Invoke-Cli -Arguments @("validate", "-Profile", "standard")) `
      -ExpectedPattern '"ok"\s*:\s*true'

    Assert-Success `
      -Name "create-contract" `
      -Result (Invoke-Cli -Arguments @(
        "create-contract",
        "-TaskId",
        "cli-fixture",
        "-Title",
        "CLI Fixture",
        "-Goal",
        "Create a deterministic CLI fixture contract.",
        "-RelatedIssue",
        "https://github.com/yagooyarzabaldev-ops/specbridge/issues/998",
        "-OutputPath",
        ".specbridge/contracts/cli-fixture.execution.md"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/contracts/cli-fixture\.execution\.md"'

    $contractValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created contract did not validate."
      Write-Output ($contractValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created contract validates."
    }

    Assert-Success `
      -Name "create-report" `
      -Result (Invoke-Cli -Arguments @(
        "create-report",
        "-Summary",
        "CLI fixture final report.",
        "-ChangedFile",
        "docs/cli-fixture.md",
        "-Validation",
        "CLI fixture validation: passed",
        "-PolicyResult",
        "Passed in CLI fixture.",
        "-RiskResult",
        "Low risk CLI fixture.",
        "-CompletionStatus",
        "complete",
        "-OutputPath",
        ".specbridge/reports/cli-fixture.final-report.json"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/reports/cli-fixture\.final-report\.json"'

    $reportValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created report did not validate."
      Write-Output ($reportValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created report validates."
    }

    Assert-Success `
      -Name "audit-packet" `
      -Result (Invoke-Cli -Arguments @(
        "audit-packet",
        "-TaskId",
        "cli-fixture",
        "-ContractPath",
        ".specbridge/contracts/cli-fixture.execution.md",
        "-ReportPath",
        ".specbridge/reports/cli-fixture.final-report.json",
        "-OutputFileName",
        "cli-fixture.audit-packet.json"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/audit-packets/cli-fixture\.audit-packet\.json"'

    $auditPacketValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created audit packet did not validate."
      Write-Output ($auditPacketValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created audit packet validates."
    }

    New-Item -ItemType Directory -Force -Path ".specbridge/decompositions" | Out-Null

    $decompositionInput = [ordered]@{
      task_id = "cli-decomposition"
      slices = @(
        [ordered]@{
          id = "agent-a"
          goal = "Implement the fixture slice."
          exclusive_write = @("docs/agent-a.md")
        },
        [ordered]@{
          id = "agent-b"
          goal = "Test the fixture slice."
          exclusive_write = @("docs/agent-b.md")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/decompositions/cli-input.json" `
      -Value ($decompositionInput | ConvertTo-Json -Depth 6) `
      -NoNewline

    Assert-Success `
      -Name "decompose-task" `
      -Result (Invoke-Cli -Arguments @(
        "decompose-task",
        "-InputPath",
        ".specbridge/decompositions/cli-input.json",
        "-OutputPath",
        ".specbridge/decompositions/cli-fixture.decomposition.json"
      )) `
      -ExpectedPattern '"slices"\s*:\s*2'

    Assert-Success `
      -Name "detect-conflicts" `
      -Result (Invoke-Cli -Arguments @("detect-conflicts")) `
      -ExpectedPattern '"command"\s*:\s*"detect-conflicts"'

    Assert-Success `
      -Name "review-gate" `
      -Result (Invoke-Cli -Arguments @("review-gate")) `
      -ExpectedPattern '"command"\s*:\s*"review-gate"'

    Assert-Failure `
      -Name "create-contract-missing-output" `
      -Result (Invoke-Cli -Arguments @(
        "create-contract",
        "-TaskId",
        "missing-output",
        "-Title",
        "Missing Output",
        "-Goal",
        "This fixture should fail.",
        "-RelatedIssue",
        "https://github.com/yagooyarzabaldev-ops/specbridge/issues/998"
      )) `
      -ExpectedPattern "OutputPath is required"
  }
  finally {
    Pop-Location
  }
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failed) {
  Write-Output "SpecBridge CLI tests failed."
  exit 1
}

Write-Output "SpecBridge CLI tests passed."
exit 0
