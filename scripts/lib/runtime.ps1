# SpecBridge CLI library: runtime
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Invoke-PrepareRuntimeLaunchCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$" `
    -Description "a .specbridge/runtime-launches/*.runtime-launch.json runtime launch plan"

  if ($input -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$") {
    Fail "InputPath must be a .specbridge/executor-packets/*.executor-packet.json file: $input"
  }

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  $packet = Get-JsonObjectFromFile -Path $input -Description "executor packet"
  $context = "executor packet $input"

  foreach ($field in @("packet_id", "task_id", "slice_id", "agent_role", "goal", "branch_name", "execution_contract_path", "final_report_path", "exclusive_write", "read_only", "required_validations", "stop_conditions", "status")) {
    if (-not $packet.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($packet.status -ne "ready_for_handoff") {
    Fail "executor packet status must be ready_for_handoff: $input"
  }

  $contractPath = Normalize-RepoPath -Path $packet.execution_contract_path -FieldName "execution_contract_path"
  $finalReportPath = Normalize-RepoPath -Path $packet.final_report_path -FieldName "final_report_path"
  $exclusiveWrite = @($packet.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })
  $readOnly = @($packet.read_only | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "read_only" })
  $validations = @($packet.required_validations | ForEach-Object {
    if ($null -eq $_ -or $_.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($_)) {
      Fail "required_validations must contain only non-empty strings"
    }

    $_.Trim()
  })
  $stopConditions = @($packet.stop_conditions | ForEach-Object {
    if ($null -eq $_ -or $_.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($_)) {
      Fail "stop_conditions must contain only non-empty strings"
    }

    $_.Trim()
  })

  if ($contractPath -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
    Fail "execution_contract_path must point to a SpecBridge execution contract: $contractPath"
  }

  if (-not (Test-Path -LiteralPath $contractPath)) {
    Fail "execution_contract_path does not exist: $contractPath"
  }

  if ($finalReportPath -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
    Fail "final_report_path must point to a SpecBridge final report path: $finalReportPath"
  }

  if ($exclusiveWrite.Count -le 0) {
    Fail "executor packet exclusive_write must not be empty"
  }

  if ($readOnly.Count -le 0) {
    Fail "executor packet read_only must not be empty"
  }

  if ($validations.Count -le 0) {
    Fail "executor packet required_validations must not be empty"
  }

  $approvedTools = @("Read", "Write", "Edit")
  $normalizedAllowedTools = @()

  foreach ($toolEntry in @($AllowedTool)) {
    if ($null -eq $toolEntry -or $toolEntry.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($toolEntry)) {
      Fail "AllowedTool must contain only non-empty strings"
    }

    foreach ($tool in @($toolEntry -split ",")) {
      $trimmedTool = $tool.Trim()

      if ([string]::IsNullOrWhiteSpace($trimmedTool)) {
        Fail "AllowedTool must contain only non-empty strings"
      }

      if ($approvedTools -notcontains $trimmedTool) {
        Fail "AllowedTool is not approved for runtime launch planning: $trimmedTool"
      }

      $normalizedAllowedTools += $trimmedTool
    }
  }

  $normalizedAllowedTools = @($normalizedAllowedTools | Sort-Object -Unique)

  if ($normalizedAllowedTools.Count -le 0) {
    Fail "AllowedTool must include at least one approved tool"
  }

  foreach ($requiredTool in @("Read", "Write")) {
    if ($normalizedAllowedTools -notcontains $requiredTool) {
      Fail "AllowedTool must include $requiredTool for runtime launch planning"
    }
  }

  if ($MaxBudgetUsd -notmatch "^[0-9]+(\.[0-9]{1,2})?$") {
    Fail "MaxBudgetUsd must be a positive decimal string with up to two fractional digits"
  }

  $budget = [decimal]::Parse($MaxBudgetUsd, [System.Globalization.CultureInfo]::InvariantCulture)

  if ($budget -le 0 -or $budget -gt 10) {
    Fail "MaxBudgetUsd must be greater than 0 and no more than 10"
  }

  if ($MaxTurns -lt 1 -or $MaxTurns -gt 100) {
    Fail "MaxTurns must be between 1 and 100"
  }

  $safeLaunchId = Convert-ToSafeName -Value ($packet.packet_id + "-runtime-launch") -FieldName "launch_id"
  $allowedToolsText = ($normalizedAllowedTools -join ",")
  $maxTurnsText = $MaxTurns.ToString([System.Globalization.CultureInfo]::InvariantCulture)

  $promptSections = @(
    "Read README.md, SPECBRIDGE.md, AGENTS.md, CLAUDE.md, .specbridge/policy.yaml, the execution contract, and the executor packet before writing.",
    "Modify only paths declared in exclusive_write.",
    "Treat read_only paths as context only.",
    "Run only required validations that are explicitly allowed by the runtime operator.",
    "Stop on policy conflict, scope conflict, missing required context, impossible acceptance criteria, protected resource requirement, secrets, production configuration, billing, authentication security, authorization security, dependency installation, database change, CI/CD security change, or deployment automation.",
    "Report changed files, validation evidence, policy result, unresolved risks, and completion status."
  )

  $launch = [ordered]@{
    schema_version = "1"
    launch_id = $safeLaunchId
    generated_by = "specbridge-cli"
    source_executor_packet_path = $input
    task_id = $packet.task_id
    packet_id = $packet.packet_id
    slice_id = $packet.slice_id
    agent_role = $packet.agent_role
    goal = $packet.goal
    branch_name = $packet.branch_name
    execution_contract_path = $contractPath
    final_report_path = $finalReportPath
    exclusive_write = @($exclusiveWrite)
    read_only = @($readOnly)
    required_validations = @($validations)
    allowed_tools = @($normalizedAllowedTools)
    permission_mode = $PermissionMode
    max_budget_usd = $MaxBudgetUsd
    max_turns = $MaxTurns
    conditional_flags = [ordered]@{
      max_turns = [ordered]@{
        flag = "--max-turns"
        desired_value = $MaxTurns
        apply_when = "claude_help_exposes_flag"
      }
    }
    command_summary = "claude -p --no-session-persistence --max-budget-usd $MaxBudgetUsd [--max-turns $maxTurnsText if supported] --permission-mode $PermissionMode --tools `"$allowedToolsText`" --allowedTools `"$allowedToolsText`" <bounded prompt>"
    prompt_sections = @($promptSections)
    stop_conditions = @($stopConditions)
    launch_status = "ready_for_operator_launch"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($input, $contractPath)
  }

  Write-Utf8JsonFile -Path $output -Value $launch -Depth 10

  Write-CliJson ([ordered]@{
    command = "prepare-runtime-launch"
    ok = $true
    output_path = $output
    source_executor_packet_path = $input
    launch_status = "ready_for_operator_launch"
  })

  exit 0
}

