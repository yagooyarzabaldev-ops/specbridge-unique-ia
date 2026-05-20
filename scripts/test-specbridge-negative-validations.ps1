$ErrorActionPreference = "Stop"

Write-Output "SpecBridge negative validation tests started."

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path $repoRoot).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specbridge-negative-tests-" + [guid]::NewGuid().ToString("N"))
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
}

function Invoke-ExpectedFailure {
  param(
    [string] $Name,
    [scriptblock] $Arrange,
    [string] $Command,
    [string] $ExpectedPattern,
    [bool] $RequiresGit = $false
  )

  $caseDir = Join-Path $tempRoot $Name
  Copy-RepoFixture -Destination $caseDir

  if ($RequiresGit) {
    Push-Location $caseDir
    try {
      git init | Out-Null
      git config user.email "specbridge-tests@example.invalid"
      git config user.name "SpecBridge Tests"
      git config core.autocrlf false
      git commit --allow-empty -m "baseline" | Out-Null
    }
    finally {
      Pop-Location
    }
  }

  Push-Location $caseDir
  try {
    & $Arrange

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousHeadRef = $env:GITHUB_HEAD_REF
    $env:GITHUB_BASE_REF = $null
    $env:GITHUB_HEAD_REF = $null

    try {
      $output = & powershell -ExecutionPolicy Bypass -Command $Command 2>&1
      $exitCode = $LASTEXITCODE
      $outputText = ($output | Out-String)
    }
    finally {
      $env:GITHUB_BASE_REF = $previousBaseRef
      $env:GITHUB_HEAD_REF = $previousHeadRef
    }

    if ($exitCode -eq 0) {
      Write-Output "FAIL negative test did not fail: $Name"
      $script:failed = $true
      return
    }

    if ($outputText -notmatch $ExpectedPattern) {
      Write-Output "FAIL negative test failed for unexpected reason: $Name"
      Write-Output "Expected pattern: $ExpectedPattern"
      Write-Output $outputText
      $script:failed = $true
      return
    }

    Write-Output "PASS negative test: $Name"
  }
  finally {
    Pop-Location
  }
}

function Invoke-ExpectedSuccess {
  param(
    [string] $Name,
    [scriptblock] $Arrange,
    [string] $Command,
    [bool] $RequiresGit = $false
  )

  $caseDir = Join-Path $tempRoot $Name
  Copy-RepoFixture -Destination $caseDir

  if ($RequiresGit) {
    Push-Location $caseDir
    try {
      git init | Out-Null
      git config user.email "specbridge-tests@example.invalid"
      git config user.name "SpecBridge Tests"
      git config core.autocrlf false
      git commit --allow-empty -m "baseline" | Out-Null
    }
    finally {
      Pop-Location
    }
  }

  Push-Location $caseDir
  try {
    & $Arrange

    $previousBaseRef = $env:GITHUB_BASE_REF
    $previousHeadRef = $env:GITHUB_HEAD_REF
    $env:GITHUB_BASE_REF = $null
    $env:GITHUB_HEAD_REF = $null

    try {
      $output = & powershell -ExecutionPolicy Bypass -Command $Command 2>&1
      $exitCode = $LASTEXITCODE
      $outputText = ($output | Out-String)
    }
    finally {
      $env:GITHUB_BASE_REF = $previousBaseRef
      $env:GITHUB_HEAD_REF = $previousHeadRef
    }

    if ($exitCode -ne 0) {
      Write-Output "FAIL positive fixture failed unexpectedly: $Name"
      Write-Output $outputText
      $script:failed = $true
      return
    }

    Write-Output "PASS positive fixture: $Name"
  }
  finally {
    Pop-Location
  }
}

