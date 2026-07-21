# tests/unique-ai/test-ci.ps1
# Deterministic CI governance tests for the provider-neutral Unique IA CI setup.
# Exits 0 if all pass, 1 if any fail. No network, no AI provider, no secrets.
param([string]$RepoRoot = '')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$passed = 0
$failed = 0

function Assert-Condition {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host "  PASS: $Name"
        $script:passed++
    } else {
        Write-Host "  FAIL: $Name$(if ($Detail) { ': ' + $Detail })"
        $script:failed++
    }
}

Write-Host "=== test-ci ==="

# --- 1. unique-ai-ci.yml existence and required structure ---

$uniqueAiCiPath = Join-Path $RepoRoot '.github\workflows\unique-ai-ci.yml'
$uniqueAiCiExists = Test-Path -LiteralPath $uniqueAiCiPath -PathType Leaf
Assert-Condition 'unique-ai-ci.yml exists' $uniqueAiCiExists

if ($uniqueAiCiExists) {
    $ciContent = Get-Content -LiteralPath $uniqueAiCiPath -Raw

    Assert-Condition 'unique-ai-ci has pull_request trigger' ($ciContent -match 'pull_request:')
    Assert-Condition 'unique-ai-ci targets main branch' ($ciContent -match 'branches:\s*[\r\n]+\s*-\s*main')
    Assert-Condition 'unique-ai-ci has push trigger' ($ciContent -match '(?m)^\s+push:')
    Assert-Condition 'unique-ai-ci permissions contents read' ($ciContent -match 'contents:\s*read')
    Assert-Condition 'unique-ai-ci job id is unique-ai-ci' (
        $ciContent -match '(?m)^\s{2}unique-ai-ci\s*:'
    )
    Assert-Condition 'unique-ai-ci has stable job name' (
        $ciContent -match "name:\s*unique-ai-ci"
    )
    Assert-Condition 'unique-ai-ci runs on windows-latest' ($ciContent -match 'windows-latest')
    Assert-Condition 'unique-ai-ci runs test.ps1' ($ciContent -match 'scripts/test\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-contracts.ps1' ($ciContent -match 'validate-contracts\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-contract-scopes.ps1' ($ciContent -match 'validate-contract-scopes\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-final-reports.ps1' ($ciContent -match 'validate-final-reports\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-audit-packets.ps1' ($ciContent -match 'validate-audit-packets\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-chatgpt-audits.ps1' ($ciContent -match 'validate-chatgpt-audits\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-standard-ci-authority.ps1' ($ciContent -match 'validate-standard-ci-authority\.ps1')
    Assert-Condition 'unique-ai-ci runs validate-security-gates.ps1' ($ciContent -match 'validate-security-gates\.ps1')
    Assert-Condition 'unique-ai-ci has whitespace check' ($ciContent -match 'git diff --check')
    Assert-Condition 'unique-ai-ci does not use provider actions' (
        $ciContent -notmatch 'anthropics/' -and
        $ciContent -notmatch 'openai/' -and
        $ciContent -notmatch 'codex-action'
    )
    Assert-Condition 'unique-ai-ci does not reference provider API-key secrets' (
        $ciContent -notmatch 'ANTHROPIC_API_KEY' -and
        $ciContent -notmatch 'OPENAI_API_KEY'
    )
    Assert-Condition 'unique-ai-ci has no write permissions beyond read' (
        $ciContent -notmatch 'contents:\s*write' -and
        $ciContent -notmatch 'pull-requests:\s*write' -and
        $ciContent -notmatch 'issues:\s*write'
    )
}

$foundationPath = Join-Path $RepoRoot '.github\workflows\foundation-validation.yml'
$foundationContent = Get-Content -LiteralPath $foundationPath -Raw
Assert-Condition 'foundation validation runs security gate' ($foundationContent -match 'validate-security-gates\.ps1')

# --- 2. Active workflows must not reference provider-specific actions or secrets ---

$workflowsDir = Join-Path $RepoRoot '.github\workflows'
$providerPatterns = @(
    'anthropics/',
    'openai/',
    'ANTHROPIC_API_KEY',
    'OPENAI_API_KEY',
    'codex-action'
)

if (Test-Path -LiteralPath $workflowsDir -PathType Container) {
    $workflowFiles = @(Get-ChildItem -Path $workflowsDir -Filter '*.yml' -File)
    foreach ($wf in $workflowFiles) {
        $wfContent = Get-Content -LiteralPath $wf.FullName -Raw
        foreach ($pattern in $providerPatterns) {
            Assert-Condition "active workflow '$($wf.Name)' does not reference '$pattern'" (
                $wfContent -notmatch [regex]::Escape($pattern)
            ) $wf.Name
        }
    }
}

# --- 3. Removed provider-specific workflow files are absent ---

$removedFiles = @(
    '.github\workflows\claude-review-non-blocking.yml',
    '.github\workflows\codex-review.example.yml',
    '.github\workflows\claude-code-review.example.yml',
    '.github\workflows\claude-code-execute.example.yml'
)

foreach ($rel in $removedFiles) {
    $absPath = Join-Path $RepoRoot $rel
    Assert-Condition "removed provider workflow absent: $rel" (
        -not (Test-Path -LiteralPath $absPath -PathType Leaf)
    )
}

# --- 4. Authority validator requires unique-ai-ci ---

$validatorPath = Join-Path $RepoRoot 'scripts\validate-standard-ci-authority.ps1'
$validatorExists = Test-Path -LiteralPath $validatorPath -PathType Leaf
Assert-Condition 'validate-standard-ci-authority.ps1 exists' $validatorExists

if ($validatorExists) {
    $validatorContent = Get-Content -LiteralPath $validatorPath -Raw
    Assert-Condition 'authority validator requires unique-ai-ci.yml' (
        $validatorContent -match [regex]::Escape('unique-ai-ci.yml')
    )
    Assert-Condition 'authority validator does not require claude-review-non-blocking.yml' (
        $validatorContent -notmatch [regex]::Escape('claude-review-non-blocking.yml')
    )
}

$reviewGatePath = Join-Path $RepoRoot 'scripts\validate-review-gate.ps1'
$reviewGateContent = Get-Content -LiteralPath $reviewGatePath -Raw -Encoding UTF8
Assert-Condition 'review gate handles deleted workflow paths' (
    $reviewGateContent -match 'Workflow deletion detected' -and
    $reviewGateContent -match 'Test-Path -LiteralPath'
)
Assert-Condition 'review gate has no approved provider secret exception' (
    $reviewGateContent -notmatch 'ANTHROPIC_API_KEY' -and
    $reviewGateContent -notmatch 'OPENAI_API_KEY'
)

# --- 5. Workflow authorization covers changed paths and is current ---

$registryPath = Join-Path $RepoRoot '.specbridge\policies\workflow-change-authorizations.json'
$registryExists = Test-Path -LiteralPath $registryPath -PathType Leaf
Assert-Condition 'workflow-change-authorizations.json exists' $registryExists

if ($registryExists) {
    $registry = $null
    try {
        $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
    Assert-Condition 'workflow-change-authorizations.json is valid JSON' ($null -ne $registry)

    if ($null -ne $registry) {
        $today = (Get-Date).Date
        $allAuthorizedFiles = @()
        $hasCurrentEntry = $false

        foreach ($auth in @($registry.authorizations)) {
            if ($null -eq $auth) { continue }
            $expires = $null
            try { $expires = [datetime]::ParseExact($auth.expires_at, "yyyy-MM-dd", $null) } catch { continue }
            if ($expires.Date -lt $today) { continue }
            $allAuthorizedFiles += @($auth.files)
            $hasCurrentEntry = $true
        }

        Assert-Condition 'authorization registry has a current (non-expired) entry' $hasCurrentEntry

        $expectedCoveredPaths = @(
            '.github/workflows/unique-ai-ci.yml',
            '.github/workflows/foundation-validation.yml',
            '.github/workflows/claude-review-non-blocking.yml',
            '.github/workflows/codex-review.example.yml',
            '.github/workflows/claude-code-review.example.yml',
            '.github/workflows/claude-code-execute.example.yml'
        )

        foreach ($path in $expectedCoveredPaths) {
            Assert-Condition "authorization covers: $path" (
                $allAuthorizedFiles -contains $path
            )
        }
    }
}

Write-Host ""
Write-Host "test-ci: $passed passed, $failed failed"

exit $(if ($failed -gt 0) { 1 } else { 0 })