function Get-PreflightStringList {
  param(
    [string[]] $Values,
    [string] $FieldName,
    [bool] $AllowEmpty = $false
  )

  $items = @()

  foreach ($entry in @($Values)) {
    if ($null -eq $entry) {
      continue
    }

    foreach ($value in @($entry -split ",")) {
      $trimmed = $value.Trim()

      if ([string]::IsNullOrWhiteSpace($trimmed)) {
        continue
      }

      $items += $trimmed
    }
  }

  $items = @($items | Sort-Object -Unique)

  if (-not $AllowEmpty -and $items.Count -le 0) {
    Fail "$FieldName must include at least one value"
  }

  return @($items)
}

function Get-PreflightRuntimeLaunchPaths {
  if ([string]::IsNullOrWhiteSpace($InputPath)) {
    Fail "InputPath is required"
  }

  $paths = @()

  foreach ($entry in @($InputPath -split "[,;]")) {
    $trimmed = $entry.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }

    $normalized = Normalize-RepoPath -Path $trimmed -FieldName "InputPath"

    if (Test-Path -LiteralPath $normalized -PathType Container) {
      if ($normalized -notmatch "^\.specbridge/runtime-launches($|/)") {
        Fail "InputPath directory must be under .specbridge/runtime-launches: $normalized"
      }

      $paths += @(Get-ChildItem -LiteralPath $normalized -Filter "*.runtime-launch.json" -File | ForEach-Object {
        Normalize-RepoPath -Path (Join-Path $normalized $_.Name) -FieldName "InputPath"
      })

      continue
    }

    if ($normalized -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file or directory: $normalized"
    }

    $paths += $normalized
  }

  $paths = @($paths | Sort-Object -Unique)

  if ($paths.Count -le 0) {
    Fail "InputPath did not resolve to any runtime launch files"
  }

  foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "InputPath does not exist: $path"
    }
  }

  return @($paths)
}

function Test-PreflightPathOverlap {
  param(
    [string] $First,
    [string] $Second
  )

  if ($First -eq $Second) {
    return $true
  }

  if ($First.StartsWith("$Second/") -or $Second.StartsWith("$First/")) {
    return $true
  }

  return $false
}