function Write-ScopeManifest {
  param(
    [string] $Path,
    [string] $ContractId,
    [string] $Status,
    [string[]] $ExclusiveWrite,
    [string[]] $ReadOnly,
    [string[]] $CoordinatorOwned,
    [string[]] $Dependencies,
    [string] $FinalReport
  )

  $manifest = [ordered]@{
    contract_id = $ContractId
    status = $Status
    exclusive_write = @($ExclusiveWrite)
    read_only = @($ReadOnly)
    coordinator_owned = @($CoordinatorOwned)
    dependencies = @($Dependencies)
    final_report = $FinalReport
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
  Set-Content -LiteralPath $Path -Value ($manifest | ConvertTo-Json -Depth 4) -NoNewline
}

function Write-AuditFixtureFiles {
  param(
    [string] $ContractPath = ".specbridge/contracts/audit-fixture.execution.md",
    [string] $ReportPath = ".specbridge/reports/audit-fixture.final-report.json"
  )

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ContractPath) | Out-Null
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null

  Set-Content -LiteralPath $ContractPath -Value "# Audit Fixture Contract" -NoNewline

  $report = [ordered]@{
    summary = "Audit fixture final report"
    changed_files = @(
      "docs/audit-fixture.md",
      ".specbridge/reports/audit-fixture.final-report.json"
    )
    validations = @(
      "powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1: passed",
      "git diff --check: passed"
    )
    policy_result = "Passed in audit packet fixture."
    risk_result = "Low risk fixture."
    unresolved_risks = @()
    merge_status = "Not applicable."
    deployment_status = "Not applicable."
    completion_status = "complete"
  }

  Set-Content -LiteralPath $ReportPath -Value ($report | ConvertTo-Json -Depth 6) -NoNewline
}

