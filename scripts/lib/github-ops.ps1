# SpecBridge CLI library: github-ops
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Invoke-IssueToMergePlanCommand {
  if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Fail "TaskId is required for issue-to-merge-plan"
  }

  $safeTaskId = Convert-ToSafeName -Value $TaskId -FieldName "task_id"
  $contractSeed = New-StandardLoopContractSeed -TaskIdentifier $safeTaskId

  $issueReference = $RelatedIssue
  if ([string]::IsNullOrWhiteSpace($issueReference)) {
    $issueReference = $contractSeed.issue_reference
  }

  if ([string]::IsNullOrWhiteSpace($issueReference) -or $issueReference -eq "not_declared") {
    $issueReference = "not_declared"
  }

  $resolvedTitle = $Title
  if ([string]::IsNullOrWhiteSpace($resolvedTitle)) {
    $resolvedTitle = $safeTaskId
  }

  $resolvedGoal = $Goal
  if ([string]::IsNullOrWhiteSpace($resolvedGoal)) {
    $resolvedGoal = "Run the governed SpecBridge issue-to-merge loop for $safeTaskId."
  }

  $runPath = ".specbridge/issue-to-merge-runs/$safeTaskId.issue-to-merge-run.json"

  $phases = @(
    [ordered]@{
      order = 1
      id = "issue_intake"
      name = "GitHub issue intake"
      required_evidence = @("GitHub issue", ".specbridge/context/CURRENT_GOAL.md")
      operator_action = "verify_issue_exists_or_create_outside_plan_only_command"
      gate = "issue_has_goal_scope_acceptance_policy"
      writes_repository_files = $false
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 2
      id = "contract_package"
      name = "Execution contract, scope, report, and audit package"
      required_evidence = @(
        $contractSeed.contract_path,
        $contractSeed.scope_path,
        $contractSeed.final_report_path,
        $contractSeed.audit_packet_path,
        $contractSeed.chatgpt_audit_path
      )
      operator_action = "create_or_update_declared_repository_evidence"
      gate = "contract_scope_report_audit_validate"
      writes_repository_files = $true
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 3
      id = "local_validation"
      name = "Local validation gates"
      required_evidence = @("standard validation", "CLI tests", "smoke validation", "security gate", "review gate", "git diff --check")
      operator_action = "run_declared_local_gates"
      gate = "local_gates_pass"
      writes_repository_files = $false
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 4
      id = "pull_request"
      name = "Pull request creation or update"
      required_evidence = @("GitHub pull request URL", "PR body with validations and policy result")
      operator_action = "open_or_update_pr_outside_plan_only_command"
      gate = "pr_exists_and_targets_default_branch"
      writes_repository_files = $false
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 5
      id = "ci_review"
      name = "GitHub CI and review gates"
      required_evidence = @("Foundation Validation", "SpecBridge Review Gate", "SpecBridge PR Review Report", "Claude Review Non Blocking")
      operator_action = "wait_for_ci_outside_plan_only_command"
      gate = "ci_review_security_policy_pass"
      writes_repository_files = $false
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 6
      id = "policy_merge"
      name = "Policy-gated merge"
      required_evidence = @("passed CI", "passed tests", "no policy violation", "no protected files changed", "ChatGPT/Codex audit approved")
      operator_action = "merge_outside_plan_only_command_only_when_gates_pass"
      gate = "merge_allowed_by_policy"
      writes_repository_files = $false
      calls_github_from_command = $false
    },
    [ordered]@{
      order = 7
      id = "post_merge_memory"
      name = "Post-merge repository memory closure"
      required_evidence = @(".specbridge/context/CURRENT_GOAL.md", "merged pull request", "closed issue")
      operator_action = "record_next_goal_or_closure_after_merge"
      gate = "repository_memory_matches_merged_state"
      writes_repository_files = $true
      calls_github_from_command = $false
    }
  )

  $operator = [ordered]@{
    schema_version = "1"
    command = "issue-to-merge-plan"
    ok = $true
    mode = "plan_only"
    task_id = $safeTaskId
    title = $resolvedTitle
    goal = $resolvedGoal
    issue_reference = $issueReference
    repository_url = $RepositoryUrl
    base_branch = $BaseBranch
    recommended_branch = $contractSeed.recommended_branch
    current_branch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
    head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
    evidence_paths = [ordered]@{
      contract = $contractSeed.contract_path
      scope = $contractSeed.scope_path
      final_report = $contractSeed.final_report_path
      audit_packet = $contractSeed.audit_packet_path
      chatgpt_audit = $contractSeed.chatgpt_audit_path
      issue_to_merge_run = $runPath
      standard_loop_run = $contractSeed.standard_loop_run_path
    }
    phases = @($phases)
    required_gates = [ordered]@{
      local = @(
        "validate-contracts",
        "validate-contract-scopes",
        "validate-final-reports",
        "validate-audit-packets",
        "validate-chatgpt-audits",
        "validate-security-gates",
        "validate-review-gate",
        "test-specbridge-cli",
        "specbridge-smoke",
        "git diff --check"
      )
      github = @(
        "Foundation Validation",
        "SpecBridge Review Gate",
        "SpecBridge PR Review Report",
        "Claude Review Non Blocking"
      )
    }
    merge_conditions = @(
      "ci_passed",
      "tests_passed",
      "no_policy_violation",
      "no_protected_files_changed",
      "chatgpt_codex_audit_approved",
      "branch_mergeable",
      "deployment_not_requested"
    )
    post_merge_memory_closure = [ordered]@{
      required = $true
      current_goal_update = ".specbridge/context/CURRENT_GOAL.md"
      issue_closure_required = $true
      pr_merge_evidence_required = $true
      next_recommended_task_required = $true
    }
    policy_boundaries = @(
      "no-secrets",
      "no-production",
      "no-billing",
      "no-auth-security-change",
      "no-authorization-security-change",
      "no-database-change",
      "no-dependency-installation",
      "no-ci-cd-security-change",
      "no-deployment"
    )
    command_boundary = "plan-only does-not-create-issues does-not-open-prs does-not-wait-for-ci does-not-merge does-not-launch-claude-code does-not-launch-antigravity does-not-install-dependencies does-not-deploy"
    output_path = $null
  }

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = Assert-OutputPath `
      -Path $OutputPath `
      -Pattern "^\.specbridge/issue-to-merge-runs/.+\.issue-to-merge-run\.json$" `
      -Description "a .specbridge/issue-to-merge-runs/*.issue-to-merge-run.json operator artifact"

    $operator["output_path"] = $output
    Write-Utf8JsonFile -Path $output -Value $operator -Depth 12
  }

  Write-CliJson $operator -Depth 12
  exit 0
}

function New-GithubMutationOperation {
  param(
    [string] $Id,
    [string] $Name,
    [string[]] $RequiredEvidence,
    [string[]] $Preconditions,
    [string] $ConnectorAction,
    [bool] $MutatesGithub = $true,
    [bool] $WritesRepositoryFiles = $false
  )

  return [ordered]@{
    id = $Id
    name = $Name
    mutates_github = $MutatesGithub
    writes_repository_files = $WritesRepositoryFiles
    connector_action = $ConnectorAction
    required_evidence = @($RequiredEvidence)
    preconditions = @($Preconditions)
    stop_if_missing_evidence = $true
  }
}

function Invoke-IssueToMergeGithubCommand {
  if ([string]::IsNullOrWhiteSpace($TaskId)) {
    Fail "TaskId is required for issue-to-merge-github"
  }

  if ($DryRun -and $MutationMode -eq "apply") {
    Fail "DryRun cannot be combined with MutationMode apply"
  }

  $safeTaskId = Convert-ToSafeName -Value $TaskId -FieldName "task_id"
  $contractSeed = New-StandardLoopContractSeed -TaskIdentifier $safeTaskId

  # Read run_id from scope file (set by specbridge-intake; empty string if not present or not an intake-generated task)
  $taskRunId = ""
  $taskScopePath = ".specbridge/scopes/$safeTaskId.scope.json"
  if (Test-Path (Join-Path $repoRoot $taskScopePath)) {
    try {
      $taskScope = (Get-Content (Join-Path $repoRoot $taskScopePath) -Raw -Encoding UTF8) | ConvertFrom-Json
      if ($taskScope.run_id) { $taskRunId = $taskScope.run_id }
    } catch {}
  }

  $issueReference = $RelatedIssue
  if ([string]::IsNullOrWhiteSpace($issueReference)) {
    $issueReference = $contractSeed.issue_reference
  }

  if ([string]::IsNullOrWhiteSpace($issueReference) -or $issueReference -eq "not_declared") {
    $issueReference = "not_declared"
  }

  $resolvedTitle = $Title
  if ([string]::IsNullOrWhiteSpace($resolvedTitle)) {
    $resolvedTitle = $safeTaskId
  }

  $resolvedGoal = $Goal
  if ([string]::IsNullOrWhiteSpace($resolvedGoal)) {
    $resolvedGoal = "Run bounded GitHub operator steps for $safeTaskId."
  }

  $selectedOperations = @($GithubOperation)
  if ($selectedOperations.Count -eq 0) {
    $selectedOperations = @("issue_create", "pr_open", "ci_wait", "merge", "issue_close", "post_merge_memory")
  }

  $currentBranch = Get-GitValue -Arguments @("branch", "--show-current") -Fallback "unknown"
  $head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD") -Fallback "unknown"
  $runPath = ".specbridge/issue-to-merge-runs/$safeTaskId.github-mutation-run.json"

  $operationCatalog = [ordered]@{
    issue_create = New-GithubMutationOperation `
      -Id "issue_create" `
      -Name "Create or verify GitHub issue" `
      -RequiredEvidence @("task goal", "allowed scope", "blocked scope", "acceptance criteria", "policy boundaries") `
      -Preconditions @("TaskId is declared", "title and goal are non-empty", "protected scope is not required") `
      -ConnectorAction "github.issue.create_or_verify"

    pr_open = New-GithubMutationOperation `
      -Id "pr_open" `
      -Name "Open or update pull request" `
      -RequiredEvidence @("branch pushed", "execution contract", "scope manifest", "final report draft", "audit packet draft", "ChatGPT/Codex audit draft") `
      -Preconditions @("local branch exists", "working tree is clean", "scope validation passes", "security gate passes") `
      -ConnectorAction "github.pull_request.open_or_update"

    ci_wait = New-GithubMutationOperation `
      -Id "ci_wait" `
      -Name "Wait for GitHub CI and review checks" `
      -RequiredEvidence @("pull request URL", "Foundation Validation", "SpecBridge Review Gate", "SpecBridge PR Review Report", "Claude Review Non Blocking") `
      -Preconditions @("pull request exists", "required GitHub checks are declared") `
      -ConnectorAction "github.checks.wait_required" `
      -MutatesGithub $false

    merge = New-GithubMutationOperation `
      -Id "merge" `
      -Name "Policy-gated merge" `
      -RequiredEvidence @("CI passed", "tests passed", "security gate passed", "review gate passed", "ChatGPT/Codex audit approved", "no protected files changed", "branch mergeable") `
      -Preconditions @("autonomous merge enabled", "deployment not requested", "merge method declared", "expected head SHA matches") `
      -ConnectorAction "github.pull_request.merge"

    issue_close = New-GithubMutationOperation `
      -Id "issue_close" `
      -Name "Close completed issue" `
      -RequiredEvidence @("merged pull request", "completion status complete", "final report recorded") `
      -Preconditions @("related issue exists", "merge completed") `
      -ConnectorAction "github.issue.close_completed"

    post_merge_memory = New-GithubMutationOperation `
      -Id "post_merge_memory" `
      -Name "Post-merge repository memory closure" `
      -RequiredEvidence @("merged pull request", "closed issue", ".specbridge/context/CURRENT_GOAL.md next task") `
      -Preconditions @("main is updated", "next recommended task is recorded") `
      -ConnectorAction "repository.memory.update_after_merge" `
      -MutatesGithub $false `
      -WritesRepositoryFiles $true
  }

  $operations = @()
  foreach ($operationId in $selectedOperations) {
    $operations += $operationCatalog[$operationId]
  }

  $applyEvidence = $null
  $applyEvidencePath = $null
  $applyAllowed = $false
  $applyBlockers = @()
  $githubCallsPerformed = $false
  $githubMutationResult = $null

  if ($MutationMode -eq "apply") {
    if (-not $Force) {
      Fail "issue-to-merge-github apply mode requires -Force"
    }

    if (-not $ConfirmGithubMutation) {
      Fail "issue-to-merge-github apply mode requires -ConfirmGithubMutation"
    }

    if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
      Fail "EvidencePath is required for issue-to-merge-github apply mode"
    }

    $applyEvidencePath = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"

    if ($applyEvidencePath -notmatch "^\.specbridge/github-evidence/.+\.github-mutation-evidence\.json$") {
      Fail "EvidencePath must be a .specbridge/github-evidence/*.github-mutation-evidence.json file: $applyEvidencePath"
    }

    if (-not (Test-Path -LiteralPath $applyEvidencePath -PathType Leaf)) {
      Fail "EvidencePath does not exist: $applyEvidencePath"
    }

    $applyEvidence = Get-JsonObjectFromFile -Path $applyEvidencePath -Description "GitHub mutation evidence"

    foreach ($field in @("task_id", "local_gates_passed", "security_gate_passed", "review_gate_passed", "github_ci_passed", "chatgpt_audit_approved", "no_protected_files_changed", "deployment_not_requested")) {
      if (-not $applyEvidence.PSObject.Properties.Name.Contains($field)) {
        Fail "GitHub mutation evidence must include $field"
      }
    }

    if ($applyEvidence.task_id -ne $safeTaskId) {
      Fail "GitHub mutation evidence task_id must match TaskId: expected=$safeTaskId actual=$($applyEvidence.task_id)"
    }

    foreach ($booleanField in @("local_gates_passed", "security_gate_passed", "review_gate_passed", "github_ci_passed", "chatgpt_audit_approved", "no_protected_files_changed", "deployment_not_requested")) {
      if ($applyEvidence.$booleanField -ne $true) {
        $applyBlockers += $booleanField
      }
    }

    $applyAllowed = ($applyBlockers.Count -eq 0)

    if ($applyAllowed) {
      $pilotSupportedOps = @("issue_create", "issue_close", "pr_open", "ci_wait", "merge", "post_merge_memory")
      $unsupportedOps = $selectedOperations | Where-Object { $pilotSupportedOps -notcontains $_ }
      if ($unsupportedOps.Count -gt 0) {
        $applyBlockers += "apply_mode_pilot_supports_all_six_operations_only"
        $applyAllowed = $false
      }
    }

    $mergedPrNumber = $null
    $mergeCompleted = $false

    if ($applyAllowed) {
      Write-LockFile -TaskId $safeTaskId -Branch $currentBranch
    }

    if ($applyAllowed -and $selectedOperations -contains "issue_create") {
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")
      $issueTitle = if (-not [string]::IsNullOrWhiteSpace($resolvedTitle)) { $resolvedTitle } else { $safeTaskId }
      $issueBody = if (-not [string]::IsNullOrWhiteSpace($resolvedGoal)) { $resolvedGoal } else { "Created by SpecBridge issue-to-merge-github apply mode for task: $safeTaskId" }

      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      $searchOutput = & gh issue list --repo $repoSlug --search "in:title $issueTitle" --state open --json number,title,url 2>&1
      $searchExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap

      $existingIssue = $null
      if ($searchExitCode -eq 0) {
        try {
          $issues = $searchOutput | ConvertFrom-Json
          $existingIssue = $issues | Where-Object { $_.title -eq $issueTitle } | Select-Object -First 1
        } catch {}
      }

      if ($existingIssue) {
        $issueReference = $existingIssue.url
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "issue_create"
          issue_number = [int]$existingIssue.number
          issue_url    = $existingIssue.url
          repository   = $repoSlug
          gh_exit_code = 0
          gh_output    = "issue already exists: $($existingIssue.url)"
          status       = "verified_existing"
        }
      } else {
        $ghArgs = @("issue", "create", "--title", $issueTitle, "--body", $issueBody, "--repo", $repoSlug)
        $previousEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $ghOutput = & gh @ghArgs 2>&1
        $ghExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousEap
        $issueUrl = ($ghOutput | Where-Object { $_ -match "^https://" } | Select-Object -First 1)
        $issueNumber = if ($issueUrl -match "/issues/(\d+)") { [int]$Matches[1] } else { $null }
        if ($issueUrl) { $issueReference = $issueUrl }
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "issue_create"
          issue_number = $issueNumber
          issue_url    = $issueUrl
          repository   = $repoSlug
          gh_exit_code = $ghExitCode
          gh_output    = ($ghOutput -join " ").Trim()
          status       = if ($ghExitCode -eq 0) { "success" } else { "failed" }
        }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "issue_create" -Status $githubMutationResult.status -Detail $(if ($githubMutationResult.issue_url) { $githubMutationResult.issue_url } else { "" }) -RunId $taskRunId
    }

    if ($applyAllowed -and $selectedOperations -contains "pr_open") {
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")
      $prTitle = if (-not [string]::IsNullOrWhiteSpace($resolvedTitle)) { $resolvedTitle } else { $safeTaskId }
      $prBody = "Created by SpecBridge issue-to-merge-github apply mode for task: $safeTaskId"
      if (-not [string]::IsNullOrWhiteSpace($issueReference)) {
        $prBody += "`n`nRelated: $issueReference"
      }

      $ghArgs = @("pr", "create", "--title", $prTitle, "--body", $prBody, "--base", $BaseBranch, "--head", $currentBranch, "--repo", $repoSlug)
      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      $ghOutput = & gh @ghArgs 2>&1
      $ghExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap
      # stdout contains URL on success; on "already exists" the URL may be in stderr (ErrorRecord in PS5.1)
      $prUrl = ($ghOutput | Where-Object { "$_" -match "^https://" } | Select-Object -First 1)
      if (-not $prUrl) {
        # Scan combined text for a pull URL (handles stderr ErrorRecord coercion)
        $allOutputText = ($ghOutput | ForEach-Object { "$_" }) -join " "
        $urlMatch = [regex]::Match($allOutputText, 'https://github\.com/[^/]+/[^/]+/pull/\d+')
        if ($urlMatch.Success) { $prUrl = $urlMatch.Value }
      }
      if (-not $prUrl -and (($ghOutput | ForEach-Object { "$_" }) -join " ") -match "already exists") {
        # Fallback: fetch PR info via gh pr view
        $previousEap2 = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        $viewOut2 = & gh pr view $currentBranch --repo $repoSlug --json number,url 2>&1
        $viewExit2 = $LASTEXITCODE
        $ErrorActionPreference = $previousEap2
        if ($viewExit2 -eq 0) {
          try { $viewData2 = ($viewOut2 -join "") | ConvertFrom-Json; $prUrl = $viewData2.url } catch {}
        }
      }
      $prNumber = if ($prUrl -match "/pull/(\d+)") { [int]$Matches[1] } else { $null }
      $githubCallsPerformed = $true
      $allOutputStr = ($ghOutput | ForEach-Object { "$_" }) -join " "
      $githubMutationResult = [ordered]@{
        operation = "pr_open"
        pr_url = $prUrl
        pr_number = $prNumber
        head = $currentBranch
        base = $BaseBranch
        repository = $repoSlug
        gh_exit_code = $ghExitCode
        gh_output = $allOutputStr.Trim()
        status = if ($ghExitCode -eq 0) { "success" } elseif ($allOutputStr -match "already exists") { "already_exists" } else { "failed" }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "pr_open" -Status $githubMutationResult.status -Detail $(if ($githubMutationResult.pr_url) { $githubMutationResult.pr_url } else { "" }) -RunId $taskRunId
    }

    if ($applyAllowed -and $selectedOperations -contains "ci_wait") {
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")
      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      $prViewOutput = & gh pr view $currentBranch --repo $repoSlug --json number,state 2>&1
      $prViewExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap

      if ($prViewExitCode -ne 0) {
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "ci_wait"
          pr_number    = $null
          head         = $currentBranch
          repository   = $repoSlug
          gh_exit_code = $prViewExitCode
          gh_output    = ($prViewOutput -join " ").Trim()
          status       = "failed_no_pr_found"
        }
      } else {
        $ciPrNumber = [int]($prViewOutput | ConvertFrom-Json).number
        $checksStatus = "pending"
        $checksExitCode = 1
        $checksOutput = @()
        $maxAttempts = 20
        for ($attempt = 0; $attempt -lt $maxAttempts; $attempt++) {
          $previousEap = $ErrorActionPreference
          $ErrorActionPreference = "Continue"
          $checksOutput = & gh pr checks $ciPrNumber --repo $repoSlug 2>&1
          $checksExitCode = $LASTEXITCODE
          $ErrorActionPreference = $previousEap
          $outputStr = ($checksOutput -join " ").Trim()
          if ($checksExitCode -eq 0) {
            $checksStatus = "checks_passed"
            break
          } elseif ($outputStr -match "pending|in_progress|queued|PENDING|IN_PROGRESS|QUEUED") {
            if ($attempt -lt ($maxAttempts - 1)) { Start-Sleep -Seconds 30 }
          } elseif ([string]::IsNullOrWhiteSpace($outputStr) -or $outputStr -match "no checks|No checks") {
            if ($attempt -lt ($maxAttempts - 1)) { Start-Sleep -Seconds 30 }
          } else {
            $checksStatus = "checks_failed"
            break
          }
        }
        if ($checksStatus -eq "pending") { $checksStatus = "timed_out" }
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "ci_wait"
          pr_number    = $ciPrNumber
          head         = $currentBranch
          repository   = $repoSlug
          gh_exit_code = $checksExitCode
          gh_output    = ($checksOutput -join " ").Trim()
          status       = $checksStatus
        }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "ci_wait" -Status $githubMutationResult.status -Detail "pr #$($githubMutationResult.pr_number)" -RunId $taskRunId
    }

    if ($applyAllowed -and $selectedOperations -contains "merge") {
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")
      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      $prViewOutput = & gh pr view $currentBranch --repo $repoSlug --json number 2>&1
      $prViewExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap

      if ($prViewExitCode -ne 0) {
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation = "merge"
          pr_number = $null
          head = $currentBranch
          repository = $repoSlug
          gh_exit_code = $prViewExitCode
          gh_output = ($prViewOutput -join " ").Trim()
          status = "failed_no_pr_found"
        }
      } else {
        $prViewData = $prViewOutput | ConvertFrom-Json
        $prNumber = [int]$prViewData.number
        $ghArgs = @("pr", "merge", $prNumber, "--squash", "--repo", $repoSlug, "--auto")
        $previousEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $ghOutput = & gh @ghArgs 2>&1
        $ghExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousEap

        # Distinguish auto_merge_enabled from merge_completed by checking actual PR state
        $mergeStatus = "failed"
        if ($ghExitCode -eq 0) {
          $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
          $prStateOutput = & gh pr view $prNumber --repo $repoSlug --json state,mergedAt 2>&1
          $prStateExit = $LASTEXITCODE
          $ErrorActionPreference = $previousEap
          $actuallyMerged = $false
          if ($prStateExit -eq 0) {
            try { $actuallyMerged = (($prStateOutput | ConvertFrom-Json).state -eq "MERGED") } catch {}
          }
          $mergeStatus = if ($actuallyMerged) { "merge_completed" } else { "auto_merge_enabled" }
        } elseif (($ghOutput -join " ") -match "already merged") {
          $mergeStatus = "already_merged"
        }

        $mergeCompleted = ($mergeStatus -eq "merge_completed" -or $mergeStatus -eq "already_merged")
        if ($mergeCompleted) { $mergedPrNumber = $prNumber }
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "merge"
          pr_number    = $prNumber
          head         = $currentBranch
          repository   = $repoSlug
          gh_exit_code = $ghExitCode
          gh_output    = ($ghOutput -join " ").Trim()
          status       = $mergeStatus
        }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "merge" -Status $githubMutationResult.status -Detail "pr #$($githubMutationResult.pr_number)" -RunId $taskRunId
    }

    # issue_close runs AFTER merge and only when merge is confirmed complete
    if ($applyAllowed -and $mergeCompleted -and $selectedOperations -contains "issue_close") {
      if ($issueReference -notmatch "github\.com/.+/issues/(\d+)") {
        Fail "RelatedIssue must be a GitHub issue URL to execute issue_close: $issueReference"
      }
      $issueNumber = $Matches[1]
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")

      $ghArgs = @("issue", "close", $issueNumber, "--repo", $repoSlug, "--comment", "Closed by SpecBridge issue-to-merge-github apply mode after PR merge confirmed.")
      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      $ghOutput = & gh @ghArgs 2>&1
      $ghExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap
      $githubCallsPerformed = $true
      $githubMutationResult = [ordered]@{
        operation    = "issue_close"
        issue_number = [int]$issueNumber
        repository   = $repoSlug
        gh_exit_code = $ghExitCode
        gh_output    = ($ghOutput -join " ").Trim()
        status       = if ($ghExitCode -eq 0) { "success" } elseif (($ghOutput -join " ") -match "already closed|issue is already") { "already_closed" } else { "failed" }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "issue_close" -Status $githubMutationResult.status -Detail "issue #$($githubMutationResult.issue_number)" -RunId $taskRunId
    } elseif ($applyAllowed -and (-not $mergeCompleted) -and $selectedOperations -contains "issue_close") {
      $githubMutationResult = [ordered]@{
        operation    = "issue_close"
        merge_status = if ($mergeCompleted) { "merge_completed" } else { "not_merge_completed" }
        status       = "blocked_merge_not_completed"
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "issue_close" -Status "blocked_merge_not_completed" -Detail "merge not confirmed complete" -RunId $taskRunId
    }

    if ($applyAllowed -and $selectedOperations -contains "post_merge_memory") {
      $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")
      $closureBranch = "specbridge/memory-closure-$safeTaskId"

      # Guard: verify primary PR is actually MERGED before creating closure
      $primaryPrActualState = "UNKNOWN"
      if ($mergedPrNumber) {
        $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
        $prCheckOutput = & gh pr view $mergedPrNumber --repo $repoSlug --json state,mergedAt 2>&1
        $prCheckExit = $LASTEXITCODE
        $ErrorActionPreference = $previousEap
        if ($prCheckExit -eq 0) {
          try { $primaryPrActualState = ($prCheckOutput | ConvertFrom-Json).state } catch {}
        }
      }

      if ($primaryPrActualState -ne "MERGED") {
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation    = "post_merge_memory"
          pr_number    = $mergedPrNumber
          pr_state     = $primaryPrActualState
          repository   = $repoSlug
          status       = "blocked_pr_not_merged"
        }
        Write-LedgerEntry -TaskId $safeTaskId -Operation "post_merge_memory" -Status "blocked_pr_not_merged" -Detail "pr #$mergedPrNumber state=$primaryPrActualState" -RunId $taskRunId
      } else {

      $previousEap = $ErrorActionPreference
      $ErrorActionPreference = "Continue"
      & git fetch origin $BaseBranch 2>&1 | Out-Null
      & git checkout -b $closureBranch "origin/$BaseBranch" 2>&1 | Out-Null
      $checkoutExitCode = $LASTEXITCODE
      $ErrorActionPreference = $previousEap

      if ($checkoutExitCode -ne 0) {
        $githubCallsPerformed = $true
        $githubMutationResult = [ordered]@{
          operation      = "post_merge_memory"
          closure_branch = $closureBranch
          repository     = $repoSlug
          status         = "failed_branch_creation"
        }
      } else {
        $scopePath = ".specbridge/scopes/$safeTaskId.scope.json"
        $scopeCompleted = $false
        if (Test-Path -LiteralPath $scopePath) {
          $scopeRaw = Get-Content $scopePath -Raw -Encoding UTF8
          $scopeUpdated = $scopeRaw -replace '"status":\s*"active"', '"status": "completed"'
          $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
          [System.IO.File]::WriteAllText((Join-Path $repoRoot $scopePath), $scopeUpdated, $utf8NoBom)
          $scopeCompleted = $true
        }

        $closureEvidencePath = ".specbridge/github-evidence/$safeTaskId.closure.json"
        $closureEvidence = [ordered]@{
          schema_version = "1"
          task_id        = $safeTaskId
          run_id         = $taskRunId
          closure_type   = "post_merge_closure"
          closed_at      = (Get-Date -Format "yyyy-MM-dd")
          pr_merged      = $true
          pr_number      = $mergedPrNumber
          github_ci_passed = $true
          scope_completed  = $scopeCompleted
          closed_by        = "specbridge-post-merge-memory-operator"
        }
        Write-Utf8JsonFile -Path $closureEvidencePath -Value $closureEvidence -Depth 5

        $filesToAdd = @($closureEvidencePath)
        if ($scopeCompleted) { $filesToAdd += $scopePath }
        $previousEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & git add @filesToAdd 2>&1 | Out-Null
        $commitOutput = & git commit -m "chore: post-merge memory closure for $safeTaskId" 2>&1
        $commitExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousEap

        if ($commitExitCode -ne 0) {
          $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
          & git checkout $currentBranch 2>&1 | Out-Null
          $ErrorActionPreference = $previousEap
          $githubCallsPerformed = $true
          $githubMutationResult = [ordered]@{
            operation      = "post_merge_memory"
            closure_branch = $closureBranch
            repository     = $repoSlug
            status         = "failed_commit"
          }
        } else {
          $previousEap = $ErrorActionPreference
          $ErrorActionPreference = "Continue"
          $pushOutput = & git push origin $closureBranch 2>&1
          $pushExitCode = $LASTEXITCODE
          $ErrorActionPreference = $previousEap

          if ($pushExitCode -ne 0) {
            $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
            & git checkout $currentBranch 2>&1 | Out-Null
            $ErrorActionPreference = $previousEap
            $githubCallsPerformed = $true
            $githubMutationResult = [ordered]@{
              operation      = "post_merge_memory"
              closure_branch = $closureBranch
              repository     = $repoSlug
              status         = "failed_push"
            }
          } else {
            $closurePrTitle = "chore: post-merge memory closure for $safeTaskId"
            $closurePrBody = "Automated memory closure. Marks $safeTaskId scope completed and records closure evidence after PR $mergedPrNumber merged."
            $prCreateArgs = @("pr", "create", "--title", $closurePrTitle, "--body", $closurePrBody, "--base", $BaseBranch, "--head", $closureBranch, "--repo", $repoSlug)
            $previousEap = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            $prCreateOutput = & gh @prCreateArgs 2>&1
            $prCreateExitCode = $LASTEXITCODE
            $ErrorActionPreference = $previousEap
            $closurePrUrl = ($prCreateOutput | Where-Object { $_ -match "^https://" } | Select-Object -First 1)
            $closurePrNumber = if ($closurePrUrl -match "/pull/(\d+)") { [int]$Matches[1] } else { $null }

            if ($closurePrNumber) {
              $previousEap = $ErrorActionPreference
              $ErrorActionPreference = "Continue"
              & gh pr merge $closurePrNumber --squash --auto --repo $repoSlug 2>&1 | Out-Null
              $ErrorActionPreference = $previousEap
            }

            $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
            & git checkout $currentBranch 2>&1 | Out-Null
            $ErrorActionPreference = $previousEap
            $githubCallsPerformed = $true
            $githubMutationResult = [ordered]@{
              operation         = "post_merge_memory"
              closure_branch    = $closureBranch
              closure_pr_number = $closurePrNumber
              closure_pr_url    = $closurePrUrl
              scope_completed   = $scopeCompleted
              repository        = $repoSlug
              status            = if ($closurePrNumber) { "success" } else { "failed_pr_not_created" }
            }
          }
        }
      }
      Write-LedgerEntry -TaskId $safeTaskId -Operation "post_merge_memory" -Status $githubMutationResult.status -Detail $(if ($githubMutationResult.closure_pr_url) { $githubMutationResult.closure_pr_url } else { "" }) -RunId $taskRunId
      } # end else (primaryPrActualState eq MERGED)
    }
  }

  if ($applyAllowed) { Remove-LockFile -TaskId $safeTaskId }

  $operator = [ordered]@{
    schema_version = "1"
    command = "issue-to-merge-github"
    ok = $true
    mutation_mode = $MutationMode
    dry_run = ($MutationMode -eq "dry_run")
    task_id = $safeTaskId
    title = $resolvedTitle
    goal = $resolvedGoal
    issue_reference = $issueReference
    repository_url = $RepositoryUrl
    base_branch = $BaseBranch
    current_branch = $currentBranch
    head = $head
    selected_operations = @($selectedOperations)
    operations = @($operations)
    apply_requested = ($MutationMode -eq "apply")
    apply_allowed = $applyAllowed
    apply_blockers = @($applyBlockers)
    github_calls_performed = $githubCallsPerformed
    github_mutation_result = $githubMutationResult
    mutation_execution = if ($MutationMode -eq "dry_run") { "dry_run_no_github_calls" } elseif ($githubCallsPerformed) { "apply_executed" } else { "external_connector_action_envelope_ready" }
    connector_action_envelope = [ordered]@{
      connector = "github"
      execution_owner = "SpecBridge coordinator with GitHub connector"
      performs_local_secret_access = $false
      actions = @($operations | ForEach-Object { $_.connector_action })
    }
    evidence_paths = [ordered]@{
      contract = $contractSeed.contract_path
      scope = $contractSeed.scope_path
      final_report = $contractSeed.final_report_path
      audit_packet = $contractSeed.audit_packet_path
      chatgpt_audit = $contractSeed.chatgpt_audit_path
      github_mutation_run = $runPath
      apply_evidence = $applyEvidencePath
    }
    required_local_gates = @(
      "validate-contracts",
      "validate-contract-scopes",
      "validate-final-reports",
      "validate-audit-packets",
      "validate-chatgpt-audits",
      "validate-security-gates",
      "validate-review-gate",
      "test-specbridge-cli",
      "specbridge-smoke",
      "git diff --check"
    )
    required_github_gates = @(
      "Foundation Validation",
      "SpecBridge Review Gate",
      "SpecBridge PR Review Report",
      "Claude Review Non Blocking"
    )
    merge_conditions = @(
      "ci_passed",
      "tests_passed",
      "no_policy_violation",
      "no_protected_files_changed",
      "chatgpt_codex_audit_approved",
      "branch_mergeable",
      "expected_head_sha_matches",
      "deployment_not_requested"
    )
    policy_boundaries = @(
      "no-secrets",
      "no-production",
      "no-billing",
      "no-auth-security-change",
      "no-authorization-security-change",
      "no-database-change",
      "no-dependency-installation",
      "no-ci-cd-security-change",
      "no-deployment"
    )
    stop_conditions = @(
      "missing_required_evidence",
      "failed_local_gate",
      "failed_github_ci",
      "blocking_review",
      "protected_file_changed",
      "head_sha_mismatch",
      "deployment_requested",
      "policy_boundary_reached"
    )
    command_boundary = "dry-run-by-default apply-requires-force-confirmation-and-evidence apply-pilot-supports-all-six-operations emits-connector-action-envelope does-not-store-secrets does-not-launch-claude-code does-not-launch-antigravity does-not-install-dependencies does-not-deploy"
    output_path = $null
  }

  if ($MutationMode -eq "apply") {
    $operator["output_path"] = $runPath
    Write-Utf8JsonFile -Path $runPath -Value $operator -Depth 14
  }

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = Assert-OutputPath `
      -Path $OutputPath `
      -Pattern "^\.specbridge/issue-to-merge-runs/.+\.github-mutation-run\.json$" `
      -Description "a .specbridge/issue-to-merge-runs/*.github-mutation-run.json GitHub mutation operator artifact"

    $operator["output_path"] = $output
    Write-Utf8JsonFile -Path $output -Value $operator -Depth 14
  }

  Write-CliJson $operator -Depth 14
  exit 0
}

function Get-ExecutorPacketFiles {
  param(
    [string] $Path
  )

  $normalizedInput = Normalize-RepoPath -Path $Path -FieldName "InputPath"

  if (-not (Test-Path -LiteralPath $normalizedInput)) {
    Fail "InputPath does not exist: $normalizedInput"
  }

  $item = Get-Item -LiteralPath $normalizedInput

  if ($item.PSIsContainer) {
    if ($normalizedInput -notmatch "^\.specbridge/executor-packets(/.*)?$") {
      Fail "InputPath directory must be under .specbridge/executor-packets: $normalizedInput"
    }

    $files = @(
      Get-ChildItem -LiteralPath $normalizedInput -Filter "*.executor-packet.json" -File |
        Sort-Object Name
    )

    if ($files.Count -le 0) {
      Fail "InputPath directory contains no executor packets: $normalizedInput"
    }

    return @(
      $files |
        ForEach-Object { Normalize-RepoPath -Path (Join-Path $normalizedInput $_.Name) -FieldName "executor_packet" }
    )
  }

  if ($normalizedInput -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$") {
    Fail "InputPath file must be a .specbridge/executor-packets/*.executor-packet.json file: $normalizedInput"
  }

  return @($normalizedInput)
}

function Invoke-PlanExecutorBranchesCommand {
  $packetPaths = Get-ExecutorPacketFiles -Path $InputPath
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/branch-plans/.+\.branch-plan\.json$" `
    -Description "a .specbridge/branch-plans/*.branch-plan.json branch plan"

  $packets = @()
  $packetIds = @{}
  $branchNames = @{}
  $packetTaskIdentifier = ""

  foreach ($packetPath in $packetPaths) {
    $packet = Get-JsonObjectFromFile -Path $packetPath -Description "executor packet"
    $context = "executor packet $packetPath"

    foreach ($field in @("packet_id", "task_id", "slice_id", "agent_role", "goal", "branch_name", "execution_contract_path", "final_report_path", "exclusive_write", "required_validations")) {
      if (-not $packet.PSObject.Properties.Name.Contains($field)) {
        Fail "$context must include $field"
      }
    }

    if ([string]::IsNullOrWhiteSpace($packetTaskIdentifier)) {
      $packetTaskIdentifier = $packet.task_id
    }
    elseif ($packetTaskIdentifier -ne $packet.task_id) {
      Fail "All executor packets in a branch plan must share one task_id"
    }

    if ($packetIds.ContainsKey($packet.packet_id)) {
      Fail "Duplicate packet_id in branch plan input: $($packet.packet_id)"
    }

    if ($branchNames.ContainsKey($packet.branch_name)) {
      Fail "Duplicate branch_name in branch plan input: $($packet.branch_name)"
    }

    $packetIds[$packet.packet_id] = $packetPath
    $branchNames[$packet.branch_name] = $packetPath

    $packets += [pscustomobject]@{
      Path = $packetPath
      Packet = $packet
    }
  }

  $executorBranches = @()
  $sourceTaskId = $packetTaskIdentifier
  $planTaskId = $sourceTaskId

  if (-not [string]::IsNullOrWhiteSpace($TaskId)) {
    $planTaskId = $TaskId.Trim()
  }

  foreach ($entry in @($packets | Sort-Object { $_.Packet.packet_id })) {
    $packet = $entry.Packet
    $rollbackNotes = @(
      "Close the executor PR if it exists.",
      "Delete or abandon branch $($packet.branch_name) after coordinator review.",
      "Re-run the coordinator plan before retrying this packet."
    )

    $executorBranches += [ordered]@{
      packet_id = $packet.packet_id
      slice_id = $packet.slice_id
      agent_role = $packet.agent_role
      branch_name = $packet.branch_name
      base_branch = $BaseBranch
      execution_contract_path = $packet.execution_contract_path
      final_report_path = $packet.final_report_path
      exclusive_write = @($packet.exclusive_write)
      required_validations = @($packet.required_validations)
      pr_title = "Executor $($packet.slice_id): $($packet.goal)"
      pr_url = $null
      pr_status = "not_created"
      ci_status = "not_collected"
      chatgpt_audit_status = "not_collected"
      merge_status = "not_ready"
      rollback_notes = @($rollbackNotes)
    }
  }

  $branchPlan = [ordered]@{
    schema_version = "1"
    plan_id = $planTaskId
    task_id = $planTaskId
    source_task_id = $sourceTaskId
    generated_by = "specbridge-cli"
    repository_url = $RepositoryUrl
    base_branch = $BaseBranch
    source_packet_count = @($executorBranches).Count
    executor_branches = @($executorBranches)
    coordinator_gates = [ordered]@{
      one_branch_per_packet = $true
      one_pr_per_branch_required = $true
      ci_status_required = "passed"
      chatgpt_audit_required = "approved"
      integration_waits_for_all_children = $true
      simulation_cannot_authorize_merge = $true
    }
    status = "planned"
    source_files = @($packetPaths)
  }

  Write-Utf8JsonFile -Path $output -Value $branchPlan -Depth 10

  Write-CliJson ([ordered]@{
    command = "plan-executor-branches"
    ok = $true
    output_path = $output
    branch_count = @($executorBranches).Count
  })

  exit 0
}