function Invoke-PreflightRuntimeLaunchesCommand {
  $launchPaths = Get-PreflightRuntimeLaunchPaths
  $requiredSlices = Get-PreflightStringList -Values $RequiredSlice -FieldName "RequiredSlice" -AllowEmpty $true
  $allowedToolLimit = Get-PreflightStringList -Values $AllowedTool -FieldName "AllowedTool" -AllowEmpty $false
  $approvedToolNames = @("Read", "Write", "Edit")

  foreach ($tool in $allowedToolLimit) {
    if ($approvedToolNames -notcontains $tool) {
      Fail "AllowedTool is not approved for runtime launch preflight: $tool"
    }
  }

  if ($MaxBudgetUsd -notmatch "^[0-9]+(\.[0-9]{1,2})?$") {
    Fail "MaxBudgetUsd must be a positive decimal string with up to two fractional digits"
  }

  $maxBudget = [decimal]::Parse($MaxBudgetUsd, [System.Globalization.CultureInfo]::InvariantCulture)

  if ($maxBudget -le 0 -or $maxBudget -gt 10) {
    Fail "MaxBudgetUsd must be greater than 0 and no more than 10"
  }

  $output = $null

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = Assert-OutputPath `
      -Path $OutputPath `
      -Pattern "^\.specbridge/preflights/.+\.runtime-preflight\.json$" `
      -Description "a .specbridge/preflights/*.runtime-preflight.json runtime preflight"
  }

  $blockers = @()
  $loadedLaunches = @()
  $sliceCounts = @{}
  $writeOwners = @()
  $overlapConflicts = @()
  $budgetViolations = @()
  $toolViolations = @()
  $policyViolations = @()
  $totalBudget = [decimal] 0
  $policyFields = @(
    "launches_claude",
    "launches_antigravity",
    "executes_shell",
    "requires_network",
    "touches_secrets",
    "touches_production",
    "installs_dependencies",
    "deploys"
  )

  foreach ($path in $launchPaths) {
    $launch = Get-JsonObjectFromFile -Path $path -Description "runtime launch"
    $propertyNames = @($launch.PSObject.Properties.Name)
    $requiredFields = @(
      "launch_id",
      "task_id",
      "packet_id",
      "slice_id",
      "branch_name",
      "exclusive_write",
      "allowed_tools",
      "max_budget_usd",
      "launch_status",
      "execution_policy"
    )

    foreach ($field in $requiredFields) {
      if ($propertyNames -notcontains $field) {
        $blockers += "runtime launch missing required field: $path $field"
      }
    }

    $sliceId = ""

    if ($propertyNames -contains "slice_id" -and $null -ne $launch.slice_id) {
      $sliceId = $launch.slice_id.ToString().Trim()
    }

    if ([string]::IsNullOrWhiteSpace($sliceId)) {
      $sliceId = "unknown"
      $blockers += "runtime launch slice_id must be non-empty: $path"
    }

    if (-not $sliceCounts.ContainsKey($sliceId)) {
      $sliceCounts[$sliceId] = 0
    }

    $sliceCounts[$sliceId] += 1

    if ($propertyNames -contains "launch_status" -and $launch.launch_status -ne "ready_for_operator_launch") {
      $blockers += "launch_status must be ready_for_operator_launch: $sliceId"
    }

    $exclusiveWrite = @()

    if ($propertyNames -contains "exclusive_write" -and $null -ne $launch.exclusive_write -and $launch.exclusive_write -is [System.Array]) {
      foreach ($writePath in @($launch.exclusive_write)) {
        $normalizedWrite = Normalize-RepoPath -Path $writePath -FieldName "exclusive_write"
        $exclusiveWrite += $normalizedWrite

        foreach ($owner in @($writeOwners)) {
          if (Test-PreflightPathOverlap -First $owner.path -Second $normalizedWrite) {
            $overlapConflicts += [ordered]@{
              path = $normalizedWrite
              existing_path = $owner.path
              first_slice = $owner.slice_id
              second_slice = $sliceId
            }
            $blockers += "exclusive_write overlap: $normalizedWrite between $($owner.slice_id) and $sliceId"
          }
        }

        $writeOwners += [ordered]@{
          path = $normalizedWrite
          slice_id = $sliceId
        }
      }
    }
    else {
      $blockers += "exclusive_write must be a non-empty array: $sliceId"
    }

    $exclusiveWrite = @($exclusiveWrite | Sort-Object -Unique)

    if ($exclusiveWrite.Count -le 0) {
      $blockers += "exclusive_write must not be empty: $sliceId"
    }

    $launchTools = @()

    if ($propertyNames -contains "allowed_tools" -and $null -ne $launch.allowed_tools -and $launch.allowed_tools -is [System.Array]) {
      foreach ($tool in @($launch.allowed_tools)) {
        if ($null -eq $tool -or $tool.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($tool)) {
          $toolViolations += [ordered]@{
            slice_id = $sliceId
            tool = ""
            reason = "empty_tool"
          }
          $blockers += "allowed_tools must contain only non-empty strings: $sliceId"
          continue
        }

        $trimmedTool = $tool.Trim()
        $launchTools += $trimmedTool

        if ($allowedToolLimit -notcontains $trimmedTool) {
          $toolViolations += [ordered]@{
            slice_id = $sliceId
            tool = $trimmedTool
            reason = "not_in_preflight_allow_list"
          }
          $blockers += "allowed_tools outside preflight allow-list: $sliceId $trimmedTool"
        }
      }
    }
    else {
      $toolViolations += [ordered]@{
        slice_id = $sliceId
        tool = ""
        reason = "missing_allowed_tools"
      }
      $blockers += "allowed_tools must be a non-empty array: $sliceId"
    }

    $launchTools = @($launchTools | Sort-Object -Unique)

    if ($launchTools.Count -le 0) {
      $blockers += "allowed_tools must not be empty: $sliceId"
    }

    $launchBudgetText = ""

    if ($propertyNames -contains "max_budget_usd" -and $null -ne $launch.max_budget_usd) {
      $launchBudgetText = $launch.max_budget_usd.ToString().Trim()
    }

    if ($launchBudgetText -notmatch "^[0-9]+(\.[0-9]{1,2})?$") {
      $budgetViolations += [ordered]@{
        slice_id = $sliceId
        max_budget_usd = $launchBudgetText
        reason = "invalid_budget"
      }
      $blockers += "max_budget_usd must be a positive decimal string: $sliceId"
    }
    else {
      $launchBudget = [decimal]::Parse($launchBudgetText, [System.Globalization.CultureInfo]::InvariantCulture)
      $totalBudget += $launchBudget

      if ($launchBudget -le 0) {
        $budgetViolations += [ordered]@{
          slice_id = $sliceId
          max_budget_usd = $launchBudgetText
          reason = "non_positive_budget"
        }
        $blockers += "max_budget_usd must be greater than 0: $sliceId"
      }

      if ($launchBudget -gt $maxBudget) {
        $budgetViolations += [ordered]@{
          slice_id = $sliceId
          max_budget_usd = $launchBudgetText
          limit = $MaxBudgetUsd
          reason = "over_preflight_limit"
        }
        $blockers += "max_budget_usd exceeds preflight limit: $sliceId $launchBudgetText > $MaxBudgetUsd"
      }
    }

    if ($propertyNames -contains "execution_policy" -and $null -ne $launch.execution_policy -and $launch.execution_policy.GetType().Name -match "Object") {
      foreach ($policyField in $policyFields) {
        if (-not $launch.execution_policy.PSObject.Properties.Name.Contains($policyField)) {
          $policyViolations += [ordered]@{
            slice_id = $sliceId
            field = $policyField
            reason = "missing"
          }
          $blockers += "execution_policy.$policyField is required: $sliceId"
          continue
        }

        if ($launch.execution_policy.$policyField -isnot [bool]) {
          $policyViolations += [ordered]@{
            slice_id = $sliceId
            field = $policyField
            reason = "not_boolean"
          }
          $blockers += "execution_policy.$policyField must be boolean: $sliceId"
          continue
        }

        if ($launch.execution_policy.$policyField -ne $false) {
          $policyViolations += [ordered]@{
            slice_id = $sliceId
            field = $policyField
            reason = "not_false"
          }
          $blockers += "execution_policy.$policyField must be false: $sliceId"
        }
      }
    }
    else {
      $policyViolations += [ordered]@{
        slice_id = $sliceId
        field = "execution_policy"
        reason = "missing_or_invalid"
      }
      $blockers += "execution_policy must be an object: $sliceId"
    }

    $loadedLaunches += [ordered]@{
      path = $path
      launch_id = $launch.launch_id
      task_id = $launch.task_id
      packet_id = $launch.packet_id
      slice_id = $sliceId
      branch_name = $launch.branch_name
      max_budget_usd = $launchBudgetText
      allowed_tools = @($launchTools)
      exclusive_write = @($exclusiveWrite)
    }
  }

  $presentSlices = @($sliceCounts.Keys | Sort-Object)
  $missingSlices = @()

  foreach ($slice in $requiredSlices) {
    if (-not $sliceCounts.ContainsKey($slice)) {
      $missingSlices += $slice
      $blockers += "missing required slice: $slice"
    }
  }

  $duplicateSlices = @($sliceCounts.GetEnumerator() | Where-Object { $_.Value -gt 1 } | ForEach-Object { $_.Key } | Sort-Object)

  foreach ($slice in $duplicateSlices) {
    $blockers += "duplicate slice id: $slice"
  }

  $blockers = @($blockers | Sort-Object -Unique)
  $ok = ($blockers.Count -eq 0)
  $totalBudgetText = $totalBudget.ToString("0.00", [System.Globalization.CultureInfo]::InvariantCulture)

  $result = [ordered]@{
    schema_version = "1"
    command = "preflight-runtime-launches"
    ok = $ok
    mode = "plan_only_preflight"
    input_paths = @($launchPaths)
    loaded_launches = @($loadedLaunches)
    required_slices = @($requiredSlices)
    present_slices = @($presentSlices)
    missing_required_slices = @($missingSlices)
    duplicate_slices = @($duplicateSlices)
    non_overlap = [ordered]@{
      result = $(if ($overlapConflicts.Count -eq 0) { "pass" } else { "fail" })
      conflicts = @($overlapConflicts)
    }
    budget = [ordered]@{
      result = $(if ($budgetViolations.Count -eq 0) { "pass" } else { "fail" })
      max_budget_usd = $MaxBudgetUsd
      total_budget_usd = $totalBudgetText
      violations = @($budgetViolations)
    }
    tools = [ordered]@{
      result = $(if ($toolViolations.Count -eq 0) { "pass" } else { "fail" })
      allowed_tools = @($allowedToolLimit)
      violations = @($toolViolations)
    }
    execution_policy = [ordered]@{
      result = $(if ($policyViolations.Count -eq 0) { "pass" } else { "fail" })
      required_false_fields = @($policyFields)
      violations = @($policyViolations)
    }
    blockers = @($blockers)
    policy_boundary = "plan-only no-launch no-antigravity no-shell no-network no-secrets no-production no-dependency-installation no-deploy"
    source_files = @($launchPaths)
    output_path = $output
  }

  if ($output) {
    Write-Utf8JsonFile -Path $output -Value $result -Depth 12
  }

  Write-CliJson $result -Depth 12

  if (-not $ok) {
    exit 1
  }

  exit 0
}

function Invoke-RecordRuntimeResultCommand {
  $input = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidence = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-results/.+\.runtime-result\.json$" `
    -Description "a .specbridge/runtime-results/*.runtime-result.json runtime result"

  if ($input -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $input"
  }

  if (-not (Test-Path -LiteralPath $input)) {
    Fail "InputPath does not exist: $input"
  }

  if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
    Fail "EvidencePath must reference an existing executor evidence file: $evidence"
  }

  $launch = Get-JsonObjectFromFile -Path $input -Description "runtime launch plan"
  $context = "runtime launch plan $input"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "exclusive_write", "required_validations", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch plan status must be ready_for_operator_launch: $input"
  }

  $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })

  if ($exclusiveWrite.Count -le 0) {
    Fail "runtime launch plan exclusive_write must not be empty"
  }

  if ($exclusiveWrite -notcontains $evidence) {
    Fail "EvidencePath must be declared in runtime launch exclusive_write: $evidence"
  }

  if ($RuntimeExitCode -lt 0 -or $RuntimeExitCode -gt 255) {
    Fail "RuntimeExitCode must be between 0 and 255"
  }

  $allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")

  if ($allowedCompletionStatuses -notcontains $CompletionStatus) {
    Fail "CompletionStatus must be one of: $($allowedCompletionStatuses -join ', ')"
  }

  if ([string]::IsNullOrWhiteSpace($PolicyResult)) {
    Fail "PolicyResult is required"
  }

  $filesWritten = @()

  if ($WrittenFile.Count -le 0) {
    $filesWritten += $evidence
  }
  else {
    foreach ($path in @($WrittenFile)) {
      $filesWritten += Normalize-RepoPath -Path $path -FieldName "WrittenFile"
    }
  }

  $filesWritten = @($filesWritten | Sort-Object -Unique)

  foreach ($path in $filesWritten) {
    if ($exclusiveWrite -notcontains $path) {
      Fail "WrittenFile must be declared in runtime launch exclusive_write: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "WrittenFile must reference an existing file: $path"
    }
  }

  if ($filesWritten -notcontains $evidence) {
    Fail "WrittenFile must include EvidencePath: $evidence"
  }

  $validationResults = Convert-ValidationRecords -Records $Validation
  $runtimeStatus = "succeeded"

  if ($RuntimeExitCode -ne 0) {
    $runtimeStatus = "failed"
  }

  $safeResultId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-result") -FieldName "result_id"

  $result = [ordered]@{
    schema_version = "1"
    result_id = $safeResultId
    generated_by = "specbridge-cli"
    source_runtime_launch_path = $input
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    executor_evidence_path = $evidence
    exit_code = $RuntimeExitCode
    files_written = @($filesWritten)
    validation_results = @($validationResults)
    policy_result = $PolicyResult.Trim()
    stop_conditions = @($launch.stop_conditions)
    completion_status = $CompletionStatus
    runtime_status = $runtimeStatus
    result_status = "recorded"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($input, $evidence)
  }

  Write-Utf8JsonFile -Path $output -Value $result -Depth 10

  Write-CliJson ([ordered]@{
    command = "record-runtime-result"
    ok = $true
    output_path = $output
    source_runtime_launch_path = $input
    executor_evidence_path = $evidence
    runtime_status = $runtimeStatus
    result_status = "recorded"
  })

  exit 0
}

