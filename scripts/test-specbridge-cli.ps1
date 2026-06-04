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
      -Name "standard-loop-status" `
      -Result (Invoke-Cli -Arguments @("standard-loop-status")) `
      -ExpectedPattern '"standard"\s*:\s*"SpecBridge Standard Loop v1"'

    $standardLoopOrchestrationResult = Invoke-Cli -Arguments @("standard-loop-orchestrate")

    Assert-Success `
      -Name "standard-loop-orchestrate" `
      -Result $standardLoopOrchestrationResult `
      -ExpectedPattern '"command"\s*:\s*"standard-loop-orchestrate"'

    if ($standardLoopOrchestrationResult.ExitCode -eq 0) {
      $standardLoopOrchestrationJson = $null
      try { $standardLoopOrchestrationJson = $standardLoopOrchestrationResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $standardLoopOrchestrationJson) {
        Write-Output "FAIL standard-loop-orchestrate output was not valid JSON."
        $failed = $true
      }
      elseif (@($standardLoopOrchestrationJson.phases).Count -lt 9) {
        Write-Output "FAIL standard-loop-orchestrate expected at least 9 phases."
        $failed = $true
      }
      elseif (-not $standardLoopOrchestrationJson.required_gates.PSObject.Properties.Name.Contains("github")) {
        Write-Output "FAIL standard-loop-orchestrate missing required_gates.github."
        $failed = $true
      }
      elseif ($null -eq $standardLoopOrchestrationJson.next_contract_seed) {
        Write-Output "FAIL standard-loop-orchestrate missing next_contract_seed."
        $failed = $true
      }
      elseif ($standardLoopOrchestrationJson.next_contract_seed.contract_path -ne ".specbridge/contracts/current-goal.execution.md") {
        Write-Output "FAIL standard-loop-orchestrate next_contract_seed has unexpected contract path."
        $failed = $true
      }
      else {
        Write-Output "PASS standard-loop-orchestrate includes phases, GitHub gates, and contract seed."
      }
    }

    Assert-Success `
      -Name "standard-loop-orchestrate-output-path" `
      -Result (Invoke-Cli -Arguments @(
        "standard-loop-orchestrate",
        "-TaskId",
        "cli-fixture",
        "-OutputPath",
        ".specbridge/standard-loop-runs/cli-fixture.standard-loop-run.json",
        "-Force"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/standard-loop-runs/cli-fixture\.standard-loop-run\.json"'

    if (-not (Test-Path -LiteralPath ".specbridge/standard-loop-runs/cli-fixture.standard-loop-run.json" -PathType Leaf)) {
      Write-Output "FAIL standard-loop-orchestrate did not write the requested output path."
      $failed = $true
    }
    else {
      try {
        $standardLoopRun = Get-Content -LiteralPath ".specbridge/standard-loop-runs/cli-fixture.standard-loop-run.json" -Raw | ConvertFrom-Json

        if ($standardLoopRun.command -ne "standard-loop-orchestrate" -or $standardLoopRun.task_id -ne "cli-fixture") {
          Write-Output "FAIL standard-loop-orchestrate output artifact has unexpected content."
          $failed = $true
        }
        elseif ($standardLoopRun.next_contract_seed.standard_loop_run_path -ne ".specbridge/standard-loop-runs/cli-fixture.standard-loop-run.json") {
          Write-Output "FAIL standard-loop-orchestrate output artifact has unexpected seed path."
          $failed = $true
        }
        elseif ($standardLoopRun.next_contract_seed.recommended_branch -ne "codex/cli-fixture") {
          Write-Output "FAIL standard-loop-orchestrate output artifact has unexpected seed branch."
          $failed = $true
        }
        else {
          Write-Output "PASS standard-loop-orchestrate output artifact and seed validate by inspection."
        }
      }
      catch {
        Write-Output "FAIL standard-loop-orchestrate output artifact is not valid JSON."
        Write-Output $_.Exception.Message
        $failed = $true
      }
    }

    Assert-Success `
      -Name "v5-pilot-status" `
      -Result (Invoke-Cli -Arguments @("v5-pilot-status")) `
      -ExpectedPattern '"readiness_status"\s*:\s*"ready_for_v5_live_contract"'

    Assert-Success `
      -Name "v5-live-status" `
      -Result (Invoke-Cli -Arguments @("v5-live-status")) `
      -ExpectedPattern '"live_status"\s*:\s*"completed_with_coordinator_remediation"'

    $v5AutonomyStatusResult = Invoke-Cli -Arguments @("v5-autonomy-status")

    Assert-Success `
      -Name "v5-autonomy-status" `
      -Result $v5AutonomyStatusResult `
      -ExpectedPattern '"command"\s*:\s*"v5-autonomy-status"'

    if ($v5AutonomyStatusResult.Text -notmatch '"autonomy_standard"') {
      Write-Output "FAIL v5-autonomy-status output is missing autonomy_standard field."
      $script:failed = $true
    }
    else {
      Write-Output "PASS v5-autonomy-status includes autonomy_standard field."
    }

    $v5SeriousPilotStatusResult = Invoke-Cli -Arguments @("v5-serious-pilot-status")

    Assert-Success `
      -Name "v5-serious-pilot-status" `
      -Result $v5SeriousPilotStatusResult `
      -ExpectedPattern '"command"\s*:\s*"v5-serious-pilot-status"'

    if ($v5SeriousPilotStatusResult.ExitCode -eq 0) {
      $v5SeriousPilotStatusJson = $null
      try { $v5SeriousPilotStatusJson = $v5SeriousPilotStatusResult.Text.Trim() | ConvertFrom-Json } catch {}

      foreach ($fieldCheck in @(
        [pscustomobject]@{ Field = "runner_baseline"; Expected = "v5_hardened_runtime_runner" },
        [pscustomobject]@{ Field = "default_runtime_budget_usd"; Expected = "2.00" },
        [pscustomobject]@{ Field = "diagnostic_preview_policy"; Expected = "ascii_stable_bounded_240_chars" }
      )) {
        $actual = if ($null -ne $v5SeriousPilotStatusJson) { $v5SeriousPilotStatusJson.($fieldCheck.Field) } else { $null }
        if ($actual -ne $fieldCheck.Expected) {
          Write-Output "FAIL v5-serious-pilot-status $($fieldCheck.Field) expected '$($fieldCheck.Expected)' got '$actual'."
          $failed = $true
        }
        else {
          Write-Output "PASS v5-serious-pilot-status $($fieldCheck.Field) is $($fieldCheck.Expected)."
        }
      }

      $coordinatorRemediationAllowed = if ($null -ne $v5SeriousPilotStatusJson) { $v5SeriousPilotStatusJson.coordinator_remediation_allowed } else { $null }
      if ($coordinatorRemediationAllowed -ne $false) {
        Write-Output "FAIL v5-serious-pilot-status coordinator_remediation_allowed expected false got '$coordinatorRemediationAllowed'."
        $failed = $true
      }
      else {
        Write-Output "PASS v5-serious-pilot-status coordinator_remediation_allowed is false."
      }

      $requiredSlices = if ($null -ne $v5SeriousPilotStatusJson) { @($v5SeriousPilotStatusJson.required_slices) } else { @() }
      $missingSlices = @("status", "tests", "docs") | Where-Object { $requiredSlices -notcontains $_ }
      if ($missingSlices.Count -gt 0) {
        Write-Output "FAIL v5-serious-pilot-status required_slices missing: $($missingSlices -join ', ')."
        $failed = $true
      }
      else {
        Write-Output "PASS v5-serious-pilot-status required_slices includes status, tests, docs."
      }
    }

    Assert-Success `
      -Name "runtime-capability-status" `
      -Result (Invoke-Cli -Arguments @("runtime-capability-status")) `
      -ExpectedPattern '"command"\s*:\s*"runtime-capability-status"'

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

    $handoffInput = [ordered]@{
      task_id = "cli-executor-handoff"
      slices = @(
        [ordered]@{
          id = "agent-a-implementation"
          role = "implementation"
          goal = "Prepare an implementation executor handoff packet."
          contract_path = ".specbridge/contracts/issue-054-agent-a-implementation-slice.execution.md"
          final_report_path = ".specbridge/reports/issue-054-agent-a-implementation-slice.final-report.json"
          exclusive_write = @(".specbridge/pilot/multi-agent/agent-a-implementation-output.md")
          read_only = @("README.md")
          required_validations = @("powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1")
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/decompositions/cli-handoff-input.json" `
      -Value ($handoffInput | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Success `
      -Name "prepare-executors" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-executors",
        "-InputPath",
        ".specbridge/decompositions/cli-handoff-input.json",
        "-OutputDirectory",
        ".specbridge/executor-packets",
        "-Force"
      )) `
      -ExpectedPattern '"packet_count"\s*:\s*1'

    $executorPacketValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created executor packet did not validate."
      Write-Output ($executorPacketValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created executor packet validates."
    }

    Assert-Success `
      -Name "prepare-runtime-launch" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-runtime-launch",
        "-InputPath",
        ".specbridge/executor-packets/cli-executor-handoff-agent-a-implementation.executor-packet.json",
        "-OutputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-AllowedTool",
        "Read,Write",
        "-PermissionMode",
        "acceptEdits",
        "-Force"
      )) `
      -ExpectedPattern '"launch_status"\s*:\s*"ready_for_operator_launch"'

    $runtimeLaunchValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime launch did not validate."
      Write-Output ($runtimeLaunchValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime launch validates."
    }

    $runtimeLaunch = Get-Content -LiteralPath ".specbridge/runtime-launches/cli-fixture.runtime-launch.json" -Raw | ConvertFrom-Json

    if ($runtimeLaunch.max_budget_usd -ne "2.00") {
      Write-Output "FAIL CLI-created runtime launch did not use default max_budget_usd 2.00."
      Write-Output ($runtimeLaunch | ConvertTo-Json -Depth 8)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime launch uses default max_budget_usd 2.00."
    }

    Assert-Success `
      -Name "execute-runtime-launch-dry-run" `
      -Result (Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/cli-fixture.runtime-execution.json",
        "-TimeoutSeconds",
        "30",
        "-DryRun",
        "-Force"
      )) `
      -ExpectedPattern '"execution_status"\s*:\s*"dry_run"'

    $runtimeExecution = Get-Content -LiteralPath ".specbridge/runtime-executions/cli-fixture.runtime-execution.json" -Raw | ConvertFrom-Json

    if (-not $runtimeExecution.PSObject.Properties.Name.Contains("failure_diagnostics")) {
      Write-Output "FAIL CLI-created runtime execution is missing failure_diagnostics."
      $failed = $true
    }
    elseif ($runtimeExecution.failure_diagnostics.status -ne "not_applicable" -or $runtimeExecution.failure_diagnostics.reason -ne "dry_run") {
      Write-Output "FAIL CLI-created runtime execution has unexpected dry-run failure diagnostics."
      Write-Output ($runtimeExecution.failure_diagnostics | ConvertTo-Json -Depth 8)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime execution records dry-run failure diagnostics."
    }

    $fakeBin = Join-Path $caseDir "fake-bin"
    New-Item -ItemType Directory -Force -Path $fakeBin | Out-Null
    $fakeClaudePath = Join-Path $fakeBin "claude.cmd"
    Set-Content -LiteralPath $fakeClaudePath -Encoding ASCII -Value @(
      "@echo off",
      'powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); $s = ''Fake Claude failure with unicode: '' + [char]0x00E1 + '' '' + [char]0x00F1 + '' '' + [char]0x2713 + '' repeated 1234567890 1234567890 1234567890 1234567890 1234567890''; Write-Output $s"',
      "exit /b 1"
    )

    $previousPath = $env:PATH

    try {
      $env:PATH = "$fakeBin;$previousPath"

      $fakeClaudeResult = Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/cli-fake-unicode.runtime-execution.json",
        "-TimeoutSeconds",
        "30",
        "-Force"
      )
    }
    finally {
      $env:PATH = $previousPath
    }

    if ($fakeClaudeResult.ExitCode -eq 0) {
      Write-Output "FAIL fake Claude runtime execution did not fail."
      Write-Output $fakeClaudeResult.Text
      $failed = $true
    }
    elseif (-not (Test-Path -LiteralPath ".specbridge/runtime-executions/cli-fake-unicode.runtime-execution.json" -PathType Leaf)) {
      Write-Output "FAIL fake Claude runtime execution did not write an artifact."
      Write-Output $fakeClaudeResult.Text
      $failed = $true
    }
    else {
      $unicodeExecution = Get-Content -LiteralPath ".specbridge/runtime-executions/cli-fake-unicode.runtime-execution.json" -Raw | ConvertFrom-Json
      $stdoutPreview = $unicodeExecution.failure_diagnostics.stdout_preview

      if (
        $unicodeExecution.execution_status -ne "failed" -or
        $unicodeExecution.failure_diagnostics.status -ne "recorded" -or
        $unicodeExecution.failure_diagnostics.reason -ne "stdout_only_failure" -or
        $stdoutPreview.preview_length -ne $stdoutPreview.text.Length -or
        $stdoutPreview.text.Length -gt $stdoutPreview.max_length -or
        $stdoutPreview.text -match "[^\u0009\u000A\u0020-\u007E]"
      ) {
        Write-Output "FAIL fake Claude runtime execution did not normalize diagnostic preview as expected."
        Write-Output ($unicodeExecution.failure_diagnostics | ConvertTo-Json -Depth 8)
        $failed = $true
      }
      else {
        Write-Output "PASS fake Claude runtime execution normalizes non-ASCII diagnostic previews."
      }
    }

    Set-Content -LiteralPath $fakeClaudePath -Encoding ASCII -Value @(
      "@echo off",
      ":loop",
      "ping -n 2 127.0.0.1 > nul",
      "goto loop"
    )

    try {
      $env:PATH = "$fakeBin;$previousPath"

      $fakeTimeoutResult = Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/cli-fake-timeout.runtime-execution.json",
        "-TimeoutSeconds",
        "30",
        "-Force"
      )
    }
    finally {
      $env:PATH = $previousPath
    }

    if ($fakeTimeoutResult.ExitCode -eq 0) {
      Write-Output "FAIL fake Claude timeout runtime execution did not fail."
      Write-Output $fakeTimeoutResult.Text
      $failed = $true
    }
    elseif (-not (Test-Path -LiteralPath ".specbridge/runtime-executions/cli-fake-timeout.runtime-execution.json" -PathType Leaf)) {
      Write-Output "FAIL fake Claude timeout runtime execution did not write an artifact."
      Write-Output $fakeTimeoutResult.Text
      $failed = $true
    }
    else {
      $timeoutExecution = Get-Content -LiteralPath ".specbridge/runtime-executions/cli-fake-timeout.runtime-execution.json" -Raw | ConvertFrom-Json

      if (
        $timeoutExecution.execution_status -ne "timed_out" -or
        $timeoutExecution.exit_code -ne 255 -or
        $timeoutExecution.timed_out -ne $true -or
        $timeoutExecution.failure_diagnostics.status -ne "recorded" -or
        $timeoutExecution.failure_diagnostics.reason -ne "timeout" -or
        $timeoutExecution.failure_diagnostics.exit_code -ne 255 -or
        $timeoutExecution.failure_diagnostics.timed_out -ne $true
      ) {
        Write-Output "FAIL fake Claude timeout runtime execution did not normalize timeout exit code as expected."
        Write-Output ($timeoutExecution | ConvertTo-Json -Depth 8)
        $failed = $true
      }
      else {
        Write-Output "PASS fake Claude timeout runtime execution normalizes timeout exit code."
      }
    }

    $runtimeExecutionValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime execution did not validate."
      Write-Output ($runtimeExecutionValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime execution validates."
    }

    Assert-Success `
      -Name "record-runtime-result" `
      -Result (Invoke-Cli -Arguments @(
        "record-runtime-result",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        ".specbridge/pilot/multi-agent/agent-a-implementation-output.md",
        "-OutputPath",
        ".specbridge/runtime-results/cli-fixture.runtime-result.json",
        "-RuntimeExitCode",
        "0",
        "-WrittenFile",
        ".specbridge/pilot/multi-agent/agent-a-implementation-output.md",
        "-Validation",
        "powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-multi-agent-pilot.ps1: passed",
        "-PolicyResult",
        "Passed in CLI runtime result fixture.",
        "-CompletionStatus",
        "complete",
        "-Force"
      )) `
      -ExpectedPattern '"result_status"\s*:\s*"recorded"'

    $runtimeResultValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime result did not validate."
      Write-Output ($runtimeResultValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime result validates."
    }

    Assert-Success `
      -Name "summarize-runtime" `
      -Result (Invoke-Cli -Arguments @(
        "summarize-runtime",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        ".specbridge/runtime-results/cli-fixture.runtime-result.json",
        "-OutputPath",
        ".specbridge/runtime-summaries/cli-fixture.runtime-summary.json",
        "-Force"
      )) `
      -ExpectedPattern '"merge_readiness"\s*:\s*"ready_for_policy_gates"'

    $runtimeSummaryValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime summary did not validate."
      Write-Output ($runtimeSummaryValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime summary validates."
    }

    Assert-Success `
      -Name "run-runtime-launch" `
      -Result (Invoke-Cli -Arguments @(
        "run-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        ".specbridge/pilot/multi-agent/agent-a-implementation-output.md",
        "-OutputPath",
        ".specbridge/runtime-runs/cli-fixture.runtime-run.json",
        "-RuntimeExitCode",
        "0",
        "-WrittenFile",
        ".specbridge/pilot/multi-agent/agent-a-implementation-output.md",
        "-Validation",
        "CLI runtime run evidence capture: passed",
        "-PolicyResult",
        "Passed in CLI runtime run fixture.",
        "-CompletionStatus",
        "complete",
        "-Force"
      )) `
      -ExpectedPattern '"run_status"\s*:\s*"recorded"'

    $runtimeRunValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime run did not validate."
      Write-Output ($runtimeRunValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime run validates."
    }

    Assert-Success `
      -Name "summarize-autonomy-metrics" `
      -Result (Invoke-Cli -Arguments @(
        "summarize-autonomy-metrics",
        "-TaskId",
        "cli-executor-handoff",
        "-InputPath",
        ".specbridge/runtime-summaries",
        "-EvidencePath",
        ".specbridge/runtime-results",
        "-OutputPath",
        ".specbridge/metrics/cli-fixture.autonomy-metrics.json",
        "-Force"
      )) `
      -ExpectedPattern '"policy_gate_ready_rate"\s*:\s*1'

    $autonomyMetricsValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-autonomy-metrics.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created autonomy metrics did not validate."
      Write-Output ($autonomyMetricsValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created autonomy metrics validate."
    }

    Assert-Success `
      -Name "plan-executor-branches" `
      -Result (Invoke-Cli -Arguments @(
        "plan-executor-branches",
        "-InputPath",
        ".specbridge/executor-packets/cli-executor-handoff-agent-a-implementation.executor-packet.json",
        "-OutputPath",
        ".specbridge/branch-plans/cli-fixture.branch-plan.json",
        "-Force"
      )) `
      -ExpectedPattern '"branch_count"\s*:\s*[1-9]'

    Assert-Success `
      -Name "coordinate-executors" `
      -Result (Invoke-Cli -Arguments @(
        "coordinate-executors",
        "-InputPath",
        ".specbridge/branch-plans/cli-fixture.branch-plan.json",
        "-OutputPath",
        ".specbridge/orchestrations/cli-fixture.executor-orchestration.json",
        "-EvidenceMode",
        "simulation",
        "-Force"
      )) `
      -ExpectedPattern '"integration_decision"\s*:\s*"simulation_only_no_merge"'

    New-Item -ItemType Directory -Force -Path ".specbridge/github-evidence" | Out-Null

    $cliGithubEvidence = [ordered]@{
      task_id = "cli-github-evidence"
      child_prs = @(
        [ordered]@{
          packet_id = "cli-executor-handoff-agent-a-implementation"
          branch_name = "claude/cli-executor-handoff-agent-a-implementation"
          pr_url = "https://github.com/yagooyarzabaldev-ops/specbridge/pull/1004"
          pr_status = "open"
          ci_status = "passed"
          chatgpt_audit_status = "approved"
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/github-evidence/cli-github-evidence.input.json" `
      -Value ($cliGithubEvidence | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Success `
      -Name "record-github-evidence" `
      -Result (Invoke-Cli -Arguments @(
        "record-github-evidence",
        "-InputPath",
        ".specbridge/branch-plans/cli-fixture.branch-plan.json",
        "-EvidencePath",
        ".specbridge/github-evidence/cli-github-evidence.input.json",
        "-OutputPath",
        ".specbridge/branch-plans/cli-github-evidence.branch-plan.json",
        "-Force"
      )) `
      -ExpectedPattern '"child_count"\s*:\s*1'

    $branchOrchestrationValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-branch-orchestrations.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created branch orchestration artifacts did not validate."
      Write-Output ($branchOrchestrationValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created branch orchestration artifacts validate."
    }

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

    Assert-Failure `
      -Name "prepare-runtime-launch-invalid-tool" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-runtime-launch",
        "-InputPath",
        ".specbridge/executor-packets/cli-executor-handoff-agent-a-implementation.executor-packet.json",
        "-OutputPath",
        ".specbridge/runtime-launches/invalid-tool.runtime-launch.json",
        "-AllowedTool",
        "Bash",
        "-Force"
      )) `
      -ExpectedPattern "AllowedTool is not approved"

    Assert-Failure `
      -Name "prepare-runtime-launch-missing-write-tool" `
      -Result (Invoke-Cli -Arguments @(
        "prepare-runtime-launch",
        "-InputPath",
        ".specbridge/executor-packets/cli-executor-handoff-agent-a-implementation.executor-packet.json",
        "-OutputPath",
        ".specbridge/runtime-launches/missing-write.runtime-launch.json",
        "-AllowedTool",
        "Read",
        "-Force"
      )) `
      -ExpectedPattern "AllowedTool must include Write"

    Assert-Failure `
      -Name "record-runtime-result-out-of-scope-evidence" `
      -Result (Invoke-Cli -Arguments @(
        "record-runtime-result",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        "README.md",
        "-OutputPath",
        ".specbridge/runtime-results/out-of-scope.runtime-result.json",
        "-Validation",
        "fixture validation: passed",
        "-PolicyResult",
        "Passed in CLI fixture.",
        "-CompletionStatus",
        "complete",
        "-Force"
      )) `
      -ExpectedPattern "EvidencePath must be declared"

    Assert-Failure `
      -Name "run-runtime-launch-out-of-scope-evidence" `
      -Result (Invoke-Cli -Arguments @(
        "run-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        "README.md",
        "-OutputPath",
        ".specbridge/runtime-runs/out-of-scope.runtime-run.json",
        "-PolicyResult",
        "Passed in CLI fixture.",
        "-CompletionStatus",
        "complete",
        "-Force"
      )) `
      -ExpectedPattern "EvidencePath must be declared"

    Assert-Failure `
      -Name "execute-runtime-launch-live-without-force" `
      -Result (Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/live-without-force.runtime-execution.json",
        "-TimeoutSeconds",
        "30"
      )) `
      -ExpectedPattern "requires -Force"

    Assert-Failure `
      -Name "summarize-runtime-mismatched-result" `
      -Result (Invoke-Cli -Arguments @(
        "summarize-runtime",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-EvidencePath",
        ".specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json",
        "-OutputPath",
        ".specbridge/runtime-summaries/mismatched.runtime-summary.json",
        "-Force"
      )) `
      -ExpectedPattern "source_runtime_launch_path must match InputPath"

    Assert-Failure `
      -Name "summarize-autonomy-metrics-missing-task" `
      -Result (Invoke-Cli -Arguments @(
        "summarize-autonomy-metrics",
        "-TaskId",
        "missing-runtime-task",
        "-InputPath",
        ".specbridge/runtime-summaries",
        "-EvidencePath",
        ".specbridge/runtime-results",
        "-OutputPath",
        ".specbridge/metrics/missing-runtime-task.autonomy-metrics.json",
        "-Force"
      )) `
      -ExpectedPattern "No runtime summaries found for TaskId"
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
