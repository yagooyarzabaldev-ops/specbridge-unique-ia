$ErrorActionPreference = "Stop"

Write-Output "SpecBridge branch orchestration tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-branch-orchestration-" + [guid]::NewGuid().ToString("N"))
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
    Write-Output "FAIL branch orchestration command failed unexpectedly: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if (-not [string]::IsNullOrWhiteSpace($ExpectedPattern) -and $Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL branch orchestration output did not match expected pattern: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS branch orchestration command: $Name"
}

function Assert-Failure {
  param(
    [string] $Name,
    [object] $Result,
    [string] $ExpectedPattern
  )

  if ($Result.ExitCode -eq 0) {
    Write-Output "FAIL branch orchestration command did not fail: $Name"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  if ($Result.Text -notmatch $ExpectedPattern) {
    Write-Output "FAIL branch orchestration command failed for unexpected reason: $Name"
    Write-Output "Expected pattern: $ExpectedPattern"
    Write-Output $Result.Text
    $script:failed = $true
    return
  }

  Write-Output "PASS branch orchestration failure: $Name"
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $caseDir = Join-Path $tempRoot "branch-orchestration"
  Copy-RepoFixture -Destination $caseDir

  Push-Location $caseDir
  try {
    $planInputDir = ".specbridge/executor-packets/branch-plan-fixture"
    New-Item -ItemType Directory -Force -Path $planInputDir | Out-Null
    Get-ChildItem -LiteralPath ".specbridge/executor-packets" -Filter "issue-058-live-antigravity-executor-handoff-*.executor-packet.json" -File |
      Copy-Item -Destination $planInputDir -Force

    Assert-Success `
      -Name "plan-executor-branches" `
      -Result (Invoke-Cli -Arguments @(
        "plan-executor-branches",
        "-InputPath",
        $planInputDir,
        "-OutputPath",
        ".specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json",
        "-Force"
      )) `
      -ExpectedPattern '"branch_count"\s*:\s*3'

    Assert-Success `
      -Name "coordinate-executors-simulation" `
      -Result (Invoke-Cli -Arguments @(
        "coordinate-executors",
        "-InputPath",
        ".specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json",
        "-OutputPath",
        ".specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json",
        "-EvidenceMode",
        "simulation",
        "-Force"
      )) `
      -ExpectedPattern '"integration_decision"\s*:\s*"simulation_only_no_merge"'

    $validation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-branch-orchestrations.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL branch orchestration artifacts did not validate."
      Write-Output ($validation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS branch orchestration artifacts validate."
    }

    $orchestration = Get-Content -LiteralPath ".specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json" -Raw | ConvertFrom-Json
    $mergeAllowedChildren = @($orchestration.child_results | Where-Object { $_.merge_allowed -eq $true })

    if ($mergeAllowedChildren.Count -gt 0) {
      Write-Output "FAIL simulation evidence must not allow child merge."
      $failed = $true
    }
    else {
      Write-Output "PASS simulation evidence blocks merge authorization."
    }

    New-Item -ItemType Directory -Force -Path ".specbridge/github-evidence" | Out-Null

    $githubEvidence = [ordered]@{
      schema_version = "1"
      task_id = "issue-060-controlled-github-evidence-run"
      generated_by = "specbridge-test"
      source_branch_plan_path = ".specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json"
      child_prs = @(
        [ordered]@{
          packet_id = "issue-058-live-antigravity-executor-handoff-agent-a-implementation"
          branch_name = "claude/issue-058-live-antigravity-executor-handoff-agent-a-implementation"
          pr_url = "https://github.com/yagooyarzabaldev-ops/specbridge/pull/1001"
          pr_status = "open"
          ci_status = "passed"
          chatgpt_audit_status = "approved"
        },
        [ordered]@{
          packet_id = "issue-058-live-antigravity-executor-handoff-agent-b-tests"
          branch_name = "claude/issue-058-live-antigravity-executor-handoff-agent-b-tests"
          pr_url = "https://github.com/yagooyarzabaldev-ops/specbridge/pull/1002"
          pr_status = "open"
          ci_status = "passed"
          chatgpt_audit_status = "approved"
        },
        [ordered]@{
          packet_id = "issue-058-live-antigravity-executor-handoff-agent-c-documentation"
          branch_name = "claude/issue-058-live-antigravity-executor-handoff-agent-c-documentation"
          pr_url = "https://github.com/yagooyarzabaldev-ops/specbridge/pull/1003"
          pr_status = "open"
          ci_status = "passed"
          chatgpt_audit_status = "approved"
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/github-evidence/issue-060-fixture.input.json" `
      -Value ($githubEvidence | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Success `
      -Name "record-github-evidence" `
      -Result (Invoke-Cli -Arguments @(
        "record-github-evidence",
        "-InputPath",
        ".specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json",
        "-EvidencePath",
        ".specbridge/github-evidence/issue-060-fixture.input.json",
        "-OutputPath",
        ".specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json",
        "-Force"
      )) `
      -ExpectedPattern '"child_count"\s*:\s*3'

    Assert-Success `
      -Name "coordinate-executors-github" `
      -Result (Invoke-Cli -Arguments @(
        "coordinate-executors",
        "-InputPath",
        ".specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json",
        "-OutputPath",
        ".specbridge/orchestrations/issue-060-controlled-github-evidence-run.executor-orchestration.json",
        "-EvidenceMode",
        "github",
        "-Force"
      )) `
      -ExpectedPattern '"integration_decision"\s*:\s*"ready_for_integration"'

    $githubValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-branch-orchestrations.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL github evidence branch orchestration artifacts did not validate."
      Write-Output ($githubValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS github evidence branch orchestration artifacts validate."
    }

    $invalidEvidence = [ordered]@{
      task_id = "issue-060-invalid-github-evidence"
      child_prs = @(
        [ordered]@{
          packet_id = "issue-058-live-antigravity-executor-handoff-agent-a-implementation"
          branch_name = "claude/issue-058-live-antigravity-executor-handoff-agent-a-implementation"
          pr_url = "simulation://pull-requests/agent-a"
          pr_status = "open"
          ci_status = "passed"
          chatgpt_audit_status = "approved"
        }
      )
    }

    Set-Content `
      -LiteralPath ".specbridge/github-evidence/issue-060-invalid-input.json" `
      -Value ($invalidEvidence | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Failure `
      -Name "record-github-evidence-rejects-simulation-url" `
      -Result (Invoke-Cli -Arguments @(
        "record-github-evidence",
        "-InputPath",
        ".specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json",
        "-EvidencePath",
        ".specbridge/github-evidence/issue-060-invalid-input.json",
        "-OutputPath",
        ".specbridge/branch-plans/invalid.branch-plan.json",
        "-Force"
      )) `
      -ExpectedPattern "GitHub evidence pr_url must use a GitHub pull request URL"

    $conflictDir = ".specbridge/executor-packets/branch-conflict-fixture"
    New-Item -ItemType Directory -Force -Path $conflictDir | Out-Null
    $sourcePackets = @(Get-ChildItem -LiteralPath ".specbridge/executor-packets" -Filter "issue-058-live-antigravity-executor-handoff-*.executor-packet.json" -File | Sort-Object Name | Select-Object -First 2)
    $firstPacket = Get-Content -LiteralPath $sourcePackets[0].FullName -Raw | ConvertFrom-Json
    $secondPacket = Get-Content -LiteralPath $sourcePackets[1].FullName -Raw | ConvertFrom-Json
    $secondPacket.branch_name = $firstPacket.branch_name

    Set-Content `
      -LiteralPath (Join-Path $conflictDir "first.executor-packet.json") `
      -Value ($firstPacket | ConvertTo-Json -Depth 8) `
      -NoNewline

    Set-Content `
      -LiteralPath (Join-Path $conflictDir "second.executor-packet.json") `
      -Value ($secondPacket | ConvertTo-Json -Depth 8) `
      -NoNewline

    Assert-Failure `
      -Name "plan-executor-branches-duplicate-branch" `
      -Result (Invoke-Cli -Arguments @(
        "plan-executor-branches",
        "-InputPath",
        $conflictDir,
        "-OutputPath",
        ".specbridge/branch-plans/conflict.branch-plan.json",
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
  Write-Output "SpecBridge branch orchestration tests failed."
  exit 1
}

Write-Output "SpecBridge branch orchestration tests passed."
exit 0
