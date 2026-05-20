$ErrorActionPreference = "Stop"

Write-Output "SpecBridge multi-agent pilot tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-multi-agent-pilot-" + [guid]::NewGuid().ToString("N"))
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
    Write-Output "FAIL multi-agent pilot command failed unexpectedly: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if (-not [string]::IsNullOrWhiteSpace($ExpectedPattern) -and $Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL multi-agent pilot output did not match expected pattern: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS multi-agent pilot command: $Name"
}

function Assert-Failure {
  param(
    [string] $Name,
    [object] $Result,
    [string] $ExpectedPattern
  )

  if ($Result.ExitCode -eq 0) {
    Write-Output "FAIL multi-agent pilot command did not fail: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if ($Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL multi-agent pilot command failed for unexpected reason: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS multi-agent pilot failure: $Name"
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $caseDir = Join-Path $tempRoot "multi-agent"
  Copy-RepoFixture -Destination $caseDir

  Push-Location $caseDir
  try {
    New-Item -ItemType Directory -Force -Path ".specbridge/decompositions" | Out-Null

    $pilotInput = [ordered]@{
      task_id = "issue-054-multi-agent-pilot"
      slices = @(
        [ordered]@{
          id = "agent-a-implementation"
          goal = "Produce the implementation-slice evidence artifact."
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-a-implementation-output.md")
        },
        [ordered]@{
          id = "agent-b-tests"
          goal = "Produce the test-slice evidence artifact."
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-b-test-output.md")
        },
        [ordered]@{
          id = "agent-c-documentation"
          goal = "Produce the documentation-slice evidence artifact."
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-c-documentation-output.md")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/decompositions/issue-054-input.json" `
      -Value ($pilotInput | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Success `
      -Name "decompose-three-agent-pilot" `
      -Result (Invoke-Cli -Arguments @(
        "decompose-task",
        "-InputPath",
        ".specbridge/decompositions/issue-054-input.json",
        "-OutputPath",
        ".specbridge/decompositions/issue-054-multi-agent-pilot.decomposition.json",
        "-Force"
      )) `
      -ExpectedPattern '"slices"\s*:\s*3'

    $decomposition = Get-Content -LiteralPath ".specbridge/decompositions/issue-054-multi-agent-pilot.decomposition.json" -Raw | ConvertFrom-Json
    $writePaths = @($decomposition.slices | ForEach-Object { $_.exclusive_write } | ForEach-Object { $_ })
    $duplicateWrites = @($writePaths | Group-Object | Where-Object { $_.Count -gt 1 })

    if (@($decomposition.slices).Count -ne 3) {
      Write-Output "FAIL multi-agent pilot decomposition did not produce three slices."
      $failed = $true
    }
    elseif ($duplicateWrites.Count -gt 0) {
      Write-Output "FAIL multi-agent pilot decomposition produced duplicate write paths."
      $duplicateWrites | ForEach-Object { Write-Output $_.Name }
      $failed = $true
    }
    else {
      Write-Output "PASS multi-agent pilot decomposition has three disjoint write scopes."
    }

    $conflictInput = [ordered]@{
      task_id = "issue-054-multi-agent-conflict"
      slices = @(
        [ordered]@{
          id = "agent-a"
          goal = "Own the shared path."
          exclusive_write = @(".specbridge/pilot/multi-agent/shared-output.md")
        },
        [ordered]@{
          id = "agent-b"
          goal = "Incorrectly own the same shared path."
          exclusive_write = @(".specbridge/pilot/multi-agent/shared-output.md")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/decompositions/issue-054-conflict-input.json" `
      -Value ($conflictInput | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Failure `
      -Name "decompose-overlapping-agent-scopes" `
      -Result (Invoke-Cli -Arguments @(
        "decompose-task",
        "-InputPath",
        ".specbridge/decompositions/issue-054-conflict-input.json",
        "-OutputPath",
        ".specbridge/decompositions/issue-054-conflict.decomposition.json"
      )) `
      -ExpectedPattern "Duplicate exclusive_write path"
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
  Write-Output "SpecBridge multi-agent pilot tests failed."
  exit 1
}

Write-Output "SpecBridge multi-agent pilot tests passed."
exit 0
