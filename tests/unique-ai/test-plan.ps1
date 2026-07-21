# tests/unique-ai/test-plan.ps1
# Tests for the plan command (dry-run mode). Exits 0 if all pass, 1 if any fail.
param([string]$RepoRoot = '')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$scriptPath = Join-Path $RepoRoot 'scripts\unique-ai.ps1'
$testTaskId = 'ua-test-plan-' + (Get-Date -Format 'yyyyMMddHHmmss')
$runDir     = Join-Path $RepoRoot ".unique-ai\runs\$testTaskId"

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

Write-Host "=== test-plan ==="

# Test 1: plan dry-run exits 0
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan `
    -TaskId $testTaskId -Title 'Test Plan' -Goal 'Verify deterministic plan artifact' 2>&1
$exitCode = $LASTEXITCODE
Assert-Condition 'plan exits 0' ($exitCode -eq 0)

# Test 2: output is valid JSON
$json = $null
try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'plan output is valid JSON' ($null -ne $json)

# Test 3: ok=true
Assert-Condition 'plan ok=true' ($null -ne $json -and $json.ok -eq $true)

# Test 4: command=plan
Assert-Condition 'plan command field' ($null -ne $json -and $json.command -eq 'plan')

# Test 5: dry-run status
Assert-Condition 'plan status=dry_run' ($null -ne $json -and $json.status -eq 'dry_run')

# Test 6: dry_run=true (no -Apply passed)
Assert-Condition 'plan dry_run=true' ($null -ne $json -and $json.dry_run -eq $true)

# Test 7: artifact path returned
Assert-Condition 'plan has artifact path' ($null -ne $json -and -not [string]::IsNullOrWhiteSpace($json.artifact))

# Test 8: artifact file exists on disk
$artifactPath = if ($json) { $json.artifact } else { '' }
Assert-Condition 'plan artifact file exists' (
    -not [string]::IsNullOrWhiteSpace($artifactPath) -and (Test-Path $artifactPath)
)

# Test 9: artifact JSON shape
$artifactJson = $null
if (Test-Path $artifactPath) {
    try {
        $text = [System.IO.File]::ReadAllText($artifactPath, [System.Text.Encoding]::UTF8)
        $artifactJson = $text | ConvertFrom-Json
    } catch {}
}
Assert-Condition 'plan artifact is valid JSON' ($null -ne $artifactJson)
Assert-Condition 'plan artifact schema_version' ($null -ne $artifactJson -and $artifactJson.schema_version -eq '1')
Assert-Condition 'plan artifact task_id correct' ($null -ne $artifactJson -and $artifactJson.task_id -eq $testTaskId)
Assert-Condition 'plan artifact title' ($null -ne $artifactJson -and $artifactJson.title -eq 'Test Plan')
Assert-Condition 'plan artifact goal' ($null -ne $artifactJson -and $artifactJson.goal -eq 'Verify deterministic plan artifact')
Assert-Condition 'plan artifact phase=plan' ($null -ne $artifactJson -and $artifactJson.phase -eq 'plan')
Assert-Condition 'plan artifact status=dry_run' ($null -ne $artifactJson -and $artifactJson.status -eq 'dry_run')
Assert-Condition 'plan artifact dry_run=true' ($null -ne $artifactJson -and $artifactJson.dry_run -eq $true)
Assert-Condition 'plan artifact review_label' ($null -ne $artifactJson -and $artifactJson.review_label -eq 'fresh_session_self_review')
Assert-Condition 'plan artifact merge_policy' ($null -ne $artifactJson -and $artifactJson.merge_policy -eq 'no_autonomous_merge')
Assert-Condition 'plan artifact next_phase=implement' ($null -ne $artifactJson -and $artifactJson.next_phase -eq 'implement')

# Test: next_phase in CLI result
Assert-Condition 'plan next_phase=implement in result' ($null -ne $json -and $json.next_phase -eq 'implement')

# Test: demo command from contract acceptance criteria
$demoOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath plan `
    -TaskId demo -Title Demo -Goal Demonstrate 2>&1
$demoExitCode = $LASTEXITCODE
$demoJson = $null
try { $demoJson = $demoOutput | ConvertFrom-Json } catch {}
Assert-Condition 'demo plan exits 0' ($demoExitCode -eq 0)
Assert-Condition 'demo plan ok=true' ($null -ne $demoJson -and $demoJson.ok -eq $true)
Assert-Condition 'demo plan status=dry_run' ($null -ne $demoJson -and $demoJson.status -eq 'dry_run')

Write-Host ""
Write-Host "test-plan: $passed passed, $failed failed"

# Cleanup test run directories (not evidence, just test artifacts)
try {
    if (Test-Path $runDir) { Remove-Item $runDir -Recurse -Force -ErrorAction SilentlyContinue }
    $demoDir = Join-Path $RepoRoot '.unique-ai\runs\demo'
    if (Test-Path $demoDir) { Remove-Item $demoDir -Recurse -Force -ErrorAction SilentlyContinue }
} catch {}

exit $(if ($failed -gt 0) { 1 } else { 0 })
