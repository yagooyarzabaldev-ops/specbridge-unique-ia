# Governed lifecycle for one locked provider_id + model.

function Get-TaskPlan {
    param([string]$TaskId)
    $plan = Get-UniqueAIArtifact -TaskId $TaskId -Name 'plan'
    if ($null -eq $plan) { throw "Plan artifact not found for task '$TaskId'." }
    return $plan
}

function New-PhaseArtifact {
    param([string]$TaskId, [string]$Phase, [string]$Status, [bool]$DryRun, [object]$ProviderResult = $null, [hashtable]$Extra = @{})
    $artifact = [ordered]@{ schema_version = '1'; task_id = $TaskId; phase = $Phase; status = $Status; dry_run = $DryRun; created_at = (Get-Date).ToUniversalTime().ToString('o') }
    if ($null -ne $ProviderResult) { $artifact.provider_result = $ProviderResult }
    foreach ($key in $Extra.Keys) { $artifact[$key] = $Extra[$key] }
    $path = Join-Path (Get-UniqueAIRunDir -TaskId $TaskId) "$Phase.json"
    Write-Utf8JsonFile -Path $path -Value $artifact -Depth 10
    $result = [ordered]@{ ok = ($Status -notin @('failed', 'blocked')); task_id = $TaskId; phase = $Phase; status = $Status; dry_run = $DryRun; artifact = $path }
    if ($Extra.ContainsKey('next_phase')) { $result.next_phase = $Extra.next_phase }
    if ($Extra.ContainsKey('review_label')) { $result.review_label = $Extra.review_label }
    return $result
}

function Invoke-UniqueAIPlan {
    param([string]$TaskId, [string]$Title, [string]$Goal, [object]$Config, [bool]$DryRun = $true)
    Assert-SafeTaskId -TaskId $TaskId
    Assert-UniqueAIConfig -Config $Config
    $providerResult = Invoke-UniqueAIProvider -Config $Config -Phase 'plan' -TaskId $TaskId -Prompt "Create an implementation plan. Title: $Title`nGoal: $Goal" -DryRun $DryRun
    $status = if ($DryRun) { 'dry_run' } elseif ($providerResult.ok) { 'completed' } else { 'failed' }
    $extra = @{ title = $Title; goal = $Goal; provider_identity = (Get-ProviderIdentity -Config $Config); lifecycle_phases = @('plan','implement','validate_fix','fresh_session_self_review','close'); review_label = 'fresh_session_self_review'; merge_policy = 'no_autonomous_merge'; next_phase = 'implement' }
    return New-PhaseArtifact -TaskId $TaskId -Phase 'plan' -Status $status -DryRun $DryRun -ProviderResult $providerResult -Extra $extra
}

function Invoke-UniqueAIImplement {
    param([string]$TaskId, [object]$Config, [bool]$DryRun = $true)
    Assert-SafeTaskId -TaskId $TaskId
    $plan = Get-TaskPlan -TaskId $TaskId
    Assert-ProviderIdentityLock -Config $Config -PlanArtifact $plan
    if (-not $DryRun -and $plan.status -ne 'completed') { throw 'Apply mode requires a successfully completed plan phase.' }
    $prompt = "Implement task '$($plan.title)' in the repository. Goal: $($plan.goal). Respect repository policy and blocked paths. Do not merge or deploy."
    $providerResult = Invoke-UniqueAIProvider -Config $Config -Phase 'implement' -TaskId $TaskId -Prompt $prompt -DryRun $DryRun
    $status = if ($DryRun) { 'dry_run' } elseif ($providerResult.ok) { 'completed' } else { 'failed' }
    return New-PhaseArtifact -TaskId $TaskId -Phase 'implement' -Status $status -DryRun $DryRun -ProviderResult $providerResult -Extra @{ next_phase = 'validate' }
}

function Invoke-ValidationScripts {
    param([object]$Config)
    $results = @()
    foreach ($relativePath in @($Config.validation_scripts)) {
        $normalized = ([string]$relativePath).Replace('\','/')
        if ($normalized -notmatch '^[a-zA-Z0-9._/-]+\.ps1$' -or (Test-BlockedPath -BlockedPatterns @($Config.blocked_paths) -Path $normalized)) {
            $results += [ordered]@{ script = $normalized; ok = $false; exit_code = -1; failure = 'blocked_or_invalid_validation_path' }
            continue
        }
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $REPO_ROOT $normalized))
        if (-not $fullPath.StartsWith(([System.IO.Path]::GetFullPath($REPO_ROOT) + [System.IO.Path]::DirectorySeparatorChar), [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullPath)) {
            $results += [ordered]@{ script = $normalized; ok = $false; exit_code = -1; failure = 'validation_script_not_found' }
            continue
        }
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $fullPath 2>&1
        $exitCode = $LASTEXITCODE
        $results += [ordered]@{ script = $normalized; ok = ($exitCode -eq 0); exit_code = $exitCode; output = ($output -join "`n") }
    }
    return @($results)
}

