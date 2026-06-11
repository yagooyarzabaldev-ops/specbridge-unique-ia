# Executor Evidence: tests slice (v5-serious-live-pilot-no-coordinator-remediation)

- packet_id: v5-serious-live-pilot-no-coordinator-remediation-tests
- slice_id: tests
- date: 2026-06-10
- status: complete
- retry_context: second bounded launch; the first launch blocked on a Read/Write-only
  tool allowlist and recommended re-launching with an edit-capable tool, which this
  launch had.

## Change applied

Extended the existing `v5-serious-pilot-status` test block in
`scripts/test-specbridge-cli.ps1` by adding two entries to the existing
`$fieldCheck` assertion loop (previously lines 1169-1182):

```powershell
[pscustomobject]@{ Field = "max_live_retry_per_slice"; Expected = 1 },
[pscustomobject]@{ Field = "pilot_block_rule"; Expected = "two_failures_per_slice_block_the_pilot" }
```

No other test or file was modified.

## Exact assertions now enforced by the block

After this change the `v5-serious-pilot-status` test block deterministically
asserts, via the neighboring PASS/FAIL Write-Output style with the failed-flag
handling already in the loop:

1. `max_live_retry_per_slice` equals `1` (new, via fieldCheck loop).
2. `pilot_block_rule` equals `"two_failures_per_slice_block_the_pilot"` (new,
   via fieldCheck loop).
3. `coordinator_remediation_allowed` equals `$false` (pre-existing dedicated
   assertion in the same block, lines 1184-1191; verified present and unchanged).

## Source verification

`scripts/lib/status.ps1` (`Invoke-V5SeriousPilotStatusCommand`) emits all three
fields with exactly these values, so the assertions are deterministic:
`max_live_retry_per_slice = 1`, `pilot_block_rule =
"two_failures_per_slice_block_the_pilot"`,
`coordinator_remediation_allowed = $false`.

## Validation

The required validation
`powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1`
could not be executed inside this runtime launch because the launch tool
allowlist provides no command-execution tool. The change is two array entries
identical in shape to the adjacent entries in the same literal array; no control
flow was altered. Validation execution is deferred to the runtime operator's
required validation step. This is reported as evidence, not as a passed run.