function Invoke-RunRuntimeLaunchCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $evidence = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-runs/.+\.runtime-run\.json$" `
    -Description "a .specbridge/runtime-runs/*.runtime-run.json runtime run"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
    Fail "EvidencePath must reference an existing executor evidence file: $evidence"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $context = "runtime launch $launchPath"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "exclusive_write", "allowed_tools", "permission_mode", "max_budget_usd", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch status must be ready_for_operator_launch: $launchPath"
  }

  $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "exclusive_write" })

  if ($exclusiveWrite -notcontains $evidence) {
    Fail "EvidencePath must be declared in runtime launch exclusive_write: $evidence"
  }

  if ($RuntimeExitCode -lt 0 -or $RuntimeExitCode -gt 255) {
    Fail "RuntimeExitCode must be between 0 and 255"
  }

  $allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")

  if ($allowedCompletionStatuses -notcontains $CompletionStatus) {
    Fail "CompletionStatus must be one of: $($allowedCompletionStatuses -join ', ')"
  }

  if ([string]::IsNullOrWhiteSpace($PolicyResult)) {
    Fail "PolicyResult is required"
  }

  $filesWritten = @()

  if ($WrittenFile.Count -le 0) {
    $filesWritten += $evidence
  }
  else {
    foreach ($path in @($WrittenFile)) {
      $filesWritten += Normalize-RepoPath -Path $path -FieldName "WrittenFile"
    }
  }

  $filesWritten = @($filesWritten | Sort-Object -Unique)

  foreach ($path in $filesWritten) {
    if ($exclusiveWrite -notcontains $path) {
      Fail "WrittenFile must be declared in runtime launch exclusive_write: $path"
    }

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      Fail "WrittenFile must reference an existing file: $path"
    }
  }

  if ($filesWritten -notcontains $evidence) {
    Fail "WrittenFile must include EvidencePath: $evidence"
  }

  $validationRecords = @($Validation)

  if ($validationRecords.Count -le 0) {
    $validationRecords = @("runtime launch evidence capture: recorded")
  }

  $validationResults = Convert-ValidationRecords -Records $validationRecords
  $runtimeStatus = "succeeded"

  if ($RuntimeExitCode -ne 0) {
    $runtimeStatus = "failed"
  }

  $safeRunId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-run") -FieldName "run_id"

  $run = [ordered]@{
    schema_version = "1"
    run_id = $safeRunId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    executor_evidence_path = $evidence
    exit_code = $RuntimeExitCode
    files_written = @($filesWritten)
    validation_results = @($validationResults)
    tool_restriction = @($launch.allowed_tools)
    permission_mode = $launch.permission_mode
    max_budget_usd = $launch.max_budget_usd
    policy_result = $PolicyResult.Trim()
    stop_conditions = @($launch.stop_conditions)
    completion_status = $CompletionStatus
    runtime_status = $runtimeStatus
    run_status = "recorded"
    runner_mode = "evidence_capture"
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($launchPath, $evidence)
  }

  Write-Utf8JsonFile -Path $output -Value $run -Depth 10

  Write-CliJson ([ordered]@{
    command = "run-runtime-launch"
    ok = $true
    output_path = $output
    runtime_launch_path = $launchPath
    executor_evidence_path = $evidence
    runtime_status = $runtimeStatus
    run_status = "recorded"
  })

  exit 0
}

