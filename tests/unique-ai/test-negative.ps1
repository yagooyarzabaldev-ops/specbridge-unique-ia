# tests/unique-ai/test-negative.ps1
# Negative tests: missing args, invalid TaskId, provider lock, blocked paths.
# Exits 0 if all pass, 1 if any fail.
param([string]$RepoRoot = '')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$scriptPath = Join-Path $RepoRoot 'scripts\unique-ai.ps1'

$passed = 0
$failed = 0

function Assert-Condition {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host "  PASS: $Name"
        $script:passed++
    } else {
        Write-Host "  FAIL: $Name$(if ($Detail) { ": $Detail" })"
        $script:failed++
    }
}

Write-Host "=== test-negative ==="

# --- Missing required args ---

# plan missing -TaskId
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan -Title T -Goal G 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan missing TaskId exits 1' ($ec -eq 1)
Assert-Condition 'plan missing TaskId ok=false' ($null -ne $json -and $json.ok -eq $false)

# plan missing -Title
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan -TaskId valid-id -Goal G 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan missing Title exits 1' ($ec -eq 1)
Assert-Condition 'plan missing Title ok=false' ($null -ne $json -and $json.ok -eq $false)

# plan missing -Goal
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan -TaskId valid-id -Title T 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan missing Goal exits 1' ($ec -eq 1)
Assert-Condition 'plan missing Goal ok=false' ($null -ne $json -and $json.ok -eq $false)

# implement missing -TaskId
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath implement 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'implement missing TaskId exits 1' ($ec -eq 1)
Assert-Condition 'implement missing TaskId ok=false' ($null -ne $json -and $json.ok -eq $false)

# --- Invalid TaskId ---

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan `
    -TaskId 'invalid!task' -Title T -Goal G 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan invalid TaskId exits 1' ($ec -eq 1)
Assert-Condition 'plan invalid TaskId ok=false' ($null -ne $json -and $json.ok -eq $false)

# TaskId with spaces
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan `
    -TaskId 'bad task id' -Title T -Goal G 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan TaskId with spaces exits 1' ($ec -eq 1)
Assert-Condition 'plan TaskId with spaces ok=false' ($null -ne $json -and $json.ok -eq $false)

# --- implement without prior plan ---

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath implement `
    -TaskId 'no-plan-task-xyz' 2>&1
$ec = $LASTEXITCODE
$json = $null; try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'implement without plan exits 1' ($ec -eq 1)
Assert-Condition 'implement without plan ok=false' ($null -ne $json -and $json.ok -eq $false)

# --- Provider lock: test the assertion function directly ---

$REPO_ROOT = $RepoRoot
. (Join-Path $RepoRoot 'scripts\lib\unique-ai-common.ps1')
. (Join-Path $RepoRoot 'scripts\lib\unique-ai-provider.ps1')

$mockConfig = [PSCustomObject]@{
    provider = [PSCustomObject]@{ provider_id = 'provider-a'; model = 'model-a'; executable = 'powershell'; arguments = @() }
    limits = [PSCustomObject]@{ max_retries = 1; timeout_seconds = 30; budget_usd = 2.0; estimated_cost_per_invocation_usd = 0.1; max_invocations = 5 }
}
$mockPlan = [PSCustomObject]@{ provider_identity = [PSCustomObject]@{ provider_id = 'provider-b'; model = 'model-a' } }

$lockViolationCaught = $false
try {
    Assert-ProviderIdentityLock -Config $mockConfig -PlanArtifact $mockPlan
} catch {
    $lockViolationCaught = ($_.Exception.Message -like '*Provider identity lock*')
}
Assert-Condition 'provider lock violation throws' $lockViolationCaught

# Same provider should not throw
$mockPlanSame = [PSCustomObject]@{ provider_identity = [PSCustomObject]@{ provider_id = 'provider-a'; model = 'model-a' } }
$lockNoViolation = $true
try {
    Assert-ProviderIdentityLock -Config $mockConfig -PlanArtifact $mockPlanSame
} catch {
    $lockNoViolation = $false
}
Assert-Condition 'same provider does not throw' $lockNoViolation

# --- Blocked path test ---

$blockedPatterns = @('.env', '.env.*', '.github/workflows/**')

$isBlocked = Test-BlockedPath -BlockedPatterns $blockedPatterns -Path '.env'
Assert-Condition 'blocked path: .env' ($isBlocked -eq $true)

$isBlocked2 = Test-BlockedPath -BlockedPatterns $blockedPatterns -Path '.env.production'
Assert-Condition 'blocked path: .env.production' ($isBlocked2 -eq $true)

$isBlocked3 = Test-BlockedPath -BlockedPatterns $blockedPatterns -Path '.github/workflows/ci.yml'
Assert-Condition 'blocked path: .github/workflows/ci.yml' ($isBlocked3 -eq $true)

$notBlocked = Test-BlockedPath -BlockedPatterns $blockedPatterns -Path 'scripts/unique-ai.ps1'
Assert-Condition 'not blocked: scripts/unique-ai.ps1' ($notBlocked -eq $false)

# --- Dry-run: no provider invocation in plan ---

$planOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan `
    -TaskId 'dry-run-check-xyz' -Title 'Dry' -Goal 'Check no provider called' 2>&1
$planJson = $null; try { $planJson = $planOutput | ConvertFrom-Json } catch {}
Assert-Condition 'plan dry-run ok=true' ($null -ne $planJson -and $planJson.ok -eq $true)
Assert-Condition 'plan dry-run dry_run=true' ($null -ne $planJson -and $planJson.dry_run -eq $true)

# plan artifact should not have provider_result (provider was not called)
$dryArtifact = $null
if ($planJson -and -not [string]::IsNullOrWhiteSpace($planJson.artifact) -and (Test-Path $planJson.artifact)) {
    try {
        $text = [System.IO.File]::ReadAllText($planJson.artifact, [System.Text.Encoding]::UTF8)
        $dryArtifact = $text | ConvertFrom-Json
    } catch {}
}
# plan artifact records a structured non-invocation.
$notInvoked = ($null -ne $dryArtifact -and $dryArtifact.provider_result.invoked -eq $false)
Assert-Condition 'plan dry-run provider not invoked' $notInvoked

Write-Host ""
Write-Host "test-negative: $passed passed, $failed failed"

# Cleanup
try {
    $dryRunDir = Join-Path $RepoRoot '.unique-ai\runs\dry-run-check-xyz'
    if (Test-Path $dryRunDir) { Remove-Item $dryRunDir -Recurse -Force -ErrorAction SilentlyContinue }
} catch {}

exit $(if ($failed -gt 0) { 1 } else { 0 })
