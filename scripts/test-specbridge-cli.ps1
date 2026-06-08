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

    $statusResult = Invoke-Cli -Arguments @("status")

    Assert-Success `
      -Name "status" `
      -Result $statusResult `
      -ExpectedPattern '"command"\s*:\s*"status"'

    if ($statusResult.ExitCode -eq 0) {
      $statusJson = $null
      try { $statusJson = $statusResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $statusJson) {
        Write-Output "FAIL status output was not valid JSON for detail inspection."
        $script:failed = $true
      }
      else {
        foreach ($fieldCheck in @(
          [pscustomobject]@{ Field = "ok"; Expected = $true },
          [pscustomobject]@{ Field = "repository"; Expected = "specbridge" },
          [pscustomobject]@{ Field = "current_goal_path"; Expected = ".specbridge/context/CURRENT_GOAL.md" }
        )) {
          $actual = $statusJson.($fieldCheck.Field)
          if ($actual -ne $fieldCheck.Expected) {
            Write-Output "FAIL status field $($fieldCheck.Field) expected '$($fieldCheck.Expected)' got '$actual'."
            $script:failed = $true
          }
          else {
            Write-Output "PASS status field $($fieldCheck.Field) is $($fieldCheck.Expected)."
          }
        }

        if (-not $statusJson.PSObject.Properties.Name.Contains("default_mode")) {
          Write-Output "FAIL status missing default_mode field."
          $script:failed = $true
        }
        else {
          Write-Output "PASS status includes default_mode field."
        }

        $countsFields = @("contracts", "scopes", "reports", "audit_packets", "chatgpt_audits", "runtime_launches", "runtime_preflights", "runtime_results", "runtime_summaries", "runtime_runs", "runtime_executions")
        $missingCountFields = $countsFields | Where-Object { -not $statusJson.counts.PSObject.Properties.Name.Contains($_) }
        if ($missingCountFields.Count -gt 0) {
          Write-Output "FAIL status counts missing fields: $($missingCountFields -join ', ')."
          $script:failed = $true
        }
        else {
          Write-Output "PASS status counts includes all expected fields."
        }
      }
    }

    $statusLatestResult = Invoke-Cli -Arguments @("status", "-IncludeLatestArtifacts")

    Assert-Success `
      -Name "status-latest-artifacts" `
      -Result $statusLatestResult `
      -ExpectedPattern '"latest_artifacts"'

    if ($statusLatestResult.ExitCode -eq 0) {
      $statusLatestJson = $null
      try { $statusLatestJson = $statusLatestResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $statusLatestJson) {
        Write-Output "FAIL status -IncludeLatestArtifacts output was not valid JSON for detail inspection."
        $script:failed = $true
      }
      else {
        $artifactFields = @("contract", "scope", "final_report", "audit_packet", "chatgpt_audit", "runtime_launch", "runtime_preflight", "runtime_result", "runtime_summary", "runtime_run", "runtime_execution")
        $missingArtifactFields = $artifactFields | Where-Object { -not $statusLatestJson.latest_artifacts.PSObject.Properties.Name.Contains($_) }
        if ($missingArtifactFields.Count -gt 0) {
          Write-Output "FAIL status latest_artifacts missing fields: $($missingArtifactFields -join ', ')."
          $script:failed = $true
        }
        else {
          Write-Output "PASS status latest_artifacts includes all expected fields."
        }
      }
    }

    $boundedLivePilotStatusResult = Invoke-Cli -Arguments @("bounded-live-pilot-status")

    Assert-Success `
      -Name "bounded-live-pilot-status" `
      -Result $boundedLivePilotStatusResult `
      -ExpectedPattern '"pilot_id"\s*:\s*"issue-097-multi-slice-live-pilot"'

    if ($boundedLivePilotStatusResult.ExitCode -eq 0) {
      $boundedLivePilotStatusJson = $null
      try { $boundedLivePilotStatusJson = $boundedLivePilotStatusResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $boundedLivePilotStatusJson) {
        Write-Output "FAIL bounded-live-pilot-status output was not valid JSON for detail inspection."
        $script:failed = $true
      }
      else {
        foreach ($slice in @("docs", "status", "tests")) {
          if (-not $boundedLivePilotStatusJson.prepared_launch_plans.$slice.exists) {
            Write-Output "FAIL bounded-live-pilot-status missing prepared launch plan for slice: $slice."
            $script:failed = $true
          }
          else {
            Write-Output "PASS bounded-live-pilot-status prepared launch plan exists for slice: $slice."
          }
        }

        if ($boundedLivePilotStatusJson.executor_evidence_count -lt 1) {
          Write-Output "FAIL bounded-live-pilot-status executor_evidence_count expected at least 1."
          $script:failed = $true
        }
        else {
          Write-Output "PASS bounded-live-pilot-status executor_evidence_count is populated."
        }
      }
    }

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

    $issueToMergePlanResult = Invoke-Cli -Arguments @(
      "issue-to-merge-plan",
      "-TaskId",
      "issue-109-governed-issue-to-merge-operator",
      "-RelatedIssue",
      "https://github.com/yagooyarzabaldev-ops/specbridge/issues/109"
    )

    Assert-Success `
      -Name "issue-to-merge-plan" `
      -Result $issueToMergePlanResult `
      -ExpectedPattern '"command"\s*:\s*"issue-to-merge-plan"'

    if ($issueToMergePlanResult.ExitCode -eq 0) {
      $issueToMergePlanJson = $null
      try { $issueToMergePlanJson = $issueToMergePlanResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $issueToMergePlanJson) {
        Write-Output "FAIL issue-to-merge-plan output was not valid JSON."
        $script:failed = $true
      }
      elseif ($issueToMergePlanJson.mode -ne "plan_only") {
        Write-Output "FAIL issue-to-merge-plan expected plan_only mode."
        $script:failed = $true
      }
      elseif (@($issueToMergePlanJson.phases).Count -lt 7) {
        Write-Output "FAIL issue-to-merge-plan expected at least 7 phases."
        $script:failed = $true
      }
      elseif ($issueToMergePlanJson.evidence_paths.issue_to_merge_run -ne ".specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json") {
        Write-Output "FAIL issue-to-merge-plan has unexpected issue-to-merge run path."
        $script:failed = $true
      }
      elseif ($issueToMergePlanJson.command_boundary -notmatch "does-not-open-prs") {
        Write-Output "FAIL issue-to-merge-plan command boundary did not record no PR mutation."
        $script:failed = $true
      }
      else {
        Write-Output "PASS issue-to-merge-plan includes plan-only gates, paths, and boundaries."
      }
    }

    Assert-Success `
      -Name "issue-to-merge-plan-output-path" `
      -Result (Invoke-Cli -Arguments @(
        "issue-to-merge-plan",
        "-TaskId",
        "cli-fixture",
        "-RelatedIssue",
        "https://github.com/yagooyarzabaldev-ops/specbridge/issues/999",
        "-OutputPath",
        ".specbridge/issue-to-merge-runs/cli-fixture.issue-to-merge-run.json",
        "-Force"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/issue-to-merge-runs/cli-fixture\.issue-to-merge-run\.json"'

    if (-not (Test-Path -LiteralPath ".specbridge/issue-to-merge-runs/cli-fixture.issue-to-merge-run.json" -PathType Leaf)) {
      Write-Output "FAIL issue-to-merge-plan did not write the requested output path."
      $script:failed = $true
    }
    else {
      try {
        $issueToMergeRun = Get-Content -LiteralPath ".specbridge/issue-to-merge-runs/cli-fixture.issue-to-merge-run.json" -Raw | ConvertFrom-Json

        if ($issueToMergeRun.command -ne "issue-to-merge-plan" -or $issueToMergeRun.task_id -ne "cli-fixture") {
          Write-Output "FAIL issue-to-merge-plan output artifact has unexpected content."
          $script:failed = $true
        }
        elseif ($issueToMergeRun.recommended_branch -ne "codex/cli-fixture") {
          Write-Output "FAIL issue-to-merge-plan output artifact has unexpected branch."
          $script:failed = $true
        }
        elseif (-not $issueToMergeRun.post_merge_memory_closure.required) {
          Write-Output "FAIL issue-to-merge-plan output artifact does not require post-merge memory closure."
          $script:failed = $true
        }
        else {
          Write-Output "PASS issue-to-merge-plan output artifact validates by inspection."
        }
      }
      catch {
        Write-Output "FAIL issue-to-merge-plan output artifact is not valid JSON."
        Write-Output $_.Exception.Message
        $script:failed = $true
      }
    }

    $issueToMergeGithubResult = Invoke-Cli -Arguments @(
      "issue-to-merge-github",
      "-TaskId",
      "issue-113-bounded-github-mutation-operator",
      "-RelatedIssue",
      "https://github.com/yagooyarzabaldev-ops/specbridge/issues/113"
    )

    Assert-Success `
      -Name "issue-to-merge-github" `
      -Result $issueToMergeGithubResult `
      -ExpectedPattern '"command"\s*:\s*"issue-to-merge-github"'

    if ($issueToMergeGithubResult.ExitCode -eq 0) {
      $issueToMergeGithubJson = $null
      try { $issueToMergeGithubJson = $issueToMergeGithubResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $issueToMergeGithubJson) {
        Write-Output "FAIL issue-to-merge-github output was not valid JSON."
        $script:failed = $true
      }
      elseif ($issueToMergeGithubJson.mutation_mode -ne "dry_run") {
        Write-Output "FAIL issue-to-merge-github expected dry_run mode."
        $script:failed = $true
      }
      elseif ($issueToMergeGithubJson.github_calls_performed -ne $false) {
        Write-Output "FAIL issue-to-merge-github dry-run must not perform GitHub calls."
        $script:failed = $true
      }
      elseif (@($issueToMergeGithubJson.operations).Count -lt 6) {
        Write-Output "FAIL issue-to-merge-github expected the default GitHub operation set."
        $script:failed = $true
      }
      elseif ($issueToMergeGithubJson.command_boundary -notmatch "apply-requires-force-confirmation-and-evidence") {
        Write-Output "FAIL issue-to-merge-github command boundary did not record apply gates."
        $script:failed = $true
      }
      else {
        Write-Output "PASS issue-to-merge-github includes dry-run mutation gates and boundaries."
      }
    }

    Assert-Success `
      -Name "issue-to-merge-github-output-path" `
      -Result (Invoke-Cli -Arguments @(
        "issue-to-merge-github",
        "-TaskId",
        "cli-fixture",
        "-RelatedIssue",
        "https://github.com/yagooyarzabaldev-ops/specbridge/issues/999",
        "-GithubOperation",
        "pr_open",
        "-OutputPath",
        ".specbridge/issue-to-merge-runs/cli-fixture.github-mutation-run.json",
        "-Force"
      )) `
      -ExpectedPattern '"output_path"\s*:\s*"\.specbridge/issue-to-merge-runs/cli-fixture\.github-mutation-run\.json"'

    if (-not (Test-Path -LiteralPath ".specbridge/issue-to-merge-runs/cli-fixture.github-mutation-run.json" -PathType Leaf)) {
      Write-Output "FAIL issue-to-merge-github did not write the requested output path."
      $script:failed = $true
    }
    else {
      try {
        $issueToMergeGithubRun = Get-Content -LiteralPath ".specbridge/issue-to-merge-runs/cli-fixture.github-mutation-run.json" -Raw | ConvertFrom-Json

        if ($issueToMergeGithubRun.command -ne "issue-to-merge-github" -or $issueToMergeGithubRun.task_id -ne "cli-fixture") {
          Write-Output "FAIL issue-to-merge-github output artifact has unexpected content."
          $script:failed = $true
        }
        elseif (@($issueToMergeGithubRun.operations).Count -ne 1 -or $issueToMergeGithubRun.operations[0].id -ne "pr_open") {
          Write-Output "FAIL issue-to-merge-github output artifact has unexpected selected operations."
          $script:failed = $true
        }
        elseif ($issueToMergeGithubRun.connector_action_envelope.actions[0] -ne "github.pull_request.open_or_update") {
          Write-Output "FAIL issue-to-merge-github output artifact has unexpected connector action."
          $script:failed = $true
        }
        else {
          Write-Output "PASS issue-to-merge-github output artifact validates by inspection."
        }
      }
      catch {
        Write-Output "FAIL issue-to-merge-github output artifact is not valid JSON."
        Write-Output $_.Exception.Message
        $script:failed = $true
      }
    }

    $fullLoopDryRunResult = Invoke-Cli -Arguments @(
      "issue-to-merge-github",
      "-TaskId",
      "issue-127-full-loop-test",
      "-Title",
      "Full End-to-End Apply-Mode Loop Test",
      "-RelatedIssue",
      "https://github.com/yagooyarzabaldev-ops/specbridge/issues/127",
      "-OutputPath",
      ".specbridge/issue-to-merge-runs/issue-127-full-loop-test.github-mutation-run.json",
      "-Force"
    )

    Assert-Success `
      -Name "issue-to-merge-github-full-loop-dry-run" `
      -Result $fullLoopDryRunResult `
      -ExpectedPattern '"command"\s*:\s*"issue-to-merge-github"'

    if ($fullLoopDryRunResult.ExitCode -eq 0) {
      try {
        $fullLoopRun = Get-Content -LiteralPath ".specbridge/issue-to-merge-runs/issue-127-full-loop-test.github-mutation-run.json" -Raw | ConvertFrom-Json
        if ($fullLoopRun.dry_run -ne $true) {
          Write-Output "FAIL issue-to-merge-github-full-loop-dry-run: expected dry_run=true"
          $script:failed = $true
        } elseif ($fullLoopRun.github_calls_performed -ne $false) {
          Write-Output "FAIL issue-to-merge-github-full-loop-dry-run: expected github_calls_performed=false"
          $script:failed = $true
        } elseif (@($fullLoopRun.operations).Count -ne 6) {
          Write-Output "FAIL issue-to-merge-github-full-loop-dry-run: expected 6 default operations, got $(@($fullLoopRun.operations).Count)"
          $script:failed = $true
        } elseif (@($fullLoopRun.connector_action_envelope.actions).Count -ne 6) {
          Write-Output "FAIL issue-to-merge-github-full-loop-dry-run: expected 6 connector actions in envelope"
          $script:failed = $true
        } else {
          Write-Output "PASS issue-to-merge-github-full-loop-dry-run: full loop dry-run produces 6 operations and connector envelope"
        }
      } catch {
        Write-Output "FAIL issue-to-merge-github-full-loop-dry-run: output artifact is not valid JSON"
        $script:failed = $true
      }
    }

    # specbridge-doctor
    $doctorResult = Invoke-Cli -Arguments @("specbridge-doctor")
    Assert-Success `
      -Name "specbridge-doctor" `
      -Result $doctorResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-doctor"'
    if ($doctorResult.ExitCode -eq 0) {
      $doctorJson = $null
      try { $doctorJson = $doctorResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -eq $doctorJson) {
        Write-Output "FAIL specbridge-doctor output was not valid JSON."
        $script:failed = $true
      } elseif (-not ($doctorJson.PSObject.Properties.Name -contains "health")) {
        Write-Output "FAIL specbridge-doctor missing 'health' field."
        $script:failed = $true
      } elseif (-not ($doctorJson.PSObject.Properties.Name -contains "blockers")) {
        Write-Output "FAIL specbridge-doctor missing 'blockers' field."
        $script:failed = $true
      } else {
        Write-Output "PASS specbridge-doctor returns health and blockers fields."
      }
    }

    # generate-dashboard
    $dashResult = Invoke-Cli -Arguments @("generate-dashboard")
    Assert-Success `
      -Name "generate-dashboard" `
      -Result $dashResult `
      -ExpectedPattern '"command"\s*:\s*"generate-dashboard"'
    if ($dashResult.ExitCode -eq 0) {
      $dashHtmlPath = Join-Path (Get-Location).Path "docs/status-dashboard.html"
      if (-not (Test-Path $dashHtmlPath)) {
        Write-Output "FAIL generate-dashboard: docs/status-dashboard.html not written."
        $script:failed = $true
      } else {
        $dashHtml = Get-Content $dashHtmlPath -Raw
        if ($dashHtml -notmatch "OPEN LIFECYCLE DEBT") {
          Write-Output "FAIL generate-dashboard: HTML missing 'OPEN LIFECYCLE DEBT' section."
          $script:failed = $true
        } else {
          Write-Output "PASS generate-dashboard: HTML includes OPEN LIFECYCLE DEBT section."
        }
      }
    }

    # lifecycle-guard: verify output structure regardless of exit code (violations may exist in repo state)
    $lgResult = Invoke-Cli -Arguments @("lifecycle-guard")
    if ($lgResult.Text -notmatch '"command"\s*:\s*"lifecycle-guard"') {
      Write-Output "FAIL lifecycle-guard: output missing expected command field."
      $script:failed = $true
    } else {
      $lgJson = $null
      try { $lgJson = $lgResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -eq $lgJson) {
        Write-Output "FAIL lifecycle-guard output was not valid JSON."
        $script:failed = $true
      } elseif (-not ($lgJson.PSObject.Properties.Name -contains "violations")) {
        Write-Output "FAIL lifecycle-guard missing 'violations' field."
        $script:failed = $true
      } elseif (-not ($lgJson.PSObject.Properties.Name -contains "guard")) {
        Write-Output "FAIL lifecycle-guard missing 'guard' field."
        $script:failed = $true
      } else {
        Write-Output "PASS lifecycle-guard returns guard and violations fields (guard=$($lgJson.guard))."
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
      -Name "preflight-runtime-launches" `
      -Result (Invoke-Cli -Arguments @(
        "preflight-runtime-launches",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-RequiredSlice",
        "agent-a-implementation",
        "-AllowedTool",
        "Read,Write",
        "-MaxBudgetUsd",
        "2.00",
        "-OutputPath",
        ".specbridge/preflights/cli-fixture.runtime-preflight.json",
        "-Force"
      )) `
      -ExpectedPattern '"ok"\s*:\s*true'

    $runtimePreflightValidation = & powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-preflights.ps1 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Output "FAIL CLI-created runtime preflight did not validate."
      Write-Output ($runtimePreflightValidation | Out-String)
      $failed = $true
    }
    else {
      Write-Output "PASS CLI-created runtime preflight validates."
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
      -Name "issue-to-merge-plan-missing-task" `
      -Result (Invoke-Cli -Arguments @("issue-to-merge-plan")) `
      -ExpectedPattern "TaskId is required for issue-to-merge-plan"

    Assert-Failure `
      -Name "issue-to-merge-github-missing-task" `
      -Result (Invoke-Cli -Arguments @("issue-to-merge-github")) `
      -ExpectedPattern "TaskId is required for issue-to-merge-github"

    Assert-Failure `
      -Name "issue-to-merge-github-apply-without-force" `
      -Result (Invoke-Cli -Arguments @(
        "issue-to-merge-github",
        "-TaskId",
        "cli-fixture",
        "-MutationMode",
        "apply",
        "-ConfirmGithubMutation"
      )) `
      -ExpectedPattern "apply mode requires -Force"

    Assert-Failure `
      -Name "issue-to-merge-github-apply-without-evidence" `
      -Result (Invoke-Cli -Arguments @(
        "issue-to-merge-github",
        "-TaskId",
        "cli-fixture",
        "-MutationMode",
        "apply",
        "-ConfirmGithubMutation",
        "-Force"
      )) `
      -ExpectedPattern "EvidencePath is required for issue-to-merge-github apply mode"

    $applyBlockedResult = Invoke-Cli -Arguments @(
      "issue-to-merge-github",
      "-TaskId",
      "cli-fixture",
      "-MutationMode",
      "apply",
      "-GithubOperation",
      "issue_close",
      "-Force",
      "-ConfirmGithubMutation",
      "-EvidencePath",
      ".specbridge/github-evidence/cli-fixture-blocked-gates.github-mutation-evidence.json"
    )
    $applyBlockedJson = $null
    try { $applyBlockedJson = $applyBlockedResult.Text | ConvertFrom-Json } catch {}
    if ($applyBlockedResult.ExitCode -ne 0) {
      Write-Output "FAIL issue-to-merge-github-apply-blocked: command should succeed with apply_allowed=false, not fail with exit 1"
    } elseif ($null -eq $applyBlockedJson) {
      Write-Output "FAIL issue-to-merge-github-apply-blocked: output was not valid JSON"
    } elseif ($applyBlockedJson.apply_allowed -ne $false) {
      Write-Output "FAIL issue-to-merge-github-apply-blocked: expected apply_allowed=false"
    } elseif ($applyBlockedJson.github_calls_performed -ne $false) {
      Write-Output "FAIL issue-to-merge-github-apply-blocked: github_calls_performed must be false when gates blocked"
    } elseif ($applyBlockedJson.apply_blockers.Count -eq 0) {
      Write-Output "FAIL issue-to-merge-github-apply-blocked: apply_blockers must be non-empty"
    } else {
      Write-Output "PASS issue-to-merge-github-apply-blocked: apply_allowed=false with blockers, no GitHub call made"
    }

    $applyUnsupportedResult = Invoke-Cli -Arguments @(
      "issue-to-merge-github",
      "-TaskId",
      "cli-fixture",
      "-MutationMode",
      "apply",
      "-GithubOperation",
      "issue_create",
      "-Force",
      "-ConfirmGithubMutation",
      "-EvidencePath",
      ".specbridge/github-evidence/cli-fixture-blocked-gates.github-mutation-evidence.json"
    )
    $applyUnsupportedJson = $null
    try { $applyUnsupportedJson = $applyUnsupportedResult.Text | ConvertFrom-Json } catch {}
    if ($null -eq $applyUnsupportedJson) {
      Write-Output "FAIL issue-to-merge-github-apply-unsupported-op: output was not valid JSON"
    } elseif ($applyUnsupportedJson.command_boundary -notmatch "apply-pilot-supports-all-six-operations") {
      Write-Output "FAIL issue-to-merge-github-apply-unsupported-op: command_boundary must declare pilot scope"
    } else {
      Write-Output "PASS issue-to-merge-github-apply-unsupported-op: command_boundary records apply pilot scope"
    }

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

    $overlapLaunch = Get-Content -LiteralPath ".specbridge/runtime-launches/cli-fixture.runtime-launch.json" -Raw | ConvertFrom-Json
    $overlapLaunch.launch_id = "cli-overlap-runtime-launch"
    $overlapLaunch.packet_id = "cli-overlap"
    $overlapLaunch.slice_id = "agent-a-overlap"
    $overlapLaunch.branch_name = "claude/cli-overlap"
    Set-Content `
      -LiteralPath ".specbridge/runtime-launches/cli-overlap.runtime-launch.json" `
      -Value ($overlapLaunch | ConvertTo-Json -Depth 10) `
      -NoNewline

    Assert-Failure `
      -Name "preflight-runtime-launches-overlap" `
      -Result (Invoke-Cli -Arguments @(
        "preflight-runtime-launches",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json,.specbridge/runtime-launches/cli-overlap.runtime-launch.json",
        "-RequiredSlice",
        "agent-a-implementation,agent-a-overlap",
        "-AllowedTool",
        "Read,Write",
        "-MaxBudgetUsd",
        "2.00"
      )) `
      -ExpectedPattern "exclusive_write overlap"

    $overBudgetLaunch = Get-Content -LiteralPath ".specbridge/runtime-launches/cli-fixture.runtime-launch.json" -Raw | ConvertFrom-Json
    $overBudgetLaunch.launch_id = "cli-over-budget-runtime-launch"
    $overBudgetLaunch.packet_id = "cli-over-budget"
    $overBudgetLaunch.slice_id = "agent-a-over-budget"
    $overBudgetLaunch.branch_name = "claude/cli-over-budget"
    $overBudgetLaunch.max_budget_usd = "5.00"
    $overBudgetLaunch.exclusive_write = @(".specbridge/runtime-evidence/cli-over-budget.executor-output.md")
    Set-Content `
      -LiteralPath ".specbridge/runtime-launches/cli-over-budget.runtime-launch.json" `
      -Value ($overBudgetLaunch | ConvertTo-Json -Depth 10) `
      -NoNewline

    Assert-Failure `
      -Name "preflight-runtime-launches-over-budget" `
      -Result (Invoke-Cli -Arguments @(
        "preflight-runtime-launches",
        "-InputPath",
        ".specbridge/runtime-launches/cli-over-budget.runtime-launch.json",
        "-RequiredSlice",
        "agent-a-over-budget",
        "-AllowedTool",
        "Read,Write",
        "-MaxBudgetUsd",
        "2.00"
      )) `
      -ExpectedPattern "max_budget_usd exceeds preflight limit"

    $unsafePolicyLaunch = Get-Content -LiteralPath ".specbridge/runtime-launches/cli-fixture.runtime-launch.json" -Raw | ConvertFrom-Json
    $unsafePolicyLaunch.launch_id = "cli-unsafe-policy-runtime-launch"
    $unsafePolicyLaunch.packet_id = "cli-unsafe-policy"
    $unsafePolicyLaunch.slice_id = "agent-a-unsafe-policy"
    $unsafePolicyLaunch.branch_name = "claude/cli-unsafe-policy"
    $unsafePolicyLaunch.exclusive_write = @(".specbridge/runtime-evidence/cli-unsafe-policy.executor-output.md")
    $unsafePolicyLaunch.execution_policy.executes_shell = $true
    Set-Content `
      -LiteralPath ".specbridge/runtime-launches/cli-unsafe-policy.runtime-launch.json" `
      -Value ($unsafePolicyLaunch | ConvertTo-Json -Depth 10) `
      -NoNewline

    Assert-Failure `
      -Name "preflight-runtime-launches-unsafe-policy" `
      -Result (Invoke-Cli -Arguments @(
        "preflight-runtime-launches",
        "-InputPath",
        ".specbridge/runtime-launches/cli-unsafe-policy.runtime-launch.json",
        "-RequiredSlice",
        "agent-a-unsafe-policy",
        "-AllowedTool",
        "Read,Write",
        "-MaxBudgetUsd",
        "2.00"
      )) `
      -ExpectedPattern "execution_policy.executes_shell must be false"

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