function Invoke-RecordGithubEvidenceCommand {
  $branchPlanPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidencePath = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/branch-plans/.+\.branch-plan\.json$" `
    -Description "a .specbridge/branch-plans/*.branch-plan.json branch plan"

  if ($branchPlanPath -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$") {
    Fail "InputPath must be a .specbridge/branch-plans/*.branch-plan.json file: $branchPlanPath"
  }

  if ($evidencePath -notmatch "^\.specbridge/github-evidence/.+\.json$") {
    Fail "EvidencePath must be under .specbridge/github-evidence and end with .json: $evidencePath"
  }

  if (-not (Test-Path -LiteralPath $branchPlanPath)) {
    Fail "InputPath does not exist: $branchPlanPath"
  }

  if (-not (Test-Path -LiteralPath $evidencePath)) {
    Fail "EvidencePath does not exist: $evidencePath"
  }

  $branchPlan = Get-JsonObjectFromFile -Path $branchPlanPath -Description "branch plan"
  $evidence = Get-JsonObjectFromFile -Path $evidencePath -Description "GitHub evidence"

  foreach ($field in @("task_id", "executor_branches", "source_files")) {
    if (-not $branchPlan.PSObject.Properties.Name.Contains($field)) {
      Fail "branch plan must include $field"
    }
  }

  foreach ($field in @("task_id", "child_prs")) {
    if (-not $evidence.PSObject.Properties.Name.Contains($field)) {
      Fail "GitHub evidence must include $field"
    }
  }

  if (-not ($evidence.child_prs -is [System.Array]) -or @($evidence.child_prs).Count -le 0) {
    Fail "GitHub evidence child_prs must be a non-empty array"
  }

  $evidenceByPacketId = @{}

  foreach ($child in @($evidence.child_prs)) {
    foreach ($field in @("packet_id", "branch_name", "pr_url", "pr_status", "ci_status", "chatgpt_audit_status")) {
      if (-not $child.PSObject.Properties.Name.Contains($field)) {
        Fail "GitHub evidence child_prs entries must include $field"
      }

      $value = $child.$field

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Fail "GitHub evidence child_prs.$field must be a non-empty string"
      }
    }

    if ($child.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
      Fail "GitHub evidence pr_url must use a GitHub pull request URL: $($child.pr_url)"
    }

    if ($evidenceByPacketId.ContainsKey($child.packet_id)) {
      Fail "Duplicate packet_id in GitHub evidence: $($child.packet_id)"
    }

    $evidenceByPacketId[$child.packet_id] = $child
  }

  $updatedBranches = @()

  foreach ($executor in @($branchPlan.executor_branches | Sort-Object packet_id)) {
    if (-not $evidenceByPacketId.ContainsKey($executor.packet_id)) {
      Fail "Missing GitHub evidence for packet_id: $($executor.packet_id)"
    }

    $child = $evidenceByPacketId[$executor.packet_id]

    if ($child.branch_name -ne $executor.branch_name) {
      Fail "GitHub evidence branch_name mismatch for packet_id $($executor.packet_id): expected=$($executor.branch_name) actual=$($child.branch_name)"
    }

    $mergeStatus = "not_ready"

    if ($child.ci_status -eq "passed" -and $child.chatgpt_audit_status -eq "approved") {
      $mergeStatus = "ready_for_integration"
    }
    elseif ($child.ci_status -eq "failed" -or $child.chatgpt_audit_status -in @("changes_requested", "blocked")) {
      $mergeStatus = "blocked"
    }

    $updatedBranches += [ordered]@{
      packet_id = $executor.packet_id
      slice_id = $executor.slice_id
      agent_role = $executor.agent_role
      branch_name = $executor.branch_name
      base_branch = $executor.base_branch
      execution_contract_path = $executor.execution_contract_path
      final_report_path = $executor.final_report_path
      exclusive_write = @($executor.exclusive_write)
      required_validations = @($executor.required_validations)
      pr_title = $executor.pr_title
      pr_url = $child.pr_url
      pr_status = $child.pr_status
      ci_status = $child.ci_status
      chatgpt_audit_status = $child.chatgpt_audit_status
      merge_status = $mergeStatus
      rollback_notes = @($executor.rollback_notes)
    }
  }

  $sourceFiles = @($branchPlan.source_files)
  $sourceFiles += $branchPlanPath
  $sourceFiles += $evidencePath

  $updatedPlan = [ordered]@{
    schema_version = $branchPlan.schema_version
    plan_id = $evidence.task_id
    task_id = $evidence.task_id
    source_task_id = $branchPlan.source_task_id
    generated_by = "specbridge-cli"
    repository_url = $branchPlan.repository_url
    base_branch = $branchPlan.base_branch
    source_packet_count = @($updatedBranches).Count
    executor_branches = @($updatedBranches)
    coordinator_gates = $branchPlan.coordinator_gates
    status = "evidence_recorded"
    source_files = @($sourceFiles | Sort-Object -Unique)
  }

  Write-Utf8JsonFile -Path $output -Value $updatedPlan -Depth 10

  Write-CliJson ([ordered]@{
    command = "record-github-evidence"
    ok = $true
    output_path = $output
    evidence_path = $evidencePath
    child_count = @($updatedBranches).Count
  })

  exit 0
}