function Invoke-SummarizeRuntimeCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $resultPath = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-summaries/.+\.runtime-summary\.json$" `
    -Description "a .specbridge/runtime-summaries/*.runtime-summary.json runtime summary"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if ($resultPath -notmatch "^\.specbridge/runtime-results/.+\.runtime-result\.json$") {
    Fail "EvidencePath must be a .specbridge/runtime-results/*.runtime-result.json file: $resultPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
    Fail "EvidencePath does not exist: $resultPath"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $result = Get-JsonObjectFromFile -Path $resultPath -Description "runtime result"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "execution_policy", "source_files")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "runtime launch must include $field"
    }
  }

  foreach ($field in @("source_runtime_launch_path", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "validation_results", "policy_result", "completion_status", "runtime_status", "result_status", "execution_policy", "source_files")) {
    if (-not $result.PSObject.Properties.Name.Contains($field)) {
      Fail "runtime result must include $field"
    }
  }

  if ((Normalize-RepoPath -Path $result.source_runtime_launch_path -FieldName "source_runtime_launch_path") -ne $launchPath) {
    Fail "Runtime result source_runtime_launch_path must match InputPath"
  }

  foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name")) {
    if ($launch.$matchingField -ne $result.$matchingField) {
      Fail "$matchingField must match between runtime launch and runtime result"
    }
  }

  if ($result.validation_results -isnot [System.Array] -or @($result.validation_results).Count -le 0) {
    Fail "runtime result validation_results must be a non-empty array"
  }

  $validationTotal = @($result.validation_results).Count
  $validationPassed = @($result.validation_results | Where-Object { $_.result -eq "passed" }).Count
  $validationFailed = @($result.validation_results | Where-Object { $_.result -eq "failed" }).Count
  $validationOther = $validationTotal - $validationPassed - $validationFailed
  $blockers = @()

  if ($result.runtime_status -ne "succeeded") {
    $blockers += "runtime_status is not succeeded"
  }

  if ($result.result_status -ne "recorded") {
    $blockers += "result_status is not recorded"
  }

  if ($result.completion_status -ne "complete") {
    $blockers += "completion_status is not complete"
  }

  if ($validationFailed -gt 0 -or $validationOther -gt 0) {
    $blockers += "validation_results are not all passed"
  }

  if ([string]::IsNullOrWhiteSpace($result.policy_result)) {
    $blockers += "policy_result is empty"
  }

  $mergeReadiness = "ready_for_policy_gates"

  if ($blockers.Count -gt 0) {
    $mergeReadiness = "blocked"
  }

  $sourceFiles = @()
  $sourceFiles += $launchPath
  $sourceFiles += $resultPath
  $sourceFiles += @($launch.source_files)
  $sourceFiles += @($result.source_files)
  $sourceFiles = @($sourceFiles | ForEach-Object { Normalize-RepoPath -Path $_ -FieldName "source_files" } | Sort-Object -Unique)
  $summaryId = Convert-ToSafeName -Value ($result.task_id + "-runtime-summary") -FieldName "summary_id"

  $summary = [ordered]@{
    schema_version = "1"
    summary_id = $summaryId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    runtime_result_path = $resultPath
    launch_id = $result.launch_id
    task_id = $result.task_id
    packet_id = $result.packet_id
    slice_id = $result.slice_id
    branch_name = $result.branch_name
    completion_status = $result.completion_status
    runtime_status = $result.runtime_status
    result_status = $result.result_status
    validation_totals = [ordered]@{
      total = $validationTotal
      passed = $validationPassed
      failed = $validationFailed
      other = $validationOther
    }
    policy_result = $result.policy_result
    merge_readiness = $mergeReadiness
    blockers = @($blockers)
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_antigravity = $false
      executes_shell = $false
      requires_network = $false
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($sourceFiles)
  }

  Write-Utf8JsonFile -Path $output -Value $summary -Depth 10

  Write-CliJson ([ordered]@{
    command = "summarize-runtime"
    ok = $true
    output_path = $output
    runtime_launch_path = $launchPath
    runtime_result_path = $resultPath
    merge_readiness = $mergeReadiness
    blocker_count = @($blockers).Count
  })

  exit 0
}

