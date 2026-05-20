$ErrorActionPreference = "Stop"

Write-Output "SpecBridge contract scope validation started."

$scopePath = ".specbridge/scopes"
$failed = $false

$requiredProperties = @(
  "contract_id",
  "status",
  "exclusive_write",
  "read_only",
  "coordinator_owned",
  "dependencies",
  "final_report"
)

$allowedProperties = @(
  "contract_id",
  "status",
  "exclusive_write",
  "read_only",
  "coordinator_owned",
  "dependencies",
  "final_report"
)

$allowedStatuses = @(
  "planned",
  "ready_for_execution",
  "active",
  "blocked",
  "completed",
  "cancelled"
)

$conflictStatuses = @(
  "planned",
  "ready_for_execution",
  "active"
)

function Write-Failure {
  param(
    [string] $Message
  )

  [Console]::Out.WriteLine("FAIL $Message")
  $script:failed = $true
}

function Get-RequiredProperty {
  param(
    [object] $Object,
    [string] $PropertyName,
    [string] $FileName
  )

  $property = $Object.PSObject.Properties[$PropertyName]

  if ($null -eq $property) {
    Write-Failure "missing required property in $($FileName): $PropertyName"
    return $null
  }

  return $property.Value
}

function Get-RequiredString {
  param(
    [object] $Object,
    [string] $PropertyName,
    [string] $FileName
  )

  $value = Get-RequiredProperty -Object $Object -PropertyName $PropertyName -FileName $FileName

  if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
    Write-Failure "property must be a non-empty string in $($FileName): $PropertyName"
    return $null
  }

  return $value.Trim()
}

function Get-RequiredArray {
  param(
    [object] $Object,
    [string] $PropertyName,
    [string] $FileName
  )

  $property = $Object.PSObject.Properties[$PropertyName]

  if ($null -eq $property) {
    Write-Failure "missing required property in $($FileName): $PropertyName"
    return ,@()
  }

  $value = $property.Value

  if ($null -eq $value -or -not ($value -is [System.Array])) {
    Write-Failure "property must be an array in $($FileName): $PropertyName"
    return ,@()
  }

  return ,@($value)
}

function Normalize-ScopePath {
  param(
    [string] $Path,
    [string] $FieldName,
    [string] $ContractId,
    [string] $FileName
  )

  if ([string]::IsNullOrWhiteSpace($Path)) {
    Write-Failure "path must be non-empty in $($FileName): contract=$ContractId field=$FieldName"
    return $null
  }

  $trimmedPath = $Path.Trim()

  if ([System.IO.Path]::IsPathRooted($trimmedPath)) {
    Write-Failure "path must be repository-relative in $($FileName): contract=$ContractId field=$FieldName path=$trimmedPath"
    return $null
  }

  $normalizedPath = $trimmedPath.Replace("\", "/")

  while ($normalizedPath.StartsWith("./")) {
    $normalizedPath = $normalizedPath.Substring(2)
  }

  if ($normalizedPath -match "(^|/)\.\.(/|$)") {
    Write-Failure "path must not traverse parent directories in $($FileName): contract=$ContractId field=$FieldName path=$trimmedPath"
    return $null
  }

  if ([string]::IsNullOrWhiteSpace($normalizedPath)) {
    Write-Failure "path must be non-empty after normalization in $($FileName): contract=$ContractId field=$FieldName"
    return $null
  }

  return $normalizedPath
}

function Normalize-PathArray {
  param(
    [object[]] $Values,
    [string] $FieldName,
    [string] $ContractId,
    [string] $FileName
  )

  $paths = @()

  foreach ($value in $Values) {
    if ($null -eq $value -or $value.GetType().Name -ne "String") {
      Write-Failure "array must contain only strings in $($FileName): contract=$ContractId field=$FieldName"
      continue
    }

    $normalizedPath = Normalize-ScopePath -Path $value -FieldName $FieldName -ContractId $ContractId -FileName $FileName

    if ($null -ne $normalizedPath) {
      $paths += $normalizedPath
    }
  }

  $duplicatePaths = $paths |
    Group-Object |
    Where-Object { $_.Count -gt 1 }

  foreach ($duplicatePath in $duplicatePaths) {
    Write-Failure "duplicate path in $($FileName): contract=$ContractId field=$FieldName path=$($duplicatePath.Name)"
  }

  return ,@($paths)
}

function Normalize-DependencyArray {
  param(
    [object[]] $Values,
    [string] $ContractId,
    [string] $FileName
  )

  $dependencies = @()

  foreach ($value in $Values) {
    if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
      Write-Failure "dependencies must contain only non-empty strings in $($FileName): contract=$ContractId"
      continue
    }

    $dependencies += $value.Trim()
  }

  $duplicateDependencies = $dependencies |
    Group-Object |
    Where-Object { $_.Count -gt 1 }

  foreach ($duplicateDependency in $duplicateDependencies) {
    Write-Failure "duplicate dependency in $($FileName): contract=$ContractId dependency=$($duplicateDependency.Name)"
  }

  return ,@($dependencies)
}