function Invoke-CoordinateExecutorsCommand {
  $branchPlanPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"

  if ($branchPlanPath -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$") {
    Fail "InputPath must be a .specbridge/branch-plans/*.branch-plan.json file: $branchPlanPath"
  }

  if (-not (Test-Path -LiteralPath $branchPlanPath)) {
    Fail "InputPath does not exist: $branchPlanPath"
  }

  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/orchestrations/.+\.executor-orchestration\.json$" `
    -Description "a .specbridge/orchestrations/*.executor-orchestration.json orchestration"

  $branchPlan = Get-JsonObjectFromFile -Path $branchPlanPath -Description "branch plan"

  foreach ($field in @("task_id", "repository_url", "base_branch", "executor_branches")) {
    if (-not $branchPlan.PSObject.Properties.Name.Contains($field)) {
      Fail "branch plan must include $field"
    }
  }

  $children = @()
  $allGithubEvidencePassed = $true

  foreach ($executor in @($branchPlan.executor_branches | Sort-Object packet_id)) {
    foreach ($field in @("packet_id", "slice_id", "agent_role", "branch_name", "pr_url", "ci_status", "chatgpt_audit_status", "rollback_notes")) {
      if (-not $executor.PSObject.Properties.Name.Contains($field)) {
        Fail "executor branch entry must include $field"
      }
    }

    if ($EvidenceMode -eq "simulation") {
      $children += [ordered]@{
        packet_id = $executor.packet_id
        slice_id = $executor.slice_id
        agent_role = $executor.agent_role
        branch_name = $executor.branch_name
        pr_url = "simulation://pull-requests/$($executor.packet_id)"
        pr_status = "simulated_open"
        ci_status = "simulated_passed"
        chatgpt_audit_status = "simulated_approved"
        merge_allowed = $false
        merge_blocker = "Simulation evidence cannot authorize merge."
        rollback_notes = @($executor.rollback_notes)
      }

      continue
    }

    if ($null -eq $executor.pr_url -or $executor.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
      $allGithubEvidencePassed = $false
    }

    if ($executor.ci_status -ne "passed" -or $executor.chatgpt_audit_status -ne "approved") {
      $allGithubEvidencePassed = $false
    }

    $children += [ordered]@{
      packet_id = $executor.packet_id
      slice_id = $executor.slice_id
      agent_role = $executor.agent_role
      branch_name = $executor.branch_name
      pr_url = $executor.pr_url
      pr_status = $executor.pr_status
      ci_status = $executor.ci_status
      chatgpt_audit_status = $executor.chatgpt_audit_status
      merge_allowed = ($executor.ci_status -eq "passed" -and $executor.chatgpt_audit_status -eq "approved")
      merge_blocker = ""
      rollback_notes = @($executor.rollback_notes)
    }
  }

  $integrationDecision = "simulation_only_no_merge"
  $coordinatorStatus = "simulated"
  $requiredNextEvidence = @(
    "Create real executor branches from the branch plan.",
    "Open one GitHub PR per executor branch.",
    "Collect real CI status for every child PR.",
    "Collect a ChatGPT/Codex audit for every child PR.",
    "Regenerate coordination in github evidence mode before integration merge."
  )

  if ($EvidenceMode -eq "github") {
    if ($allGithubEvidencePassed) {
      $integrationDecision = "ready_for_integration"
      $coordinatorStatus = "ready_for_integration"
      $requiredNextEvidence = @()
    }
    else {
      $integrationDecision = "blocked"
      $coordinatorStatus = "blocked"
      $requiredNextEvidence = @(
        "Every executor branch must have a GitHub pull request URL.",
        "Every executor PR must have CI status passed.",
        "Every executor PR must have ChatGPT/Codex audit status approved."
      )
    }
  }

  $orchestration = [ordered]@{
    schema_version = "1"
    orchestration_id = $branchPlan.task_id
    task_id = $branchPlan.task_id
    generated_by = "specbridge-cli"
    evidence_mode = $EvidenceMode
    branch_plan_path = $branchPlanPath
    repository_url = $branchPlan.repository_url
    base_branch = $branchPlan.base_branch
    child_results = @($children)
    integration_decision = $integrationDecision
    coordinator_status = $coordinatorStatus
    required_next_evidence = @($requiredNextEvidence)
    source_files = @($branchPlanPath)
  }

  Write-Utf8JsonFile -Path $output -Value $orchestration -Depth 10

  Write-CliJson ([ordered]@{
    command = "coordinate-executors"
    ok = $true
    evidence_mode = $EvidenceMode
    output_path = $output
    child_count = @($children).Count
    integration_decision = $integrationDecision
  })

  exit 0
}

function Invoke-ReviewGateCommand {
  $security = Invoke-ScriptGate -ScriptPath "./scripts/validate-security-gates.ps1"
  $review = $null

  if ($security.exit_code -eq 0) {
    $review = Invoke-ScriptGate -ScriptPath "./scripts/validate-review-gate.ps1"
  }

  $failed = ($security.exit_code -ne 0 -or ($null -ne $review -and $review.exit_code -ne 0))
  $results = @($security)

  if ($null -ne $review) {
    $results += $review
  }

  Write-CliJson ([ordered]@{
    command = "review-gate"
    ok = (-not $failed)
    results = $results
  })

  if ($failed) {
    exit 1
  }

  exit 0
}