function Invoke-UniqueAIValidate {
    param([string]$TaskId, [object]$Config, [bool]$DryRun = $true)
    Assert-SafeTaskId -TaskId $TaskId
    $plan = Get-TaskPlan -TaskId $TaskId
    Assert-ProviderIdentityLock -Config $Config -PlanArtifact $plan
    if ($DryRun) { return New-PhaseArtifact -TaskId $TaskId -Phase 'validate' -Status 'dry_run' -DryRun $true -Extra @{ results = @(); fix_attempted = $false; next_phase = 'review' } }
    Assert-PhaseSucceeded -TaskId $TaskId -Phase 'implement'
    $results = @(Invoke-ValidationScripts -Config $Config)
    $failed = @($results | Where-Object { -not $_.ok })
    $fixResult = $null
    if ($failed.Count -gt 0) {
        $summary = ($failed | ConvertTo-Json -Depth 5)
        $fixResult = Invoke-UniqueAIProvider -Config $Config -Phase 'validate_fix' -TaskId $TaskId -Prompt "Fix only the validation failures for task $TaskId. Failures: $summary" -DryRun $false
        if ($fixResult.ok) { $results = @(Invoke-ValidationScripts -Config $Config); $failed = @($results | Where-Object { -not $_.ok }) }
    }
    $status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
    return New-PhaseArtifact -TaskId $TaskId -Phase 'validate' -Status $status -DryRun $false -ProviderResult $fixResult -Extra @{ results = $results; fix_attempted = ($null -ne $fixResult); next_phase = 'review' }
}

function Invoke-UniqueAIReview {
    param([string]$TaskId, [object]$Config, [bool]$DryRun = $true)
    Assert-SafeTaskId -TaskId $TaskId
    $plan = Get-TaskPlan -TaskId $TaskId
    Assert-ProviderIdentityLock -Config $Config -PlanArtifact $plan
    if (-not $DryRun) { Assert-PhaseSucceeded -TaskId $TaskId -Phase 'validate' }
    $sessionId = [guid]::NewGuid().ToString()
    $prompt = "Fresh-session self-review. Review task $TaskId against its plan and repository evidence. Report defects honestly; do not merge or deploy."
    $providerResult = Invoke-UniqueAIProvider -Config $Config -Phase 'fresh_session_self_review' -TaskId $TaskId -Prompt $prompt -DryRun $DryRun
    $status = if ($DryRun) { 'dry_run' } elseif ($providerResult.ok) { 'completed' } else { 'failed' }
    return New-PhaseArtifact -TaskId $TaskId -Phase 'review' -Status $status -DryRun $DryRun -ProviderResult $providerResult -Extra @{ review_label = 'fresh_session_self_review'; session_mode = 'fresh_process'; session_id = $sessionId; independence_limit = 'same provider and model; context isolation only'; next_phase = 'close' }
}

function Invoke-UniqueAIClose {
    param([string]$TaskId, [object]$Config, [bool]$DryRun = $true)
    Assert-SafeTaskId -TaskId $TaskId
    $plan = Get-TaskPlan -TaskId $TaskId
    Assert-ProviderIdentityLock -Config $Config -PlanArtifact $plan
    if ($DryRun) { return New-PhaseArtifact -TaskId $TaskId -Phase 'close' -Status 'dry_run' -DryRun $true -Extra @{ merge_policy = 'no_autonomous_merge'; deployment = 'none' } }
    Assert-PhaseSucceeded -TaskId $TaskId -Phase 'implement'
    Assert-PhaseSucceeded -TaskId $TaskId -Phase 'validate'
    Assert-PhaseSucceeded -TaskId $TaskId -Phase 'review'
    return New-PhaseArtifact -TaskId $TaskId -Phase 'close' -Status 'completed' -DryRun $false -Extra @{ merge_policy = 'no_autonomous_merge'; deployment = 'none'; evidence_complete = $true }
}
