$ErrorActionPreference = "Stop"

Write-Output "SpecBridge final report validation started."

$reportsPath = ".specbridge/reports"

if (-not (Test-Path $reportsPath)) {
  Write-Output "FAIL missing reports directory: $reportsPath"
  exit 1
}

$reportFiles = Get-ChildItem $reportsPath -Filter "*.final-report.json" -File

if ($reportFiles.Count -le 0) {
  Write-Output "FAIL no final report files found in $reportsPath"
  exit 1
}

$requiredProperties = @(
  "summary",
  "changed_files",
  "validations",
  "policy_result",
  "risk_result",
  "completion_status"
)

$allowedProperties = @(
  "summary",
  "changed_files",
  "validations",
  "policy_result",
  "risk_result",
  "unresolved_risks",
  "merge_status",
  "deployment_status",
  "completion_status"
)

$failed = $false

foreach ($file in $reportFiles) {
  Write-Output "Validating final report: $($file.FullName)"

  $raw = Get-Content $file.FullName -Raw

  if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Output "FAIL empty final report file: $($file.FullName)"
    $failed = $true
    continue
  }

  try {
    $report = $raw | ConvertFrom-Json
  }
  catch {
    Write-Output "FAIL invalid JSON in final report: $($file.FullName)"
    Write-Output $_.Exception.Message
    $failed = $true
    continue
  }

  $propertyNames = @($report.PSObject.Properties.Name)

  foreach ($requiredProperty in $requiredProperties) {
    if ($propertyNames -notcontains $requiredProperty) {
      Write-Output "FAIL missing required property in $($file.FullName): $requiredProperty"
      $failed = $true
    }
  }

  foreach ($propertyName in $propertyNames) {
    if ($allowedProperties -notcontains $propertyName) {
      Write-Output "FAIL unexpected property in $($file.FullName): $propertyName"
      $failed = $true
    }
  }

  foreach ($stringProperty in @("summary", "policy_result", "risk_result", "completion_status")) {
    if ($propertyNames -contains $stringProperty) {
      $value = $report.$stringProperty
      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Output "FAIL property must be a non-empty string in $($file.FullName): $stringProperty"
        $failed = $true
      }
    }
  }

  foreach ($arrayProperty in @("changed_files", "validations")) {
    if ($propertyNames -contains $arrayProperty) {
      $value = @($report.$arrayProperty)
      if ($null -eq $report.$arrayProperty -or $value.Count -le 0) {
        Write-Output "FAIL property must be a non-empty array in $($file.FullName): $arrayProperty"
        $failed = $true
      }

      foreach ($item in $value) {
        if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
          Write-Output "FAIL array property must contain only non-empty strings in $($file.FullName): $arrayProperty"
          $failed = $true
        }
      }
    }
  }

  foreach ($optionalArrayProperty in @("unresolved_risks")) {
    if ($propertyNames -contains $optionalArrayProperty -and $null -ne $report.$optionalArrayProperty) {
      foreach ($item in @($report.$optionalArrayProperty)) {
        if ($null -eq $item -or $item.GetType().Name -ne "String") {
          Write-Output "FAIL optional array property must contain only strings in $($file.FullName): $optionalArrayProperty"
          $failed = $true
        }
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge final report validation failed."
  exit 1
}

Write-Output "SpecBridge final report validation passed."
exit 0