if (-not (Test-Path $scopePath)) {
  Write-Output "FAIL missing contract scope directory: $scopePath"
  exit 1
}

$scopeFiles = Get-ChildItem $scopePath -Filter "*.scope.json" -File

if ($scopeFiles.Count -le 0) {
  Write-Output "FAIL no contract scope manifest files found in $scopePath"
  exit 1
}

$manifests = @()

foreach ($file in $scopeFiles) {
  Write-Output "Validating contract scope: $($file.FullName)"

  $raw = Get-Content $file.FullName -Raw

  if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Failure "empty contract scope manifest: $($file.FullName)"
    continue
  }

  try {
    $scope = $raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in contract scope manifest: $($file.FullName)"
    Write-Output $_.Exception.Message
    continue
  }

  $propertyNames = @($scope.PSObject.Properties.Name)

  foreach ($requiredProperty in $requiredProperties) {
    if ($propertyNames -notcontains $requiredProperty) {
      Write-Failure "missing required property in $($file.FullName): $requiredProperty"
    }
  }

  foreach ($propertyName in $propertyNames) {
    if ($allowedProperties -notcontains $propertyName) {
      Write-Failure "unexpected property in $($file.FullName): $propertyName"
    }
  }

  $contractId = Get-RequiredString -Object $scope -PropertyName "contract_id" -FileName $file.FullName
  $status = Get-RequiredString -Object $scope -PropertyName "status" -FileName $file.FullName
  $finalReport = Get-RequiredString -Object $scope -PropertyName "final_report" -FileName $file.FullName

  if ($status -and $allowedStatuses -notcontains $status) {
    Write-Failure "invalid status in $($file.FullName): contract=$contractId status=$status"
  }

  $exclusiveWrite = Normalize-PathArray `
    -Values (Get-RequiredArray -Object $scope -PropertyName "exclusive_write" -FileName $file.FullName) `
    -FieldName "exclusive_write" `
    -ContractId $contractId `
    -FileName $file.FullName

  $readOnly = Normalize-PathArray `
    -Values (Get-RequiredArray -Object $scope -PropertyName "read_only" -FileName $file.FullName) `
    -FieldName "read_only" `
    -ContractId $contractId `
    -FileName $file.FullName

  $coordinatorOwned = Normalize-PathArray `
    -Values (Get-RequiredArray -Object $scope -PropertyName "coordinator_owned" -FileName $file.FullName) `
    -FieldName "coordinator_owned" `
    -ContractId $contractId `
    -FileName $file.FullName

  $dependencies = Normalize-DependencyArray `
    -Values (Get-RequiredArray -Object $scope -PropertyName "dependencies" -FileName $file.FullName) `
    -ContractId $contractId `
    -FileName $file.FullName

  $normalizedFinalReport = $null

  if ($finalReport) {
    $normalizedFinalReport = Normalize-ScopePath `
      -Path $finalReport `
      -FieldName "final_report" `
      -ContractId $contractId `
      -FileName $file.FullName

    if ($normalizedFinalReport -and $normalizedFinalReport -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Write-Failure "final_report must be under .specbridge/reports and end with .final-report.json in $($file.FullName): contract=$contractId path=$normalizedFinalReport"
    }
  }

  $selfOverlap = @(
    @{
      LeftName = "exclusive_write"
      Left = $exclusiveWrite
      RightName = "read_only"
      Right = $readOnly
    },
    @{
      LeftName = "exclusive_write"
      Left = $exclusiveWrite
      RightName = "coordinator_owned"
      Right = $coordinatorOwned
    }
  )

  foreach ($overlapCheck in $selfOverlap) {
    foreach ($path in $overlapCheck.Left) {
      if ($overlapCheck.Right -contains $path) {
        Write-Failure "path cannot be both $($overlapCheck.LeftName) and $($overlapCheck.RightName) in $($file.FullName): contract=$contractId path=$path"
      }
    }
  }

  $manifests += [pscustomobject]@{
    File = $file.FullName
    ContractId = $contractId
    Status = $status
    ExclusiveWrite = @($exclusiveWrite)
    ReadOnly = @($readOnly)
    CoordinatorOwned = @($coordinatorOwned)
    Dependencies = @($dependencies)
    FinalReport = $normalizedFinalReport
    ParticipatesInConflictCheck = ($conflictStatuses -contains $status)
  }
}

$contractIdGroups = $manifests |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_.ContractId) } |
  Group-Object ContractId |
  Where-Object { $_.Count -gt 1 }

foreach ($contractIdGroup in $contractIdGroups) {
  Write-Failure "duplicate contract_id across scope manifests: contract=$($contractIdGroup.Name)"
}

$finalReportGroups = $manifests |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_.FinalReport) } |
  Group-Object FinalReport |
  Where-Object { $_.Count -gt 1 }

foreach ($finalReportGroup in $finalReportGroups) {
  $contractIds = @($finalReportGroup.Group | ForEach-Object { $_.ContractId }) -join ", "
  Write-Failure "duplicate final_report path=$($finalReportGroup.Name) contracts=$contractIds"
}

$activeManifests = @($manifests | Where-Object { $_.ParticipatesInConflictCheck })

$exclusiveOwnership = @{}
$coordinatorOwnership = @{}

foreach ($manifest in $activeManifests) {
  foreach ($path in $manifest.ExclusiveWrite) {
    if (-not $exclusiveOwnership.ContainsKey($path)) {
      $exclusiveOwnership[$path] = @()
    }

    $exclusiveOwnership[$path] += $manifest.ContractId
  }

  foreach ($path in $manifest.CoordinatorOwned) {
    if (-not $coordinatorOwnership.ContainsKey($path)) {
      $coordinatorOwnership[$path] = @()
    }

    $coordinatorOwnership[$path] += $manifest.ContractId
  }
}

foreach ($path in $exclusiveOwnership.Keys) {
  $owners = @($exclusiveOwnership[$path])

  if ($owners.Count -gt 1) {
    Write-Failure "exclusive_write conflict path=$path contracts=$($owners -join ', ')"
  }

  if ($coordinatorOwnership.ContainsKey($path)) {
    $coordinators = @($coordinatorOwnership[$path])
    Write-Failure "coordinator_owned conflict path=$path exclusive_contracts=$($owners -join ', ') coordinator_contracts=$($coordinators -join ', ')"
  }
}

foreach ($manifest in $activeManifests) {
  foreach ($path in $manifest.ReadOnly) {
    if (-not $exclusiveOwnership.ContainsKey($path)) {
      continue
    }

    $writers = @($exclusiveOwnership[$path] | Where-Object { $_ -ne $manifest.ContractId })

    foreach ($writer in $writers) {
      if ($manifest.Dependencies -notcontains $writer) {
        Write-Failure "missing dependency for read/write relationship path=$path reader=$($manifest.ContractId) writer=$writer"
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge contract scope validation failed."
  exit 1
}

Write-Output "SpecBridge contract scope validation passed."
exit 0
