param([string]$Mode = 'success', [int]$SleepSeconds = 0)
$inputText = [Console]::In.ReadToEnd()
if ($SleepSeconds -gt 0) { Start-Sleep -Seconds $SleepSeconds }
if ($Mode -eq 'fail') { [Console]::Error.Write('fake provider failure'); exit 7 }
Write-Output (ConvertTo-Json ([ordered]@{ ok = $true; received = (-not [string]::IsNullOrWhiteSpace($inputText)) }))
exit 0
