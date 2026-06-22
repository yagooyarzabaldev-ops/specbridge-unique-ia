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

function Get-WorkingTreePorcelain {
  $previousXdgConfigHome = $env:XDG_CONFIG_HOME
  $gitConfigHome = Join-Path $tempRoot "git-config"
  New-Item -ItemType Directory -Force -Path $gitConfigHome | Out-Null
  $env:XDG_CONFIG_HOME = $gitConfigHome

  try {
    return (& git status --porcelain 2>$null | Out-String)
  }
  finally {
    $env:XDG_CONFIG_HOME = $previousXdgConfigHome
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

    # generate-studio-dashboard
    $studioResult = Invoke-Cli -Arguments @("generate-studio-dashboard")
    Assert-Success `
      -Name "generate-studio-dashboard" `
      -Result $studioResult `
      -ExpectedPattern '"command"\s*:\s*"generate-studio-dashboard"'
    if ($studioResult.ExitCode -eq 0) {
      $studioHtmlPath = Join-Path (Get-Location).Path "docs/specbridge-studio.html"
      if (-not (Test-Path $studioHtmlPath)) {
        Write-Output "FAIL generate-studio-dashboard: docs/specbridge-studio.html not written."
        $script:failed = $true
      } else {
        $studioHtml = Get-Content $studioHtmlPath -Raw -Encoding UTF8
        $studioChecks = @(
          @{ pattern = "SpecBridge Studio";                 label = "title present" },
          @{ pattern = "Current Goal";                      label = "current-goal section present" },
          @{ pattern = "Fix-Plan Alerts";                   label = "fix-plan section present" },
          @{ pattern = "Operator Queue";                    label = "operator queue section present" },
          @{ pattern = "Eligible tasks:";                   label = "operator queue eligible count present" },
          @{ pattern = "#194";                              label = "operator queue excluded issue present" },
          @{ pattern = "not_planned";                       label = "operator queue decision present" },
          @{ pattern = "Recommended action:";               label = "operator queue recommendation present" },
          @{ pattern = "Runs \(";                           label = "runs section present" },
          @{ pattern = "Scopes \(";                         label = "scopes section present" },
          @{ pattern = "generate-studio-dashboard";         label = "footer command label present" }
        )
        foreach ($chk in $studioChecks) {
          if ($studioHtml -notmatch $chk.pattern) {
            Write-Output "FAIL generate-studio-dashboard: HTML missing $($chk.label)."
            $script:failed = $true
          } else {
            Write-Output "PASS generate-studio-dashboard: $($chk.label)."
          }
        }
        if ($studioHtml -match "Operator queue state unavailable") {
          Write-Output "FAIL generate-studio-dashboard: Operator Queue fell back to unavailable state."
          $script:failed = $true
        } else {
          Write-Output "PASS generate-studio-dashboard: Operator Queue rendered from queue state."
        }
        # JSON output must include key fields
        try {
          $studioJson = $studioResult.Text | ConvertFrom-Json
          $missingFields = @("command","output","current_goal","runs","active_scopes","completed_scopes","fix_plan_actions") |
            Where-Object { $null -eq $studioJson.$_ -and $studioJson.$_ -ne 0 }
          if ($missingFields.Count -gt 0) {
            Write-Output "FAIL generate-studio-dashboard: JSON missing fields: $($missingFields -join ', ')."
            $script:failed = $true
          } else {
            Write-Output "PASS generate-studio-dashboard: JSON output has all required fields."
          }
        } catch {
          Write-Output "FAIL generate-studio-dashboard: JSON output not parseable."
          $script:failed = $true
        }
      }
    }

    # specbridge-orchestrate
    $orchTaskId = "orch-test-$(Get-Date -Format 'HHmmss')"
    $orchResult = Invoke-Cli -Arguments @("specbridge-orchestrate", "-TaskId", $orchTaskId)
    Assert-Success `
      -Name "specbridge-orchestrate" `
      -Result $orchResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-orchestrate"'
    if ($orchResult.ExitCode -eq 0) {
      $orchArtifactPath = Join-Path (Get-Location).Path ".specbridge/orchestrations/$orchTaskId.orchestration.json"
      if (-not (Test-Path $orchArtifactPath)) {
        Write-Output "FAIL specbridge-orchestrate: orchestration artifact not written."
        $script:failed = $true
      } else {
        try {
          $orchJson = Get-Content $orchArtifactPath -Raw | ConvertFrom-Json
          # Required fields
          $orchMissing = @("schema_version","task_id","run_id","coordinator","created_at","status","agents") |
            Where-Object { $null -eq $orchJson.$_ }
          if ($orchMissing.Count -gt 0) {
            Write-Output "FAIL specbridge-orchestrate: artifact missing fields: $($orchMissing -join ', ')."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-orchestrate: artifact has all required fields."
          }
          # All 7 agents present
          $expectedAgents = @("planner","implementer","reviewer","tester","security","docs","closure")
          $actualAgents   = @($orchJson.agents | ForEach-Object { $_.name })
          $missingAgents  = $expectedAgents | Where-Object { $actualAgents -notcontains $_ }
          if ($missingAgents.Count -gt 0) {
            Write-Output "FAIL specbridge-orchestrate: missing agents: $($missingAgents -join ', ')."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-orchestrate: all 7 agent roles present."
          }
          # run_id format
          if ($orchJson.run_id -notmatch "^sb-\d{8}-[a-f0-9]{8}$") {
            Write-Output "FAIL specbridge-orchestrate: run_id '$($orchJson.run_id)' does not match expected format."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-orchestrate: run_id format valid."
          }
          # status = planned
          if ($orchJson.status -ne "planned") {
            Write-Output "FAIL specbridge-orchestrate: expected status=planned, got '$($orchJson.status)'."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-orchestrate: status=planned."
          }
        } catch {
          Write-Output "FAIL specbridge-orchestrate: artifact not valid JSON."
          $script:failed = $true
        } finally {
          Remove-Item $orchArtifactPath -Force -ErrorAction SilentlyContinue
        }
      }
    }

    # specbridge-orchestrate: validate-orchestrations passes on a generated artifact
    $orchValTaskId = "orch-val-$(Get-Date -Format 'HHmmss')"
    $orchValResult = Invoke-Cli -Arguments @("specbridge-orchestrate", "-TaskId", $orchValTaskId)
    if ($orchValResult.ExitCode -eq 0) {
      $valResult2 = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-orchestrations.ps1 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Output "PASS specbridge-orchestrate: validate-orchestrations passes on generated artifact."
      } else {
        Write-Output "FAIL specbridge-orchestrate: validate-orchestrations failed on generated artifact."
        $script:failed = $true
      }
      Remove-Item ".specbridge/orchestrations/$orchValTaskId.orchestration.json" -Force -ErrorAction SilentlyContinue
    }

    # specbridge-orchestrate: fails without -TaskId
    $orchNoTaskResult = Invoke-Cli -Arguments @("specbridge-orchestrate")
    if ($orchNoTaskResult.ExitCode -ne 0) {
      Write-Output "PASS CLI failure: specbridge-orchestrate-missing-task-id"
    } else {
      Write-Output "FAIL specbridge-orchestrate-missing-task-id: expected failure without -TaskId."
      $script:failed = $true
    }

    # specbridge-handoff: full sequential protocol on a fixture orchestration
    $hoTaskId = "handoff-test-$(Get-Date -Format 'HHmmss')"
    $hoOrch = Invoke-Cli -Arguments @("specbridge-orchestrate", "-TaskId", $hoTaskId)
    if ($hoOrch.ExitCode -ne 0) {
      Write-Output "FAIL specbridge-handoff: setup orchestrate failed."
      $script:failed = $true
    } else {
      $hoPlanner = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "planner", "-Summary", "fixture planner summary")
      Assert-Success `
        -Name "specbridge-handoff planner" `
        -Result $hoPlanner `
        -ExpectedPattern '"orchestration_status"\s*:\s*"in_progress"'

      $hoPlannerOut = ".specbridge/orchestrations/$hoTaskId/planner-output.json"
      if (-not (Test-Path $hoPlannerOut)) {
        Write-Output "FAIL specbridge-handoff: planner output artifact not written."
        $script:failed = $true
      } else {
        try {
          $hoPoJson = Get-Content $hoPlannerOut -Raw -Encoding UTF8 | ConvertFrom-Json
          if ($hoPoJson.agent -ne "planner" -or $hoPoJson.status -ne "completed" -or $hoPoJson.task_id -ne $hoTaskId -or $hoPoJson.summary -ne "fixture planner summary") {
            Write-Output "FAIL specbridge-handoff: planner output artifact has unexpected content."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-handoff: planner output artifact content valid."
          }
        } catch {
          Write-Output "FAIL specbridge-handoff: planner output artifact not valid JSON."
          $script:failed = $true
        }
      }

      try {
        $hoManifest = Get-Content ".specbridge/orchestrations/$hoTaskId.orchestration.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $hoAgents = @($hoManifest.agents)
        $hoPlannerEntry = $hoAgents | Where-Object { $_.name -eq "planner" }
        $hoImplEntry = $hoAgents | Where-Object { $_.name -eq "implementer" }
        if ($hoPlannerEntry.status -ne "completed" -or $hoImplEntry.status -ne "active" -or $hoManifest.status -ne "in_progress") {
          Write-Output "FAIL specbridge-handoff: manifest did not advance (planner=$($hoPlannerEntry.status), implementer=$($hoImplEntry.status), status=$($hoManifest.status))."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-handoff: manifest advanced planner->implementer, status=in_progress."
        }
      } catch {
        Write-Output "FAIL specbridge-handoff: manifest not readable after handoff."
        $script:failed = $true
      }

      $hoOutOfOrder = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "tester")
      if ($hoOutOfOrder.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: specbridge-handoff-out-of-order"
      } else {
        Write-Output "FAIL specbridge-handoff-out-of-order: expected failure when skipping agents."
        $script:failed = $true
      }

      $hoRepeat = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "planner")
      if ($hoRepeat.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: specbridge-handoff-repeat-agent"
      } else {
        Write-Output "FAIL specbridge-handoff-repeat-agent: expected failure on repeated handoff."
        $script:failed = $true
      }

      $hoUnknown = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "ghostwriter")
      if ($hoUnknown.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: specbridge-handoff-unknown-agent"
      } else {
        Write-Output "FAIL specbridge-handoff-unknown-agent: expected failure on unknown agent."
        $script:failed = $true
      }

      $hoNoAgent = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId)
      if ($hoNoAgent.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: specbridge-handoff-missing-agent"
      } else {
        Write-Output "FAIL specbridge-handoff-missing-agent: expected failure without -Agent."
        $script:failed = $true
      }

      # Reviewer gate: review-report command and handoff enforcement
      $rrImpl = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "implementer", "-Summary", "fixture implementer summary")
      if ($rrImpl.ExitCode -ne 0) {
        Write-Output "FAIL specbridge-review-report: setup implementer handoff failed."
        $script:failed = $true
      }

      $rrNoReport = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "reviewer")
      if ($rrNoReport.ExitCode -ne 0 -and $rrNoReport.Text -match "requires a review-agent report") {
        Write-Output "PASS CLI failure: reviewer-handoff-without-report"
      } else {
        Write-Output "FAIL reviewer-handoff-without-report: expected failure without a review report."
        $script:failed = $true
      }

      $rrNoVerdict = Invoke-Cli -Arguments @("specbridge-review-report", "-TaskId", $hoTaskId)
      if ($rrNoVerdict.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: review-report-missing-verdict"
      } else {
        Write-Output "FAIL review-report-missing-verdict: expected failure without -Verdict."
        $script:failed = $true
      }

      $rrBadSeverity = Invoke-Cli -Arguments @("specbridge-review-report", "-TaskId", $hoTaskId, "-Verdict", "approve", "-Validation", "catastrophic|file.ps1|bad severity")
      if ($rrBadSeverity.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: review-report-invalid-severity"
      } else {
        Write-Output "FAIL review-report-invalid-severity: expected failure on invalid severity."
        $script:failed = $true
      }

      $rrBlockerApprove = Invoke-Cli -Arguments @("specbridge-review-report", "-TaskId", $hoTaskId, "-Verdict", "approve", "-Validation", "blocker|file.ps1|fixture blocker")
      if ($rrBlockerApprove.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: review-report-blocker-approve-inconsistent"
      } else {
        Write-Output "FAIL review-report-blocker-approve-inconsistent: expected failure."
        $script:failed = $true
      }

      $rrBlock = Invoke-Cli -Arguments @("specbridge-review-report", "-TaskId", $hoTaskId, "-Verdict", "block", "-Validation", "blocker|file.ps1|fixture blocker finding")
      if ($rrBlock.ExitCode -eq 0) {
        $rrBlockedHandoff = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "reviewer")
        if ($rrBlockedHandoff.ExitCode -ne 0 -and $rrBlockedHandoff.Text -match "verdict") {
          Write-Output "PASS CLI failure: reviewer-handoff-blocked-by-verdict"
        } else {
          Write-Output "FAIL reviewer-handoff-blocked-by-verdict: expected failure on block verdict."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL specbridge-review-report: block report generation failed."
        $script:failed = $true
      }

      $rrApprove = Invoke-Cli -Arguments @("specbridge-review-report", "-TaskId", $hoTaskId, "-Verdict", "approve", "-Summary", "fixture approve review", "-Validation", "minor|file.ps1|fixture minor finding")
      Assert-Success `
        -Name "specbridge-review-report approve" `
        -Result $rrApprove `
        -ExpectedPattern '"verdict"\s*:\s*"approve"'

      $rrReviewerOk = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "reviewer", "-Summary", "fixture reviewer summary")
      if ($rrReviewerOk.ExitCode -eq 0) {
        $rrReviewerOut = ".specbridge/orchestrations/$hoTaskId/reviewer-output.json"
        $rrOutJson = $null
        try { $rrOutJson = Get-Content $rrReviewerOut -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
        if ($null -ne $rrOutJson -and $rrOutJson.review_report -eq ".specbridge/agent-reviews/$hoTaskId.review-agent-report.json") {
          Write-Output "PASS specbridge-handoff: reviewer artifact references the review report."
        } else {
          Write-Output "FAIL specbridge-handoff: reviewer artifact does not reference the review report."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL specbridge-handoff: reviewer handoff with approve report failed."
        $script:failed = $true
      }

      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-agent-review-reports.ps1 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Output "PASS validate-agent-review-reports: passes on fixture report."
      } else {
        Write-Output "FAIL validate-agent-review-reports: failed on valid fixture report."
        $script:failed = $true
      }

      $hoLast = $null
      foreach ($hoNext in @("tester", "security", "docs", "closure")) {
        $hoLast = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", $hoNext, "-Summary", "fixture $hoNext summary")
        if ($hoLast.ExitCode -ne 0) {
          Write-Output "FAIL specbridge-handoff: chain handoff for '$hoNext' failed."
          $script:failed = $true
          break
        }
      }
      if ($null -ne $hoLast -and $hoLast.ExitCode -eq 0) {
        if ($hoLast.Text -match '"orchestration_status"\s*:\s*"completed"') {
          Write-Output "PASS specbridge-handoff: full chain completes orchestration."
        } else {
          Write-Output "FAIL specbridge-handoff: final handoff did not complete orchestration."
          $script:failed = $true
        }
      }

      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-orchestrations.ps1 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Output "PASS specbridge-handoff: validate-orchestrations passes on completed chain."
      } else {
        Write-Output "FAIL specbridge-handoff: validate-orchestrations failed on completed chain."
        $script:failed = $true
      }

      $hoAfterDone = Invoke-Cli -Arguments @("specbridge-handoff", "-TaskId", $hoTaskId, "-Agent", "planner")
      if ($hoAfterDone.ExitCode -ne 0) {
        Write-Output "PASS CLI failure: specbridge-handoff-on-completed-orchestration"
      } else {
        Write-Output "FAIL specbridge-handoff-on-completed-orchestration: expected failure."
        $script:failed = $true
      }

      # validator negative: completed agent with deleted output artifact must fail
      Remove-Item $hoPlannerOut -Force -ErrorAction SilentlyContinue
      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-orchestrations.ps1 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Output "PASS validate-orchestrations: detects missing output artifact for completed agent."
      } else {
        Write-Output "FAIL validate-orchestrations: missing output artifact not detected."
        $script:failed = $true
      }

      # validator negative: review report with invalid verdict must fail
      $rrFixturePath = ".specbridge/agent-reviews/$hoTaskId.review-agent-report.json"
      try {
        $rrCorrupt = Get-Content $rrFixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $rrCorrupt.verdict = "maybe"
        Set-Content -Path $rrFixturePath -Value ($rrCorrupt | ConvertTo-Json -Depth 5) -Encoding UTF8
        $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-agent-review-reports.ps1 2>&1
        if ($LASTEXITCODE -ne 0) {
          Write-Output "PASS validate-agent-review-reports: detects invalid verdict."
        } else {
          Write-Output "FAIL validate-agent-review-reports: invalid verdict not detected."
          $script:failed = $true
        }
      } catch {
        Write-Output "FAIL validate-agent-review-reports: could not exercise negative case."
        $script:failed = $true
      }

      Remove-Item $rrFixturePath -Force -ErrorAction SilentlyContinue
      Remove-Item ".specbridge/orchestrations/$hoTaskId.orchestration.json" -Force -ErrorAction SilentlyContinue
      Remove-Item ".specbridge/orchestrations/$hoTaskId" -Recurse -Force -ErrorAction SilentlyContinue
    }

    # specbridge-next-task: offline queue selector
    $ntResult = Invoke-Cli -Arguments @("specbridge-next-task")
    Assert-Success `
      -Name "specbridge-next-task" `
      -Result $ntResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-next-task"'
    if ($ntResult.ExitCode -eq 0) {
      $ntJson = $null
      try { $ntJson = $ntResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -eq $ntJson) {
        Write-Output "FAIL specbridge-next-task: output not valid JSON."
        $script:failed = $true
      } else {
        $ntProps = @($ntJson.PSObject.Properties.Name)
        $ntMissing = @("ok", "current_goal_status", "eligible_tasks", "excluded_issues", "recommended_action") |
          Where-Object { $ntProps -notcontains $_ }
        if ($ntMissing.Count -gt 0) {
          Write-Output "FAIL specbridge-next-task: missing fields: $($ntMissing -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-next-task: all required fields present."
        }
        $ntExcluded = @($ntJson.excluded_issues | Where-Object { $_.issue -eq 194 })
        if ($ntExcluded.Count -eq 1 -and $ntExcluded[0].reason -eq "not_planned") {
          Write-Output "PASS specbridge-next-task: issue 194 excluded as not_planned."
        } else {
          Write-Output "FAIL specbridge-next-task: issue 194 not reported as excluded not_planned."
          $script:failed = $true
        }
        if (@("continue_current_goal", "execute_eligible_task", "create_new_operator_task") -contains $ntJson.recommended_action) {
          Write-Output "PASS specbridge-next-task: recommended_action within enum."
        } else {
          Write-Output "FAIL specbridge-next-task: unexpected recommended_action '$($ntJson.recommended_action)'."
          $script:failed = $true
        }
      }

      # read-only guarantee: no tracked file may change
      $ntDiff = Get-WorkingTreePorcelain
      $ntDiffBefore = $ntDiff
      $null = Invoke-Cli -Arguments @("specbridge-next-task")
      $ntDiffAfter = Get-WorkingTreePorcelain
      if ($ntDiffBefore -eq $ntDiffAfter) {
        Write-Output "PASS specbridge-next-task: read-only (no working tree mutation)."
      } else {
        Write-Output "FAIL specbridge-next-task: mutated the working tree."
        $script:failed = $true
      }
    }

    # validate-operator-task-decisions: positive on committed registry
    $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-operator-task-decisions.ps1 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Output "PASS validate-operator-task-decisions: passes on committed registry."
    } else {
      Write-Output "FAIL validate-operator-task-decisions: failed on committed registry."
      $script:failed = $true
    }

    # validate-operator-task-decisions: negatives (bad enum, duplicate issue, empty reason)
    $otdPath = ".specbridge/policies/operator-task-decisions.json"
    $otdBackup = Get-Content $otdPath -Raw -Encoding UTF8
    try {
      $otdBad = $otdBackup | ConvertFrom-Json
      $otdBad.decisions[0].decision = "maybe_later"
      Set-Content -Path $otdPath -Value ($otdBad | ConvertTo-Json -Depth 4) -Encoding UTF8
      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-operator-task-decisions.ps1 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Output "PASS validate-operator-task-decisions: detects invalid decision enum."
      } else {
        Write-Output "FAIL validate-operator-task-decisions: invalid enum not detected."
        $script:failed = $true
      }

      $otdDup = $otdBackup | ConvertFrom-Json
      $otdDup.decisions = @($otdDup.decisions[0], $otdDup.decisions[0])
      Set-Content -Path $otdPath -Value ($otdDup | ConvertTo-Json -Depth 4) -Encoding UTF8
      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-operator-task-decisions.ps1 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Output "PASS validate-operator-task-decisions: detects duplicate github_issue."
      } else {
        Write-Output "FAIL validate-operator-task-decisions: duplicate issue not detected."
        $script:failed = $true
      }

      $otdNoReason = $otdBackup | ConvertFrom-Json
      $otdNoReason.decisions[0].reason = ""
      Set-Content -Path $otdPath -Value ($otdNoReason | ConvertTo-Json -Depth 4) -Encoding UTF8
      $null = powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-operator-task-decisions.ps1 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Output "PASS validate-operator-task-decisions: detects empty reason."
      } else {
        Write-Output "FAIL validate-operator-task-decisions: empty reason not detected."
        $script:failed = $true
      }
    } finally {
      Set-Content -Path $otdPath -Value $otdBackup -Encoding UTF8 -NoNewline
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

    # quickstart: verify output structure
    $qsResult = Invoke-Cli -Arguments @("quickstart")
    if ($qsResult.ExitCode -ne 0) {
      Write-Output "FAIL quickstart: command exited with code $($qsResult.ExitCode)."
      $script:failed = $true
    } else {
      try {
        $qsJson = $qsResult.Text | ConvertFrom-Json
        $flowCommands = $qsJson.recommended_flow | ForEach-Object { $_.command }
        $expectedCommands = @("specbridge-intake", "issue-to-merge-github", "specbridge-doctor", "generate-dashboard")
        $missing = $expectedCommands | Where-Object { $flowCommands -notcontains $_ }
        if ($missing) {
          Write-Output "FAIL quickstart: recommended_flow missing commands: $($missing -join ', ')."
          $script:failed = $true
        } elseif (-not $qsJson.next_command_example) {
          Write-Output "FAIL quickstart: missing next_command_example field."
          $script:failed = $true
        } else {
          Write-Output "PASS quickstart: all 4 flow steps and next_command_example present."
        }
      } catch {
        Write-Output "FAIL quickstart: output was not valid JSON."
        $script:failed = $true
      }
    }

    # specbridge-intake: verify generated contract passes validate-contracts
    $intakeTaskId = "cli-test-intake-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $intakeTempDir = Join-Path (Get-Location).Path "specbridge-intake-test-$intakeTaskId"
    New-Item -ItemType Directory -Path $intakeTempDir -Force | Out-Null
    try {
      $intakeResult = Invoke-Cli -Arguments @("specbridge-intake", "-TaskId", $intakeTaskId, "-Title", "CLI test intake", "-Goal", "Validate intake contract structure.", "-RepositoryUrl", "https://github.com/test/test")
      $contractFile = ".specbridge/contracts/$intakeTaskId.execution.md"
      if (Test-Path $contractFile) {
        $contractText = Get-Content $contractFile -Raw
        $missingCount = 0
        @("Context","Source References","Risk Level","Acceptance Criteria","Required Validations","Final Report Requirements","Completion Rule","related_issue") | ForEach-Object {
          if ($contractText -notmatch [regex]::Escape($_)) { $missingCount++ }
        }
        if ($missingCount -eq 0) {
          Write-Output "PASS specbridge-intake generates contract with all required sections."
        } else {
          Write-Output "FAIL specbridge-intake contract missing $missingCount required sections/fields."
          $script:failed = $true
        }
        Remove-Item $contractFile -Force -ErrorAction SilentlyContinue
        Remove-Item ".specbridge/scopes/$intakeTaskId.scope.json" -Force -ErrorAction SilentlyContinue
        Remove-Item ".specbridge/github-evidence/$intakeTaskId.github-mutation-evidence.json" -Force -ErrorAction SilentlyContinue
      } else {
        Write-Output "FAIL specbridge-intake did not create contract file."
        $script:failed = $true
      }
    } finally {
      Remove-Item $intakeTempDir -Recurse -Force -ErrorAction SilentlyContinue
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
        [pscustomobject]@{ Field = "diagnostic_preview_policy"; Expected = "ascii_stable_bounded_240_chars" },
        [pscustomobject]@{ Field = "max_live_retry_per_slice"; Expected = 1 },
        [pscustomobject]@{ Field = "pilot_block_rule"; Expected = "two_failures_per_slice_block_the_pilot" }
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

    # specbridge-mcp-runtime: resources/list
    $mcpListResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "resources/list")
    Assert-Success `
      -Name "specbridge-mcp-runtime resources/list" `
      -Result $mcpListResult `
      -ExpectedPattern '"method"\s*:\s*"resources/list"'
    if ($mcpListResult.ExitCode -eq 0) {
      $mcpListJson = $null
      try { $mcpListJson = $mcpListResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -eq $mcpListJson) {
        Write-Output "FAIL specbridge-mcp-runtime resources/list: output not valid JSON."
        $script:failed = $true
      } elseif (@($mcpListJson.result.resources).Count -ne 3) {
        Write-Output "FAIL specbridge-mcp-runtime resources/list: expected 3 resources, got $(@($mcpListJson.result.resources).Count)."
        $script:failed = $true
      } else {
        $uris = @($mcpListJson.result.resources | ForEach-Object { $_.uri })
        $expectedUris = @("specbridge://operator/current-goal","specbridge://operator/doctor-fix-plan","specbridge://operator/orchestration-summaries")
        $missingUris = $expectedUris | Where-Object { $uris -notcontains $_ }
        if ($missingUris.Count -gt 0) {
          Write-Output "FAIL specbridge-mcp-runtime resources/list: missing URIs: $($missingUris -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-runtime resources/list: 3 expected URIs present."
        }
      }
    }

    # specbridge-mcp-runtime: resources/read each known URI
    foreach ($mcpUri in @("specbridge://operator/current-goal","specbridge://operator/doctor-fix-plan","specbridge://operator/orchestration-summaries")) {
      $mcpReadResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "resources/read", "-Uri", $mcpUri)
      Assert-Success `
        -Name "specbridge-mcp-runtime resources/read $mcpUri" `
        -Result $mcpReadResult `
        -ExpectedPattern '"method"\s*:\s*"resources/read"'
      if ($mcpReadResult.ExitCode -eq 0) {
        $mcpReadJson = $null
        try { $mcpReadJson = $mcpReadResult.Text.Trim() | ConvertFrom-Json } catch {}
        if ($null -eq $mcpReadJson -or $mcpReadJson.ok -ne $true) {
          Write-Output "FAIL specbridge-mcp-runtime resources/read $mcpUri`: not ok or not valid JSON."
          $script:failed = $true
        } elseif ($mcpReadJson.uri -ne $mcpUri) {
          Write-Output "FAIL specbridge-mcp-runtime resources/read $mcpUri`: uri mismatch in response."
          $script:failed = $true
        } elseif (@($mcpReadJson.result.contents).Count -ne 1) {
          Write-Output "FAIL specbridge-mcp-runtime resources/read $mcpUri`: expected 1 content item."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-runtime resources/read $mcpUri`: ok=true, 1 content item."
        }
      }
    }

    # specbridge-mcp-runtime: tools/list returns the bounded local allowlist
    $mcpToolsListResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "tools/list")
    Assert-Success `
      -Name "specbridge-mcp-runtime tools/list" `
      -Result $mcpToolsListResult `
      -ExpectedPattern '"method"\s*:\s*"tools/list"'
    if ($mcpToolsListResult.ExitCode -eq 0) {
      $mcpToolsListJson = $null
      try { $mcpToolsListJson = $mcpToolsListResult.Text.Trim() | ConvertFrom-Json } catch {}
      $toolItems = if ($null -ne $mcpToolsListJson -and $null -ne $mcpToolsListJson.result) { @($mcpToolsListJson.result.tools) } else { @() }
      $toolNames = @($toolItems | ForEach-Object { $_.name })
      $missingReadOnlyHint = @($toolItems | Where-Object { $null -eq $_.annotations -or $_.annotations.readOnlyHint -ne $true })
      if ($null -eq $mcpToolsListJson -or $toolNames -notcontains "specbridge.operator.status" -or $toolNames -notcontains "specbridge.next-task" -or $toolNames.Count -ne 2 -or $missingReadOnlyHint.Count -ne 0) {
        Write-Output "FAIL specbridge-mcp-runtime tools/list: expected exactly specbridge.operator.status and specbridge.next-task with annotations.readOnlyHint true."
        $script:failed = $true
      } else {
        Write-Output "PASS specbridge-mcp-runtime tools/list: bounded read-only tool allowlist present."
      }
    }

    # specbridge-mcp-runtime: tools/call allows only the read-only local status helper
    $mcpToolsCallAllowedResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "tools/call", "-ToolName", "specbridge.operator.status")
    Assert-Success `
      -Name "specbridge-mcp-runtime tools/call specbridge.operator.status" `
      -Result $mcpToolsCallAllowedResult `
      -ExpectedPattern '"tool"\s*:\s*"specbridge.operator.status"'
    if ($mcpToolsCallAllowedResult.ExitCode -eq 0) {
      $mcpToolsCallAllowedJson = $null
      try { $mcpToolsCallAllowedJson = $mcpToolsCallAllowedResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -eq $mcpToolsCallAllowedJson -or $mcpToolsCallAllowedJson.ok -ne $true -or @($mcpToolsCallAllowedJson.result.content).Count -ne 1) {
        Write-Output "FAIL specbridge-mcp-runtime tools/call allowed: invalid response shape."
        $script:failed = $true
      } else {
        Write-Output "PASS specbridge-mcp-runtime tools/call allowed: operator status returned."
      }
    }

    # specbridge-mcp-runtime: tools/call exposes the read-only local next-task selector
    $mcpToolsCallNextTaskResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "tools/call", "-ToolName", "specbridge.next-task")
    Assert-Success `
      -Name "specbridge-mcp-runtime tools/call specbridge.next-task" `
      -Result $mcpToolsCallNextTaskResult `
      -ExpectedPattern '"tool"\s*:\s*"specbridge.next-task"'
    if ($mcpToolsCallNextTaskResult.ExitCode -eq 0) {
      $mcpToolsCallNextTaskJson = $null
      $mcpToolsCallNextTaskPayload = $null
      try {
        $mcpToolsCallNextTaskJson = $mcpToolsCallNextTaskResult.Text.Trim() | ConvertFrom-Json
        $mcpToolsCallNextTaskPayload = $mcpToolsCallNextTaskJson.result.content[0].text | ConvertFrom-Json
      } catch {}
      $payloadFields = if ($null -ne $mcpToolsCallNextTaskPayload) { @($mcpToolsCallNextTaskPayload.PSObject.Properties.Name) } else { @() }
      $missingPayloadField = $false
      foreach ($requiredPayloadField in @("current_goal_status", "current_task_id", "eligible_tasks", "excluded_issues", "recommended_action")) {
        if ($payloadFields -notcontains $requiredPayloadField) {
          $missingPayloadField = $true
        }
      }
      if ($null -eq $mcpToolsCallNextTaskJson -or $mcpToolsCallNextTaskJson.ok -ne $true -or @($mcpToolsCallNextTaskJson.result.content).Count -ne 1 -or $missingPayloadField) {
        Write-Output "FAIL specbridge-mcp-runtime tools/call specbridge.next-task: invalid next-task payload."
        $script:failed = $true
      } else {
        Write-Output "PASS specbridge-mcp-runtime tools/call specbridge.next-task: next-task selector returned."
      }
    }

    # specbridge-mcp-runtime: tools/call blocks anything outside the allowlist
    $mcpToolsCallBlockedResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "tools/call", "-ToolName", "specbridge.github.mutate")
    if ($mcpToolsCallBlockedResult.ExitCode -ne 0 -and $mcpToolsCallBlockedResult.Text -match "tool_not_allowed") {
      Write-Output "PASS CLI failure: specbridge-mcp-runtime-tools-call-blocked"
    } else {
      Write-Output "FAIL specbridge-mcp-runtime-tools-call-blocked: expected failure with tool_not_allowed."
      $script:failed = $true
    }

    # specbridge-mcp-runtime: tools/call requires an explicit tool name
    $mcpToolsCallMissingNameResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "tools/call")
    if ($mcpToolsCallMissingNameResult.ExitCode -ne 0 -and $mcpToolsCallMissingNameResult.Text -match "tool_name_required") {
      Write-Output "PASS CLI failure: specbridge-mcp-runtime-tools-call-tool-name-required"
    } else {
      Write-Output "FAIL specbridge-mcp-runtime-tools-call-tool-name-required: expected failure with tool_name_required."
      $script:failed = $true
    }

    $mcpWriteResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "resources/write")
    if ($mcpWriteResult.ExitCode -ne 0 -and $mcpWriteResult.Text -match "method_not_allowed") {
      Write-Output "PASS CLI failure: specbridge-mcp-runtime-resources-write-rejected"
    } else {
      Write-Output "FAIL specbridge-mcp-runtime-resources-write-rejected: expected failure with method_not_allowed."
      $script:failed = $true
    }

    # specbridge-mcp-runtime: unknown URI returns resource_not_found
    $mcpUnknownUriResult = Invoke-Cli -Arguments @("specbridge-mcp-runtime", "-Method", "resources/read", "-Uri", "specbridge://operator/nonexistent")
    if ($mcpUnknownUriResult.ExitCode -ne 0 -and $mcpUnknownUriResult.Text -match "resource_not_found") {
      Write-Output "PASS CLI failure: specbridge-mcp-runtime-unknown-uri-rejected"
    } else {
      Write-Output "FAIL specbridge-mcp-runtime-unknown-uri-rejected: expected failure with resource_not_found."
      $script:failed = $true
    }

    # specbridge-mcp-resources catalog now reports readonly_local_runtime
    $mcpResourcesResult = Invoke-Cli -Arguments @("specbridge-mcp-resources")
    Assert-Success `
      -Name "specbridge-mcp-resources-readonly-runtime-status" `
      -Result $mcpResourcesResult `
      -ExpectedPattern '"mcp_server_status"\s*:\s*"readonly_local_runtime"'

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
    $previousPath = $env:PATH

    Set-Content -LiteralPath $fakeClaudePath -Encoding ASCII -Value @(
      "@echo off",
      "echo %* | findstr /C:""--version"" > nul && echo Fake Claude 1.0 && exit /b 0",
      "echo %* | findstr /C:""--help"" > nul && echo Usage: claude -p --max-turns 8 --max-budget-usd 2.00 && exit /b 0",
      "echo Fake Claude success",
      "exit /b 0"
    )

    try {
      $env:PATH = "$fakeBin;$previousPath"

      $fakeCapabilityResult = Invoke-Cli -Arguments @("runtime-capability-status")
      $fakeMaxTurnsResult = Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/cli-fake-max-turns-supported.runtime-execution.json",
        "-TimeoutSeconds",
        "30",
        "-Force"
      )
    }
    finally {
      $env:PATH = $previousPath
    }

    if ($fakeCapabilityResult.ExitCode -ne 0) {
      Write-Output "FAIL fake Claude capability status did not succeed."
      Write-Output $fakeCapabilityResult.Text
      $failed = $true
    }
    else {
      try {
        $fakeCapabilityJson = $fakeCapabilityResult.Text.Trim() | ConvertFrom-Json

        if ($fakeCapabilityJson.claude.supports_max_turns -ne $true) {
          Write-Output "FAIL runtime-capability-status did not detect fake Claude --max-turns support."
          Write-Output ($fakeCapabilityJson.claude | ConvertTo-Json -Depth 8)
          $failed = $true
        }
        else {
          Write-Output "PASS runtime-capability-status detects fake Claude --max-turns support."
        }
      }
      catch {
        Write-Output "FAIL fake Claude capability status output was not valid JSON."
        $failed = $true
      }
    }

    if ($fakeMaxTurnsResult.ExitCode -ne 0) {
      Write-Output "FAIL fake Claude max-turns supported execution did not succeed."
      Write-Output $fakeMaxTurnsResult.Text
      $failed = $true
    }
    else {
      $maxTurnsExecution = Get-Content -LiteralPath ".specbridge/runtime-executions/cli-fake-max-turns-supported.runtime-execution.json" -Raw | ConvertFrom-Json

      if (
        $maxTurnsExecution.execution_status -ne "succeeded" -or
        $maxTurnsExecution.claude_capabilities.max_turns.supported -ne $true -or
        $maxTurnsExecution.claude_capabilities.max_turns.applied -ne $true -or
        $maxTurnsExecution.command_summary -notmatch "--max-turns\s+8"
      ) {
        Write-Output "FAIL execute-runtime-launch did not apply --max-turns when fake Claude supports it."
        Write-Output ($maxTurnsExecution | ConvertTo-Json -Depth 10)
        $failed = $true
      }
      else {
        Write-Output "PASS execute-runtime-launch applies --max-turns when fake Claude supports it."
      }
    }

    Set-Content -LiteralPath $fakeClaudePath -Encoding ASCII -Value @(
      "@echo off",
      "echo %* | findstr /C:""--version"" > nul && echo Fake Claude 1.0 && exit /b 0",
      "echo %* | findstr /C:""--help"" > nul && echo Usage: claude -p --max-budget-usd 2.00 && exit /b 0",
      "echo Fake Claude success",
      "exit /b 0"
    )

    try {
      $env:PATH = "$fakeBin;$previousPath"

      $fakeNoMaxTurnsResult = Invoke-Cli -Arguments @(
        "execute-runtime-launch",
        "-InputPath",
        ".specbridge/runtime-launches/cli-fixture.runtime-launch.json",
        "-OutputPath",
        ".specbridge/runtime-executions/cli-fake-max-turns-unsupported.runtime-execution.json",
        "-TimeoutSeconds",
        "30",
        "-Force"
      )
    }
    finally {
      $env:PATH = $previousPath
    }

    if ($fakeNoMaxTurnsResult.ExitCode -ne 0) {
      Write-Output "FAIL fake Claude max-turns unsupported execution did not succeed."
      Write-Output $fakeNoMaxTurnsResult.Text
      $failed = $true
    }
    else {
      $noMaxTurnsExecution = Get-Content -LiteralPath ".specbridge/runtime-executions/cli-fake-max-turns-unsupported.runtime-execution.json" -Raw | ConvertFrom-Json

      if (
        $noMaxTurnsExecution.execution_status -ne "succeeded" -or
        $noMaxTurnsExecution.claude_capabilities.max_turns.supported -ne $false -or
        $noMaxTurnsExecution.claude_capabilities.max_turns.applied -ne $false -or
        $noMaxTurnsExecution.command_summary -match "--max-turns\s+8"
      ) {
        Write-Output "FAIL execute-runtime-launch applied --max-turns when fake Claude does not support it."
        Write-Output ($noMaxTurnsExecution | ConvertTo-Json -Depth 10)
        $failed = $true
      }
      else {
        Write-Output "PASS execute-runtime-launch omits --max-turns when fake Claude does not support it."
      }
    }

    Set-Content -LiteralPath $fakeClaudePath -Encoding ASCII -Value @(
      "@echo off",
      'powershell -NoProfile -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); $s = ''Fake Claude failure with unicode: '' + [char]0x00E1 + '' '' + [char]0x00F1 + '' '' + [char]0x2713 + '' repeated 1234567890 1234567890 1234567890 1234567890 1234567890''; Write-Output $s"',
      "exit /b 1"
    )

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

    # ── specbridge-doctor --fix-plan tests ───────────────────────────────────

    # 1. Structural output: valid JSON, required fields, actions is array
    $fpResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
    if ($fpResult.ExitCode -ne 0) {
      Write-Output "FAIL fix-plan-healthy: command exited with code $($fpResult.ExitCode)."
      Write-Output $fpResult.Text
      $script:failed = $true
    } else {
      try {
        $fpJson = $fpResult.Text | ConvertFrom-Json
        $missingFields = @("fix_plan_generated","health","mode","online_checks","blockers","warnings","actions","action_count") |
          Where-Object { -not ($fpJson.PSObject.Properties.Name -contains $_) }
        if ($missingFields.Count -gt 0) {
          Write-Output "FAIL fix-plan-healthy: missing fields: $($missingFields -join ', ')."
          $script:failed = $true
        } elseif ($fpJson.fix_plan_generated -ne $true) {
          Write-Output "FAIL fix-plan-healthy: fix_plan_generated is not true."
          $script:failed = $true
        } elseif ($fpJson.online_checks.enabled -ne $false) {
          Write-Output "FAIL fix-plan-healthy: online_checks.enabled should be false in -Offline mode."
          $script:failed = $true
        } else {
          Write-Output "PASS fix-plan-healthy: valid JSON with all required fields."
        }
      } catch {
        Write-Output "FAIL fix-plan-healthy: output was not valid JSON."
        $script:failed = $true
      }
    }

    # 2. Offline mode flag sets online_checks.enabled=false
    $fpOfflineResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
    if ($fpOfflineResult.ExitCode -eq 0) {
      try {
        $fpOfflineJson = $fpOfflineResult.Text | ConvertFrom-Json
        if ($fpOfflineJson.online_checks.enabled -eq $false -and $fpOfflineJson.online_checks.reason -eq "offline_mode") {
          Write-Output "PASS fix-plan-offline-mode: online_checks.enabled=false, reason=offline_mode."
        } else {
          Write-Output "FAIL fix-plan-offline-mode: expected enabled=false reason=offline_mode, got enabled=$($fpOfflineJson.online_checks.enabled) reason=$($fpOfflineJson.online_checks.reason)."
          $script:failed = $true
        }
      } catch {
        Write-Output "FAIL fix-plan-offline-mode: output was not valid JSON."
        $script:failed = $true
      }
    } else {
      Write-Output "FAIL fix-plan-offline-mode: command failed."
      $script:failed = $true
    }

    # 3. current-goal stale: status=active but no active scope → current_goal_active_but_no_active_scope action
    $cgPath = ".specbridge/state/current-goal.json"
    $cgOriginal = Get-Content $cgPath -Raw -Encoding UTF8
    try {
      Set-Content $cgPath -Encoding UTF8 -Value '{"current_task_id":"fp-test-stale","title":"test","status":"active","primary_pr":null,"closure_pr":null,"last_updated":"2026-01-01T00:00:00Z","updated_by":"test","note":"test"}'
      $fpStaleResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($fpStaleResult.ExitCode -eq 0) {
        try {
          $fpStaleJson = $fpStaleResult.Text | ConvertFrom-Json
          $staleAction = @($fpStaleJson.actions | Where-Object { $_.id -eq "current_goal_active_but_no_active_scope" })
          if ($staleAction.Count -gt 0) {
            Write-Output "PASS fix-plan-current-goal-stale: current_goal_active_but_no_active_scope action present."
          } else {
            Write-Output "FAIL fix-plan-current-goal-stale: expected current_goal_active_but_no_active_scope action not found."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-current-goal-stale: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-current-goal-stale: command failed."
        $script:failed = $true
      }
    } finally {
      Set-Content $cgPath -Encoding UTF8 -Value $cgOriginal
    }

    # 4. Completed scope missing closure.json → completed_scope_missing_closure_json action
    $fpTestScopeId = "fp-test-missing-closure-$(Get-Date -Format 'HHmmss')"
    $fpScopePath   = ".specbridge/scopes/$fpTestScopeId.scope.json"
    try {
      Set-Content $fpScopePath -Encoding UTF8 -Value "{`"contract_id`":`"$fpTestScopeId`",`"status`":`"completed`"}"
      $fpMissingResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($fpMissingResult.ExitCode -eq 0) {
        try {
          $fpMissingJson = $fpMissingResult.Text | ConvertFrom-Json
          $missingAction = @($fpMissingJson.actions | Where-Object { $_.id -eq "completed_scope_missing_closure_json" -and $_.task_id -eq $fpTestScopeId })
          if ($missingAction.Count -gt 0) {
            Write-Output "PASS fix-plan-completed-scope-missing-closure: action present for test scope."
          } else {
            Write-Output "FAIL fix-plan-completed-scope-missing-closure: expected action not found for $fpTestScopeId."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-completed-scope-missing-closure: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-completed-scope-missing-closure: command failed."
        $script:failed = $true
      }
    } finally {
      Remove-Item $fpScopePath -Force -ErrorAction SilentlyContinue
    }

    # 5. Active scope without contract → missing_contract blocker action
    $fpActiveId    = "fp-test-active-no-contract-$(Get-Date -Format 'HHmmss')"
    $fpActivePath  = ".specbridge/scopes/$fpActiveId.scope.json"
    try {
      Set-Content $fpActivePath -Encoding UTF8 -Value "{`"contract_id`":`"$fpActiveId`",`"status`":`"active`"}"
      $fpBlockerResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($fpBlockerResult.ExitCode -eq 0) {
        try {
          $fpBlockerJson = $fpBlockerResult.Text | ConvertFrom-Json
          $blockerAction = @($fpBlockerJson.actions | Where-Object { $_.id -eq "missing_contract" -and $_.task_id -eq $fpActiveId })
          if ($blockerAction.Count -gt 0 -and $fpBlockerJson.health -eq "blocked") {
            Write-Output "PASS fix-plan-missing-contract: blocker action present and health=blocked."
          } else {
            Write-Output "FAIL fix-plan-missing-contract: expected blocker missing_contract for $fpActiveId (health=$($fpBlockerJson.health))."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-missing-contract: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-missing-contract: command failed."
        $script:failed = $true
      }
    } finally {
      Remove-Item $fpActivePath -Force -ErrorAction SilentlyContinue
    }

    # 6. merged_pr_missing_closure detects merge_completed and already_merged ledger states
    $fpMergedId     = "fp-test-merge-state-$(Get-Date -Format 'HHmmss')"
    $fpMergedScope  = ".specbridge/scopes/$fpMergedId.scope.json"
    $fpLedgerDir    = ".specbridge/ledger"
    $fpLedgerPath   = "$fpLedgerDir/operations.ndjson"
    $fpLedgerBackup = if (Test-Path $fpLedgerPath) { Get-Content $fpLedgerPath -Raw -Encoding UTF8 } else { $null }
    try {
      Set-Content $fpMergedScope -Encoding UTF8 -Value "{`"contract_id`":`"$fpMergedId`",`"status`":`"active`"}"
      New-Item -ItemType Directory -Force -Path $fpLedgerDir | Out-Null
      $fpLedgerLine = "{`"task_id`":`"$fpMergedId`",`"operation`":`"merge`",`"status`":`"merge_completed`",`"timestamp`":`"2026-01-01T00:00:00Z`"}"
      if ($null -ne $fpLedgerBackup) {
        Set-Content $fpLedgerPath -Encoding UTF8 -Value ($fpLedgerBackup.TrimEnd() + "`n" + $fpLedgerLine)
      } else {
        Set-Content $fpLedgerPath -Encoding UTF8 -Value $fpLedgerLine
      }
      $fpMergeResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($fpMergeResult.ExitCode -eq 0) {
        try {
          $fpMergeJson = $fpMergeResult.Text | ConvertFrom-Json
          $mergeAction = @($fpMergeJson.actions | Where-Object { $_.id -eq "merged_pr_missing_closure" -and $_.task_id -eq $fpMergedId })
          if ($mergeAction.Count -gt 0) {
            Write-Output "PASS fix-plan-merge-state: merged_pr_missing_closure detected for merge_completed ledger entry."
          } else {
            Write-Output "FAIL fix-plan-merge-state: expected merged_pr_missing_closure for $fpMergedId not found."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-merge-state: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-merge-state: command failed."
        $script:failed = $true
      }
    } finally {
      Remove-Item $fpMergedScope -Force -ErrorAction SilentlyContinue
      if ($null -ne $fpLedgerBackup) {
        Set-Content $fpLedgerPath -Encoding UTF8 -Value $fpLedgerBackup
      } else {
        Remove-Item $fpLedgerPath -Force -ErrorAction SilentlyContinue
      }
    }

    # 7. specbridge-intake emits run_id in output and scope.json
    $riTaskId = "trace-test-$(Get-Date -Format 'HHmmss')"
    $riResult = Invoke-Cli -Arguments @("specbridge-intake", "-TaskId", $riTaskId, "-Title", "Trace test intake", "-Goal", "Verify run_id propagation.", "-RepositoryUrl", "https://github.com/test/test")
    if ($riResult.ExitCode -eq 0) {
      try {
        $riJson    = $riResult.Text | ConvertFrom-Json
        $riScopePath = ".specbridge/scopes/$riTaskId.scope.json"
        $riScopeJson = if (Test-Path $riScopePath) { Get-Content $riScopePath -Raw | ConvertFrom-Json } else { $null }
        $riContractPath = ".specbridge/contracts/$riTaskId.execution.md"
        $riContractText = if (Test-Path $riContractPath) { Get-Content $riContractPath -Raw } else { "" }
        $runIdPresent = ($riJson.PSObject.Properties.Name -contains "run_id") -and ($riJson.run_id -match "^sb-\d{8}-[a-f0-9]{8}$")
        $scopeHasRunId = ($null -ne $riScopeJson) -and ($riScopeJson.PSObject.Properties.Name -contains "run_id") -and ($riScopeJson.run_id -eq $riJson.run_id)
        $contractHasRunId = $riContractText -match "- run_id: sb-\d{8}-"
        if ($runIdPresent -and $scopeHasRunId -and $contractHasRunId) {
          Write-Output "PASS trace-run-id-propagation: intake emits run_id, scope.json and contract carry it."
        } else {
          Write-Output "FAIL trace-run-id-propagation: run_id=$($runIdPresent) scope=$($scopeHasRunId) contract=$($contractHasRunId)."
          $script:failed = $true
        }
      } catch {
        Write-Output "FAIL trace-run-id-propagation: output was not valid JSON."
        $script:failed = $true
      }
    } else {
      Write-Output "FAIL trace-run-id-propagation: specbridge-intake command failed."
      $script:failed = $true
    }
    # cleanup
    Remove-Item ".specbridge/contracts/$riTaskId.execution.md" -Force -ErrorAction SilentlyContinue
    Remove-Item ".specbridge/scopes/$riTaskId.scope.json" -Force -ErrorAction SilentlyContinue
    Remove-Item ".specbridge/github-evidence/$riTaskId.github-mutation-evidence.json" -Force -ErrorAction SilentlyContinue

    # 8. fix-plan detects intake_run_never_started when scope has run_id but no ledger entry
    $neverStartedId = "fp-never-started-$(Get-Date -Format 'HHmmss')"
    $neverStartedScope = ".specbridge/scopes/$neverStartedId.scope.json"
    try {
      Set-Content $neverStartedScope -Encoding UTF8 -Value "{`"contract_id`":`"$neverStartedId`",`"run_id`":`"sb-20260101-abcd1234`",`"status`":`"active`"}"
      $nsResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($nsResult.ExitCode -eq 0) {
        try {
          $nsJson = $nsResult.Text | ConvertFrom-Json
          $nsAction = @($nsJson.actions | Where-Object { $_.id -eq "intake_run_never_started" -and $_.task_id -eq $neverStartedId })
          if ($nsAction.Count -gt 0) {
            Write-Output "PASS fix-plan-intake-run-never-started: action detected for scope with run_id and no ledger entry."
          } else {
            Write-Output "FAIL fix-plan-intake-run-never-started: expected intake_run_never_started for $neverStartedId not found."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-intake-run-never-started: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-intake-run-never-started: command failed."
        $script:failed = $true
      }
    } finally {
      Remove-Item $neverStartedScope -Force -ErrorAction SilentlyContinue
    }

    # 9. fix-plan detects run_merge_without_closure when ledger has merge but no post_merge_memory for same run_id
    $rmwcId         = "fp-run-merge-no-closure-$(Get-Date -Format 'HHmmss')"
    $rmwcScopePath  = ".specbridge/scopes/$rmwcId.scope.json"
    $rmwcRunId      = "sb-20260101-eeee9999"
    $rmwcLedgerDir  = ".specbridge/ledger"
    $rmwcLedgerPath = "$rmwcLedgerDir/operations.ndjson"
    $rmwcLedgerBak  = if (Test-Path $rmwcLedgerPath) { Get-Content $rmwcLedgerPath -Raw -Encoding UTF8 } else { $null }
    try {
      Set-Content $rmwcScopePath -Encoding UTF8 -Value "{`"contract_id`":`"$rmwcId`",`"run_id`":`"$rmwcRunId`",`"status`":`"active`"}"
      New-Item -ItemType Directory -Force -Path $rmwcLedgerDir | Out-Null
      $rmwcLine = "{`"task_id`":`"$rmwcId`",`"run_id`":`"$rmwcRunId`",`"operation`":`"merge`",`"status`":`"success`",`"timestamp`":`"2026-01-01T00:00:00Z`"}"
      $newContent = if ($null -ne $rmwcLedgerBak) { $rmwcLedgerBak.TrimEnd() + "`n" + $rmwcLine } else { $rmwcLine }
      Set-Content $rmwcLedgerPath -Encoding UTF8 -Value $newContent
      $rmwcResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline")
      if ($rmwcResult.ExitCode -eq 0) {
        try {
          $rmwcJson = $rmwcResult.Text | ConvertFrom-Json
          $rmwcAction = @($rmwcJson.actions | Where-Object { $_.id -eq "run_merge_without_closure" -and $_.task_id -eq $rmwcId })
          if ($rmwcAction.Count -gt 0) {
            Write-Output "PASS fix-plan-run-merge-without-closure: action detected for run with merge but no post_merge_memory."
          } else {
            Write-Output "FAIL fix-plan-run-merge-without-closure: expected action for $rmwcRunId not found."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL fix-plan-run-merge-without-closure: output was not valid JSON."
          $script:failed = $true
        }
      } else {
        Write-Output "FAIL fix-plan-run-merge-without-closure: command failed."
        $script:failed = $true
      }
    } finally {
      Remove-Item $rmwcScopePath -Force -ErrorAction SilentlyContinue
      if ($null -ne $rmwcLedgerBak) {
        Set-Content $rmwcLedgerPath -Encoding UTF8 -Value $rmwcLedgerBak
      } else {
        Remove-Item $rmwcLedgerPath -Force -ErrorAction SilentlyContinue
      }
    }

    # 10. Human output format: contains "SpecBridge Fix Plan" text
    $fpHumanResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan", "-Offline", "-OutputFormat", "human")
    if ($fpHumanResult.ExitCode -eq 0 -and $fpHumanResult.Text -match "SpecBridge Fix Plan") {
      Write-Output "PASS fix-plan-human-output: 'SpecBridge Fix Plan' header present."
    } elseif ($fpHumanResult.ExitCode -ne 0) {
      Write-Output "FAIL fix-plan-human-output: command failed."
      $script:failed = $true
    } else {
      Write-Output "FAIL fix-plan-human-output: 'SpecBridge Fix Plan' header not found."
      $script:failed = $true
    }

    # specbridge-mcp-resources tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $mcpResult = Invoke-Cli -Arguments @("specbridge-mcp-resources")
    Assert-Success `
      -Name "specbridge-mcp-resources" `
      -Result $mcpResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-mcp-resources"'

    if ($mcpResult.ExitCode -eq 0) {
      $mcpJson = $null
      try { $mcpJson = $mcpResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $mcpJson) {
        Write-Output "FAIL specbridge-mcp-resources: output was not valid JSON."
        $script:failed = $true
      } else {
        # ok field
        if ($mcpJson.ok -ne $true) {
          Write-Output "FAIL specbridge-mcp-resources: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-resources: ok is true."
        }

        # catalog fields
        $requiredCatalogFields = @("schema_version","catalog_id","generated_at","mcp_server_status","mcp_server_note","read_only_policy","resources")
        $missingCatalog = $requiredCatalogFields | Where-Object { $null -eq $mcpJson.catalog.$_ -and $mcpJson.catalog.$_ -ne $false }
        if ($missingCatalog.Count -gt 0) {
          Write-Output "FAIL specbridge-mcp-resources: catalog missing fields: $($missingCatalog -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-resources: catalog has all required fields."
        }

        # mcp_server_status records the bounded read-only runtime.
        if ($mcpJson.catalog.mcp_server_status -ne "readonly_local_runtime") {
          Write-Output "FAIL specbridge-mcp-resources: mcp_server_status expected 'readonly_local_runtime'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-resources: mcp_server_status is readonly_local_runtime."
        }

        # 2. Required resources present
        $resources = @($mcpJson.catalog.resources)
        $requiredUris = @(
          "specbridge://operator/current-goal",
          "specbridge://operator/doctor-fix-plan",
          "specbridge://operator/orchestration-summaries"
        )
        $actualUris = $resources | ForEach-Object { $_.uri }
        $missingUris = $requiredUris | Where-Object { $actualUris -notcontains $_ }
        if ($missingUris.Count -gt 0) {
          Write-Output "FAIL specbridge-mcp-resources: missing resource URIs: $($missingUris -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-resources: all 3 required resource URIs present."
        }

        # Each resource entry must have required fields
        $requiredResourceFields = @("name","uri","content_type","source_paths","refresh_behavior","sensitivity","read_only","description")
        $resourceFieldFail = $false
        foreach ($res in $resources) {
          $missingResFields = $requiredResourceFields | Where-Object { $null -eq $res.$_ -and $res.$_ -ne $false }
          if ($missingResFields.Count -gt 0) {
            Write-Output "FAIL specbridge-mcp-resources: resource '$($res.uri)' missing fields: $($missingResFields -join ', ')."
            $script:failed = $true
            $resourceFieldFail = $true
          }
          if ($res.read_only -ne $true) {
            Write-Output "FAIL specbridge-mcp-resources: resource '$($res.uri)' read_only is not true."
            $script:failed = $true
            $resourceFieldFail = $true
          }
        }
        if (-not $resourceFieldFail) {
          Write-Output "PASS specbridge-mcp-resources: all resource entries have required fields and read_only=true."
        }
      }
    }

    # 3. No mutation without OutputPath: no catalog file written when -OutputPath is omitted
    $catalogArtifact = Join-Path (Get-Location).Path ".specbridge/mcp-resources/operator-state.catalog.json"
    $catalogExistedBefore = Test-Path $catalogArtifact
    $catalogOriginalRaw = $null
    if ($catalogExistedBefore) {
      $catalogOriginalRaw = Get-Content $catalogArtifact -Raw -Encoding UTF8
    }
    Remove-Item $catalogArtifact -Force -ErrorAction SilentlyContinue
    $mcpNoPathResult = Invoke-Cli -Arguments @("specbridge-mcp-resources")
    if (Test-Path $catalogArtifact) {
      Write-Output "FAIL specbridge-mcp-resources-no-mutation: catalog file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-mcp-resources-no-mutation: no catalog file written without -OutputPath."
    }

    # 4. OutputPath behavior: writes catalog to declared path
    $mcpOutputResult = Invoke-Cli -Arguments @("specbridge-mcp-resources", "-OutputPath", ".specbridge/mcp-resources/operator-state.catalog.json", "-Force")
    Assert-Success `
      -Name "specbridge-mcp-resources-output-path" `
      -Result $mcpOutputResult `
      -ExpectedPattern '"output_path"'

    if ($mcpOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $catalogArtifact)) {
        Write-Output "FAIL specbridge-mcp-resources-output-path: catalog file was not written."
        $script:failed = $true
      } else {
        $writtenCatalog = $null
        try {
          $writtenRaw = Get-Content $catalogArtifact -Raw -Encoding UTF8
          $writtenCatalog = $writtenRaw | ConvertFrom-Json
        } catch {}
        if ($null -eq $writtenCatalog) {
          Write-Output "FAIL specbridge-mcp-resources-output-path: written catalog is not valid JSON."
          $script:failed = $true
        } elseif ($writtenCatalog.catalog_id -ne "specbridge-operator-state") {
          Write-Output "FAIL specbridge-mcp-resources-output-path: written catalog catalog_id mismatch."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-mcp-resources-output-path: catalog file written and valid."
        }
      }

      # Existing catalog artifacts require -Force.
      $mcpExistingPathResult = Invoke-Cli -Arguments @("specbridge-mcp-resources", "-OutputPath", ".specbridge/mcp-resources/operator-state.catalog.json")
      Assert-Failure `
        -Name "specbridge-mcp-resources-output-path-requires-force" `
        -Result $mcpExistingPathResult `
        -ExpectedPattern "use -Force"
    }

    # Restore the original artifact state after mutation tests.
    if ($catalogExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($catalogArtifact, $catalogOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $catalogArtifact -Force -ErrorAction SilentlyContinue
    }

    # 5. OutputPath outside the contract artifact must fail
    $mcpBadPathResult = Invoke-Cli -Arguments @("specbridge-mcp-resources", "-OutputPath", "docs/bad-catalog.json")
    Assert-Failure `
      -Name "specbridge-mcp-resources-bad-output-path" `
      -Result $mcpBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/mcp-resources/operator-state.catalog.json"

    # specbridge-token-governance-status tests

    $tgsResult = Invoke-Cli -Arguments @("specbridge-token-governance-status")
    Assert-Success `
      -Name "specbridge-token-governance-status" `
      -Result $tgsResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-token-governance-status"'

    $tgsRepeatResult = Invoke-Cli -Arguments @("specbridge-token-governance-status")
    if ($tgsResult.ExitCode -eq 0 -and $tgsRepeatResult.ExitCode -eq 0) {
      if ($tgsResult.Text -eq $tgsRepeatResult.Text) {
        Write-Output "PASS specbridge-token-governance-status-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-token-governance-status-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($tgsResult.ExitCode -eq 0) {
      $tgsJson = $null
      try { $tgsJson = $tgsResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $tgsJson) {
        Write-Output "FAIL specbridge-token-governance-status: output was not valid JSON."
        $script:failed = $true
      } else {
        $requiredTgsFields = @(
          "schema_version",
          "governance_id",
          "provider_sources",
          "codex_context_governance",
          "claude_code_runtime_governance",
          "mcp_tool_context_governance",
          "multi_agent_slice_governance",
          "blocked_disclosures",
          "evidence_requirements",
          "policy_boundary",
          "execution_policy",
          "evidence_sources"
        )
        $missingTgsFields = $requiredTgsFields | Where-Object { -not ($tgsJson.PSObject.Properties.Name -contains $_) }
        if ($missingTgsFields.Count -gt 0) {
          Write-Output "FAIL specbridge-token-governance-status: missing fields: $($missingTgsFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-token-governance-status: required fields present."
        }

        if ($tgsJson.ok -ne $true) {
          Write-Output "FAIL specbridge-token-governance-status: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-token-governance-status: ok is true."
        }

        $providerSources = @($tgsJson.provider_sources)
        $hasAnthropic = (@($providerSources | Where-Object { $_.provider -eq "Anthropic" }).Count -gt 0)
        $hasOpenAi = (@($providerSources | Where-Object { $_.provider -eq "OpenAI" }).Count -gt 0)
        if ($hasAnthropic -and $hasOpenAi) {
          Write-Output "PASS specbridge-token-governance-status: Anthropic and OpenAI sources are recorded."
        } else {
          Write-Output "FAIL specbridge-token-governance-status: expected Anthropic and OpenAI sources."
          $script:failed = $true
        }

        if ($tgsJson.claude_code_runtime_governance.max_budget_usd_default -eq "2.00" -and $tgsJson.claude_code_runtime_governance.max_budget_usd_ceiling -eq "10.00") {
          Write-Output "PASS specbridge-token-governance-status: max_budget_usd default and ceiling are recorded."
        } else {
          Write-Output "FAIL specbridge-token-governance-status: max_budget_usd default or ceiling mismatch."
          $script:failed = $true
        }

        if ([int] $tgsJson.claude_code_runtime_governance.max_turns_default -eq 8 -and (@($tgsJson.claude_code_runtime_governance.conditional_flags) -contains "--max-turns")) {
          Write-Output "PASS specbridge-token-governance-status: max_turns policy is recorded."
        } else {
          Write-Output "FAIL specbridge-token-governance-status: max_turns policy missing."
          $script:failed = $true
        }

        $blockedDisclosures = @($tgsJson.blocked_disclosures)
        $requiredBlocked = @("provider API keys", "OAuth tokens", "raw hidden prompts", "raw ChatGPT transcripts", "raw unbounded stdout", "raw unbounded stderr")
        $missingBlocked = $requiredBlocked | Where-Object { $blockedDisclosures -notcontains $_ }
        if ($missingBlocked.Count -eq 0) {
          Write-Output "PASS specbridge-token-governance-status: blocked disclosures are recorded."
        } else {
          Write-Output "FAIL specbridge-token-governance-status: missing blocked disclosures: $($missingBlocked -join ', ')."
          $script:failed = $true
        }

        if ($tgsJson.execution_policy.launches_claude -eq $false -and $tgsJson.execution_policy.calls_network -eq $false -and $tgsJson.execution_policy.reads_secrets -eq $false -and $tgsJson.execution_policy.changes_billing -eq $false) {
          Write-Output "PASS specbridge-token-governance-status: read-only/no-secret/no-billing execution policy recorded."
        } else {
          Write-Output "FAIL specbridge-token-governance-status: execution policy boundary mismatch."
          $script:failed = $true
        }
      }
    }

    $tgsStatusPath = ".specbridge/token-governance/current.status.json"
    $tgsBefore = if (Test-Path $tgsStatusPath) { Get-Content $tgsStatusPath -Raw -Encoding UTF8 } else { $null }
    $tgsNoPathResult = Invoke-Cli -Arguments @("specbridge-token-governance-status")
    $tgsAfter = if (Test-Path $tgsStatusPath) { Get-Content $tgsStatusPath -Raw -Encoding UTF8 } else { $null }
    if ($tgsNoPathResult.ExitCode -eq 0 -and $tgsBefore -eq $tgsAfter) {
      Write-Output "PASS specbridge-token-governance-status-no-mutation: status artifact unchanged without -OutputPath."
    } else {
      Write-Output "FAIL specbridge-token-governance-status-no-mutation: status artifact changed without -OutputPath."
      $script:failed = $true
    }

    $tgsTempPath = ".specbridge/token-governance/test-token-governance.status.json"
    Remove-Item $tgsTempPath -Force -ErrorAction SilentlyContinue
    $tgsOutputResult = Invoke-Cli -Arguments @("specbridge-token-governance-status", "-OutputPath", $tgsTempPath)
    Assert-Success `
      -Name "specbridge-token-governance-status-output-path" `
      -Result $tgsOutputResult `
      -ExpectedPattern '"writes_output_artifact"\s*:\s*true'

    if ($tgsOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $tgsTempPath)) {
        Write-Output "FAIL specbridge-token-governance-status-output-path: status file was not written."
        $script:failed = $true
      } else {
        try {
          $tgsWritten = Get-Content $tgsTempPath -Raw -Encoding UTF8 | ConvertFrom-Json
          if ($tgsWritten.command -eq "specbridge-token-governance-status" -and $tgsWritten.execution_policy.writes_output_artifact -eq $true) {
            Write-Output "PASS specbridge-token-governance-status-output-path: status file written and valid."
          } else {
            Write-Output "FAIL specbridge-token-governance-status-output-path: written status fields mismatch."
            $script:failed = $true
          }
        } catch {
          Write-Output "FAIL specbridge-token-governance-status-output-path: written status was not valid JSON."
          $script:failed = $true
        }
      }

      $tgsExistingResult = Invoke-Cli -Arguments @("specbridge-token-governance-status", "-OutputPath", $tgsTempPath)
      Assert-Failure `
        -Name "specbridge-token-governance-status-output-path-requires-force" `
        -Result $tgsExistingResult `
        -ExpectedPattern "OutputPath already exists; use -Force"
    }
    Remove-Item $tgsTempPath -Force -ErrorAction SilentlyContinue

    $tgsBadPathResult = Invoke-Cli -Arguments @("specbridge-token-governance-status", "-OutputPath", "docs/bad-token-governance.json")
    Assert-Failure `
      -Name "specbridge-token-governance-status-bad-output-path" `
      -Result $tgsBadPathResult `
      -ExpectedPattern "OutputPath must point to"

    $fpMalformedBranchResult = Invoke-Cli -Arguments @("specbridge-doctor", "-FixPlan")
    if ($fpMalformedBranchResult.ExitCode -eq 0) {
      try {
        $fpMalformedBranchJson = $fpMalformedBranchResult.Text | ConvertFrom-Json
        if (@($fpMalformedBranchJson.warnings) -contains "branch_convention_violation:#") {
          Write-Output "FAIL fix-plan-no-empty-branch-warning: malformed branch_convention_violation:# warning present."
          $script:failed = $true
        } else {
          Write-Output "PASS fix-plan-no-empty-branch-warning: malformed branch_convention_violation:# warning absent."
        }
      } catch {
        Write-Output "FAIL fix-plan-no-empty-branch-warning: output was not valid JSON."
        $script:failed = $true
      }
    } else {
      Write-Output "FAIL fix-plan-no-empty-branch-warning: command failed."
      $script:failed = $true
    }

    # specbridge-project-starter tests

    $psTaskId = "cli-project-starter"
    $psOutputPath = ".specbridge/project-starters/$psTaskId.project-starter.json"
    $psArtifact = Join-Path (Get-Location).Path $psOutputPath
    Remove-Item $psArtifact -Force -ErrorAction SilentlyContinue

    $psArgs = @(
      "specbridge-project-starter",
      "-TaskId", $psTaskId,
      "-Title", "CLI Project Starter",
      "-Goal", "Define a governed starter package before implementation.",
      "-TargetUser", "founder,operator",
      "-MvpScope", "starter artifact,validation plan",
      "-NonGoal", "deployment,dependency installation"
    )

    $psResult = Invoke-Cli -Arguments $psArgs
    Assert-Success `
      -Name "specbridge-project-starter" `
      -Result $psResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-project-starter"'

    if ($psResult.ExitCode -eq 0) {
      $psJson = $null
      try { $psJson = $psResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $psJson) {
        Write-Output "FAIL specbridge-project-starter: output was not valid JSON."
        $script:failed = $true
      } else {
        $missingStarterFields = @(
          "schema_version", "command", "starter_id", "title", "goal", "target_users",
          "mvp_scope", "non_goals", "blocked_scope", "future_spec_package",
          "agent_architecture", "validation_plan", "security_boundaries",
          "security_review_prompts", "next_steps", "standard_boundaries"
        ) | Where-Object { @($psJson.starter.PSObject.Properties.Name) -notcontains $_ }

        if ($psJson.ok -ne $true) {
          Write-Output "FAIL specbridge-project-starter: ok field is not true."
          $script:failed = $true
        } elseif ($missingStarterFields.Count -gt 0) {
          Write-Output "FAIL specbridge-project-starter: starter missing fields: $($missingStarterFields -join ', ')."
          $script:failed = $true
        } elseif ($psJson.starter.starter_id -ne $psTaskId) {
          Write-Output "FAIL specbridge-project-starter: starter_id mismatch."
          $script:failed = $true
        } elseif (@($psJson.starter.target_users).Count -ne 2 -or @($psJson.starter.mvp_scope).Count -ne 2 -or @($psJson.starter.non_goals).Count -ne 2) {
          Write-Output "FAIL specbridge-project-starter: expected target_users, mvp_scope, and non_goals arrays to preserve two values each."
          $script:failed = $true
        } elseif (@($psJson.starter.blocked_scope) -notcontains "network_calls") {
          Write-Output "FAIL specbridge-project-starter: blocked_scope must include network_calls."
          $script:failed = $true
        } elseif (@($psJson.starter.security_review_prompts).Count -lt 1) {
          Write-Output "FAIL specbridge-project-starter: security_review_prompts must not be empty."
          $script:failed = $true
        } elseif ($psJson.starter.standard_boundaries.calls_network -ne $false -or
                  $psJson.starter.standard_boundaries.installs_dependencies -ne $false -or
                  $psJson.starter.standard_boundaries.deploys -ne $false -or
                  $psJson.starter.standard_boundaries.cleanup_enforcement -ne "none") {
          Write-Output "FAIL specbridge-project-starter: standard boundaries must block network, dependencies, deploy, and cleanup enforcement."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-project-starter: artifact shape and boundaries are valid."
        }
      }
    }

    if (Test-Path $psArtifact) {
      Write-Output "FAIL specbridge-project-starter-no-mutation: artifact file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-project-starter-no-mutation: no artifact written without -OutputPath."
    }

    $psOutputResult = Invoke-Cli -Arguments ($psArgs + @("-OutputPath", $psOutputPath, "-Force"))
    Assert-Success `
      -Name "specbridge-project-starter-output-path" `
      -Result $psOutputResult `
      -ExpectedPattern '"output_path"'

    if ($psOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $psArtifact)) {
        Write-Output "FAIL specbridge-project-starter-output-path: artifact file was not written."
        $script:failed = $true
      } else {
        $psWritten = $null
        try { $psWritten = Get-Content $psArtifact -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
        if ($null -eq $psWritten) {
          Write-Output "FAIL specbridge-project-starter-output-path: written artifact is not valid JSON."
          $script:failed = $true
        } elseif ($psWritten.command -ne "specbridge-project-starter" -or $psWritten.starter_id -ne $psTaskId) {
          Write-Output "FAIL specbridge-project-starter-output-path: written artifact fields mismatch."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-project-starter-output-path: artifact file written and valid."
        }
      }

      $psExistingResult = Invoke-Cli -Arguments ($psArgs + @("-OutputPath", $psOutputPath))
      Assert-Failure `
        -Name "specbridge-project-starter-output-path-requires-force" `
        -Result $psExistingResult `
        -ExpectedPattern "use -Force"
    }

    $psMissingGoalResult = Invoke-Cli -Arguments @(
      "specbridge-project-starter",
      "-TaskId", "missing-goal",
      "-Title", "Missing goal",
      "-TargetUser", "operator",
      "-MvpScope", "starter artifact",
      "-NonGoal", "deployment"
    )
    Assert-Failure `
      -Name "specbridge-project-starter-missing-goal" `
      -Result $psMissingGoalResult `
      -ExpectedPattern "Goal is required"

    $psMissingTargetUserResult = Invoke-Cli -Arguments @(
      "specbridge-project-starter",
      "-TaskId", "missing-target-user",
      "-Title", "Missing target user",
      "-Goal", "Validate missing target user.",
      "-MvpScope", "starter artifact",
      "-NonGoal", "deployment"
    )
    Assert-Failure `
      -Name "specbridge-project-starter-missing-target-user" `
      -Result $psMissingTargetUserResult `
      -ExpectedPattern "TargetUser must include at least one value"

    $psBadPathResult = Invoke-Cli -Arguments ($psArgs + @("-OutputPath", "docs/bad-project-starter.json"))
    Assert-Failure `
      -Name "specbridge-project-starter-bad-output-path" `
      -Result $psBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/project-starters/$psTaskId.project-starter.json"

    $psAiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($psAiResult.ExitCode -eq 0) {
      $psAiJson = $null
      try { $psAiJson = $psAiResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -ne $psAiJson) {
        $psFamilies = @($psAiJson.inventory.families)
        $psFamilyIds = $psFamilies | ForEach-Object { $_.family_id }
        if ($psFamilyIds -contains "project_starters") {
          $psFamily = $psFamilies | Where-Object { $_.family_id -eq "project_starters" }
          if ($psFamily.repository_path -eq ".specbridge/project-starters" -and $psFamily.cleanup_permission -eq "none") {
            Write-Output "PASS specbridge-project-starter-artifact-family: project_starters family present with correct path and cleanup_permission=none."
          } else {
            Write-Output "FAIL specbridge-project-starter-artifact-family: project_starters family has unexpected path or cleanup_permission."
            $script:failed = $true
          }
        } else {
          Write-Output "FAIL specbridge-project-starter-artifact-family: project_starters family not found in artifact inventory."
          $script:failed = $true
        }
      }
    }

    # specbridge-artifact-inventory tests


    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $aiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    Assert-Success `
      -Name "specbridge-artifact-inventory" `
      -Result $aiResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-artifact-inventory"'

    $aiRepeatResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($aiResult.ExitCode -eq 0 -and $aiRepeatResult.ExitCode -eq 0) {
      if ($aiResult.Text.Trim() -ceq $aiRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-artifact-inventory-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-artifact-inventory-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($aiResult.ExitCode -eq 0) {
      $aiJson = $null
      try { $aiJson = $aiResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $aiJson) {
        Write-Output "FAIL specbridge-artifact-inventory: output was not valid JSON."
        $script:failed = $true
      } else {
        # ok field
        if ($aiJson.ok -ne $true) {
          Write-Output "FAIL specbridge-artifact-inventory: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: ok is true."
        }

        # inventory top-level fields
        $requiredTopFields = @("command", "generated_at", "families", "totals", "retention_enforcement", "read_only_note")
        $missingTop = $requiredTopFields | Where-Object { $null -eq $aiJson.inventory.$_ -and $aiJson.inventory.$_ -ne 0 }
        if ($missingTop.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-inventory: inventory missing fields: $($missingTop -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: inventory has all required top-level fields."
        }

        # retention_enforcement must be "none"
        if ($aiJson.inventory.retention_enforcement -ne "none") {
          Write-Output "FAIL specbridge-artifact-inventory: retention_enforcement expected 'none', got '$($aiJson.inventory.retention_enforcement)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: retention_enforcement is none."
        }

        # 2. Required families present
        $families = @($aiJson.inventory.families)
        $requiredFamilyIds = @(
          "contracts", "scopes", "reports", "audit_packets", "chatgpt_audits",
          "runtime_launches", "runtime_preflights", "runtime_results", "runtime_summaries",
          "runtime_runs", "runtime_executions", "orchestrations", "executor_packets",
          "github_evidence", "ledger", "mcp_resources", "artifact_inventory", "branch_inventory",
          "branch_cleanup_policy", "artifact_retention_policy", "repository_health_summary",
          "standard_readiness", "project_starters"
        )
        $actualFamilyIds = $families | ForEach-Object { $_.family_id }
        $missingFamilies = $requiredFamilyIds | Where-Object { $actualFamilyIds -notcontains $_ }
        if ($missingFamilies.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-inventory: missing families: $($missingFamilies -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: all required family IDs present."
        }

        # 3. Required fields per family entry
        $requiredFamilyFields = @("family_id", "repository_path", "file_count", "total_bytes", "latest_modified", "retention_posture", "cleanup_permission")
        $familyFieldFail = $false
        foreach ($fam in $families) {
          $missingFamFields = $requiredFamilyFields | Where-Object { -not ($fam.PSObject.Properties.Name -contains $_) }
          if ($missingFamFields.Count -gt 0) {
            Write-Output "FAIL specbridge-artifact-inventory: family '$($fam.family_id)' missing fields: $($missingFamFields -join ', ')."
            $script:failed = $true
            $familyFieldFail = $true
          }
          if ($fam.cleanup_permission -ne "none") {
            Write-Output "FAIL specbridge-artifact-inventory: family '$($fam.family_id)' cleanup_permission must be 'none'."
            $script:failed = $true
            $familyFieldFail = $true
          }
          if ($fam.retention_posture -ne "preserve") {
            Write-Output "FAIL specbridge-artifact-inventory: family '$($fam.family_id)' retention_posture must be 'preserve'."
            $script:failed = $true
            $familyFieldFail = $true
          }
        }
        if (-not $familyFieldFail) {
          Write-Output "PASS specbridge-artifact-inventory: all family entries have required fields, cleanup_permission=none, retention_posture=preserve."
        }

        # 4. Totals fields
        $totalsFields = @("family_count", "total_file_count", "total_bytes")
        $missingTotals = $totalsFields | Where-Object { $null -eq $aiJson.inventory.totals.$_ -and $aiJson.inventory.totals.$_ -ne 0 }
        if ($missingTotals.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-inventory: totals missing fields: $($missingTotals -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: totals has all required fields."
        }

        if ($aiJson.inventory.totals.family_count -ne $requiredFamilyIds.Count) {
          Write-Output "FAIL specbridge-artifact-inventory: totals.family_count expected $($requiredFamilyIds.Count), got $($aiJson.inventory.totals.family_count)."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory: totals.family_count is $($requiredFamilyIds.Count)."
        }
      }
    }

    # 8. No mutation without OutputPath: no inventory file written
    $aiInventoryArtifact = Join-Path (Get-Location).Path ".specbridge/artifact-inventory/current.inventory.json"
    $aiInventoryExistedBefore = Test-Path $aiInventoryArtifact
    $aiInventoryOriginalRaw = $null
    if ($aiInventoryExistedBefore) {
      $aiInventoryOriginalRaw = Get-Content $aiInventoryArtifact -Raw -Encoding UTF8
    }
    Remove-Item $aiInventoryArtifact -Force -ErrorAction SilentlyContinue
    $aiNoPathResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if (Test-Path $aiInventoryArtifact) {
      Write-Output "FAIL specbridge-artifact-inventory-no-mutation: inventory file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-artifact-inventory-no-mutation: no inventory file written without -OutputPath."
    }

    # 6. OutputPath behavior: writes inventory to declared path
    $aiOutputResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory", "-OutputPath", ".specbridge/artifact-inventory/current.inventory.json", "-Force")
    Assert-Success `
      -Name "specbridge-artifact-inventory-output-path" `
      -Result $aiOutputResult `
      -ExpectedPattern '"output_path"'

    if ($aiOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $aiInventoryArtifact)) {
        Write-Output "FAIL specbridge-artifact-inventory-output-path: inventory file was not written."
        $script:failed = $true
      } else {
        $writtenInventory = $null
        try {
          $writtenInventory = Get-Content $aiInventoryArtifact -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
        if ($null -eq $writtenInventory) {
          Write-Output "FAIL specbridge-artifact-inventory-output-path: written inventory is not valid JSON."
          $script:failed = $true
        } elseif ($writtenInventory.command -ne "specbridge-artifact-inventory") {
          Write-Output "FAIL specbridge-artifact-inventory-output-path: written inventory command field mismatch."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-inventory-output-path: inventory file written and valid."
        }
      }

      # Force required when replacing
      $aiExistingResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory", "-OutputPath", ".specbridge/artifact-inventory/current.inventory.json")
      Assert-Failure `
        -Name "specbridge-artifact-inventory-output-path-requires-force" `
        -Result $aiExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($aiInventoryExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($aiInventoryArtifact, $aiInventoryOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $aiInventoryArtifact -Force -ErrorAction SilentlyContinue
    }

    # 7. OutputPath outside the contract artifact must fail
    $aiBadPathResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory", "-OutputPath", "docs/bad-inventory.json")
    Assert-Failure `
      -Name "specbridge-artifact-inventory-bad-output-path" `
      -Result $aiBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/artifact-inventory/current.inventory.json"

    # specbridge-branch-inventory tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $biResult = Invoke-Cli -Arguments @("specbridge-branch-inventory")
    Assert-Success `
      -Name "specbridge-branch-inventory" `
      -Result $biResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-branch-inventory"'

    $biRepeatResult = Invoke-Cli -Arguments @("specbridge-branch-inventory")
    if ($biResult.ExitCode -eq 0 -and $biRepeatResult.ExitCode -eq 0) {
      if ($biResult.Text.Trim() -ceq $biRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-branch-inventory-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-branch-inventory-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($biResult.ExitCode -eq 0) {
      $biJson = $null
      try { $biJson = $biResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $biJson) {
        Write-Output "FAIL specbridge-branch-inventory: output was not valid JSON."
        $script:failed = $true
      } else {
        if ($biJson.ok -ne $true) {
          Write-Output "FAIL specbridge-branch-inventory: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: ok is true."
        }

        $requiredBranchInventoryFields = @(
          "command",
          "generated_at",
          "base_ref",
          "current_branch",
          "branches",
          "totals",
          "prefix_counts",
          "branch_mutation_policy",
          "read_only_note"
        )
        $inventoryFieldNames = @($biJson.inventory.PSObject.Properties.Name)
        $missingBranchInventoryFields = $requiredBranchInventoryFields | Where-Object { $inventoryFieldNames -notcontains $_ }
        if ($missingBranchInventoryFields.Count -gt 0) {
          Write-Output "FAIL specbridge-branch-inventory: inventory missing fields: $($missingBranchInventoryFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: inventory has all required top-level fields."
        }

        if ($biJson.inventory.branch_mutation_policy -ne "none") {
          Write-Output "FAIL specbridge-branch-inventory: branch_mutation_policy expected 'none', got '$($biJson.inventory.branch_mutation_policy)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: branch_mutation_policy is none."
        }

        foreach ($blockedVerb in @("delete", "prune", "rename", "move", "archive", "fetch", "pull", "force-push")) {
          if ($biJson.inventory.read_only_note -notmatch [regex]::Escape($blockedVerb)) {
            Write-Output "FAIL specbridge-branch-inventory: read_only_note missing '$blockedVerb'."
            $script:failed = $true
          }
        }

        $branches = @($biJson.inventory.branches)
        $branchFieldFail = $false
        $requiredBranchFields = @(
          "ref_name",
          "branch_name",
          "ref_type",
          "object_id",
          "latest_commit_at",
          "prefix",
          "merged_into_main",
          "retention_posture",
          "cleanup_permission"
        )
        foreach ($branch in $branches) {
          $branchFieldNames = @($branch.PSObject.Properties.Name)
          $missingBranchFields = $requiredBranchFields | Where-Object { $branchFieldNames -notcontains $_ }
          if ($missingBranchFields.Count -gt 0) {
            Write-Output "FAIL specbridge-branch-inventory: branch '$($branch.ref_name)' missing fields: $($missingBranchFields -join ', ')."
            $script:failed = $true
            $branchFieldFail = $true
          }
          if (@("local", "origin") -notcontains $branch.ref_type) {
            Write-Output "FAIL specbridge-branch-inventory: branch '$($branch.ref_name)' has invalid ref_type '$($branch.ref_type)'."
            $script:failed = $true
            $branchFieldFail = $true
          }
          if ($branch.cleanup_permission -ne "none") {
            Write-Output "FAIL specbridge-branch-inventory: branch '$($branch.ref_name)' cleanup_permission must be 'none'."
            $script:failed = $true
            $branchFieldFail = $true
          }
          if ($branch.retention_posture -ne "preserve") {
            Write-Output "FAIL specbridge-branch-inventory: branch '$($branch.ref_name)' retention_posture must be 'preserve'."
            $script:failed = $true
            $branchFieldFail = $true
          }
        }
        if (-not $branchFieldFail) {
          Write-Output "PASS specbridge-branch-inventory: all branch entries have required fields, cleanup_permission=none, retention_posture=preserve."
        }

        $totalsFields = @(
          "total_refs",
          "local_branch_count",
          "origin_branch_count",
          "merged_into_main_count",
          "unmerged_into_main_count",
          "unknown_merge_status_count"
        )
        $branchTotalsFieldNames = @($biJson.inventory.totals.PSObject.Properties.Name)
        $missingBranchTotals = $totalsFields | Where-Object { $branchTotalsFieldNames -notcontains $_ }
        if ($missingBranchTotals.Count -gt 0) {
          Write-Output "FAIL specbridge-branch-inventory: totals missing fields: $($missingBranchTotals -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: totals has all required fields."
        }

        if ($biJson.inventory.totals.total_refs -ne $branches.Count) {
          Write-Output "FAIL specbridge-branch-inventory: totals.total_refs expected $($branches.Count), got $($biJson.inventory.totals.total_refs)."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: totals.total_refs matches branches count."
        }

        $localCount = @($branches | Where-Object { $_.ref_type -eq "local" }).Count
        $originCount = @($branches | Where-Object { $_.ref_type -eq "origin" }).Count
        if ($biJson.inventory.totals.local_branch_count -ne $localCount -or $biJson.inventory.totals.origin_branch_count -ne $originCount) {
          Write-Output "FAIL specbridge-branch-inventory: local/origin totals do not match branch entries."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: local/origin totals match branch entries."
        }

        $prefixCounts = @($biJson.inventory.prefix_counts)
        $prefixTotal = 0
        foreach ($prefixEntry in $prefixCounts) {
          $prefixTotal += [int] $prefixEntry.count
        }
        if ($prefixTotal -ne $branches.Count) {
          Write-Output "FAIL specbridge-branch-inventory: prefix counts expected total $($branches.Count), got $prefixTotal."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory: prefix counts match branches count."
        }
      }
    }

    # 5. No mutation without OutputPath: no inventory file written
    $biInventoryArtifact = Join-Path (Get-Location).Path ".specbridge/branch-inventory/current.inventory.json"
    $biInventoryExistedBefore = Test-Path $biInventoryArtifact
    $biInventoryOriginalRaw = $null
    if ($biInventoryExistedBefore) {
      $biInventoryOriginalRaw = Get-Content $biInventoryArtifact -Raw -Encoding UTF8
    }
    Remove-Item $biInventoryArtifact -Force -ErrorAction SilentlyContinue
    $biNoPathResult = Invoke-Cli -Arguments @("specbridge-branch-inventory")
    if (Test-Path $biInventoryArtifact) {
      Write-Output "FAIL specbridge-branch-inventory-no-mutation: inventory file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-branch-inventory-no-mutation: no inventory file written without -OutputPath."
    }

    # 6. OutputPath behavior: writes inventory to declared path
    $biOutputResult = Invoke-Cli -Arguments @("specbridge-branch-inventory", "-OutputPath", ".specbridge/branch-inventory/current.inventory.json", "-Force")
    Assert-Success `
      -Name "specbridge-branch-inventory-output-path" `
      -Result $biOutputResult `
      -ExpectedPattern '"output_path"'

    if ($biOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $biInventoryArtifact)) {
        Write-Output "FAIL specbridge-branch-inventory-output-path: inventory file was not written."
        $script:failed = $true
      } else {
        $writtenBranchInventory = $null
        try {
          $writtenBranchInventory = Get-Content $biInventoryArtifact -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
        if ($null -eq $writtenBranchInventory) {
          Write-Output "FAIL specbridge-branch-inventory-output-path: written inventory is not valid JSON."
          $script:failed = $true
        } elseif ($writtenBranchInventory.command -ne "specbridge-branch-inventory") {
          Write-Output "FAIL specbridge-branch-inventory-output-path: written inventory command field mismatch."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-inventory-output-path: inventory file written and valid."
        }
      }

      # Force required when replacing
      $biExistingResult = Invoke-Cli -Arguments @("specbridge-branch-inventory", "-OutputPath", ".specbridge/branch-inventory/current.inventory.json")
      Assert-Failure `
        -Name "specbridge-branch-inventory-output-path-requires-force" `
        -Result $biExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($biInventoryExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($biInventoryArtifact, $biInventoryOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $biInventoryArtifact -Force -ErrorAction SilentlyContinue
    }

    # 7. OutputPath outside the contract artifact must fail
    $biBadPathResult = Invoke-Cli -Arguments @("specbridge-branch-inventory", "-OutputPath", "docs/bad-branch-inventory.json")
    Assert-Failure `
      -Name "specbridge-branch-inventory-bad-output-path" `
      -Result $biBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/branch-inventory/current.inventory.json"

    # specbridge-branch-cleanup-policy tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $bcpResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy")
    Assert-Success `
      -Name "specbridge-branch-cleanup-policy" `
      -Result $bcpResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-branch-cleanup-policy"'

    # 2. Deterministic output: two read-only calls produce identical output
    $bcpRepeatResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy")
    if ($bcpResult.ExitCode -eq 0 -and $bcpRepeatResult.ExitCode -eq 0) {
      if ($bcpResult.Text.Trim() -ceq $bcpRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-branch-cleanup-policy-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-branch-cleanup-policy-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($bcpResult.ExitCode -eq 0) {
      $bcpJson = $null
      try { $bcpJson = $bcpResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $bcpJson) {
        Write-Output "FAIL specbridge-branch-cleanup-policy: output was not valid JSON."
        $script:failed = $true
      } else {
        # ok field
        if ($bcpJson.ok -ne $true) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: ok is true."
        }

        # 3. Required top-level fields in evaluation
        $requiredEvalFields = @(
          "command", "policy_metadata", "enforcement_status",
          "totals", "candidate_counts", "blocked_counts",
          "required_future_gates", "branch_evaluations", "read_only_note"
        )
        $evalFieldNames = @($bcpJson.evaluation.PSObject.Properties.Name)
        $missingEvalFields = $requiredEvalFields | Where-Object { $evalFieldNames -notcontains $_ }
        if ($missingEvalFields.Count -gt 0) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: evaluation missing fields: $($missingEvalFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: evaluation has all required fields."
        }

        # enforcement_status must be "none"
        if ($bcpJson.evaluation.enforcement_status -ne "none") {
          Write-Output "FAIL specbridge-branch-cleanup-policy: enforcement_status expected 'none', got '$($bcpJson.evaluation.enforcement_status)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: enforcement_status is none."
        }

        foreach ($blockedVerb in @("delete", "prune", "rename", "move", "archive", "fetch", "pull", "force-push")) {
          if ($bcpJson.evaluation.read_only_note -notmatch [regex]::Escape($blockedVerb)) {
            Write-Output "FAIL specbridge-branch-cleanup-policy: read_only_note missing '$blockedVerb'."
            $script:failed = $true
          }
        }

        # policy_metadata fields
        $requiredPmFields = @("policy_id", "schema_version", "status", "enforcement", "cleanup_permission")
        $pmFieldNames = @($bcpJson.evaluation.policy_metadata.PSObject.Properties.Name)
        $missingPm = $requiredPmFields | Where-Object { $pmFieldNames -notcontains $_ }
        if ($missingPm.Count -gt 0) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: policy_metadata missing fields: $($missingPm -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: policy_metadata has all required fields."
        }

        if ($bcpJson.evaluation.policy_metadata.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-branch-cleanup-policy: policy_metadata.cleanup_permission must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: policy_metadata.cleanup_permission is none."
        }

        # totals fields
        $requiredTotalsFields = @("total_refs", "evaluated", "blocked_count")
        $totalsFieldNames = @($bcpJson.evaluation.totals.PSObject.Properties.Name)
        $missingTotals = $requiredTotalsFields | Where-Object { $totalsFieldNames -notcontains $_ }
        if ($missingTotals.Count -gt 0) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: totals missing fields: $($missingTotals -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: totals has all required fields."
        }

        # required_future_gates must be non-empty
        $gates = @($bcpJson.evaluation.required_future_gates)
        if ($gates.Count -eq 0) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: required_future_gates is empty."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: required_future_gates has $($gates.Count) entries."
        }

        # 4. cleanup_permission=none for all branch_evaluations
        $branchEvals = @($bcpJson.evaluation.branch_evaluations)
        $branchEvalFail = $false
        $requiredBranchEvalFields = @("ref_name", "branch_name", "ref_type", "candidate_class", "cleanup_permission", "future_gate")
        foreach ($be in $branchEvals) {
          $beFieldNames = @($be.PSObject.Properties.Name)
          $missingBe = $requiredBranchEvalFields | Where-Object { $beFieldNames -notcontains $_ }
          if ($missingBe.Count -gt 0) {
            Write-Output "FAIL specbridge-branch-cleanup-policy: branch_evaluation '$($be.ref_name)' missing fields: $($missingBe -join ', ')."
            $script:failed = $true
            $branchEvalFail = $true
          }
          if ($be.cleanup_permission -ne "none") {
            Write-Output "FAIL specbridge-branch-cleanup-policy: branch_evaluation '$($be.ref_name)' cleanup_permission must be 'none', got '$($be.cleanup_permission)'."
            $script:failed = $true
            $branchEvalFail = $true
          }
          $validClasses = @("merged_local", "merged_origin", "unmerged_local", "unmerged_origin", "unknown_merge_status")
          if ($validClasses -notcontains $be.candidate_class) {
            Write-Output "FAIL specbridge-branch-cleanup-policy: branch_evaluation '$($be.ref_name)' invalid candidate_class '$($be.candidate_class)'."
            $script:failed = $true
            $branchEvalFail = $true
          }
          $validGates = @("activation_required", "blocked")
          if ($validGates -notcontains $be.future_gate) {
            Write-Output "FAIL specbridge-branch-cleanup-policy: branch_evaluation '$($be.ref_name)' invalid future_gate '$($be.future_gate)'."
            $script:failed = $true
            $branchEvalFail = $true
          }
        }
        if (-not $branchEvalFail) {
          Write-Output "PASS specbridge-branch-cleanup-policy: all branch_evaluations have required fields, cleanup_permission=none, valid class and gate."
        }

        # totals.evaluated must match branch_evaluations count
        if ($bcpJson.evaluation.totals.evaluated -ne $branchEvals.Count) {
          Write-Output "FAIL specbridge-branch-cleanup-policy: totals.evaluated expected $($branchEvals.Count), got $($bcpJson.evaluation.totals.evaluated)."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy: totals.evaluated matches branch_evaluations count."
        }
      }
    }

    # 5. No mutation without OutputPath: no policy evaluation file written
    $bcpArtifact = Join-Path (Get-Location).Path ".specbridge/branch-cleanup/current.policy-evaluation.json"
    $bcpArtifactExistedBefore = Test-Path $bcpArtifact
    $bcpArtifactOriginalRaw = $null
    if ($bcpArtifactExistedBefore) {
      $bcpArtifactOriginalRaw = Get-Content $bcpArtifact -Raw -Encoding UTF8
    }
    Remove-Item $bcpArtifact -Force -ErrorAction SilentlyContinue
    $bcpNoPathResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy")
    if (Test-Path $bcpArtifact) {
      Write-Output "FAIL specbridge-branch-cleanup-policy-no-mutation: policy evaluation file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-branch-cleanup-policy-no-mutation: no policy evaluation file written without -OutputPath."
    }

    # 6. OutputPath behavior: writes evaluation to declared path
    $bcpOutputResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy", "-OutputPath", ".specbridge/branch-cleanup/current.policy-evaluation.json", "-Force")
    Assert-Success `
      -Name "specbridge-branch-cleanup-policy-output-path" `
      -Result $bcpOutputResult `
      -ExpectedPattern '"output_path"'

    if ($bcpOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $bcpArtifact)) {
        Write-Output "FAIL specbridge-branch-cleanup-policy-output-path: policy evaluation file was not written."
        $script:failed = $true
      } else {
        $writtenEval = $null
        try {
          $writtenEval = Get-Content $bcpArtifact -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
        if ($null -eq $writtenEval) {
          Write-Output "FAIL specbridge-branch-cleanup-policy-output-path: written evaluation is not valid JSON."
          $script:failed = $true
        } elseif ($writtenEval.command -ne "specbridge-branch-cleanup-policy") {
          Write-Output "FAIL specbridge-branch-cleanup-policy-output-path: written evaluation command field mismatch."
          $script:failed = $true
        } elseif ($writtenEval.policy_metadata.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-branch-cleanup-policy-output-path: written evaluation policy_metadata.cleanup_permission must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-branch-cleanup-policy-output-path: evaluation file written, valid, cleanup_permission=none."
        }
      }

      # 7. Force required when replacing
      $bcpExistingResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy", "-OutputPath", ".specbridge/branch-cleanup/current.policy-evaluation.json")
      Assert-Failure `
        -Name "specbridge-branch-cleanup-policy-output-path-requires-force" `
        -Result $bcpExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($bcpArtifactExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($bcpArtifact, $bcpArtifactOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $bcpArtifact -Force -ErrorAction SilentlyContinue
    }

    # 8. OutputPath outside the contract artifact must fail
    $bcpBadPathResult = Invoke-Cli -Arguments @("specbridge-branch-cleanup-policy", "-OutputPath", "docs/bad-policy-evaluation.json")
    Assert-Failure `
      -Name "specbridge-branch-cleanup-policy-bad-output-path" `
      -Result $bcpBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/branch-cleanup/current.policy-evaluation.json"

    # 9. artifact-inventory includes branch_cleanup_policy family
    $bcpAiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($bcpAiResult.ExitCode -eq 0) {
      $bcpAiJson = $null
      try { $bcpAiJson = $bcpAiResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -ne $bcpAiJson) {
        $bcpFamilies = @($bcpAiJson.inventory.families)
        $bcpFamilyIds = $bcpFamilies | ForEach-Object { $_.family_id }
        if ($bcpFamilyIds -contains "branch_cleanup_policy") {
          $bcpFamily = $bcpFamilies | Where-Object { $_.family_id -eq "branch_cleanup_policy" }
          if ($bcpFamily.repository_path -eq ".specbridge/branch-cleanup" -and $bcpFamily.cleanup_permission -eq "none") {
            Write-Output "PASS specbridge-branch-cleanup-policy-artifact-family: branch_cleanup_policy family present with correct path and cleanup_permission=none."
          } else {
            Write-Output "FAIL specbridge-branch-cleanup-policy-artifact-family: branch_cleanup_policy family has unexpected path or cleanup_permission."
            $script:failed = $true
          }
        } else {
          Write-Output "FAIL specbridge-branch-cleanup-policy-artifact-family: branch_cleanup_policy family not found in artifact inventory."
          $script:failed = $true
        }
      }
    }

    # specbridge-artifact-retention-policy tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $arpResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy")
    Assert-Success `
      -Name "specbridge-artifact-retention-policy" `
      -Result $arpResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-artifact-retention-policy"'

    # 2. Deterministic output: two read-only calls produce identical output
    $arpRepeatResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy")
    if ($arpResult.ExitCode -eq 0 -and $arpRepeatResult.ExitCode -eq 0) {
      if ($arpResult.Text.Trim() -ceq $arpRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-artifact-retention-policy-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-artifact-retention-policy-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($arpResult.ExitCode -eq 0) {
      $arpJson = $null
      try { $arpJson = $arpResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $arpJson) {
        Write-Output "FAIL specbridge-artifact-retention-policy: output was not valid JSON."
        $script:failed = $true
      } else {
        # ok field
        if ($arpJson.ok -ne $true) {
          Write-Output "FAIL specbridge-artifact-retention-policy: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: ok is true."
        }

        # 3. Required top-level fields in evaluation
        $requiredArpEvalFields = @(
          "command", "policy_metadata", "enforcement_status",
          "totals", "family_class_counts", "blocked_counts",
          "required_future_gates", "family_evaluations", "read_only_note"
        )
        $arpEvalFieldNames = @($arpJson.evaluation.PSObject.Properties.Name)
        $missingArpEvalFields = $requiredArpEvalFields | Where-Object { $arpEvalFieldNames -notcontains $_ }
        if ($missingArpEvalFields.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-retention-policy: evaluation missing fields: $($missingArpEvalFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: evaluation has all required fields."
        }

        # enforcement_status must be "none"
        if ($arpJson.evaluation.enforcement_status -ne "none") {
          Write-Output "FAIL specbridge-artifact-retention-policy: enforcement_status expected 'none', got '$($arpJson.evaluation.enforcement_status)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: enforcement_status is none."
        }

        # policy_metadata fields
        $requiredArpPmFields = @("policy_id", "schema_version", "status", "enforcement", "cleanup_permission")
        $arpPmFieldNames = @($arpJson.evaluation.policy_metadata.PSObject.Properties.Name)
        $missingArpPm = $requiredArpPmFields | Where-Object { $arpPmFieldNames -notcontains $_ }
        if ($missingArpPm.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-retention-policy: policy_metadata missing fields: $($missingArpPm -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: policy_metadata has all required fields."
        }

        if ($arpJson.evaluation.policy_metadata.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-artifact-retention-policy: policy_metadata.cleanup_permission must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: policy_metadata.cleanup_permission is none."
        }

        # totals fields
        $requiredArpTotalsFields = @("total_families", "evaluated", "blocked_count")
        $arpTotalsFieldNames = @($arpJson.evaluation.totals.PSObject.Properties.Name)
        $missingArpTotals = $requiredArpTotalsFields | Where-Object { $arpTotalsFieldNames -notcontains $_ }
        if ($missingArpTotals.Count -gt 0) {
          Write-Output "FAIL specbridge-artifact-retention-policy: totals missing fields: $($missingArpTotals -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: totals has all required fields."
        }

        # required_future_gates must be non-empty
        $arpGates = @($arpJson.evaluation.required_future_gates)
        if ($arpGates.Count -eq 0) {
          Write-Output "FAIL specbridge-artifact-retention-policy: required_future_gates is empty."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: required_future_gates has $($arpGates.Count) entries."
        }

        # 4. cleanup_permission=none for all family_evaluations
        $arpFamilyEvals = @($arpJson.evaluation.family_evaluations)
        $arpFamilyEvalFail = $false
        $requiredArpFamilyEvalFields = @("family_id", "repository_path", "family_class", "file_count", "total_bytes", "cleanup_permission", "retention_posture", "future_gate")
        foreach ($fe in $arpFamilyEvals) {
          $feFieldNames = @($fe.PSObject.Properties.Name)
          $missingFe = $requiredArpFamilyEvalFields | Where-Object { $feFieldNames -notcontains $_ }
          if ($missingFe.Count -gt 0) {
            Write-Output "FAIL specbridge-artifact-retention-policy: family_evaluation '$($fe.family_id)' missing fields: $($missingFe -join ', ')."
            $script:failed = $true
            $arpFamilyEvalFail = $true
          }
          if ($fe.cleanup_permission -ne "none") {
            Write-Output "FAIL specbridge-artifact-retention-policy: family_evaluation '$($fe.family_id)' cleanup_permission must be 'none', got '$($fe.cleanup_permission)'."
            $script:failed = $true
            $arpFamilyEvalFail = $true
          }
          if ($fe.retention_posture -ne "preserve") {
            Write-Output "FAIL specbridge-artifact-retention-policy: family_evaluation '$($fe.family_id)' retention_posture must be 'preserve', got '$($fe.retention_posture)'."
            $script:failed = $true
            $arpFamilyEvalFail = $true
          }
          $validArpGates = @("activation_required", "blocked")
          if ($validArpGates -notcontains $fe.future_gate) {
            Write-Output "FAIL specbridge-artifact-retention-policy: family_evaluation '$($fe.family_id)' invalid future_gate '$($fe.future_gate)'."
            $script:failed = $true
            $arpFamilyEvalFail = $true
          }
        }
        if (-not $arpFamilyEvalFail) {
          Write-Output "PASS specbridge-artifact-retention-policy: all family_evaluations have required fields, cleanup_permission=none, valid posture and gate."
        }

        # totals.evaluated must match family_evaluations count
        if ($arpJson.evaluation.totals.evaluated -ne $arpFamilyEvals.Count) {
          Write-Output "FAIL specbridge-artifact-retention-policy: totals.evaluated expected $($arpFamilyEvals.Count), got $($arpJson.evaluation.totals.evaluated)."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy: totals.evaluated matches family_evaluations count."
        }
      }
    }

    # 5. No mutation without OutputPath: no policy evaluation file written
    $arpArtifact = Join-Path (Get-Location).Path ".specbridge/artifact-retention/current.policy-evaluation.json"
    $arpArtifactExistedBefore = Test-Path $arpArtifact
    $arpArtifactOriginalRaw = $null
    if ($arpArtifactExistedBefore) {
      $arpArtifactOriginalRaw = Get-Content $arpArtifact -Raw -Encoding UTF8
    }
    Remove-Item $arpArtifact -Force -ErrorAction SilentlyContinue
    $arpNoPathResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy")
    if (Test-Path $arpArtifact) {
      Write-Output "FAIL specbridge-artifact-retention-policy-no-mutation: policy evaluation file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-artifact-retention-policy-no-mutation: no policy evaluation file written without -OutputPath."
    }

    # 6. OutputPath behavior: writes evaluation to declared path
    $arpOutputResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy", "-OutputPath", ".specbridge/artifact-retention/current.policy-evaluation.json", "-Force")
    Assert-Success `
      -Name "specbridge-artifact-retention-policy-output-path" `
      -Result $arpOutputResult `
      -ExpectedPattern '"output_path"'

    if ($arpOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $arpArtifact)) {
        Write-Output "FAIL specbridge-artifact-retention-policy-output-path: policy evaluation file was not written."
        $script:failed = $true
      } else {
        $arpWrittenEval = $null
        try {
          $arpWrittenEval = Get-Content $arpArtifact -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
        if ($null -eq $arpWrittenEval) {
          Write-Output "FAIL specbridge-artifact-retention-policy-output-path: written evaluation is not valid JSON."
          $script:failed = $true
        } elseif ($arpWrittenEval.command -ne "specbridge-artifact-retention-policy") {
          Write-Output "FAIL specbridge-artifact-retention-policy-output-path: written evaluation command field mismatch."
          $script:failed = $true
        } elseif ($arpWrittenEval.policy_metadata.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-artifact-retention-policy-output-path: written evaluation policy_metadata.cleanup_permission must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-artifact-retention-policy-output-path: evaluation file written, valid, cleanup_permission=none."
        }
      }

      # 7. Force required when replacing
      $arpExistingResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy", "-OutputPath", ".specbridge/artifact-retention/current.policy-evaluation.json")
      Assert-Failure `
        -Name "specbridge-artifact-retention-policy-output-path-requires-force" `
        -Result $arpExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($arpArtifactExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($arpArtifact, $arpArtifactOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $arpArtifact -Force -ErrorAction SilentlyContinue
    }

    # 8. OutputPath outside the contract artifact must fail
    $arpBadPathResult = Invoke-Cli -Arguments @("specbridge-artifact-retention-policy", "-OutputPath", "docs/bad-policy-evaluation.json")
    Assert-Failure `
      -Name "specbridge-artifact-retention-policy-bad-output-path" `
      -Result $arpBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/artifact-retention/current.policy-evaluation.json"

    # 9. artifact-inventory includes artifact_retention_policy family
    $arpAiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($arpAiResult.ExitCode -eq 0) {
      $arpAiJson = $null
      try { $arpAiJson = $arpAiResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -ne $arpAiJson) {
        $arpFamilies = @($arpAiJson.inventory.families)
        $arpFamilyIds = $arpFamilies | ForEach-Object { $_.family_id }
        if ($arpFamilyIds -contains "artifact_retention_policy") {
          $arpFamily = $arpFamilies | Where-Object { $_.family_id -eq "artifact_retention_policy" }
          if ($arpFamily.repository_path -eq ".specbridge/artifact-retention" -and $arpFamily.cleanup_permission -eq "none") {
            Write-Output "PASS specbridge-artifact-retention-policy-artifact-family: artifact_retention_policy family present with correct path and cleanup_permission=none."
          } else {
            Write-Output "FAIL specbridge-artifact-retention-policy-artifact-family: artifact_retention_policy family has unexpected path or cleanup_permission."
            $script:failed = $true
          }
        } else {
          Write-Output "FAIL specbridge-artifact-retention-policy-artifact-family: artifact_retention_policy family not found in artifact inventory."
          $script:failed = $true
        }
      }
    }

    # specbridge-repository-health-summary tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $rhsResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary")
    Assert-Success `
      -Name "specbridge-repository-health-summary" `
      -Result $rhsResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-repository-health-summary"'

    # 2. Deterministic output: two read-only calls produce identical output
    $rhsRepeatResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary")
    if ($rhsResult.ExitCode -eq 0 -and $rhsRepeatResult.ExitCode -eq 0) {
      if ($rhsResult.Text.Trim() -ceq $rhsRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-repository-health-summary-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-repository-health-summary-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($rhsResult.ExitCode -eq 0) {
      $rhsJson = $null
      try { $rhsJson = $rhsResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $rhsJson) {
        Write-Output "FAIL specbridge-repository-health-summary: output was not valid JSON."
        $script:failed = $true
      } else {
        if ($rhsJson.ok -ne $true) {
          Write-Output "FAIL specbridge-repository-health-summary: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: ok is true."
        }

        # 3. Required top-level fields in summary
        $requiredSummaryFields = @(
          "command", "generated_at", "overall_health_posture", "branch_posture",
          "artifact_posture", "policy_posture", "cleanup_permission", "enforcement_status",
          "blocked_action_counts", "required_future_gates", "evidence_sources",
          "non_enforcement_note", "read_only_note"
        )
        $summaryFieldNames = @($rhsJson.summary.PSObject.Properties.Name)
        $missingSummaryFields = $requiredSummaryFields | Where-Object { $summaryFieldNames -notcontains $_ }
        if ($missingSummaryFields.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: summary missing fields: $($missingSummaryFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: summary has all required fields."
        }

        # cleanup_permission and enforcement_status must be "none"
        if ($rhsJson.summary.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-repository-health-summary: cleanup_permission expected 'none', got '$($rhsJson.summary.cleanup_permission)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: cleanup_permission is none."
        }

        if ($rhsJson.summary.enforcement_status -ne "none") {
          Write-Output "FAIL specbridge-repository-health-summary: enforcement_status expected 'none', got '$($rhsJson.summary.enforcement_status)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: enforcement_status is none."
        }

        # overall_health_posture must be a known value
        $validPostures = @("stable_no_debt", "debt_present_cleanup_blocked")
        if ($validPostures -notcontains $rhsJson.summary.overall_health_posture) {
          Write-Output "FAIL specbridge-repository-health-summary: invalid overall_health_posture '$($rhsJson.summary.overall_health_posture)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: overall_health_posture is valid."
        }

        # branch_posture fields
        $requiredBranchPostureFields = @("total_refs", "local_branch_count", "origin_branch_count", "merged_into_main_count", "unmerged_into_main_count", "unknown_merge_status_count", "branch_mutation_policy")
        $branchPostureFieldNames = @($rhsJson.summary.branch_posture.PSObject.Properties.Name)
        $missingBranchPosture = $requiredBranchPostureFields | Where-Object { $branchPostureFieldNames -notcontains $_ }
        if ($missingBranchPosture.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: branch_posture missing fields: $($missingBranchPosture -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: branch_posture has all required fields."
        }

        if ($rhsJson.summary.branch_posture.branch_mutation_policy -ne "none") {
          Write-Output "FAIL specbridge-repository-health-summary: branch_posture.branch_mutation_policy must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: branch_posture.branch_mutation_policy is none."
        }

        # artifact_posture fields
        $requiredArtifactPostureFields = @("family_count", "total_file_count", "total_bytes", "retention_enforcement")
        $artifactPostureFieldNames = @($rhsJson.summary.artifact_posture.PSObject.Properties.Name)
        $missingArtifactPosture = $requiredArtifactPostureFields | Where-Object { $artifactPostureFieldNames -notcontains $_ }
        if ($missingArtifactPosture.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: artifact_posture missing fields: $($missingArtifactPosture -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: artifact_posture has all required fields."
        }

        if ($rhsJson.summary.artifact_posture.retention_enforcement -ne "none") {
          Write-Output "FAIL specbridge-repository-health-summary: artifact_posture.retention_enforcement must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: artifact_posture.retention_enforcement is none."
        }

        # policy_posture fields
        $requiredPolicyPostureFields = @("branch_cleanup_policy", "artifact_retention_policy")
        $policyPostureFieldNames = @($rhsJson.summary.policy_posture.PSObject.Properties.Name)
        $missingPolicyPosture = $requiredPolicyPostureFields | Where-Object { $policyPostureFieldNames -notcontains $_ }
        if ($missingPolicyPosture.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: policy_posture missing fields: $($missingPolicyPosture -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: policy_posture has all required fields."
        }

        $requiredPolicyEntryFields = @("policy_id", "status", "enforcement", "cleanup_permission")
        foreach ($policyEntryName in @("branch_cleanup_policy", "artifact_retention_policy")) {
          $policyEntry = $rhsJson.summary.policy_posture.$policyEntryName
          $policyEntryFieldNames = @($policyEntry.PSObject.Properties.Name)
          $missingPolicyEntry = $requiredPolicyEntryFields | Where-Object { $policyEntryFieldNames -notcontains $_ }
          if ($missingPolicyEntry.Count -gt 0) {
            Write-Output "FAIL specbridge-repository-health-summary: policy_posture.$policyEntryName missing fields: $($missingPolicyEntry -join ', ')."
            $script:failed = $true
          } elseif ($policyEntry.cleanup_permission -ne "none") {
            Write-Output "FAIL specbridge-repository-health-summary: policy_posture.$policyEntryName.cleanup_permission must be 'none'."
            $script:failed = $true
          } else {
            Write-Output "PASS specbridge-repository-health-summary: policy_posture.$policyEntryName has required fields and cleanup_permission=none."
          }
        }

        # blocked_action_counts fields and arithmetic
        $requiredBlockedFields = @("branch_cleanup_blocked", "artifact_retention_blocked", "total_blocked")
        $blockedFieldNames = @($rhsJson.summary.blocked_action_counts.PSObject.Properties.Name)
        $missingBlockedFields = $requiredBlockedFields | Where-Object { $blockedFieldNames -notcontains $_ }
        if ($missingBlockedFields.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: blocked_action_counts missing fields: $($missingBlockedFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: blocked_action_counts has all required fields."
        }

        $expectedTotalBlocked = [int] $rhsJson.summary.blocked_action_counts.branch_cleanup_blocked + [int] $rhsJson.summary.blocked_action_counts.artifact_retention_blocked
        if ([int] $rhsJson.summary.blocked_action_counts.total_blocked -ne $expectedTotalBlocked) {
          Write-Output "FAIL specbridge-repository-health-summary: blocked_action_counts.total_blocked expected $expectedTotalBlocked, got $($rhsJson.summary.blocked_action_counts.total_blocked)."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: blocked_action_counts.total_blocked matches sum of components."
        }

        # required_future_gates must be non-empty
        $rhsGates = @($rhsJson.summary.required_future_gates)
        if ($rhsGates.Count -eq 0) {
          Write-Output "FAIL specbridge-repository-health-summary: required_future_gates is empty."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: required_future_gates has $($rhsGates.Count) entries."
        }

        # evidence_sources must reference the four evidence builders
        $rhsSources = @($rhsJson.summary.evidence_sources | ForEach-Object { $_.evidence_id })
        $expectedSources = @("branch_inventory", "branch_cleanup_policy", "artifact_inventory", "artifact_retention_policy")
        $missingSources = $expectedSources | Where-Object { $rhsSources -notcontains $_ }
        if ($missingSources.Count -gt 0) {
          Write-Output "FAIL specbridge-repository-health-summary: evidence_sources missing: $($missingSources -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary: evidence_sources references all four evidence builders."
        }

        # read_only_note and non_enforcement_note must mention key blocked verbs
        foreach ($blockedVerb in @("delete", "prune", "rename", "move", "archive", "fetch", "pull", "force-push")) {
          if ($rhsJson.summary.read_only_note -notmatch [regex]::Escape($blockedVerb)) {
            Write-Output "FAIL specbridge-repository-health-summary: read_only_note missing '$blockedVerb'."
            $script:failed = $true
          }
        }
      }
    }

    # 4. No mutation without OutputPath: no summary file written
    $rhsArtifact = Join-Path (Get-Location).Path ".specbridge/repository-health/current.summary.json"
    $rhsArtifactExistedBefore = Test-Path $rhsArtifact
    $rhsArtifactOriginalRaw = $null
    if ($rhsArtifactExistedBefore) {
      $rhsArtifactOriginalRaw = Get-Content $rhsArtifact -Raw -Encoding UTF8
    }
    Remove-Item $rhsArtifact -Force -ErrorAction SilentlyContinue
    $rhsNoPathResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary")
    if (Test-Path $rhsArtifact) {
      Write-Output "FAIL specbridge-repository-health-summary-no-mutation: summary file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-repository-health-summary-no-mutation: no summary file written without -OutputPath."
    }

    # 5. OutputPath behavior: writes summary to declared path
    $rhsOutputResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary", "-OutputPath", ".specbridge/repository-health/current.summary.json", "-Force")
    Assert-Success `
      -Name "specbridge-repository-health-summary-output-path" `
      -Result $rhsOutputResult `
      -ExpectedPattern '"output_path"'

    if ($rhsOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $rhsArtifact)) {
        Write-Output "FAIL specbridge-repository-health-summary-output-path: summary file was not written."
        $script:failed = $true
      } else {
        $rhsWrittenSummary = $null
        try {
          $rhsWrittenSummary = Get-Content $rhsArtifact -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
        if ($null -eq $rhsWrittenSummary) {
          Write-Output "FAIL specbridge-repository-health-summary-output-path: written summary is not valid JSON."
          $script:failed = $true
        } elseif ($rhsWrittenSummary.command -ne "specbridge-repository-health-summary") {
          Write-Output "FAIL specbridge-repository-health-summary-output-path: written summary command field mismatch."
          $script:failed = $true
        } elseif ($rhsWrittenSummary.cleanup_permission -ne "none") {
          Write-Output "FAIL specbridge-repository-health-summary-output-path: written summary cleanup_permission must be 'none'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-repository-health-summary-output-path: summary file written, valid, cleanup_permission=none."
        }
      }

      # 6. Force required when replacing
      $rhsExistingResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary", "-OutputPath", ".specbridge/repository-health/current.summary.json")
      Assert-Failure `
        -Name "specbridge-repository-health-summary-output-path-requires-force" `
        -Result $rhsExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($rhsArtifactExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($rhsArtifact, $rhsArtifactOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $rhsArtifact -Force -ErrorAction SilentlyContinue
    }

    # 7. OutputPath outside the contract artifact must fail
    $rhsBadPathResult = Invoke-Cli -Arguments @("specbridge-repository-health-summary", "-OutputPath", "docs/bad-repository-health-summary.json")
    Assert-Failure `
      -Name "specbridge-repository-health-summary-bad-output-path" `
      -Result $rhsBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/repository-health/current.summary.json"

    # 8. artifact-inventory includes repository_health_summary family
    $rhsAiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($rhsAiResult.ExitCode -eq 0) {
      $rhsAiJson = $null
      try { $rhsAiJson = $rhsAiResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -ne $rhsAiJson) {
        $rhsFamilies = @($rhsAiJson.inventory.families)
        $rhsFamilyIds = $rhsFamilies | ForEach-Object { $_.family_id }
        if ($rhsFamilyIds -contains "repository_health_summary") {
          $rhsFamily = $rhsFamilies | Where-Object { $_.family_id -eq "repository_health_summary" }
          if ($rhsFamily.repository_path -eq ".specbridge/repository-health" -and $rhsFamily.cleanup_permission -eq "none") {
            Write-Output "PASS specbridge-repository-health-summary-artifact-family: repository_health_summary family present with correct path and cleanup_permission=none."
          } else {
            Write-Output "FAIL specbridge-repository-health-summary-artifact-family: repository_health_summary family has unexpected path or cleanup_permission."
            $script:failed = $true
          }
        } else {
          Write-Output "FAIL specbridge-repository-health-summary-artifact-family: repository_health_summary family not found in artifact inventory."
          $script:failed = $true
        }
      }
    }

    # specbridge-standard-readiness tests

    # 1. Command shape: exits 0, returns JSON with command and ok fields
    $srResult = Invoke-Cli -Arguments @("specbridge-standard-readiness")
    Assert-Success `
      -Name "specbridge-standard-readiness" `
      -Result $srResult `
      -ExpectedPattern '"command"\s*:\s*"specbridge-standard-readiness"'

    # 2. Deterministic output: two read-only calls produce identical output
    $srRepeatResult = Invoke-Cli -Arguments @("specbridge-standard-readiness")
    if ($srResult.ExitCode -eq 0 -and $srRepeatResult.ExitCode -eq 0) {
      if ($srResult.Text.Trim() -ceq $srRepeatResult.Text.Trim()) {
        Write-Output "PASS specbridge-standard-readiness-deterministic: repeated read-only output is stable."
      } else {
        Write-Output "FAIL specbridge-standard-readiness-deterministic: repeated read-only output changed."
        $script:failed = $true
      }
    }

    if ($srResult.ExitCode -eq 0) {
      $srJson = $null
      try { $srJson = $srResult.Text.Trim() | ConvertFrom-Json } catch {}

      if ($null -eq $srJson) {
        Write-Output "FAIL specbridge-standard-readiness: output was not valid JSON."
        $script:failed = $true
      } else {
        if ($srJson.ok -ne $true) {
          Write-Output "FAIL specbridge-standard-readiness: ok field is not true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: ok is true."
        }

        $requiredSrFields = @(
          "command", "ok", "schema_version", "readiness", "recommended_next_action",
          "task_selection", "doctor", "repository_health", "token_context_governance",
          "mcp_resource_surface", "standard_boundaries", "evidence_sources", "notes"
        )
        $srFieldNames = @($srJson.PSObject.Properties.Name)
        $missingSrFields = $requiredSrFields | Where-Object { $srFieldNames -notcontains $_ }
        if ($missingSrFields.Count -gt 0) {
          Write-Output "FAIL specbridge-standard-readiness: missing fields: $($missingSrFields -join ', ')."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: required fields present."
        }

        $validReadiness = @("ready_for_governed_task_intake", "continue_current_goal", "execute_eligible_task", "review_recommended", "blocked")
        if ($validReadiness -notcontains $srJson.readiness) {
          Write-Output "FAIL specbridge-standard-readiness: invalid readiness '$($srJson.readiness)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: readiness enum is valid."
        }

        $validNextActions = @("create_new_operator_task", "continue_current_goal", "execute_eligible_task")
        if ($validNextActions -notcontains $srJson.recommended_next_action) {
          Write-Output "FAIL specbridge-standard-readiness: invalid recommended_next_action '$($srJson.recommended_next_action)'."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: recommended_next_action is valid."
        }

        if ($srJson.repository_health.cleanup_permission -ne "none" -or $srJson.repository_health.enforcement_status -ne "none") {
          Write-Output "FAIL specbridge-standard-readiness: cleanup/enforcement posture must remain none."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: cleanup/enforcement posture remains none."
        }

        if ($srJson.standard_boundaries.launches_claude -eq $false -and
            $srJson.standard_boundaries.launches_codex -eq $false -and
            $srJson.standard_boundaries.calls_network -eq $false -and
            $srJson.standard_boundaries.mutates_github -eq $false -and
            $srJson.standard_boundaries.reads_secrets -eq $false -and
            $srJson.standard_boundaries.changes_billing -eq $false -and
            $srJson.standard_boundaries.changes_ci_cd_security -eq $false -and
            $srJson.standard_boundaries.deploys -eq $false -and
            $srJson.standard_boundaries.writes_output_artifact -eq $false) {
          Write-Output "PASS specbridge-standard-readiness: read-only/no-runtime/no-secret boundaries recorded."
        } else {
          Write-Output "FAIL specbridge-standard-readiness: standard boundary flags mismatch."
          $script:failed = $true
        }

        $validMcpStatuses = @("not_implemented", "readonly_local_runtime")
        if ($validMcpStatuses -notcontains $srJson.mcp_resource_surface.mcp_server_status -or $srJson.mcp_resource_surface.read_only_policy -ne $true) {
          Write-Output "FAIL specbridge-standard-readiness: MCP surface should remain read-only (got mcp_server_status=$($srJson.mcp_resource_surface.mcp_server_status))."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness: MCP surface is read-only (mcp_server_status=$($srJson.mcp_resource_surface.mcp_server_status))."
        }
      }
    }

    # 3. No mutation without OutputPath: readiness artifact unchanged
    $srArtifact = Join-Path (Get-Location).Path ".specbridge/standard-readiness/current.status.json"
    $srArtifactExistedBefore = Test-Path $srArtifact
    $srArtifactOriginalRaw = $null
    if ($srArtifactExistedBefore) {
      $srArtifactOriginalRaw = Get-Content $srArtifact -Raw -Encoding UTF8
    }
    Remove-Item $srArtifact -Force -ErrorAction SilentlyContinue
    $srNoPathResult = Invoke-Cli -Arguments @("specbridge-standard-readiness")
    if (Test-Path $srArtifact) {
      Write-Output "FAIL specbridge-standard-readiness-no-mutation: readiness file was written without -OutputPath."
      $script:failed = $true
    } else {
      Write-Output "PASS specbridge-standard-readiness-no-mutation: no readiness file written without -OutputPath."
    }

    # 4. OutputPath behavior: writes readiness artifact to declared path
    $srOutputResult = Invoke-Cli -Arguments @("specbridge-standard-readiness", "-OutputPath", ".specbridge/standard-readiness/current.status.json", "-Force")
    Assert-Success `
      -Name "specbridge-standard-readiness-output-path" `
      -Result $srOutputResult `
      -ExpectedPattern '"writes_output_artifact"\s*:\s*true'

    if ($srOutputResult.ExitCode -eq 0) {
      if (-not (Test-Path $srArtifact)) {
        Write-Output "FAIL specbridge-standard-readiness-output-path: readiness file was not written."
        $script:failed = $true
      } else {
        $srWritten = $null
        try { $srWritten = Get-Content $srArtifact -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
        if ($null -eq $srWritten) {
          Write-Output "FAIL specbridge-standard-readiness-output-path: written readiness file is not valid JSON."
          $script:failed = $true
        } elseif ($srWritten.command -ne "specbridge-standard-readiness") {
          Write-Output "FAIL specbridge-standard-readiness-output-path: written readiness command mismatch."
          $script:failed = $true
        } elseif ($srWritten.standard_boundaries.writes_output_artifact -ne $true) {
          Write-Output "FAIL specbridge-standard-readiness-output-path: writes_output_artifact should be true."
          $script:failed = $true
        } else {
          Write-Output "PASS specbridge-standard-readiness-output-path: readiness file written and valid."
        }
      }

      $srExistingResult = Invoke-Cli -Arguments @("specbridge-standard-readiness", "-OutputPath", ".specbridge/standard-readiness/current.status.json")
      Assert-Failure `
        -Name "specbridge-standard-readiness-output-path-requires-force" `
        -Result $srExistingResult `
        -ExpectedPattern "use -Force"
    }

    # Restore artifact state after mutation tests
    if ($srArtifactExistedBefore) {
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($srArtifact, $srArtifactOriginalRaw, $utf8NoBom)
    } else {
      Remove-Item $srArtifact -Force -ErrorAction SilentlyContinue
    }

    # 5. OutputPath outside the contract artifact must fail
    $srBadPathResult = Invoke-Cli -Arguments @("specbridge-standard-readiness", "-OutputPath", "docs/bad-standard-readiness.json")
    Assert-Failure `
      -Name "specbridge-standard-readiness-bad-output-path" `
      -Result $srBadPathResult `
      -ExpectedPattern "OutputPath must be .specbridge/standard-readiness/current.status.json"

    # 6. artifact-inventory includes standard_readiness family
    $srAiResult = Invoke-Cli -Arguments @("specbridge-artifact-inventory")
    if ($srAiResult.ExitCode -eq 0) {
      $srAiJson = $null
      try { $srAiJson = $srAiResult.Text.Trim() | ConvertFrom-Json } catch {}
      if ($null -ne $srAiJson) {
        $srFamilies = @($srAiJson.inventory.families)
        $srFamilyIds = $srFamilies | ForEach-Object { $_.family_id }
        if ($srFamilyIds -contains "standard_readiness") {
          $srFamily = $srFamilies | Where-Object { $_.family_id -eq "standard_readiness" }
          if ($srFamily.repository_path -eq ".specbridge/standard-readiness" -and $srFamily.cleanup_permission -eq "none") {
            Write-Output "PASS specbridge-standard-readiness-artifact-family: standard_readiness family present with correct path and cleanup_permission=none."
          } else {
            Write-Output "FAIL specbridge-standard-readiness-artifact-family: standard_readiness family has unexpected path or cleanup_permission."
            $script:failed = $true
          }
        } else {
          Write-Output "FAIL specbridge-standard-readiness-artifact-family: standard_readiness family not found in artifact inventory."
          $script:failed = $true
        }
      }
    }
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