function Invoke-SummarizeAutonomyMetricsCommand {
  $summaryRoot = ".specbridge/runtime-summaries"
  $resultRoot = ".specbridge/runtime-results"

  if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    $summaryRoot = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  }

  if (-not [string]::IsNullOrWhiteSpace($EvidencePath)) {
    $resultRoot = Normalize-RepoPath -Path $EvidencePath -FieldName "EvidencePath"
  }

  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/metrics/.+\.autonomy-metrics\.json$" `
    -Description "a .specbridge/metrics/*.autonomy-metrics.json autonomy metrics artifact"

  if (-not (Test-Path -LiteralPath $summaryRoot -PathType Container)) {
    Fail "InputPath must reference an existing runtime summaries directory: $summaryRoot"
  }

  if (-not (Test-Path -LiteralPath $resultRoot -PathType Container)) {
    Fail "EvidencePath must reference an existing runtime results directory: $resultRoot"
  }

  $taskFilter = $null

  if (-not [string]::IsNullOrWhiteSpace($TaskId)) {
    $taskFilter = $TaskId.Trim()
  }

  $summaryRecords = @()

  foreach ($file in @(Get-ChildItem -LiteralPath $summaryRoot -Filter "*.runtime-summary.json" -File | Sort-Object Name)) {
    $summaryPath = Normalize-RepoPath -Path (Join-Path $summaryRoot $file.Name) -FieldName "runtime_summary"
    $summary = Get-JsonObjectFromFile -Path $summaryPath -Description "runtime summary"

    if ($null -ne $taskFilter -and $summary.task_id -ne $taskFilter) {
      continue
    }

    $summaryRecords += [ordered]@{
      path = $summaryPath
      value = $summary
    }
  }

  if ($summaryRecords.Count -le 0) {
    if ($null -eq $taskFilter) {
      Fail "No runtime summaries found for autonomy metrics"
    }

    Fail "No runtime summaries found for TaskId: $taskFilter"
  }

  $resultRecords = @()

  foreach ($file in @(Get-ChildItem -LiteralPath $resultRoot -Filter "*.runtime-result.json" -File | Sort-Object Name)) {
    $resultPath = Normalize-RepoPath -Path (Join-Path $resultRoot $file.Name) -FieldName "runtime_result"
    $result = Get-JsonObjectFromFile -Path $resultPath -Description "runtime result"

    if ($null -ne $taskFilter -and $result.task_id -ne $taskFilter) {
      continue
    }

    $resultRecords += [ordered]@{
      path = $resultPath
      value = $result
    }
  }

  $runtimeStatusCounts = @{}
  $resultStatusCounts = @{}
  $completionStatusCounts = @{}
  $mergeReadinessCounts = @{}
  $sliceIds = @{}
  $validationTotal = 0
  $validationPassed = 0
  $validationFailed = 0
  $validationOther = 0
  $readyCount = 0
  $blockedCount = 0

  foreach ($record in $summaryRecords) {
    $summary = $record.value
    Add-Count -Table $runtimeStatusCounts -Key $summary.runtime_status
    Add-Count -Table $resultStatusCounts -Key $summary.result_status
    Add-Count -Table $completionStatusCounts -Key $summary.completion_status
    Add-Count -Table $mergeReadinessCounts -Key $summary.merge_readiness
    $sliceIds[$summary.slice_id] = $true

    if ($summary.merge_readiness -eq "ready_for_policy_gates") {
      $readyCount++
    }

    if ($summary.merge_readiness -eq "blocked") {
      $blockedCount++
    }

    if ($summary.PSObject.Properties.Name.Contains("validation_totals")) {
      $validationTotal += [int] $summary.validation_totals.total
      $validationPassed += [int] $summary.validation_totals.passed
      $validationFailed += [int] $summary.validation_totals.failed
      $validationOther += [int] $summary.validation_totals.other
    }
  }

  $readyRate = [math]::Round(($readyCount / $summaryRecords.Count), 4)
  $metricsIdBase = "all-runtime"

  if ($null -ne $taskFilter) {
    $metricsIdBase = $taskFilter
  }

  $metricsId = Convert-ToSafeName -Value ($metricsIdBase + "-autonomy-metrics") -FieldName "metrics_id"
  $sourceSummaries = @($summaryRecords | ForEach-Object { $_.path })
  $sourceResults = @($resultRecords | ForEach-Object { $_.path })
  $sourceFiles = @($sourceSummaries + $sourceResults | Sort-Object -Unique)

  $metrics = [ordered]@{
    schema_version = "1"
    metrics_id = $metricsId
    generated_by = "specbridge-cli"
    task_filter = $taskFilter
    summary_count = @($summaryRecords).Count
    ready_count = $readyCount
    blocked_count = $blockedCount
    executor_count = @($sliceIds.Keys).Count
    validation_totals = [ordered]@{
      total = $validationTotal
      passed = $validationPassed
      failed = $validationFailed
      other = $validationOther
    }
    runtime_status_counts = Convert-HashtableToOrderedObject -Table $runtimeStatusCounts
    result_status_counts = Convert-HashtableToOrderedObject -Table $resultStatusCounts
    completion_status_counts = Convert-HashtableToOrderedObject -Table $completionStatusCounts
    merge_readiness_counts = Convert-HashtableToOrderedObject -Table $mergeReadinessCounts
    policy_gate_ready_rate = $readyRate
    source_summaries = @($sourceSummaries)
    source_results = @($sourceResults)
    source_files = @($sourceFiles)
  }

  Write-Utf8JsonFile -Path $output -Value $metrics -Depth 10

  Write-CliJson ([ordered]@{
    command = "summarize-autonomy-metrics"
    ok = $true
    output_path = $output
    summary_count = @($summaryRecords).Count
    ready_count = $readyCount
    blocked_count = $blockedCount
    policy_gate_ready_rate = $readyRate
  })

  exit 0
}

