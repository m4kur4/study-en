$ErrorActionPreference = "Continue"
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) {
  Write-Output '{"permission":"allow"}'
  exit 0
}

try {
  $payload = $raw | ConvertFrom-Json
} catch {
  Write-Output '{"permission":"allow"}'
  exit 0
}

$command = [string]$payload.command
$isCommit = $command -match '(?i)(?:^|[\s;&|`])git(\.exe)?\s+(-c\s+\S+\s+)*commit\b'
$isPush = $command -match '(?i)(?:^|[\s;&|`])git(\.exe)?\s+(-c\s+\S+\s+)*push\b'
if (-not $isCommit -and -not $isPush) {
  Write-Output '{"permission":"allow"}'
  exit 0
}

if ($command -match '(?i)--no-verify|core\.hooksPath|--force|(^|\s)-f(\s|$)') {
  Write-Output '{"permission":"deny","agent_message":"block-git: refused a bypass flag"}'
  exit 0
}

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $root "scripts\check-notebook.ps1"))) {
  $root = (Get-Location).Path
}
Set-Location $root

$mode = "staged"
if ($command -match '(?i)\bpush\b') { $mode = "push" }

function Run-Check([string]$File, [string[]]$ArgList) {
  $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $File @ArgList 2>&1
  return @{ Code = $LASTEXITCODE; Text = ($output | Out-String).Trim() }
}

$notebook = Run-Check (Join-Path $root "scripts\check-notebook.ps1") @()
if ($notebook.Code -ne 0) {
  $msg = ($notebook.Text -replace '"', "'")
  Write-Output ("{""permission"":""deny"",""agent_message"":""$msg""}")
  exit 0
}

$scan = Run-Check (Join-Path $root "scripts\scan-public.ps1") @("-Mode", $mode)
if ($scan.Code -ne 0) {
  $msg = ($scan.Text -replace '"', "'")
  Write-Output ("{""permission"":""deny"",""agent_message"":""$msg""}")
  exit 0
}

Write-Output '{"permission":"allow"}'
exit 0
