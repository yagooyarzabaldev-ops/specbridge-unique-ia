param(
  [string] $AuditsPath = ".specbridge/audits"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge ChatGPT audit validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "audit_id",
  "auditor",
  "audit_packet_path",
  "execution_contract_path",
  "final_report_path",
  "checked_dimensions",
  "findings",
  "outcome",
  "merge_allowed",
  "unresolved_risks",
  "source_files"
)

$allowedFields = $requiredFields
$allowedOutcomes = @("approved", "changes_requested", "blocked", "needs_human_decision")
$allowedSeverities = @("info", "low", "medium", "high", "critical")
$allowedDimensionResults = @("pass", "fail", "needs_human_decision", "not_applicable")
$requiredDimensions = @(
  "spec_compliance",
  "acceptance_criteria",
  "policy_boundaries",
  "security_rules",
  "changed_file_scope",
  "test_evidence",
  "ci_evidence",
  "final_report_honesty"
)

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

function Test-RepoPath {
  param(
    [AllowNull()]
    [object] $Path,
    [string] $FieldName,
    [string] $FileName,
    [bool] $MustExist = $false
  )

  if ($null -eq $Path -or $Path.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($Path)) {
    Write-Failure "$FieldName must be a non-empty repository-relative path in $FileName"
    return
  }

  $normalizedPath = $Path.Replace("\", "/")

  if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
    Write-Failure "$FieldName must be repository-relative in $FileName`: $Path"
  }

  if ($normalizedPath -match "(^|/)\.\.(/|$)") {
    Write-Failure "$FieldName must not traverse parent directories in $FileName`: $Path"
  }

  if ($MustExist -and -not (Test-Path $normalizedPath)) {
    Write-Failure "$FieldName must reference an existing file in $FileName`: $normalizedPath"
  }
}

function Test-StringArray {
  param(
    [object] $Value,
    [string] $FieldName,
    [string] $FileName,
    [bool] $AllowEmpty = $false
  )

  if ($null -eq $Value -or -not ($Value -is [System.Array])) {
    Write-Failure "$FieldName must be an array in $FileName"
    return @()
  }

  $items = @($Value)

  if (-not $AllowEmpty -and $items.Count -le 0) {
    Write-Failure "$FieldName must not be empty in $FileName"
  }

  foreach ($item in $items) {
    if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
      Write-Failure "$FieldName must contain only non-empty strings in $FileName"
    }
  }

  return @($items)
}

function Test-ObjectArray {
  param(
    [object] $Value,
    [string] $FieldName,
    [string] $FileName
  )

  if ($null -eq $Value -or -not ($Value -is [System.Array])) {
    Write-Failure "$FieldName must be an array in $FileName"
    return @()
  }

  $items = @($Value)

  if ($items.Count -le 0) {
    Write-Failure "$FieldName must not be empty in $FileName"
  }

  return @($items)
}

function Test-RequiredObjectField {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $Context
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    Write-Failure "missing field in $Context`: $FieldName"
    return $false
  }

  return $true
}

function Test-NullablePositiveInteger {
  param(
    [AllowNull()]
    [object] $Value,
    [string] $Context
  )

  if ($null -eq $Value) {
    return
  }

  if ($Value -isnot [int] -and $Value -isnot [long]) {
    Write-Failure "line must be an integer or null in $Context"
    return
  }

  if ($Value -lt 1) {
    Write-Failure "line must be greater than zero in $Context"
  }
}

if (-not (Test-Path $AuditsPath)) {
  Write-Output "FAIL missing ChatGPT audits directory: $AuditsPath"
  exit 1
}

$auditFiles = Get-ChildItem $AuditsPath -Filter "*.chatgpt-audit.json" -File

if ($auditFiles.Count -le 0) {
  Write-Output "FAIL no ChatGPT audit files found in $AuditsPath"
  exit 1
}