function New-FailureDiagnostics {
  param(
    [bool] $DryRun,
    [string] $ExecutionStatus,
    [AllowNull()]
    [object] $ExitCode,
    [bool] $TimedOut,
    [AllowNull()]
    [string] $Stdout,
    [AllowNull()]
    [string] $Stderr
  )

  $status = "not_applicable"
  $reason = "execution_succeeded"

  if ($DryRun) {
    $reason = "dry_run"
  }
  elseif ($ExecutionStatus -in @("failed", "timed_out") -or $TimedOut) {
    $status = "recorded"

    if ($TimedOut -or $ExecutionStatus -eq "timed_out") {
      $reason = "timeout"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Stderr)) {
      $reason = "stderr_nonempty"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Stdout)) {
      $reason = "stdout_only_failure"
    }
    else {
      $reason = "process_exit_without_output"
    }
  }

  return [ordered]@{
    status = $status
    reason = $reason
    exit_code = $ExitCode
    timed_out = $TimedOut
    redaction_policy = "bounded_preview_240_chars_with_secret_token_patterns_redacted"
    stdout_preview = Get-RedactedPreview -Text $Stdout -MaxLength 240
    stderr_preview = Get-RedactedPreview -Text $Stderr -MaxLength 240
  }
}

function New-RuntimeExecutionPrompt {
  param(
    [object] $Launch
  )

  $lines = @()
  $lines += "SpecBridge controlled runtime execution."
  $lines += ""
  $lines += "Task ID: $($Launch.task_id)"
  $lines += "Packet ID: $($Launch.packet_id)"
  $lines += "Slice ID: $($Launch.slice_id)"
  $lines += "Goal: $($Launch.goal)"
  $lines += ""
  $lines += "Execution contract: $($Launch.execution_contract_path)"
  $lines += "Final report path: $($Launch.final_report_path)"
  $lines += ""
  $lines += "Exclusive write paths:"
  foreach ($path in @($Launch.exclusive_write)) {
    $lines += "- $path"
  }
  $lines += ""
  $lines += "Read-only context paths:"
  foreach ($path in @($Launch.read_only)) {
    $lines += "- $path"
  }
  $lines += ""
  $lines += "Required prompt sections:"
  foreach ($section in @($Launch.prompt_sections)) {
    $lines += "- $section"
  }
  $lines += ""
  $lines += "Stop conditions:"
  foreach ($condition in @($Launch.stop_conditions)) {
    $lines += "- $condition"
  }
  $lines += ""
  $lines += "Report evidence, not confidence. Stop on any policy or scope conflict."

  return ($lines -join "`n")
}

function Get-RuntimeDesiredMaxTurns {
  param(
    [object] $Launch
  )

  $desiredMaxTurns = 8

  if ($Launch.PSObject.Properties.Name.Contains("max_turns") -and $null -ne $Launch.max_turns) {
    $desiredMaxTurns = [int] $Launch.max_turns
  }

  if ($desiredMaxTurns -lt 1 -or $desiredMaxTurns -gt 100) {
    Fail "max_turns must be between 1 and 100"
  }

  return $desiredMaxTurns
}

function New-ClaudeMaxTurnsNegotiation {
  param(
    [bool] $DryRun,
    [int] $DesiredMaxTurns,
    [AllowNull()]
    [object] $ClaudeCapability
  )

  $supported = $false
  $probeStatus = "not_run_dry_run"
  $reason = "dry_run_no_probe"

  if (-not $DryRun) {
    if ($null -eq $ClaudeCapability) {
      $probeStatus = "not_available"
      $reason = "claude_capability_unavailable"
    }
    else {
      $supported = [bool] $ClaudeCapability.supports_max_turns
      $probeStatus = $ClaudeCapability.help_probe_status
      $reason = $(if ($supported) { "supported_by_claude_help" } else { "not_reported_by_claude_help" })
    }
  }

  return [ordered]@{
    max_turns = [ordered]@{
      flag = "--max-turns"
      desired_value = $DesiredMaxTurns
      supported = $supported
      applied = (-not $DryRun -and $supported)
      probe_source = $(if ($DryRun) { "not_run" } else { "claude --help" })
      probe_status = $probeStatus
      reason = $reason
    }
  }
}

