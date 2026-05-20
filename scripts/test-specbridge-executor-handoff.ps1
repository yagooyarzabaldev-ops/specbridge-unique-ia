$ErrorActionPreference = "Stop"

Write-Output "SpecBridge executor handoff tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-executor-handoff-" + [guid]::NewGuid().ToString("N"))
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

  $output = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 @Arguments 2>&1
  $exitCode = $LASTEXITCODE

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
    Write-Output "FAIL executor handoff command failed unexpectedly: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if (-not [string]::IsNullOrWhiteSpace($ExpectedPattern) -and $Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL executor handoff output did not match expected pattern: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS executor handoff command: $Name"
}

function Assert-Failure {
  param(
    [string] $Name,
    [object] $Result,
    [string] $ExpectedPattern
  )

  if ($Result.ExitCode -eq 0) {
    Write-Output "FAIL executor handoff command did not fail: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if ($Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL executor handoff command failed for unexpected reason: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS executor handoff failure: $Name"
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $caseDir = Join-Path $tempRoot "handoff"
  Copy-RepoFixture -Destination $caseDir

  Push-Location $caseDir
  try {
    New-Item -ItemType Directory -Force -Path ".specbridge/executor-handoffs" | Out-Null

    $handoffInput = [ordered]@{
      task_id = "issue-058-live-antigravity-executor-handoff"
      slices = @(
        [ordered]@{
          id = "agent-a-implementation"
          role = "implementation"
          goal = "Run the implementation executor contract in an Antigravity Claude Code session."
          contract_path = ".specbridge/contracts/issue-054-agent-a-implementation-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-054-agent-a-implementation-slice.final-report.json"
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-a-implementation-output.md")
          read_only = @("README.md", "SPECBRIDGE.md", ".specbridge/policy.yaml")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1")
        },
        [ordered]@{
          id = "agent-b-tests"
          role = "tests"
          goal = "Run the test executor contract in an Antigravity Claude Code session."
          contract_path = ".specbridge/contracts/issue-055-agent-b-test-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-055-agent-b-test-slice.final-report.json"
          exclusive_write = @("scripts/test-specbridge-multi-agent-pilot.ps1")
          read_only = @("README.md", "SPECBRIDGE.md", ".specbridge/policy.yaml")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1")
        },
        [ordered]@{
          id = "agent-c-documentation"
          role = "documentation"
          goal = "Run the documentation executor contract in an Antigravity Claude Code session."
          contract_path = ".specbridge/contracts/issue-056-agent-c-documentation-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-056-agent-c-documentation-slice.final-report.json"
          exclusive_write = @("docs/specbridge-multi-agent-pilot.md")
          read_only = @("README.md", "SPECBRIDGE.md", ".specbridge/policy.yaml")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/executor-handoffs/issue-058-input.json" `
      -Value ($handoffInput | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Success `
      -Name "prepare-executors" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-executors",
        "-InputPath",
        ".specbridge/executor-handoffs/issue-058-input.json",
        "-OutputDirectory",
        ".specbridge/executor-packets",
        "-BranchPrefix",
        "claude",
        "-Force"
      )) `
      -ExpectedPattern '"packet_count"\s*:\s*3'

    $packetValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL executor packets did not validate."
      Write-Output ($packetValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS executor packets validate."
    }

    $packets = @(Get-ChildItem -LiteralPath ".specbridge/executor-packets" -Filter "issue-058-live-antigravity-executor-handoff-*.executor-packet.json" -File)

    if ($packets.Count -ne 3) {
      Write-Output "FAIL expected three issue 058 executor packets."
      $failed = $true
    }
    else {
      Write-Output "PASS executor handoff generated three packets."
    }

    $conflictInput = [ordered]@{
      task_id = "issue-058-branch-conflict"
      slices = @(
        [ordered]@{
          id = "agent-a"
          role = "implementation"
          goal = "Use a duplicate branch."
          branch_name = "claude/duplicate"
          contract_path = ".specbridge/contracts/issue-054-agent-a-implementation-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-054-agent-a-implementation-slice.final-report.json"
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-a-implementation-output.md")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1")
        },
        [ordered]@{
          id = "agent-b"
          role = "tests"
          goal = "Use the same duplicate branch."
          branch_name = "claude/duplicate"
          contract_path = ".specbridge/contracts/issue-055-agent-b-test-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-055-agent-b-test-slice.final-report.json"
          exclusive_write = @("scripts/test-specbridge-multi-agent-pilot.ps1")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/executor-handoffs/issue-058-conflict-input.json" `
      -Value ($conflictInput | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Failure `
      -Name "prepare-executors-duplicate-branch" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-executors",
        "-InputPath",
        ".specbridge/executor-handoffs/issue-058-conflict-input.json",
        "-OutputDirectory",
        ".specbridge/executor-packets",
        "-Force"
      )) `
      -ExpectedPattern "Duplicate branch_name"
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
  Write-Output "SpecBridge executor handoff tests failed."
  exit 1
}

Write-Output "SpecBridge executor handoff tests passed."
exit 0