foreach ($file in $auditFiles) {
  Write-Output "Validating ChatGPT audit: $($file.FullName)"

  try {
    $audit = Get-Content $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in ChatGPT audit: $($file.FullName)"
    continue
  }

  $propertyNames = @($audit.PSObject.Properties.Name)

  foreach ($requiredField in $requiredFields) {
    if ($propertyNames -notcontains $requiredField) {
      Write-Failure "missing required field in $($file.FullName): $requiredField"
    }
  }

  foreach ($propertyName in $propertyNames) {
    if ($allowedFields -notcontains $propertyName) {
      Write-Failure "unexpected field in $($file.FullName): $propertyName"
    }
  }

  if ($audit.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("audit_id", "auditor", "outcome")) {
    if ($propertyNames -contains $stringField) {
      $value = $audit.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "outcome" -and $allowedOutcomes -notcontains $audit.outcome) {
    Write-Failure "invalid outcome in $($file.FullName): $($audit.outcome)"
  }

  if ($propertyNames -contains "merge_allowed" -and $audit.merge_allowed -isnot [bool]) {
    Write-Failure "merge_allowed must be boolean in $($file.FullName)"
  }

  if ($propertyNames -contains "audit_packet_path") {
    Test-RepoPath -Path $audit.audit_packet_path -FieldName "audit_packet_path" -FileName $file.FullName -MustExist $true

    if ($audit.audit_packet_path -notmatch "^\.specbridge/audit-packets/.+\.audit-packet\.json$") {
      Write-Failure "audit_packet_path must point to an audit packet in $($file.FullName): $($audit.audit_packet_path)"
    }
  }

  if ($propertyNames -contains "execution_contract_path") {
    Test-RepoPath -Path $audit.execution_contract_path -FieldName "execution_contract_path" -FileName $file.FullName -MustExist $true

    if ($audit.execution_contract_path -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
      Write-Failure "execution_contract_path must point to an execution contract in $($file.FullName): $($audit.execution_contract_path)"
    }
  }

  if ($propertyNames -contains "final_report_path") {
    Test-RepoPath -Path $audit.final_report_path -FieldName "final_report_path" -FileName $file.FullName -MustExist $true

    if ($audit.final_report_path -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Write-Failure "final_report_path must point to a final report in $($file.FullName): $($audit.final_report_path)"
    }
  }

  $sourceFiles = @()

  if ($propertyNames -contains "source_files") {
    $sourceFiles = Test-StringArray -Value $audit.source_files -FieldName "source_files" -FileName $file.FullName

    foreach ($path in $sourceFiles) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }

  foreach ($requiredSourceFile in @($audit.audit_packet_path, $audit.execution_contract_path, $audit.final_report_path)) {
    if (-not [string]::IsNullOrWhiteSpace($requiredSourceFile) -and $sourceFiles -notcontains $requiredSourceFile) {
      Write-Failure "source_files must include referenced evidence path in $($file.FullName): $requiredSourceFile"
    }
  }

  [void] (Test-StringArray -Value $audit.unresolved_risks -FieldName "unresolved_risks" -FileName $file.FullName -AllowEmpty $true)

  $dimensions = @()

  if ($propertyNames -contains "checked_dimensions") {
    $dimensions = Test-ObjectArray -Value $audit.checked_dimensions -FieldName "checked_dimensions" -FileName $file.FullName
  }

  foreach ($dimension in $dimensions) {
    $context = "$($file.FullName) checked_dimensions"

    foreach ($fieldName in @("name", "result", "evidence", "blocking")) {
      [void] (Test-RequiredObjectField -Object $dimension -FieldName $fieldName -Context $context)
    }

    if ($dimension.PSObject.Properties.Name.Contains("name") -and [string]::IsNullOrWhiteSpace($dimension.name)) {
      Write-Failure "dimension name must not be empty in $($file.FullName)"
    }

    if ($dimension.PSObject.Properties.Name.Contains("result") -and $allowedDimensionResults -notcontains $dimension.result) {
      Write-Failure "invalid dimension result in $($file.FullName): dimension=$($dimension.name) result=$($dimension.result)"
    }

    if ($dimension.PSObject.Properties.Name.Contains("evidence") -and [string]::IsNullOrWhiteSpace($dimension.evidence)) {
      Write-Failure "dimension evidence must not be empty in $($file.FullName): dimension=$($dimension.name)"
    }

    if ($dimension.PSObject.Properties.Name.Contains("blocking") -and $dimension.blocking -isnot [bool]) {
      Write-Failure "dimension blocking must be boolean in $($file.FullName): dimension=$($dimension.name)"
    }
  }

  $dimensionNames = @($dimensions | ForEach-Object { $_.name })

  foreach ($requiredDimension in $requiredDimensions) {
    if ($dimensionNames -notcontains $requiredDimension) {
      Write-Failure "missing required audit dimension in $($file.FullName): $requiredDimension"
    }
  }

  $duplicateDimensions = $dimensionNames |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Group-Object |
    Where-Object { $_.Count -gt 1 }

  foreach ($duplicateDimension in $duplicateDimensions) {
    Write-Failure "duplicate audit dimension in $($file.FullName): $($duplicateDimension.Name)"
  }

  $findings = @()

  if ($propertyNames -contains "findings") {
    $findings = Test-ObjectArray -Value $audit.findings -FieldName "findings" -FileName $file.FullName
  }

  foreach ($finding in $findings) {
    $context = "$($file.FullName) findings"

    foreach ($fieldName in @("severity", "category", "file", "line", "evidence", "recommendation", "blocking")) {
      [void] (Test-RequiredObjectField -Object $finding -FieldName $fieldName -Context $context)
    }

    if ($finding.PSObject.Properties.Name.Contains("severity") -and $allowedSeverities -notcontains $finding.severity) {
      Write-Failure "invalid finding severity in $($file.FullName): $($finding.severity)"
    }

    foreach ($stringField in @("category", "file", "evidence", "recommendation")) {
      if ($finding.PSObject.Properties.Name.Contains($stringField)) {
        $value = $finding.$stringField

        if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
          Write-Failure "finding $stringField must be a non-empty string in $($file.FullName)"
        }
      }
    }

    if ($finding.PSObject.Properties.Name.Contains("file")) {
      Test-RepoPath -Path $finding.file -FieldName "finding.file" -FileName $file.FullName
    }

    if ($finding.PSObject.Properties.Name.Contains("line")) {
      Test-NullablePositiveInteger -Value $finding.line -Context "$($file.FullName) finding file=$($finding.file)"
    }

    if ($finding.PSObject.Properties.Name.Contains("blocking") -and $finding.blocking -isnot [bool]) {
      Write-Failure "finding blocking must be boolean in $($file.FullName): file=$($finding.file)"
    }
  }

  $blockingFindings = @($findings | Where-Object { $_.blocking -eq $true })
  $blockingDimensions = @($dimensions | Where-Object { $_.blocking -eq $true })
  $failedDimensions = @($dimensions | Where-Object { $_.result -eq "fail" })
  $needsHumanDimensions = @($dimensions | Where-Object { $_.result -eq "needs_human_decision" })

  if (($blockingFindings.Count -gt 0 -or $blockingDimensions.Count -gt 0) -and $audit.merge_allowed -eq $true) {
    Write-Failure "blocking findings or dimensions must prevent merge in $($file.FullName)"
  }

  if (($blockingFindings.Count -gt 0 -or $blockingDimensions.Count -gt 0) -and $audit.outcome -eq "approved") {
    Write-Failure "approved audit cannot contain blocking findings or dimensions in $($file.FullName)"
  }

  if ($audit.outcome -eq "approved") {
    if ($audit.merge_allowed -ne $true) {
      Write-Failure "approved audit must set merge_allowed true in $($file.FullName)"
    }

    foreach ($dimension in $dimensions) {
      if ($dimension.result -ne "pass") {
        Write-Failure "approved audit requires all dimensions to pass in $($file.FullName): dimension=$($dimension.name) result=$($dimension.result)"
      }
    }
  }

  if ($audit.outcome -in @("changes_requested", "blocked", "needs_human_decision") -and $audit.merge_allowed -eq $true) {
    Write-Failure "non-approved audit outcomes must set merge_allowed false in $($file.FullName): outcome=$($audit.outcome)"
  }

  if ($audit.outcome -eq "blocked" -and $blockingFindings.Count -eq 0 -and $blockingDimensions.Count -eq 0) {
    Write-Failure "blocked audit must include at least one blocking finding or dimension in $($file.FullName)"
  }

  if ($audit.outcome -eq "changes_requested" -and $failedDimensions.Count -eq 0 -and $blockingFindings.Count -eq 0 -and $blockingDimensions.Count -eq 0) {
    Write-Failure "changes_requested audit must include failed evidence or a blocking finding in $($file.FullName)"
  }

  if ($audit.outcome -eq "needs_human_decision" -and $needsHumanDimensions.Count -eq 0) {
    Write-Failure "needs_human_decision audit must include at least one dimension with needs_human_decision in $($file.FullName)"
  }
}

if ($failed) {
  Write-Output "SpecBridge ChatGPT audit validation failed."
  exit 1
}

Write-Output "SpecBridge ChatGPT audit validation passed."
exit 0
