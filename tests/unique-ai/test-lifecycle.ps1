param([string]$RepoRoot = '')
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$script:passed = 0
$script:failed = 0
function Assert-Condition {
    param([string]$Name, [bool]$Condition)
    if ($Condition) { Write-Host "  PASS: $Name"; $script:passed++ }
    else { Write-Host "  FAIL: $Name"; $script:failed++ }
}
$global:REPO_ROOT = $RepoRoot
. (Join-Path $RepoRoot 'scripts\lib\unique-ai-common.ps1')
. (Join-Path $RepoRoot 'scripts\lib\unique-ai-provider.ps1')
. (Join-Path $RepoRoot 'scripts\lib\unique-ai-lifecycle.ps1')
$fixture = 'tests\unique-ai\fixtures\fake-provider.ps1'
function New-FakeConfig {
    param([string]$Mode='success',[int]$SleepSeconds=0,[int]$Retries=1,[int]$Timeout=10,[double]$Budget=5.0,[int]$MaxInvocations=10)
    return [PSCustomObject]@{
        provider = [PSCustomObject]@{ provider_id='fake-local'; model='fake-v1'; executable='powershell'; arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$fixture,'-Mode',$Mode,'-SleepSeconds',[string]$SleepSeconds) }
        limits = [PSCustomObject]@{ max_retries=$Retries; timeout_seconds=$Timeout; budget_usd=$Budget; estimated_cost_per_invocation_usd=0.25; max_invocations=$MaxInvocations }
        blocked_paths = @('.env','.github/workflows/**')
        validation_scripts = @('tests/unique-ai/fixtures/pass-validation.ps1')
    }
}
Write-Host '=== test-lifecycle ==='
$taskId = 'fixture-' + ([guid]::NewGuid().ToString('N').Substring(0,8))
$failureTask = $null; $timeoutTask = $null; $budgetTask = $null
$config = New-FakeConfig
try {
    $plan = Invoke-UniqueAIPlan -TaskId $taskId -Title 'Fixture' -Goal 'Exercise complete lifecycle' -Config $config -DryRun $false
    $implement = Invoke-UniqueAIImplement -TaskId $taskId -Config $config -DryRun $false
    $validate = Invoke-UniqueAIValidate -TaskId $taskId -Config $config -DryRun $false
    $review = Invoke-UniqueAIReview -TaskId $taskId -Config $config -DryRun $false
    $close = Invoke-UniqueAIClose -TaskId $taskId -Config $config -DryRun $false
    Assert-Condition 'successful lifecycle closes' ($plan.ok -and $implement.ok -and $validate.ok -and $review.ok -and $close.status -eq 'completed')
    $reviewArtifact = Get-UniqueAIArtifact -TaskId $taskId -Name 'review'
    Assert-Condition 'review uses fresh process marker' ($reviewArtifact.session_mode -eq 'fresh_process' -and -not [string]::IsNullOrWhiteSpace($reviewArtifact.session_id))
    Assert-Condition 'same provider and model locked' ($reviewArtifact.provider_result.provider_identity.provider_id -eq 'fake-local' -and $reviewArtifact.provider_result.provider_identity.model -eq 'fake-v1')

    $changedModel = New-FakeConfig
    $changedModel.provider.model = 'fake-v2'
    $caught = $false
    try { Invoke-UniqueAIReview -TaskId $taskId -Config $changedModel -DryRun $true | Out-Null } catch { $caught = $_.Exception.Message -like '*identity lock*' }
    Assert-Condition 'mixed model rejected' $caught

    $failureTask = 'fail-' + ([guid]::NewGuid().ToString('N').Substring(0,8))
    $failure = Invoke-UniqueAIProvider -Config (New-FakeConfig -Mode fail -Retries 1) -Phase implement -TaskId $failureTask -Prompt test -DryRun $false
    Assert-Condition 'provider failure is honest and bounded' (-not $failure.ok -and $failure.failure -eq 'provider_failed' -and $failure.attempts -eq 2)

    $timeoutTask = 'timeout-' + ([guid]::NewGuid().ToString('N').Substring(0,8))
    $timeout = Invoke-UniqueAIProvider -Config (New-FakeConfig -SleepSeconds 3 -Retries 0 -Timeout 1) -Phase implement -TaskId $timeoutTask -Prompt test -DryRun $false
    Assert-Condition 'provider timeout enforced' (-not $timeout.ok -and $timeout.failure -eq 'timeout' -and $timeout.attempts -eq 1)

    $budgetTask = 'budget-' + ([guid]::NewGuid().ToString('N').Substring(0,8))
    $budget = Invoke-UniqueAIProvider -Config (New-FakeConfig -Budget 0.1 -MaxInvocations 1) -Phase implement -TaskId $budgetTask -Prompt test -DryRun $false
    Assert-Condition 'budget enforced before invocation' (-not $budget.ok -and -not $budget.invoked -and $budget.failure -eq 'budget_exhausted')
    Assert-Condition 'blocked path enforced' (Test-BlockedPath -BlockedPatterns @('.env','.github/workflows/**') -Path '.github/workflows/ci.yml')
} finally {
    foreach ($id in @($taskId,$failureTask,$timeoutTask,$budgetTask)) {
        if ($id) { $path = Join-Path $RepoRoot ".unique-ai\runs\$id"; if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force } }
    }
}
Write-Host "test-lifecycle: $passed passed, $failed failed"
exit $(if ($failed -gt 0) { 1 } else { 0 })
