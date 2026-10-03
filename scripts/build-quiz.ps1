param([string]$Root = "")

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$root = $Root
Set-Location $root

function Fail([string]$Name, [string]$File) {
  Write-Output "build-quiz: $Name $File"
  exit 1
}

$indexPath = Join-Path $root "notes\index.md"
if (-not (Test-Path $indexPath)) { Fail "index-missing" "notes/index.md" }

$byHeading = @{}
foreach ($line in (Get-Content -LiteralPath $indexPath -Encoding UTF8)) {
  if ($line -notmatch '^notes\/.+ \| .+ \| (casual|neutral|formal) \| .+ \| phrase$') { continue }
  $parts = $line -split ' \| '
  $byHeading[$parts[1].Trim()] = @{ Path = $parts[0].Trim(); Ja = $parts[3].Trim() }
}

$headings = New-Object System.Collections.Generic.List[string]
$logDir = Join-Path $root "notes\log"
if (Test-Path $logDir) {
  foreach ($log in (Get-ChildItem -LiteralPath $logDir -Filter "*.md")) {
    foreach ($line in (Get-Content -LiteralPath $log.FullName -Encoding UTF8)) {
      if ($line -notmatch '^.+ \| phrase \| .+ \| (new|update)$') { continue }
      $heading = ($line -split ' \| ')[0].Trim()
      if (-not $byHeading.ContainsKey($heading)) { Fail "quiz-index-miss" $heading }
      if (-not $headings.Contains($heading)) { $headings.Add($heading) }
    }
  }
}

$tz = [TimeZoneInfo]::FindSystemTimeZoneById("Tokyo Standard Time")
$today = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz).ToString("yyyy-MM-dd")
$selected = New-Object System.Collections.Generic.List[string]
if ($headings.Count -gt 0) {
  $pool = New-Object System.Collections.Generic.List[string]
  foreach ($heading in $headings) { $pool.Add($heading) }
  $take = [Math]::Min(100, $pool.Count)
  for ($i = 0; $i -lt $take; $i++) {
    $pick = Get-Random -Minimum 0 -Maximum $pool.Count
    $selected.Add($pool[$pick])
    $pool.RemoveAt($pick)
  }
}

$nl = "`n"
$body = "# クイズ $today$nl"
foreach ($heading in $selected) {
  $item = $byHeading[$heading]
  $body += "$nl- path: $($item.Path)$nl  ja: $($item.Ja)$nl  done: no$nl"
}
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $root "notes\quiz.md"), $body, $utf8)
exit 0