function Write-ChatGptAuditFixtureFiles {
  param(
    [string] $AuditPath = ".specbridge/audits/chatgpt-audit-fixture.chatgpt-audit.json",
    [string] $Outcome = "approved",
    [bool] $MergeAllowed = $true,
    [string] $OmitDimension = "",
    [bool] $BlockingFinding = $false
  )

  $auditPacketPath = ".specbridge/audit-packets/chatgpt-audit-fixture.audit-packet.json"
  $contractPath = ".specbridge/contracts/chatgpt-audit-fixture.execution.md"
  $reportPath = ".specbridge/reports/chatgpt-audit-fixture.final-report.json"

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $AuditPath) | Out-Null
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $auditPacketPath) | Out-Null
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $contractPath) | Out-Null
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $reportPath) | Out-Null

  Set-Content -LiteralPath $auditPacketPath -Value "{}" -NoNewline
  Set-Content -LiteralPath $contractPath -Value "# ChatGPT Audit Fixture Contract" -NoNewline
  Set-Content -LiteralPath $reportPath -Value "{}" -NoNewline

  $dimensionNames = @(
    "spec_compliance",
    "acceptance_criteria",
    "policy_boundaries",
    "security_rules",
    "changed_file_scope",
    "test_evidence",
    "ci_evidence",
    "final_report_honesty"
  )

  $dimensions = @()

  foreach ($dimensionName in $dimensionNames) {
    if ($dimensionName -eq $OmitDimension) {
      continue
    }

    $dimensions += [ordered]@{
      name = $dimensionName
      result = "pass"
      evidence = "Fixture evidence for $dimensionName."
      blocking = $false
    }
  }

  $audit = [ordered]@{
    schema_version = "1"
    audit_id = "chatgpt-audit-fixture"
    auditor = "SpecBridge Tests"
    audit_packet_path = $auditPacketPath
    execution_contract_path = $contractPath
    final_report_path = $reportPath
    checked_dimensions = $dimensions
    findings = @(
      [ordered]@{
        severity = "info"
        category = "governance"
        file = $auditPacketPath
        line = $null
        evidence = "Fixture finding."
        recommendation = "Keep audit artifacts machine-readable."
        blocking = $BlockingFinding
      }
    )
    outcome = $Outcome
    merge_allowed = $MergeAllowed
    unresolved_risks = @()
    source_files = @(
      $auditPacketPath,
      $contractPath,
      $reportPath
    )
  }

  Set-Content -LiteralPath $AuditPath -Value ($audit | ConvertTo-Json -Depth 8) -NoNewline
}

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  Invoke-ExpectedFailure `
    -Name "foundation-missing-readme" `
    -Arrange {
      Remove-Item -LiteralPath "README.md" -Force
    } `
    -Command "./scripts/validate-foundation.ps1" `
    -ExpectedPattern "missing required file: README\.md"

  Invoke-ExpectedFailure `
    -Name "contract-missing-section" `
    -Arrange {
      $contract = @"
# Execution Contract: Negative Test

## Contract Metadata

- contract_id: negative-test
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/999
- created_by: SpecBridge Tests
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Context

This contract intentionally omits the Goal section.
"@

      Set-Content -LiteralPath ".specbridge/contracts/negative-test.execution.md" -Value $contract -NoNewline
    } `
    -Command "./scripts/validate-contracts.ps1" `
    -ExpectedPattern "missing required section.*Goal"

  Invoke-ExpectedSuccess `
    -Name "contract-scope-disjoint-manifests" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/disjoint-a.scope.json" `
        -ContractId "disjoint-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/disjoint-a.md") `
        -ReadOnly @("README.md") `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/disjoint-a.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/disjoint-b.scope.json" `
        -ContractId "disjoint-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/disjoint-b.md") `
        -ReadOnly @("README.md") `
        -CoordinatorOwned @() `
        -Dependencies @("disjoint-a") `
        -FinalReport ".specbridge/reports/disjoint-b.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1"

  Invoke-ExpectedFailure `
    -Name "contract-scope-missing-exclusive-write" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      $manifest = [ordered]@{
        contract_id = "missing-exclusive-write"
        status = "active"
        read_only = @("README.md")
        coordinator_owned = @()
        dependencies = @()
        final_report = ".specbridge/reports/missing-exclusive-write.final-report.json"
      }

      New-Item -ItemType Directory -Force -Path ".specbridge/scopes" | Out-Null
      Set-Content -LiteralPath ".specbridge/scopes/missing-exclusive-write.scope.json" -Value ($manifest | ConvertTo-Json -Depth 4) -NoNewline
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "missing required property.*exclusive_write"

  Invoke-ExpectedFailure `
    -Name "contract-scope-conflicting-write-path" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/conflict-a.scope.json" `
        -ContractId "conflict-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/shared.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/conflict-a.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/conflict-b.scope.json" `
        -ContractId "conflict-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/shared.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/conflict-b.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "exclusive_write conflict path=docs/shared\.md contracts=conflict-a, conflict-b"

  Invoke-ExpectedFailure `
    -Name "contract-scope-duplicate-final-report" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/scopes" -Recurse -Force -ErrorAction SilentlyContinue

      Write-ScopeManifest `
        -Path ".specbridge/scopes/report-a.scope.json" `
        -ContractId "report-a" `
        -Status "active" `
        -ExclusiveWrite @("docs/report-a.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/shared.final-report.json"

      Write-ScopeManifest `
        -Path ".specbridge/scopes/report-b.scope.json" `
        -ContractId "report-b" `
        -Status "active" `
        -ExclusiveWrite @("docs/report-b.md") `
        -ReadOnly @() `
        -CoordinatorOwned @() `
        -Dependencies @() `
        -FinalReport ".specbridge/reports/shared.final-report.json"
    } `
    -Command "./scripts/validate-contract-scopes.ps1" `
    -ExpectedPattern "duplicate final_report path=.specbridge/reports/shared\.final-report\.json contracts=report-a, report-b"

  Invoke-ExpectedSuccess `
    -Name "audit-packet-generator-valid-fixture" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audit-packets" -Recurse -Force -ErrorAction SilentlyContinue
      Write-AuditFixtureFiles

      powershell -ExecutionPolicy Bypass -File ./scripts/generate-audit-packet.ps1 `
        -TaskId "audit-fixture" `
        -ExecutionContractPath ".specbridge/contracts/audit-fixture.execution.md" `
        -FinalReportPath ".specbridge/reports/audit-fixture.final-report.json" `
        -CiStatus "not_collected" | Out-Null
    } `
    -Command "./scripts/validate-audit-packets.ps1"

  Invoke-ExpectedFailure `
    -Name "audit-packet-generator-missing-contract" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audit-packets" -Recurse -Force -ErrorAction SilentlyContinue
      Write-AuditFixtureFiles
    } `
    -Command "./scripts/generate-audit-packet.ps1 -TaskId audit-fixture -ExecutionContractPath .specbridge/contracts/missing.execution.md -FinalReportPath .specbridge/reports/audit-fixture.final-report.json" `
    -ExpectedPattern "missing execution contract"

  Invoke-ExpectedFailure `
    -Name "audit-packet-missing-required-field" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audit-packets" -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Force -Path ".specbridge/audit-packets" | Out-Null

      $packet = [ordered]@{
        schema_version = "1"
        task_id = "missing-required-field"
      }

      Set-Content -LiteralPath ".specbridge/audit-packets/missing-required-field.audit-packet.json" -Value ($packet | ConvertTo-Json -Depth 4) -NoNewline
    } `
    -Command "./scripts/validate-audit-packets.ps1" `
    -ExpectedPattern "missing required field.*execution_contract_path"

  Invoke-ExpectedFailure `
    -Name "audit-packet-raw-diff-field" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audit-packets" -Recurse -Force -ErrorAction SilentlyContinue
      New-Item -ItemType Directory -Force -Path ".specbridge/audit-packets" | Out-Null

      $packet = [ordered]@{
        schema_version = "1"
        task_id = "raw-diff-field"
        generated_by = "specbridge-tests"
        execution_contract_path = ".specbridge/contracts/audit-fixture.execution.md"
        changed_files = @("docs/audit-fixture.md")
        diff_summary = @(
          [ordered]@{
            file = "docs/audit-fixture.md"
            added_lines = 1
            deleted_lines = 0
          }
        )
        validation_commands = @("git diff --check")
        validation_results = @(
          [ordered]@{
            command = "git diff --check"
            result = "passed"
          }
        )
        final_report_path = ".specbridge/reports/audit-fixture.final-report.json"
        ci_status = "not_collected"
        pr_review_report_path = $null
        policy_result = "Passed."
        unresolved_risks = @()
        completion_status = "complete"
        source_files = @(".specbridge/contracts/audit-fixture.execution.md", ".specbridge/reports/audit-fixture.final-report.json")
        secret_omission = "No raw content."
        raw_diff = "diff --git a/docs/audit-fixture.md b/docs/audit-fixture.md"
      }

      Set-Content -LiteralPath ".specbridge/audit-packets/raw-diff-field.audit-packet.json" -Value ($packet | ConvertTo-Json -Depth 8) -NoNewline
    } `
    -Command "./scripts/validate-audit-packets.ps1" `
    -ExpectedPattern "unexpected field.*raw_diff"

  Invoke-ExpectedSuccess `
    -Name "chatgpt-audit-valid-fixture" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audits" -Recurse -Force -ErrorAction SilentlyContinue
      Write-ChatGptAuditFixtureFiles
    } `
    -Command "./scripts/validate-chatgpt-audits.ps1"

  Invoke-ExpectedFailure `
    -Name "chatgpt-audit-missing-required-dimension" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audits" -Recurse -Force -ErrorAction SilentlyContinue
      Write-ChatGptAuditFixtureFiles -OmitDimension "security_rules"
    } `
    -Command "./scripts/validate-chatgpt-audits.ps1" `
    -ExpectedPattern "missing required audit dimension.*security_rules"

  Invoke-ExpectedFailure `
    -Name "chatgpt-audit-approved-with-blocking-finding" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audits" -Recurse -Force -ErrorAction SilentlyContinue
      Write-ChatGptAuditFixtureFiles -BlockingFinding $true
    } `
    -Command "./scripts/validate-chatgpt-audits.ps1" `
    -ExpectedPattern "blocking findings or dimensions must prevent merge"

  Invoke-ExpectedFailure `
    -Name "chatgpt-audit-non-approved-allows-merge" `
    -Arrange {
      Remove-Item -LiteralPath ".specbridge/audits" -Recurse -Force -ErrorAction SilentlyContinue
      Write-ChatGptAuditFixtureFiles -Outcome "changes_requested" -MergeAllowed $true
    } `
    -Command "./scripts/validate-chatgpt-audits.ps1" `
    -ExpectedPattern "non-approved audit outcomes must set merge_allowed false"

  Invoke-ExpectedSuccess `
    -Name "security-gate-safe-fixture" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "docs" | Out-Null
      Set-Content -LiteralPath "docs/security-safe-fixture.md" -Value "Safe documentation fixture." -NoNewline
      git add docs/security-safe-fixture.md 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1"

  Invoke-ExpectedFailure `
    -Name "security-gate-secret-like-content" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "docs" | Out-Null
      $secretLikeValue = "AKIA" + "1234567890ABCDEF"
      Set-Content -LiteralPath "docs/security-secret-fixture.txt" -Value "fixture = $secretLikeValue" -NoNewline
      git add docs/security-secret-fixture.txt 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=secret_like_content"

  Invoke-ExpectedFailure `
    -Name "security-gate-auth-sensitive-file" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "auth" | Out-Null
      Set-Content -LiteralPath "auth/login-policy.md" -Value "Authentication fixture." -NoNewline
      git add auth/login-policy.md 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=auth_sensitive_file"

  Invoke-ExpectedFailure `
    -Name "security-gate-authorization-sensitive-file" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "rbac" | Out-Null
      Set-Content -LiteralPath "rbac/policy.md" -Value "Authorization fixture." -NoNewline
      git add rbac/policy.md 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=authorization_sensitive_file"

  Invoke-ExpectedFailure `
    -Name "security-gate-ci-permission-escalation" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path ".github/workflows" | Out-Null
      $workflow = @(
        "name: Security Fixture",
        "",
        "on:",
        "  pull_request:",
        "",
        "permissions:",
        "  contents: write",
        "",
        "jobs:",
        "  fixture:",
        "    runs-on: windows-latest",
        "    steps:",
        "      - run: echo fixture"
      ) -join "`n"

      $workflowPath = Join-Path (Join-Path ".github" "workflows") "security-fixture.yml"
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $workflowPath), $workflow, $utf8NoBom)
      git add .github/workflows/security-fixture.yml 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=ci_cd_permission_escalation"

  Invoke-ExpectedFailure `
    -Name "security-gate-dependency-addition" `
    -RequiresGit $true `
    -Arrange {
      Set-Content -LiteralPath "package.json" -Value "{}" -NoNewline
      git add package.json 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=dependency_addition"

  Invoke-ExpectedFailure `
    -Name "security-gate-unsafe-shell-command" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "docs" | Out-Null
      $dangerousCommand = "rm -r" + "f /"
      Set-Content -LiteralPath "docs/security-command-fixture.md" -Value "Do not run: $dangerousCommand" -NoNewline
      git add docs/security-command-fixture.md 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=unsafe_shell_command"

  Invoke-ExpectedFailure `
    -Name "security-gate-protected-path" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "secrets" | Out-Null
      Set-Content -LiteralPath "secrets/example.txt" -Value "protected path fixture" -NoNewline
      git add secrets/example.txt 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=protected_path_change"

  Invoke-ExpectedFailure `
    -Name "security-gate-production-config" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "infra/prod" | Out-Null
      Set-Content -LiteralPath "infra/prod/config.yaml" -Value "name: fixture" -NoNewline
      git add infra/prod/config.yaml 2>$null
    } `
    -Command "./scripts/validate-security-gates.ps1" `
    -ExpectedPattern "category=production_configuration"

  Invoke-ExpectedFailure `
    -Name "final-report-missing-property" `
    -Arrange {
      $report = @{
        summary = "Invalid report fixture"
      } | ConvertTo-Json

      Set-Content -LiteralPath ".specbridge/reports/negative-test.final-report.json" -Value $report -NoNewline
    } `
    -Command "./scripts/validate-final-reports.ps1" `
    -ExpectedPattern "missing required property.*changed_files"

  Invoke-ExpectedFailure `
    -Name "review-gate-blocked-path" `
    -RequiresGit $true `
    -Arrange {
      New-Item -ItemType Directory -Force -Path "src" | Out-Null
      Set-Content -LiteralPath "src/blocked.txt" -Value "blocked path fixture" -NoNewline
      git add src/blocked.txt 2>$null
      git commit -m "add blocked path fixture" | Out-Null
    } `
    -Command "./scripts/validate-review-gate.ps1" `
    -ExpectedPattern "blocked path changed: src/blocked\.txt"
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failed) {
  Write-Output "SpecBridge negative validation tests failed."
  exit 1
}

Write-Output "SpecBridge negative validation tests passed."
exit 0