function Invoke-ExecuteRuntimeLaunchCommand {
  $launchPath = Normalize-RepoPath -Path $InputPath -FieldName "InputPath"
  $output = Assert-OutputPath `
    -Path $OutputPath `
    -Pattern "^\.specbridge/runtime-executions/.+\.runtime-execution\.json$" `
    -Description "a .specbridge/runtime-executions/*.runtime-execution.json runtime execution artifact"

  if ($launchPath -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
    Fail "InputPath must be a .specbridge/runtime-launches/*.runtime-launch.json file: $launchPath"
  }

  if (-not (Test-Path -LiteralPath $launchPath -PathType Leaf)) {
    Fail "InputPath does not exist: $launchPath"
  }

  if ($TimeoutSeconds -lt 30 -or $TimeoutSeconds -gt 3600) {
    Fail "TimeoutSeconds must be between 30 and 3600"
  }

  $launch = Get-JsonObjectFromFile -Path $launchPath -Description "runtime launch"
  $context = "runtime launch $launchPath"

  foreach ($field in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "goal", "exclusive_write", "read_only", "allowed_tools", "permission_mode", "max_budget_usd", "prompt_sections", "stop_conditions", "launch_status")) {
    if (-not $launch.PSObject.Properties.Name.Contains($field)) {
      Fail "$context must include $field"
    }
  }

  if ($launch.launch_status -ne "ready_for_operator_launch") {
    Fail "runtime launch status must be ready_for_operator_launch: $launchPath"
  }

  $allowedTools = @($launch.allowed_tools | ForEach-Object { $_.ToString().Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  foreach ($tool in $allowedTools) {
    if (@("Read", "Write", "Edit") -notcontains $tool) {
      Fail "runtime launch contains an unapproved tool for controlled execution: $tool"
    }
  }

  if ($allowedTools -notcontains "Read" -or $allowedTools -notcontains "Write") {
    Fail "runtime launch must include Read and Write tools for controlled execution"
  }

  if (-not $DryRun -and -not $Force) {
    Fail "Live execute-runtime-launch requires -Force; use -DryRun for planning evidence"
  }

  $prompt = New-RuntimeExecutionPrompt -Launch $launch
  $toolCsv = ($allowedTools -join ",")
  $desiredMaxTurns = Get-RuntimeDesiredMaxTurns -Launch $launch
  $claudeCapability = $null
  $claudeCapabilities = New-ClaudeMaxTurnsNegotiation `
    -DryRun ([bool] $DryRun) `
    -DesiredMaxTurns $desiredMaxTurns `
    -ClaudeCapability $null

  $commandParts = @(
    "claude",
    "-p",
    "--no-session-persistence",
    "--max-budget-usd",
    $launch.max_budget_usd
  )

  $executionStatus = "dry_run"
  $exitCode = $null
  $timedOut = $false
  $stdoutLength = 0
  $stderrLength = 0
  $stdoutLineCount = 0
  $stderrLineCount = 0
  $stdoutSha256 = $null
  $stderrSha256 = $null
  $stdout = ""
  $stderr = ""

  if (-not $DryRun) {
    $claudeCommand = Get-Command claude -ErrorAction SilentlyContinue

    if ($null -eq $claudeCommand) {
      Fail "Claude Code CLI is not available on PATH"
    }

    $claudeExecutable = $claudeCommand.Source

    if ([string]::IsNullOrWhiteSpace($claudeExecutable) -and $claudeCommand.PSObject.Properties.Name.Contains("Path")) {
      $claudeExecutable = $claudeCommand.Path
    }

    if ([string]::IsNullOrWhiteSpace($claudeExecutable)) {
      $claudeExecutable = "claude"
    }

    $claudeCapability = Get-ClaudeCapability
    $claudeCapabilities = New-ClaudeMaxTurnsNegotiation `
      -DryRun $false `
      -DesiredMaxTurns $desiredMaxTurns `
      -ClaudeCapability $claudeCapability

    if ($claudeCapabilities.max_turns.applied) {
      $commandParts += @("--max-turns", $desiredMaxTurns.ToString([System.Globalization.CultureInfo]::InvariantCulture))
    }

    $commandParts += @(
      "--permission-mode",
      $launch.permission_mode,
      "--tools",
      $toolCsv,
      "--allowedTools",
      $toolCsv,
      "--input-format",
      "text"
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $claudeExecutable
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $psi.Arguments = (($commandParts | Select-Object -Skip 1 | ForEach-Object { '"' + ($_.ToString().Replace('"', '\"')) + '"' }) -join " ")
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($prompt)
    $process.StandardInput.Close()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
      $timedOut = $true
      $executionStatus = "timed_out"
      $process.Kill()
      $process.WaitForExit()
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $exitCode = $process.ExitCode

    if ($timedOut -and ($exitCode -lt 0 -or $exitCode -gt 255)) {
      $exitCode = 255
    }

    $stdoutLength = $stdout.Length
    $stderrLength = $stderr.Length
    $stdoutLineCount = Get-TextLineCount -Text $stdout
    $stderrLineCount = Get-TextLineCount -Text $stderr
    $stdoutSha256 = Get-TextSha256 -Text $stdout
    $stderrSha256 = Get-TextSha256 -Text $stderr

    if (-not $timedOut) {
      if ($exitCode -eq 0) {
        $executionStatus = "succeeded"
      }
      else {
        $executionStatus = "failed"
      }
    }
  }

  $safeExecutionId = Convert-ToSafeName -Value ($launch.launch_id + "-runtime-execution") -FieldName "execution_id"
  $policyResult = "Dry run only. Claude Code was not launched."

  if (-not $DryRun) {
    $policyResult = "Controlled Claude Code launch executed with bounded tools, budget, timeout, and repository-scoped launch plan."
  }

  if ($DryRun) {
    $commandParts += @(
      "[--max-turns",
      $desiredMaxTurns.ToString([System.Globalization.CultureInfo]::InvariantCulture),
      "if-supported]",
      "--permission-mode",
      $launch.permission_mode,
      "--tools",
      $toolCsv,
      "--allowedTools",
      $toolCsv,
      "--input-format",
      "text"
    )
  }

  $execution = [ordered]@{
    schema_version = "1"
    execution_id = $safeExecutionId
    generated_by = "specbridge-cli"
    runtime_launch_path = $launchPath
    launch_id = $launch.launch_id
    task_id = $launch.task_id
    packet_id = $launch.packet_id
    slice_id = $launch.slice_id
    branch_name = $launch.branch_name
    dry_run = [bool] $DryRun
    timeout_seconds = $TimeoutSeconds
    allowed_tools = @($allowedTools)
    permission_mode = $launch.permission_mode
    max_budget_usd = $launch.max_budget_usd
    max_turns = $desiredMaxTurns
    claude_capabilities = $claudeCapabilities
    command_summary = ($commandParts -join " ")
    prompt_sections = @($launch.prompt_sections)
    execution_status = $executionStatus
    exit_code = $exitCode
    timed_out = $timedOut
    stdout = [ordered]@{
      captured = (-not $DryRun)
      length = $stdoutLength
      line_count = $stdoutLineCount
      sha256 = $stdoutSha256
    }
    stderr = [ordered]@{
      captured = (-not $DryRun)
      length = $stderrLength
      line_count = $stderrLineCount
      sha256 = $stderrSha256
    }
    failure_diagnostics = New-FailureDiagnostics `
      -DryRun ([bool] $DryRun) `
      -ExecutionStatus $executionStatus `
      -ExitCode $exitCode `
      -TimedOut $timedOut `
      -Stdout $stdout `
      -Stderr $stderr
    policy_result = $policyResult
    execution_policy = [ordered]@{
      launches_claude = (-not [bool] $DryRun)
      launches_antigravity = $false
      executes_shell = $false
      requires_network = (-not [bool] $DryRun)
      touches_secrets = $false
      touches_production = $false
      installs_dependencies = $false
      deploys = $false
    }
    source_files = @($launchPath)
  }

  Write-Utf8JsonFile -Path $output -Value $execution -Depth 10

  Write-CliJson ([ordered]@{
    command = "execute-runtime-launch"
    ok = ($executionStatus -in @("dry_run", "succeeded"))
    output_path = $output
    runtime_launch_path = $launchPath
    execution_status = $executionStatus
    dry_run = [bool] $DryRun
  })

  if ($executionStatus -notin @("dry_run", "succeeded")) {
    exit 1
  }

  exit 0
}

