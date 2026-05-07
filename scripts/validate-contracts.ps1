$ErrorActionPreference = "Stop"

Write-Output "SpecBridge contract validation started."

$failed = $false
$contractsPath = ".specbridge/contracts"

if (-not (Test-Path $contractsPath)) {
  Write-Output "FAIL missing contracts directory: $contractsPath"
  exit 1
}

$contractFiles = Get-ChildItem $contractsPath -Filter "*.execution.md" -File

if ($contractFiles.Count -le 0) {
  Write-Output "FAIL no execution contract files found in $contractsPath"
  exit 1
}

$requiredSections = @(
  "Contract Metadata",
  "Goal",
  "Context",
  "Source References",
  "Autonomy Profile",
  "Risk Level",
  "Allowed Scope",
  "Blocked Scope",
  "Acceptance Criteria",
  "Required Validations",
  "Stop Conditions",
  "Merge Policy",
  "Deployment Policy",
  "Final Report Requirements",
  "Completion Rule"
)

$requiredMetadataFields = @(
  "contract_id",
  "related_issue",
  "created_by",
  "created_at",
  "autonomy_profile",
  "risk_level",
  "status"
)

$allowedAutonomyProfiles = @(
  "assisted",
  "vibe_autopilot",
  "full_autopilot"
)

$allowedRiskLevels = @(
  "low",
  "medium",
  "high",
  "critical"
)

$allowedStatuses = @(
  "draft",
  "ready_for_execution",
  "blocked",
  "completed",
  "cancelled"
)

function Get-MetadataValue {
  param(
    [string] $Content,
    [string] $FieldName
  )

  $escapedField = [regex]::Escape($FieldName)
  $match = [regex]::Match($Content, "(?m)^\s*-\s+$escapedField\s*:\s*(.+?)\s*$")

  if (-not $match.Success) {
    return $null
  }

  return $match.Groups[1].Value.Trim()
}

foreach ($file in $contractFiles) {
  Write-Output "Validating contract: $($file.FullName)"

  $content = Get-Content $file.FullName -Raw

  if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Output "FAIL empty contract file: $($file.FullName)"
    $failed = $true
    continue
  }

  foreach ($section in $requiredSections) {
    $sectionPattern = "(?m)^##\s+$([regex]::Escape($section))\s*$"
    if ($content -notmatch $sectionPattern) {
      Write-Output "FAIL missing required section in $($file.FullName): $section"
      $failed = $true
    }
  }

  foreach ($field in $requiredMetadataFields) {
    $value = Get-MetadataValue -Content $content -FieldName $field

    if ([string]::IsNullOrWhiteSpace($value)) {
      Write-Output "FAIL missing or empty metadata field in $($file.FullName): $field"
      $failed = $true
    }
  }

  $autonomyProfile = Get-MetadataValue -Content $content -FieldName "autonomy_profile"
  if ($autonomyProfile -and $allowedAutonomyProfiles -notcontains $autonomyProfile) {
    Write-Output "FAIL invalid autonomy_profile in $($file.FullName): $autonomyProfile"
    $failed = $true
  }

  $riskLevel = Get-MetadataValue -Content $content -FieldName "risk_level"
  if ($riskLevel -and $allowedRiskLevels -notcontains $riskLevel) {
    Write-Output "FAIL invalid risk_level in $($file.FullName): $riskLevel"
    $failed = $true
  }

  $status = Get-MetadataValue -Content $content -FieldName "status"
  if ($status -and $allowedStatuses -notcontains $status) {
    Write-Output "FAIL invalid status in $($file.FullName): $status"
    $failed = $true
  }

  $relatedIssue = Get-MetadataValue -Content $content -FieldName "related_issue"
  if ($relatedIssue -and $relatedIssue -notmatch "^https://github\.com/.+/.+/issues/[0-9]+$") {
    Write-Output "FAIL related_issue must be a GitHub issue URL in $($file.FullName): $relatedIssue"
    $failed = $true
  }

  $codeFenceCount = (Select-String -Path $file.FullName -Pattern '^```').Count
  if ($codeFenceCount % 2 -ne 0) {
    Write-Output "FAIL unbalanced markdown fences in contract: $($file.FullName) fences=$codeFenceCount"
    $failed = $true
  }
}

if ($failed) {
  Write-Output "SpecBridge contract validation failed."
  exit 1
}

Write-Output "SpecBridge contract validation passed."
exit 0
